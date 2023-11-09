load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/ut_string.ncl"
;*****************************************************
begin

;*****************************************************
; open files and read in monthly data
;*****************************************************
write="FALSE"
REG=getenv("REG")
tend = getenv("yyyy")
tstart= getenv("yyyy2")
tendobs=getenv("yyyym1")
st   = getenv("st")
stm1= getenv("stm1")
refperiod   = getenv("refperiod")
dirplots = getenv("dirplots")
nens=tointeger(getenv("nens"))
figtype=getenv("figtype")
dir = getenv("dir")
anomdir  = getenv("anomdir")
vhc  = addfile (anomdir+"/sst_SPS3.5_"+st+"_all_ano."+refperiod+".nc","r")
tshc = vhc->tso(:,:,0:5,:,:)
timehc = vhc->time(0:5)
sstmhc=new((/24,40,18,180,360/),typeof(tshc),tshc@_FillValue)
sstmhc(:,:,12:17,:,:)=tshc
time=new((/18/),typeof(timehc))
time=fspan(0,17,18)
time@units="months since "+tstart+"-"+st+"-15 12:00:00"
delete(time@calendar)
format= "%c ~C~%Y"
stime=ut_string(time,format)
sstmhc@_FillValue=1.e+20

sstm_iod_w=wgt_areaave_Wrap(sstmhc(:,:,:,{-10:10},{50:70}),1.0,1.0,1)
sstm_iod_e=wgt_areaave_Wrap(sstmhc(:,:,:,{-10:0},{90:108}),1.0,1.0,1)
sstm_iod=sstm_iod_w-sstm_iod_e
delete(sstm_iod_w)
delete(sstm_iod_e)
sstmhc_iod=reshape(sstm_iod,(/40*24,18/))
delete(sstm_iod)
printVarSummary(sstmhc_iod)

v1    = addfile (dir+"/sst_SPS3.5_sps_"+tend+st+"_all_ano."+refperiod+".nc","r")
tstmp    = v1->tso(:,0:5,:,:)
timetmp  = v1->time(0:5)
sstm=new((/nens,18,180,360/),typeof(tstmp),tstmp@_FillValue)
sstm(:,12:17,:,:)=tstmp
time=new((/18/),typeof(timetmp))
time=fspan(0,17,18)
time@units="months since "+tstart+"-"+st+"-15 12:00:00"
delete(time@calendar)
format= "%c ~C~%Y"
stime=ut_string(time,format)
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
ssto=short2flt(fobs->sst(:,0,:,:))
ssto_iod_w=wgt_areaave_Wrap(ssto(:,{-10:10},{50:70}),1.0,1.0,1)
ssto_iod_e=wgt_areaave_Wrap(ssto(:,{-10:0},{90:108}),1.0,1.0,1)
ssto_iod=ssto_iod_w-ssto_iod_e
printVarSummary(ssto_iod)

sstm_iod!0    = "ensemble"
sstm_iod!1    = "time"
sstm_iod&time = time
sstm_iodemtmp=dim_avg_n_Wrap(sstm_iod,0)

sstm_iodem=sstm_iodemtmp(12:17)

printVarSummary(sstm_iodem)

ssto_iod!0    = "time"

print(dimsizes(ssto_iod))
ssto_iodnew=new((/18/),double,sstm_iod@_FillValue)
ssto_iodnew(0:11)=ssto_iod

ssto_iodnew!0    = "time"
ssto_iodnew&time = time

;*****************************************************   
; CALCULATE MIN & MAX and Ensemble Mean
;*****************************************************

;mmax=2  ;dim_max_n(dim_max_n(sstmhc_iod,0),0)+1
;mmin=-2 ;dim_min_n(dim_min_n(sstmhc_iod,0),0)-1

mnmx      = new ((/6,18/), double)
mnmx@_FillValue=-999.
mnmx(0,:) = dim_min(sstm_iod(time|:,ensemble|:))
mnmx(1,:) = dim_max(sstm_iod(time|:,ensemble|:))
mnmx(2,:) = dim_median(sstm_iod(time|:,ensemble|:) )
mnmx(3,:) = dim_avg(sstm_iod(time|:,ensemble|:))
mnmx(3,0:10)=mnmx@_FillValue
printVarSummary(mnmx)
mnmx(4,:) = ssto_iodnew 
mnmx(4,0:10)=mnmx@_FillValue
mnmx(4,12)=mnmx(3,12)
mnmx(4,13:17)=mnmx@_FillValue
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


res@xyMonoLineColor    = False             ; want colored lines
;res@xyLineColors       = (/"Red","Red","black","LightBlue","lightpink"/) ; colors chosen
;res@xyLineColors       = (/"Red","black","black","LightBlue","lightpink"/) ; colors chosen
res@xyLineThicknesses  = (/3,2,2,2,2/)      ; line thicknesses
res@xyDashPatterns     = (/0,1,0,0,0/)      ; make all lines solid

res@tiYAxisString    = "~F35~J~F~C"      ; add an axis title    
res@txFontHeightF    = 0.007            ; change title font heights
res@gsnYRefLine      = 0.0             ; create a reference line
res@tmYLLabelFontHeightF    = 0.012
res@tmXBLabelFontHeightF    = 0.012
res@tiMainString     = REG+" Index issued "+tend+st


res@tmXBFormat = "f"        ; remove the trailing ".0"
res@trXMinF    = 0       ; starting point along X axis
res@trXMaxF    = 17
res@tmXBMode   = "Explicit"
res@tmXBValues = ispan(0,17,1)     ; choose first 13 timesteps
labelsx=stime
labelsx(1)=" "
labelsx(3)=" "
labelsx(5)=" "
labelsx(7)=" "
labelsx(9)=" "
labelsx(11)=" "
labelsx(13)=" "
labelsx(15)=" "
labelsx(17)=" "
res@tmXBLabels = labelsx    

res@xyLineColor    = "black"
res@xyLineThicknessF = 3
res@xyDashPattern = 0

obs_plot = gsn_csm_y (wks,mnmx(5,:),res)       ; create line plot

res@xyLineColor = "Red"
res@xyMonoDashPattern  = True 
res@xyDashPattern = 1

raccordo_plot = gsn_csm_y (wks,mnmx(4,:),res)       ; create line plot

; Create a plot with the area between both curves filled in pink.

delete(res@xyLineColors)
delete(res@xyDashPattern)
res@gsnXYFillColors = "LightBlue"
res@xyLineColor     = -1                           ; We don't want the line, so make it transparent.

bot_plot = gsn_csm_y (wks,mnmx(0:2:2,:),res)  ; Create filled XY plot.

res@gsnXYFillColors = "lightpink"
res@xyLineColor     = -1                           ; We don't want the line, so make it transparent.

up_plot  = gsn_csm_y (wks,mnmx(1:2,:),res)  ; Create another filled XY plot.

; Create a plot with the ensmble mean line filled in red.

res@gsnXYFillColors = "Red"
;res@gsnXYFillColors = "black"
;res@xyLineColor     =  "red"                          ; We don't want the line, so make it transparent.
res@xyLineColors    = "red"

mid_plot  = gsn_csm_y (wks,mnmx(3,:),res)  ; Create another filled XY plot.

;
; Overlay the top and mid plots on the bottom plot.
;
; Don't draw anything yet, because we still need to
; attach a legend and some titles.
;
  overlay(bot_plot,mid_plot)
  overlay(bot_plot,obs_plot)
  overlay(bot_plot,raccordo_plot)
  overlay(bot_plot,up_plot)

getvalues bot_plot                      ; Get plot size for use in
  "vpHeightF" : vph                 ; determining size of
  "vpWidthF"  : vpw                 ; labelbar.
end getvalues

;***********************************************
; legend resources
;***********************************************
lbres                    = True          ; labelbar only resources
lbres@lbAutoManage       = True          ; Necessary to control sizes
lbres@vpWidthF           = 0.2 * vpw     ; labelbar width
lbres@vpHeightF          = 0.2 * vph     ; labelbar height
lbres@lbBoxMajorExtentF  = 0.75          ; puts space between color boxes
lbres@lbFillColors       = (/"black","Red","LightBlue","lightpink"/)  ; labelbar colors
lbres@lbMonoFillPattern  = True          ; Solid fill pattern
lbres@lbLabelFontHeightF = 0.1          ; font height. default is small
lbres@lbLabelJust        = "CenterLeft"  ; left justify labels

lbid = gsn_create_labelbar(wks,4,(/"NOAA","Ensmean","Below median","Above median"/),lbres)         ; create legend

amres = True
amres@amJust           = "TopRight"
amres@amParallelPosF   = -0.3         ; move legend to the right
amres@amOrthogonalPosF = -0.5            ; move the legend down
annoid1 = gsn_add_annotation(bot_plot,lbid,amres)   ; add legend to plot

draw(bot_plot)   ; Draw base plot.
frame(wks)    ; advance frame
;*******************************************************************
geom_value=" 80x80+930+700" 
system("pwd")
print(plname+".png")
system( "composite -geometry "+geom_value+" cmcc_logo_bw.jpg "+plname+".png "+plname+".png")
system( "touch "+plname+"_DONE")
end
