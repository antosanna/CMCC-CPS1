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
tstart =getenv("yyyym1")
tend   =getenv("yyyy")
st   = getenv("st")
nens   = toint(getenv("nens"))
stm1=getenv("st")
SPSSystem=getenv("SPSSystem")
refperiod   = getenv("refperiod")
dirplots=getenv("dirplots")

figtype=getenv("figtype")
dir=getenv("anomdir")

v1    = addfile (dir+"/sst_"+SPSSystem+"_"+tend+st+"_all_ano."+refperiod+".nc","r")
tstmp    = v1->tso(:,0:5,:,:)
timetmp  = v1->time(0:5)
ts=new((/nens,15,180,360/),typeof(tstmp),tstmp@_FillValue)
ts(:,7:12,:,:)=tstmp
time=new((/15/),typeof(timetmp))
time=fspan(0,14,15)+0.5
time@units="months since "+tstart+"-"+stm1+"-15 12:00:00"
delete(time@calendar)
format= "%c ~C~%Y"
stime=cd_string(time,format)
ts@_FillValue=1.e+20

ts!0    = "ensemble"
ts!1    = "time"
ts!2    = "lat"
ts!3    = "lon"

 ncep_dir = getenv("ncep_dir")  
 fname=ncep_dir+"/sstoi.indices"
 strs = asciiread(fname,-1,"string")

 delim = " "
 field = 1    ;this is to select last archived year
 tmp = stringtointeger(str_get_field(strs, field, delim))
; tendobs=(tmp(dimsizes(tmp)-1))
 delete(tmp)
 field = 2    ;this is to select last archived month
 tmp = stringtointeger(str_get_field(strs, field, delim))
 monl=tmp(dimsizes(tmp)-1)
 print(monl)
 if ( REG .eq. "Nino1+2" ) then
    field = 4    ;this is Nino1+2 anomaly index
 else if( REG .eq. "Nino3" ) then
    field = 6    ;this is Nino3 anomaly index
 else if ( REG .eq. "Nino4" ) then
    field = 8    ;this is Nino4 anomaly index
 else if ( REG .eq. "Nino3.4" ) then
    field = 10 ;this is Nino3.4 anomaly index
 end if
 end if
 end if
 end if
 delete(tmp)
 tmp = stringtofloat(str_get_field(strs, field, delim))
 onino3=tmp(dimsizes(tmp)-7:dimsizes(tmp)-1)
 delete(tmp)

;*****************************************************   
; CALCULATE Nino3 Index
;*****************************************************
lt1=getenv("lt1")
lt2=getenv("lt2")
lg1=getenv("lg1")
lg2=getenv("lg2")
print(lt1)
print(lt2)
print(lg1)
print(lg2)
nino3=wgt_areaave_Wrap(ts(:,:,{lt1:lt2},{lg1:lg2}),1,1,0)

nino3!0    = "ensemble"
nino3!1    = "time"
nino3&time = time
ninoemtmp=dim_avg_n_Wrap(nino3,0)

ninoem=ninoemtmp(7:12)

printVarSummary(ninoem)
print(ninoem)

onino3!0    = "time"

print(dimsizes(onino3))
onino3new=new((/15/),double,nino3@_FillValue)
onino3new(0:6)=onino3

onino3new!0    = "time"
onino3new&time = time

;*****************************************************   
; CALCULATE MIN & MAX and Ensemble Mean
;*****************************************************

mnmx      = new ((/6,15/), double)
mnmx@_FillValue=-999.
mnmx(0,:) = dim_min( nino3(time|:,ensemble|:) )
mnmx(1,:) = dim_max( nino3(time|:,ensemble|:) )
mnmx(2,:) = dim_median( nino3(time|:,ensemble|:) )
mnmx(3,:) = dim_avg( nino3(time|:,ensemble|:) )
mnmx(3,0:5)=mnmx@_FillValue
mnmx(4,:) = onino3new 
mnmx(4,0:5)=mnmx@_FillValue
mnmx(4,7)=ninoem(0) ;mnmx(3,6)
mnmx(4,8:14)=mnmx@_FillValue
mnmx(5,:) = onino3new
print("Ho finito di caricare tutto in mnmx")

mmax=max(mnmx)+1
mmin=min(mnmx)-1

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

res@trYMaxF            = mmax
res@trYMinF            = mmin

;res@xyMonoLineColor    = True             ; want colored lines
;res@xyLineThicknesses  = (/3,3,3/)      ; line thicknesses
;res@xyDashPatterns     = (/0,1,0/)      ; make all lines solid

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

mid_plot  = gsn_csm_xy (wks,x,nino3,res)  ; Create another filled XY plot.

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
labels = (/"   NCEP","   SPS4 ensemble mean","   SPS4"/)

lbid   = gsn_create_legend(wks,3,labels,lgres)

amres = True
amres@amJust           = "TopRight"
amres@amParallelPosF   = -0.15         ; move legend to the right
amres@amOrthogonalPosF = -0.48            ; move the legend down
annoid1 = gsn_add_annotation(obs_plot,lbid,amres)   ; add legend to plot

draw(obs_plot)   ; Draw base plot.
frame(wks)    ; advance frame
;*******************************************************************
geom_value=" 80x80+930+670" 
system("pwd")
print(plname+".png")
;system( "composite -geometry "+geom_value+" cmcc_logo_bw.jpg "+plname+".png "+plname+".png")
system( "touch "+plname+"_DONE")

end
