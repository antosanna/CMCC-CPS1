load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/cd_string.ncl"
;*****************************************************
begin

;*****************************************************
; open files and read in monthly data
;*****************************************************
tstart =getenv("yyyym7")
yyyyfore =getenv("yyyy")
st   = getenv("st")
stm7=getenv("stm7")

nens   = toint(getenv("nens"))
SPSSystem=getenv("SPSSystem")
refperiod   = getenv("refperiod")

dirplots=getenv("dirplots")
figtype=getenv("figtype")

dir=getenv("anomdir")
region=getenv("region")
v1    = addfile (dir+"/sst_"+SPSSystem+"_"+yyyyfore+st+"_all_ano."+refperiod+".nc","r")
tstmp    = v1->tso(:,0:5,:,:)
timetmp  = v1->time(0:5)
lat=v1->lat

rad    = 4.0*atan(1.0)/180.0
clat   = cos(lat*rad)
copy_VarMeta(lat,clat)

ts=new((/nens,15,180,360/),typeof(tstmp),tstmp@_FillValue)
ts(:,7:12,:,:)=tstmp
time=new((/15/),typeof(timetmp))
time=fspan(0,14,15)+0.5
time@units="months since "+tstart+"-"+stm7+"-15 12:00:00"
delete(time@calendar)
format= "%c ~C~%Y"
stime=cd_string(time,format)
ts@_FillValue=1.e+20

ts!0    = "ensemble"
ts!1    = "time"
ts!2    = "lat"
ts!3    = "lon"



;;;;reading observed monthly roni value (ie. relative nino3.4 -> to become roni there is 3-monthly running average we are skipping)

obsf_roni=getenv("obsf_roni")
print(obsf_roni)
strs = asciiread(obsf_roni,-1,"string")

delim = " "
field = 1    ;this is to select last archived year
tmp = stringtointeger(str_get_field(strs, field, delim))
; tendobs=(tmp(dimsizes(tmp)-1))
delete(tmp)

field = 2    ;this is to select last archived month
tmp = stringtointeger(str_get_field(strs, field, delim))
monl=tmp(dimsizes(tmp)-1)
delete(tmp)

field=3   ;this is to select relative nino3.4 values
tmp = stringtofloat(str_get_field(strs, field, delim))
oroni=tmp(dimsizes(tmp)-7:dimsizes(tmp)-1)
delete(tmp)

oroni!0    = "time"
oroninew=new((/15/),double,ts@_FillValue)
oroninew(0:6)=oroni

oroninew!0    = "time"
oroninew&time = time


;*****************************************************   
; CALCULATE RONI Index
;*****************************************************
lat1n=getenv("lat1n")
lat2n=getenv("lat2n")
lon1n=getenv("lon1n")
lon2n=getenv("lon2n")

lat1t=getenv("lat1t")
lat2t=getenv("lat2t")
lon1t=getenv("lon1t")
lon2t=getenv("lon2t")


nino3=wgt_areaave_Wrap(ts(:,:,{lat1n:lat2n},{lon1n:lon2n}),clat({lat1n:lat2n}),1,0)
tropicsst=wgt_areaave_Wrap(ts(:,:,{lat1t:lat2t},{lon1t:lon2t}),clat({lat1t:lat2t}),1,0)

roni_tmp=nino3-tropicsst

stdfile=getenv("stdfile")
stf=addfile(stdfile,"r")
factor_tmp=stf->roni_factor


factor=new((/15/),float,ts@_FillValue)
factor(7:12)=factor_tmp


printVarSummary(roni_tmp)
printVarSummary(factor)


roni=roni_tmp*conform(roni_tmp,factor,1)
roni!0    = "ensemble"
roni!1    = "time"
roni&time = time
roniemtmp=dim_avg_n_Wrap(roni,0)

roniem=roniemtmp(7:12)

;*****************************************************   
; CALCULATE MIN & MAX and Ensemble Mean
;*****************************************************

mnmx      = new ((/6,15/), double)
mnmx@_FillValue=-999.
mnmx(0,:) = dim_min( roni(time|:,ensemble|:) )
mnmx(1,:) = dim_max( roni(time|:,ensemble|:) )
mnmx(2,:) = dim_median( roni(time|:,ensemble|:) )
mnmx(3,:) = dim_avg( roni(time|:,ensemble|:) )
mnmx(3,0:5)=mnmx@_FillValue
mnmx(4,:) = oroninew 
mnmx(4,0:5)=mnmx@_FillValue
mnmx(4,7)=roniem(0) ;mnmx(3,6)
mnmx(4,8:14)=mnmx@_FillValue
mnmx(5,:) = oroninew
print("Ho finito di caricare tutto in mnmx")

mmax=max(mnmx)+1
mmin=min(mnmx)-1

ymin = floor(mmin)
ymax = ceil(mmax)
dy   = 1.0
nticks = toint((ymax-ymin)/dy)+1
yticks = fspan(ymin,ymax,nticks)

;*****************************************************
; -- PLOT SETTINGS
;*****************************************************
plname=dirplots+"/sst_RONI_"+region+"_"+yyyyfore+"_"+st
wks = gsn_open_wks(figtype,plname)                 ; create plot
colors = (/"white","black","Red","LightBlue","lightpink"/)
gsn_define_colormap(wks, colors)  


res                    = True              ; plot mods desired
res@gsnDraw            = False             ; don't draw yet
res@gsnFrame           = False             ; don't advance frame yet

res@vpHeightF          = 0.4               ; change aspect ratio of plot
res@vpWidthF           = 0.7

res@trYMaxF            = 6. ;mmax
res@trYMinF            = -3. ;mmin

res@tmYLMode   = "Explicit"
res@tmYLValues = yticks
res@tmYLLabels = sprintf("%3.1f",yticks)

res@tmYLMajorLengthF   = 0.01
res@tmYLMinorOn        = True
res@tmYROn = False
res@tmYLMinorPerMajor  = 4 


;res@xyMonoLineColor    = True             ; want colored lines
;res@xyLineThicknesses  = (/3,3,3/)      ; line thicknesses
;res@xyDashPatterns     = (/0,1,0/)      ; make all lines solid

res@tiYAxisString    = "~F35~J~F~C"      ; add an axis title    
res@txFontHeightF    = 0.007            ; change title font heights
res@gsnYRefLine      = 0.0             ; create a reference line
res@tmYLLabelFontHeightF    = 0.012
res@tmXBLabelFontHeightF    = 0.012
res@tiMainString     = "Relative "+region+" Index issued "+yyyyfore+st


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
res@xyLineColor    = "blue"
res@xyLineThicknessF = 2      ; line thicknesses
res@xyDashPattern = 1
res@xyMarkLineMode = "MarkLines" 
res@xyMarker = 16
res@xyMarkerColor = "blue"
res@xyMarkerSizeF = 3

mid_plot  = gsn_csm_xy (wks,x,roni,res)  ; Create another filled XY plot.

delete(res@xyLineThicknessF)
delete(res@xyDashPattern)
delete(res@xyLineColor)
res@xyLineColor = "orange"
res@xyLineThicknessF = 5
res@xyDashPattern = 0
res@xyMarkLineMode = "MarkLines" 
res@xyMarker = 16
res@xyMarkerColor = "orange"
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
lgres@lgLineColors       = (/"black","orange","blue"/)
lgres@lgDashIndexes      = (/0,0,1/)
lgres@lgLineThicknesses  = (/3,5,3/)

lgres@lgMarkerIndexes    = (/-1,16,16/)
lgres@lgMarkerColors     = (/"black","orange","blue"/)
lgres@lgMarkerSizeF      = 0.005


lgres@lgLabelFontHeightF = .1            ; set the legend label font thickness
lgres@vpWidthF           = 0.24           ; width of legend (NDC)
lgres@vpHeightF          = 0.08            ; height of legend (NDC)
lgres@lgPerimOn          = False
labels = (/"   NOAA","   SPS4 ensemble mean","   SPS4"/)

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
