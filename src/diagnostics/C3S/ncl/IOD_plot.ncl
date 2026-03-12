load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/cd_string.ncl"
;*****************************************************
begin

;*****************************************************
; open files and read in monthly data
;*****************************************************
write="FALSE"
REG=getenv("REG")
tend = getenv("yyyy")
tstart= getenv("yyyy2")
tendobs= getenv("yyyym1")
st   = getenv("st")
stm1= getenv("stm1")
refperiod   = getenv("refperiod")
dirplots = getenv("dirplots")
nens= tointeger(getenv("nens"))
figtype=getenv("figtype")
dir = getenv("dir")

v1    = addfile (dir+"/sst_sps4_"+tend+st+"_all_ano."+refperiod+".nc","r")
tstmp    = v1->tso(:,0:5,:,:)
timetmp  = v1->time(0:5)
sstm=new((/nens,15,180,360/),typeof(tstmp),tstmp@_FillValue)
sstm(:,7:12,:,:)=tstmp
time=new((/15/),typeof(timetmp))
time=fspan(0,14,15)+0.5
time@units="months since "+tstart+"-"+st+"-15 12:00:00"
delete(time@calendar)
format= "%c ~C~%Y"
stime=cd_string(time,format)
sstm@_FillValue=1.e+20
sstm_iod_w=wgt_areaave_Wrap(sstm(:,:,{-10:10},{50:70}),1.0,1.0,1)
sstm_iod_e=wgt_areaave_Wrap(sstm(:,:,{-10:0},{90:108}),1.0,1.0,1)
sstm_iod=sstm_iod_w-sstm_iod_e
printVarSummary(sstm_iod)

sstm!0    = "ensemble"
sstm!1    = "time"
sstm!2    = "lat"
sstm!3    = "lon"

dirobs=getenv("dirobs")
fobsname = dirobs+"/anom_sst_"+tstart+st+"-"+tendobs+stm1+".nc"
print(fobsname)
fobs=addfile(fobsname,"r")
ssto=fobs->analysed_sst(5:11,:,:)
ssto_iod_w=wgt_areaave_Wrap(ssto(:,{-10:10},{50:70}),1.0,1.0,1)
ssto_iod_e=wgt_areaave_Wrap(ssto(:,{-10:0},{90:108}),1.0,1.0,1)
ssto_iod=ssto_iod_w-ssto_iod_e
printVarSummary(ssto_iod)

sstm_iod!0    = "ensemble"
sstm_iod!1    = "time"
sstm_iod&time = time
sstm_iodemtmp=dim_avg_n_Wrap(sstm_iod,0)

sstm_iodem=sstm_iodemtmp(7:12)

printVarSummary(sstm_iodem)

ssto_iod!0    = "time"

print(dimsizes(ssto_iod))
ssto_iodnew=new((/15/),double,sstm_iod@_FillValue)
ssto_iodnew(0:6)=ssto_iod

ssto_iodnew!0    = "time"
ssto_iodnew&time = time

;*****************************************************   
; CALCULATE MIN & MAX and Ensemble Mean
;*****************************************************

;mmax=2  ;dim_max_n(dim_max_n(sstmhc_iod,0),0)+1
;mmin=-2 ;dim_min_n(dim_min_n(sstmhc_iod,0),0)-1

mnmx      = new ((/6,15/), double)
mnmx@_FillValue=-999.
mnmx(0,:) = dim_min(sstm_iod(time|:,ensemble|:))
mnmx(1,:) = dim_max(sstm_iod(time|:,ensemble|:))
mnmx(2,:) = dim_median(sstm_iod(time|:,ensemble|:) )
mnmx(3,:) = dim_avg(sstm_iod(time|:,ensemble|:))
mnmx(3,0:5)=mnmx@_FillValue
printVarSummary(mnmx)
mnmx(4,:) = ssto_iodnew 
mnmx(4,0:5)=mnmx@_FillValue
mnmx(4,7)=sstm_iodem(0)  ;mnmx(3,12)
mnmx(4,8:14)=mnmx@_FillValue
mnmx(5,:) = ssto_iodnew

mmax=max(mnmx)+1
mmin=min(mnmx)-1
mint=(mmax-mmin)
;*****************************************************
; -- PLOT SETTINGS
;*****************************************************
plname=dirplots+"/sst_"+REG+"_mem_"+tend+"_"+st
wks = gsn_open_wks(figtype,plname)                 ; create plot
colors = (/"white","black","Red","LightBlue","lightpink"/)
gsn_define_colormap(wks, colors)  


res                    = True              ; plot mods desired
res@gsnDraw            = False             ; don't draw yet
res@gsnFrame           = False             ; don't advance frame yet

res@vpHeightF          = 0.4               ; change aspect ratio of plot
res@vpWidthF           = 0.7

y = fspan(toint(mmin),toint(mmax),toint(mint))
nyint = ispan(0,toint(mint)-1,1)

res@trYMinF           = mmin
res@trYMaxF           = mmax

res@tmYLMode          = "Explicit"              ; explicit labels
res@tmYLValues        = fspan(toint(mmin),toint(mmax),toint(mint)) ;fspan(-2,2,11)                   ; location of label
res@tmYLLabels        = y  ;(/-2,-1.6,-1.2,-0.8,-0.4,0,0.4,0.8,1.2,1.6,2/)               ; labels themselves
;res@tmLabelAutoStride = True                    ; nice stride on labels


;res@xyMonoLineColor    = False             ; want colored lines
;res@xyLineColors       = (/"Red","Red","black","LightBlue","lightpink"/) ; colors chosen
;res@xyLineColors       = (/"Red","black","black","LightBlue","lightpink"/) ; colors chosen
;res@xyLineThicknesses  = (/3,2,2,2,2/)      ; line thicknesses
;res@xyDashPatterns     = (/0,1,0,0,0/)      ; make all lines solid

res@tiYAxisString    = "~F35~J~F~C"      ; add an axis title    
res@txFontHeightF    = 0.007            ; change title font heights
res@gsnYRefLine      = 0.0             ; create a reference line
res@tmYLLabelFontHeightF    = 0.012
res@tmXBLabelFontHeightF    = 0.012
res@tiMainString     = REG+" Index issued "+tend+st


res@tmXBFormat = "f"        ; remove the trailing ".0"
res@trXMinF    = min(ispan(0,14,1)+0.5)       ; starting point along X axis
res@trXMaxF    = max(ispan(0,14,1)+0.5)
res@tmXBMode   = "Explicit"
res@tmXBValues = ispan(0,14,1)+0.5     ; choose first 13 timesteps
labelsx=stime
do i=0,dimsizes(stime)-1,2
   labelsx(i)=""
end do
res@tmXBLabels = labelsx    

res@tmXBMinorValues   = ispan(0,14,1)
res@tmXBMinorPerMajor = 1
res@tmXBMajorLengthF  = 0.0


x=ispan(0,14,1)+0.5

res@xyLineColor = "black"
res@xyLineThicknessF = 3
obs_plot = gsn_csm_xy (wks,x,mnmx(5,:),res)       ; create line plot

delete(res@xyLineColor)
delete(res@xyLineThicknessF)
res@xyLineColor = "Grey"
res@xyLineThicknessF = 2
raccordo_plot = gsn_csm_xy (wks,x,mnmx(4,:),res)       ; create line plot

; Create a plot with the ensemble plume in red.

delete(res@xyLineColor)
delete(res@xyLineThicknessF)
res@xyLineColor    = "red"
res@xyLineThicknessF = 2      ; line thicknesses
res@xyDashPattern = 1
res@xyMarkLineMode = "MarkLines" 
res@xyMarker = 16
res@xyMarkerColor = "red"
res@xyMarkerSizeF = 3

mid_plot  = gsn_csm_xy (wks,x,sstm_iod,res)  ; Create another filled XY plot.

delete(res@xyLineThicknessF)
delete(res@xyDashPattern)
delete(res@xyLineColor)
res@xyLineColor = "Green"
res@xyLineThicknessF = 5
res@xyDashPattern = 0
res@xyMarkLineMode = "MarkLines" 
res@xyMarker = 16
res@xyMarkerColor = "Green"
res@xyMarkerSizeF = 5

ensm_plot = gsn_csm_xy (wks,x,mnmx(3,:),res)


;
; Overlay the top and mid plots on the bottom plot.
;
; Don't draw anything yet, because we still need to
; attach a legend and some titles.
;
  overlay(obs_plot,raccordo_plot)
  overlay(obs_plot,mid_plot)
  overlay(obs_plot,ensm_plot)

getvalues obs_plot                      ; Get plot size for use in
  "vpHeightF" : vph                 ; determining size of
  "vpWidthF"  : vpw                 ; labelbar.
end getvalues

;***********************************************
; legend resources
;***********************************************
lgres                    = True

lgres@lgAutoManage        = False
lgres@lgMonoItemType      = False
lgres@lgMonoDashIndex     = False
lgres@lgMonoLineThickness = False

lgres@lgItemTypes        = (/"Lines","MarkLines","MarkLines"/)
lgres@lgLineColors       = (/"black","green","red"/)
lgres@lgDashIndexes      = (/0,0,1/)
lgres@lgLineThicknesses  = (/3,5,3/)

lgres@lgMarkerIndexes    = (/-1,16,16/)
lgres@lgMarkerColors     = (/"black","green","red"/)
lgres@lgMarkerSizeF      = 0.005


lgres@lgLabelFontHeightF = .1            ; set the legend label font thickness
lgres@vpWidthF           = 0.24           ; width of legend (NDC)
lgres@vpHeightF          = 0.08            ; height of legend (NDC)
lgres@lgPerimOn          = False
labels = (/"  ESA CCI","  SPS4 ensemble mean","  SPS4"/)

lbid   = gsn_create_legend(wks,3,labels,lgres)

amres = True
amres@amJust           = "TopRight"
amres@amParallelPosF   = -0.15         ; move legend to the right
amres@amOrthogonalPosF = -0.48            ; move the legend down
annoid1 = gsn_add_annotation(obs_plot,lbid,amres)   ; add legend to plot

draw(obs_plot)   ; Draw base plot.
frame(wks)    ; advance frame
;*******************************************************************
geom_value=" 80x80+930+700" 
system("pwd")
print(plname+".png")
;system( "composite -geometry "+geom_value+" cmcc_logo_bw.jpg "+plname+".png "+plname+".png")
system( "touch "+plname+"_DONE")
end
