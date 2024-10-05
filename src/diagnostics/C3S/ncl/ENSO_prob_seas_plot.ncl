load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
;load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/ut_string.ncl"
;*****************************************************

begin
;*****************************************************
; open files and read in monthly data
;*****************************************************
print("enter in ncl")
write="FALSE"
REG=getenv("REG")
ytstart  = getenv("yyyy")
tend     = ytstart  
st       = getenv("st")
ytstartm1 = getenv("yym1")
ytstartp1 = getenv("yymp1")
stm1      = getenv("stm1")
stp1      = getenv("stp1")
dirplots  = getenv("dirplots")
refperiod   = getenv("refperiod")
print("before nens")
nensstr=getenv("nens")
print("after nens")
nens=tointeger(nensstr)
nyearhc=toint(getenv("nyearhc"))
nenshc=toint(getenv("nrunhind"))
print("nyearhc "+nyearhc)
print("nenshc "+nenshc)
figtype=getenv("figtype")

;if ( REG.eq."Nino3.4") then
;   write="TRUE"
;end if

inputmall=getenv("inputmall")
v1=addfile(inputmall,"r")
tstmp    = v1->tso(:,0:5,:,:)
inputmclimall=getenv("inputmclimall")
vclim  = addfile (inputmclimall,"r")
tstmp_clim  = vclim->tso(:,:,0:5,:,:)
ts_seas=new((/nens,4,180,360/),typeof(tstmp),tstmp@_FillValue)
ts_clim_seas=new((/nyearhc,nenshc,4,180,360/),typeof(tstmp_clim),tstmp_clim@_FillValue)
do lead = 0,3
   ts_seas(:,lead,:,:)  = dim_avg_n_Wrap(tstmp(:,lead:lead+2,:,:),1)
   ts_clim_seas(:,:,lead,:,:)  = dim_avg_n_Wrap(tstmp_clim(:,:,lead:lead+2,:,:),2)
end do
timetmp  = v1->time(0:5)
tstmp@_FillValue=-9999.
ts=new((/nens,6,180,360/),typeof(tstmp),tstmp@_FillValue)
ts_clim=new((/nyearhc,nenshc,6,180,360/),typeof(tstmp),tstmp@_FillValue)
ts(:,1:4,:,:)=ts_seas  ;(:,1:4,:,:)
ts_clim(:,:,1:4,:,:)=ts_clim_seas  ;(:,1:4,:,:)
time=new((/6/),typeof(timetmp))
time=fspan(0,5,6)
timem1=time
timep1=time
timem1@units="months since "+ytstartm1+"-"+stm1+"-15 12:00:00"
time@units="months since "+ytstart+"-"+st+"-15 12:00:00"
timep1@units="months since "+ytstartp1+"-"+stp1+"-15 12:00:00"
;delete(time@calendar)
month_abbr=(/"","J","F","M","A","M","J","J","A","S","O","N","D"/)

utc_date_m1 = cd_calendar(timem1, 0)
yearm1   = tointeger(utc_date_m1(:,0))
monthm1  = tointeger(utc_date_m1(:,1))
utc_date = cd_calendar(time, 0)
year   = tointeger(utc_date(:,0))
month  = tointeger(utc_date(:,1))
utc_date_p1 = cd_calendar(timep1, 0)
yearp1   = tointeger(utc_date_p1(:,0))
monthp1  = tointeger(utc_date_p1(:,1))

stime=sprinti("%0.4i", year)+"~C~"+month_abbr(monthm1)+month_abbr(month)+month_abbr(monthp1)
ts@_FillValue=1.e+20

ts!0    = "ensemble"
ts!1    = "time"
ts!2    = "lat"
ts!3    = "lon"

ts_clim!0    = "ensemble"
ts_clim!1    = "year"
ts_clim!2    = "time"
ts_clim!3    = "lat"
ts_clim!4    = "lon"

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
nino3_occ_blw=where(nino3.lt.-0.5,1,0)
nino3_occ_nrm=where(nino3.ge.-0.5 .and. nino3.le.0.5,1,0)
nino3_occ_abv=where(nino3.gt.0.5,1,0)
nina_prob=dim_avg_n_Wrap(nino3_occ_blw,0)*100
nino_prob=dim_avg_n_Wrap(nino3_occ_abv,0)*100
neutr_prob=dim_avg_n_Wrap(nino3_occ_nrm,0)*100

nino3_clim=wgt_areaave_Wrap(ts_clim(:,:,:,{lt1:lt2},{lg1:lg2}),1,1,0)
nino3_clim_occ_blw=where(nino3_clim.lt.-0.5,1,0)
nino3_clim_occ_nrm=where(nino3_clim.ge.-0.5 .and. nino3_clim.le.0.5,1,0)
nino3_clim_occ_abv=where(nino3_clim.gt.0.5,1,0)
nina_clim_prob=dim_avg_n_Wrap(reshape(nino3_clim_occ_blw,(/nyearhc*nenshc,6/)),0)*100
nino_clim_prob=dim_avg_n_Wrap(reshape(nino3_clim_occ_abv,(/nyearhc*nenshc,6/)),0)*100
neutr_clim_prob=dim_avg_n_Wrap(reshape(nino3_clim_occ_nrm,(/nyearhc*nenshc,6/)),0)*100

print("nina_prob   neutr_prob   nino_prob")
print(nina_prob+" "+neutr_prob+" "+nino_prob)

;*****************************************************   
; CALCULATE MIN & MAX and Ensemble Mean
;*****************************************************

mnmx      = new ((/6,6/), double)
mnmx@_FillValue=-999.
mnmx(0,:) = nina_prob
mnmx(1,:) = neutr_prob
mnmx(2,:) = nino_prob
mnmx(3,:) = nina_clim_prob
mnmx(4,:) = neutr_clim_prob
mnmx(5,:) = nino_clim_prob

print("ready to plot")
;*****************************************************
; -- PLOT SETTINGS
;*****************************************************
plname=dirplots+"/sst_"+REG+"_prob_"+tend+"_"+st
wks = gsn_open_wks(figtype,plname)                 ; create plot
colors = (/"white","black","red","blue","grey"/)
gsn_define_colormap(wks, colors)  

sres = True
sres@vpWidthF = 0.7
sres@vpHeightF = 0.5
sres@vpXF = .15
sres@trYMinF = 0
sres@trYMaxF = 100
sres@gsnDraw = True
sres@gsnFrame = False
sres@gsnXYBarChart = True
sres@gsnXYBarChartBarWidth = 0.15           ; change bar widths

sres@tmXBFormat = "f"        ; remove the trailing ".0"
sres@trXMinF    = 0       ; starting point along X axis
sres@trXMaxF    = 5
sres@tmXBMode   = "Explicit"
sres@tmXBValues = ispan(1,4,1)     ; choose first 13 timesteps
labelsx=stime(1:4)
sres@tmXBLabels = labelsx    
sres@tmXBLabelFontHeightF = 0.012    
sres@tmYRLabelFontHeightF = 0.012
sres@tmXUseBottom     = False
sres@tmYUseLeft     = False
sres@tmXTMajorLengthF = 0
sres@tmXTMajorLineColor = -1
sres@tmXTMinorLengthF = 0
sres@tmXTMinorLineColor = -1
sres@tmYRMajorLengthF = 0
sres@tmYRMajorLineColor = -1
sres@tmYRMinorLengthF = 0
sres@tmYRMinorLineColor = -1

sres@tiMainFontHeightF = 0.02
sres@tiMainFont = "helvetica"
sres@tiMainString = "                "+REG+" ~C~ Probability of ENSO Conditions"
sres@gsnCenterString = "Neutral ENSO: -0.5 ~F35~J~F~C to 0.5 ~F35~J~F~C"
sres@tiYAxisString = "Probabiliy (%)"
sres@tiYAxisAngleF = 90.
sres@tiYAxisFontHeightF = 0.015
   
sres@gsnXYBarChartColors = (/"blue"/)	
int1=fspan(-0.15,4.85,6)
plot1 = gsn_csm_xy(wks,int1,mnmx(0,:),sres)		; draw each time series
sres@gsnXYBarChartColors = (/"grey"/)					; seperately, not
int2=fspan(0.,5,6)
plot2 = gsn_csm_xy(wks,int2,mnmx(1,:),sres)		; advancing the frame
sres@gsnXYBarChartColors = (/"red"/)					; but tweaking where
int3=fspan(0.15,5.15,6)
plot3 = gsn_csm_xy(wks,int3,mnmx(2,:),sres)		; each time series is


getvalues plot1                      ; Get plot size for use in
    "vpXF"      : vpx
    "vpYF"      : vpy
    "vpHeightF" : vph                 ; determining size of
    "vpWidthF"  : vpw                 ; labelbar.
end getvalues

res           = True
res@gsnFrame  = False
res@gsnDraw   = True
res@trYMinF = 0
res@trYMaxF = 100

res@tmXBFormat = "f"        ; remove the trailing ".0"
res@trXMinF    = 0       ; starting point along X axis
res@trXMaxF    = 5
res@tmXBMode   = "Explicit"
res@tmXBValues = ispan(1,4,1)     ; choose first 13 timesteps
labelsx=stime(1:4)
res@tmXBLabels = labelsx
res@tmXBLabelFontHeightF = 0.012
res@tmYRLabelFontHeightF = 0.012
res@tmXUseBottom     = False
res@tmYUseLeft     = False
res@tmXTMajorLengthF = 0
res@tmXTMajorLineColor = -1
res@tmXTMinorLengthF = 0
res@tmXTMinorLineColor = -1
res@tmYRMajorLengthF = 0
res@tmYRMajorLineColor = -1
res@tmYRMinorLengthF = 0
res@tmYRMinorLineColor = -1

res@vpXF      = vpx
res@vpYF      = vpy
res@vpWidthF  = vpw
res@vpHeightF = vph

res@xyLineColors      = (/"blue"/) 
res@xyLineThicknesses  = (/2.5/)      ; line thicknesses
res@xyDashPatterns     = (/3/)
plot4 = gsn_csm_xy(wks,int2,mnmx(3,:),res)		; draw each time series
delete(res@xyLineColors)
delete(res@xyLineThicknesses)
delete(res@xyDashPatterns)
res@xyLineColors      = (/"grey"/) 
res@xyLineThicknesses  = (/2.5/)      ; line thicknesses
res@xyDashPatterns     = (/3/)
plot5 = gsn_csm_xy(wks,int2,mnmx(4,:),res)		; draw each time series
delete(res@xyLineColors)
delete(res@xyLineThicknesses)
delete(res@xyDashPatterns)
res@xyLineColors      = (/"red"/) 
res@xyLineThicknesses  = (/2.5/)      ; line thicknesses
res@xyDashPatterns     = (/3/)
res@XPosPercent        = 73
res@YPosPercent        = 73
res@LineLabelWhiteSpacePercent = 1
res@ItemSpacePercent   = 4
plot6 = gsn_csm_xy(wks,int2,mnmx(5,:),res)		; draw each time series

lbres                    = True          ; labelbar only resources
lbres@lbAutoManage       = True
lbres@vpWidthF           = 0.25*vpw           ; labelbar width
lbres@vpHeightF          = 0.1*vph           ; labelbar height
lbres@lbBoxMajorExtentF  = 0.75          ; puts space between color boxes
;lbres@lbOrientation      = "horizontal"
;lbres@lbLabelFont      = "Helvetica"     ; label font
;lbres@lbLabelPosition  = "Center"             ; label position
;lbres@lbLabelAlignment = "BoxCenters"         ; label orientation
lbres@lbPerimFillColor   = "Transparent"
lbres@lbFillColors       = (/"red","grey","blue"/)
lbres@lbMonoFillPattern  = True          ; Solid fill pattern
lbres@lbLabelFontHeightF = 0.008         ; font height. default is small
lbres@lbLabelJust        = "TopLeft"  ; left justify labels
lbres@lbPerimOn          = False
lbres@lgPerimColor 	 = "white"
labels = (/"El Nino","Neutral","La Nina"/)

gsn_labelbar_ndc(wks,3,labels,0.7,0.8,lbres)	; draw right labelbar column
	
lbres@lbFillColors       = (/"blue","grey","red"/)

lineres = True
lineres@lgLineColors = (/"blue","grey","red"/) ; line colors
lineres@lgDashIndexes  = (/3,3,3/)
lineres@lgLineThicknesses = 2.5                        ; line thicknesses
lineres@LineLengthPercent = 5.                         ; expressed as %, 0->100, length of line

textres = True
textres@lgLabelFontHeights = (/0.0085,0.0085,0.0085/)
textres@lgLabels = (/"La Nina ~C~climatology","Neutral ~C~climatology","El Nino ~C~climatology"/)

simple_legend_ndc(wks,res,lineres,textres)

frame(wks)      
;*******************************************************************
geom_value=" 80x80+930+700" 
system("pwd")
print(plname+".png")
system( "composite -geometry "+geom_value+" cmcc_logo_bw.jpg "+plname+".png "+plname+".png")
system( "touch "+plname+"_DONE")

end
