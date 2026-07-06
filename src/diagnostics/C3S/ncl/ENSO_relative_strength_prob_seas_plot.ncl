load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
;load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/ut_string.ncl"
;*****************************************************

begin
;*****************************************************
; open files and read in monthly data
;*****************************************************
REG = getenv("REG")
ytstart  = getenv("yyyy")
tend     = ytstart  
st       = getenv("st")
ytstartm1 = getenv("yym1")
ytstartp1 = getenv("yymp1")
stm1      = getenv("stm1")
stp1      = getenv("stp1")
dirplots  = getenv("dirplots")
refperiod   = getenv("refperiod")
nensstr= getenv("nens")
nens=tointeger(nensstr)
figtype=getenv("figtype")
;--------------------------------------------------------------------
nleadseas=4
inputmall= getenv("inputmall")
v1=addfile(inputmall,"r")
tstmp    = v1->tso(:,0:5,:,:)
lat = v1->lat
rad    = 4.0*atan(1.0)/180.0
clat   = cos(lat*rad)
copy_VarMeta(lat,clat)
ts_seas=new((/nens,nleadseas,180,360/),typeof(tstmp),tstmp@_FillValue)
do lead = 0,nleadseas-1
   ts_seas(:,lead,:,:)  = dim_avg_n_Wrap(tstmp(:,lead:lead+2,:,:),1)
end do
timetmp  = v1->time(0:5)
time_seas=v1->time(1:4)
tstmp@_FillValue=-9999.
ts=new((/nens,6,180,360/),typeof(tstmp),tstmp@_FillValue)
ts(:,1:4,:,:)=ts_seas  

time=new((/6/),typeof(timetmp))
time=fspan(0,5,6)
timem1=time
timep1=time
timem1@units="months since "+ytstartm1+"-"+stm1+"-15 12:00:00"
time@units="months since "+ytstart+"-"+st+"-15 12:00:00"
timep1@units="months since "+ytstartp1+"-"+stp1+"-15 12:00:00"
month_abbr=(/"","J","F","M","A","M","J","J","A","S","O","N","D"/)
month_str=(/"","January","February","March","April","May","June","July","August","September", \
           "October","November","December"/)

utc_date = cd_calendar(time, 0)
year   = tointeger(utc_date(:,0))
month  = tointeger(utc_date(:,1))

utc_date_m1 = cd_calendar(timem1, 0)
yearm1   = tointeger(utc_date_m1(:,0))
monthm1  = tointeger(utc_date_m1(:,1))

utc_date_p1 = cd_calendar(timep1, 0)
yearp1   = tointeger(utc_date_p1(:,0))
monthp1  = tointeger(utc_date_p1(:,1))

stime=sprinti("%0.4i", year)+"~C~"+month_abbr(monthm1)+month_abbr(month)+month_abbr(monthp1)
startdatestr=month_str(month(0))+" "+sprinti("%0.4i", year(0))
ts@_FillValue=-9999.

ts!0    = "ensemble"
ts!1    = "time"
ts!2    = "lat"
ts!3    = "lon"

;*****************************************************   
; CALCULATE Nino3 Index
;*****************************************************
lat1n=getenv("lat1n")
lat2n=getenv("lat2n")
lon1n=getenv("lon1n")
lon2n=getenv("lon2n")

lat1t=-20. 
lat2t=20.
lon1t=0. 
lon2t=360. 

; --------- Load standard deviation ----------
stdfile=getenv("stdfile")
stf=addfile(stdfile,"r")
factor=stf->roni_factor

;------------------------------------------------------------
nino3=wgt_areaave_Wrap(ts(:,:,{lat1n:lat2n},{lon1n:lon2n}),clat({lat1n:lat2n}),1,0)
tropicsst=wgt_areaave_Wrap(ts(:,:,{lat1t:lat2t},{lon1t:lon2t}),clat({lat1t:lat2t}),1,0)
nino3_seas=new((/nens,nleadseas/),typeof(nino3),nino3@_FillValue)
tropicsst_seas=new((/nens,nleadseas/),typeof(tropicsst),tropicsst@_FillValue)
l1=0
l2=2
do lead=0,nleadseas-1
   nino3_seas(:,lead)=dim_avg_n_Wrap(nino3(:,l1:l2),1)
   tropicsst_seas(:,lead)=dim_avg_n_Wrap(tropicsst(:,l1:l2),1)
   l1=l1+1
   l2=l2+1
end do

roni_tmp=nino3_seas-tropicsst_seas
copy_VarMeta(nino3_seas,roni_tmp)
printVarSummary(roni_tmp)
roni_tmp!1    = "time"
roni_tmp&time=time_seas

roni=roni_tmp*conform(roni_tmp,factor,1)
roni!0    = "ensemble"
roni!1    = "time"
roni&time = time_seas

roni_occ_extreme_blw=where(roni.le.-2,1.,0.)
copy_VarMeta(roni,roni_occ_extreme_blw)
roni_occ_strong_blw=where(roni.le.-1.5 .and. roni.gt.-2.,1.,0.)
copy_VarMeta(roni,roni_occ_strong_blw)
roni_occ_moderate_blw=where(roni.le.-1. .and. roni.gt.-1.5 ,1.,0.)
copy_VarMeta(roni,roni_occ_moderate_blw)
roni_occ_weak_blw=where(roni.le.-0.5 .and. roni.gt.-1.,1.,0.)
copy_VarMeta(roni,roni_occ_weak_blw)

roni_occ_nrm=where(roni.gt.-0.5 .and. roni.lt.0.5,1.,0.)
copy_VarMeta(roni,roni_occ_nrm)

roni_occ_weak_abv=where(roni.ge.0.5 .and. roni.lt.1.,1.,0.)
copy_VarMeta(roni,roni_occ_weak_abv)
roni_occ_moderate_abv=where(roni.ge.1. .and. roni.lt.1.5,1.,0.)
copy_VarMeta(roni,roni_occ_moderate_abv)
roni_occ_strong_abv=where(roni.ge.1.5 .and. roni.lt.2.,1.,0.)
copy_VarMeta(roni,roni_occ_strong_abv)
roni_occ_extreme_abv=where(roni.ge.2.,1.,0.)
copy_VarMeta(roni,roni_occ_extreme_abv)

nina_prob_extreme=dim_avg_n_Wrap(roni_occ_extreme_blw,0)*100
nina_prob_strong=dim_avg_n_Wrap(roni_occ_strong_blw,0)*100
nina_prob_moderate=dim_avg_n_Wrap(roni_occ_moderate_blw,0)*100
nina_prob_weak=dim_avg_n_Wrap(roni_occ_weak_blw,0)*100

nino_prob_extreme=dim_avg_n_Wrap(roni_occ_extreme_abv,0)*100
nino_prob_strong=dim_avg_n_Wrap(roni_occ_strong_abv,0)*100
nino_prob_moderate=dim_avg_n_Wrap(roni_occ_moderate_abv,0)*100
nino_prob_weak=dim_avg_n_Wrap(roni_occ_weak_abv,0)*100

neutr_prob=dim_avg_n_Wrap(roni_occ_nrm,0)*100

;*****************************************************   
; CALCULATE MIN & MAX and Ensemble Mean
;*****************************************************

mnmx      = new ((/9,6/), double)
mnmx@_FillValue=-999.
mnmx(0,1:4) = nina_prob_extreme
mnmx(1,1:4) = nina_prob_strong
mnmx(2,1:4) = nina_prob_moderate
mnmx(3,1:4) = nina_prob_weak
mnmx(4,1:4) = nino_prob_extreme
mnmx(5,1:4) = nino_prob_strong
mnmx(6,1:4) = nino_prob_moderate
mnmx(7,1:4) = nino_prob_weak
mnmx(8,1:4) = neutr_prob

print("ready to plot")
;*****************************************************
; -- PLOT SETTINGS
;*****************************************************
plname=dirplots+"/sst_"+REG+"_relative_strength_prob_"+tend+"_"+st
wks = gsn_open_wks(figtype,plname)                 ; create plot
gsn_define_colormap(wks,"nino_strenght_a")

sres = True
sres@vpWidthF = 0.7
sres@vpHeightF = 0.5
sres@vpXF = .1
sres@trYMinF = 0.
sres@trYMaxF = 100.
sres@gsnDraw = False
sres@gsnFrame = False
sres@gsnXYBarChart = True
sres@gsnXYBarChartBarWidth = 0.15           ; change bar widths
sres@gsnYRefLine           = 0


sres@tmXBFormat = "f"        ; remove the trailing ".0"
sres@trXMinF    = 0       ; starting point along X axis
sres@trXMaxF    = 5
sres@tmXBMode   = "Explicit"
sres@tmXBValues = ispan(1,4,1)     ; choose first 13 timesteps
labelsx=stime(1:4)
sres@tmXBLabels = labelsx    
sres@tmXBLabelFontHeightF = 0.012    
sres@tmYLLabelFontHeightF = 0.012
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
sres@tmYLMinorOn        = False
sres@tmYLMode          = "Manual"
sres@tmYLTickEndF      = 100.
sres@tmYLTickSpacingF  = 10.
sres@tmYLTickStartF    = 0.

sres@tmYMajorGrid           = False
sres@tmGridDrawOrder        = "PreDraw"
sres@tmYMajorGridLineColor  = "grey85"
sres@tmYMajorGridThicknessF = 1.0

sres@tiMainFontHeightF = 0.02
sres@tiMainFont = "helvetica-bold"
sres@tiMainString = "CMCC-SPS ENSO Strength Probabilities (issued "+startdatestr+") ~C~ ~Z75~                                based on threshold in sst Relative "+REG+" index/RONI"
sres@gsnCenterString = ""
sres@tiYAxisString = "Percent Chance (%)"
sres@tiYAxisAngleF = 90.
sres@tiYAxisFontHeightF = 0.015
sres@xyLineColors = (/"red"/)   
int1=fspan(0.15,5.15,6)
sres@gsnXYBarChartColors = (/2/)					; but tweaking where
snino1=mnmx(4,:)+mnmx(5,:)+mnmx(6,:)+mnmx(7,:)
plot_nino1 = gsn_csm_xy(wks,int1,snino1,sres)		; draw each time series
sres@gsnXYBarChartColors = (/3/)					; but tweaking where
snino2=mnmx(5,:)+mnmx(6,:)+mnmx(7,:)
plot_nino2 = gsn_csm_xy(wks,int1,snino2,sres)		; draw each time series
sres@gsnXYBarChartColors = (/4/)					; but tweaking where
snino3=mnmx(6,:)+mnmx(7,:)
plot_nino3 = gsn_csm_xy(wks,int1,snino3,sres)		; draw each time series
sres@gsnXYBarChartColors = (/5/)					; but tweaking where
snino4=mnmx(7,:)
plot_nino4 = gsn_csm_xy(wks,int1,snino4,sres)		; draw each time series

delete(sres@xyLineColors)
delete(sres@gsnXYBarChartColors)
sres@xyLineColors = (/"grey"/)   
sres@gsnXYBarChartColors = (/6/)					; seperately, not
int2=fspan(0.,5,6)
plot_neutral1 = gsn_csm_xy(wks,int2,mnmx(8,:),sres)		; advancing the frame

delete(sres@xyLineColors)
delete(sres@gsnXYBarChartColors)
sres@xyLineColors = (/"blue"/)   
int3=fspan(-0.15,4.85,6)
sres@gsnXYBarChartColors = (/10/)	
snina1=mnmx(0,:)+mnmx(1,:)+mnmx(2,:)+mnmx(3,:)
plot_nina1 = gsn_csm_xy(wks,int3,snina1,sres)		; each time series is
sres@gsnXYBarChartColors = (/9/)	
snina2=mnmx(1,:)+mnmx(2,:)+mnmx(3,:)
plot_nina2 = gsn_csm_xy(wks,int3,snina2,sres)		; each time series is
sres@gsnXYBarChartColors = (/8/)	
snina3=mnmx(2,:)+mnmx(3,:)
plot_nina3 = gsn_csm_xy(wks,int3,snina3,sres)		; each time series is
sres@gsnXYBarChartColors = (/7/)	
snina4=mnmx(3,:)
plot_nina4 = gsn_csm_xy(wks,int3,snina4,sres)		; each time series is
overlay(plot_nina1,plot_nina2)
overlay(plot_nina1,plot_nina3)
overlay(plot_nina1,plot_nina4)
overlay(plot_nina1,plot_neutral1)
overlay(plot_nina1,plot_nino1)
overlay(plot_nina1,plot_nino2)
overlay(plot_nina1,plot_nino3)
overlay(plot_nina1,plot_nino4)
draw(plot_nina1)

getvalues plot_nina1                      ; Get plot size for use in
    "vpXF"      : vpx
    "vpYF"      : vpy
    "vpHeightF" : vph                 ; determining size of
    "vpWidthF"  : vpw                 ; labelbar.
end getvalues

lbres                    = True          ; labelbar only resources
lbres@lbAutoManage       = False
lbres@vpWidthF           = 0.15 ;*vpw           ; labelbar width
lbres@vpHeightF          = 0.225 ;*vph           ; labelbar height
lbres@lbBoxMajorExtentF  = 0.5          ; puts space between color boxes
my_cmap = (/2,3,4,5,6,7,8,9,10/)
lbres@lbFillColors       = my_cmap(::-1)
lbres@lbBoxLinesOn        = True
lbres@lbBoxLineColor     = (/6/)
lbres@lbMonoFillPattern  = True          ; Solid fill pattern
lbres@lbLabelFontHeightF = 0.007         ; font height. default is small
lbres@lbLabelJust        = "CenterLeft"  ; left justify labels

;lbres@lbPerimFillColor   = "Transparent"
lbres@lbPerimOn          = True
lbres@lgPerimColor 	     = "grey"

degC="~F35~J~F22~C"
greateq="~F18~L~F22~"
great="~F18~>~F22~"
lesseq="~F18~K~F22~"
less="~F18~<~F22~"
newline="~C~"
labels = (/"~F22~Very Strong El Nino "+newline+" index "+greateq+" 2.0"+degC,\
           "~F22~Strong El Nino "+newline+" 1.5"+degC+" "+lesseq+" index "+less+" 2.0"+degC,\
           "~F22~Moderate El Nino "+newline+" 1.0"+degC+" "+lesseq+" index "+less+" 1.5"+degC,\
           "~F22~Weak El Nino "+newline+" 0.5"+degC+" "+lesseq+" index "+less+" 1.0"+degC,\
           "~F22~Neutral "+newline+" -0.5"+degC+"< index < 0.5"+degC,\
           "~F22~Weak La Nina "+newline+" -0.5"+degC+" "+greateq+" index "+great+" -1.0"+degC,\
           "~F22~Moderate La Nina "+newline+" -1.0"+degC+" "+greateq+" index "+great+" -1.5"+degC,\
           "~F22~Strong La Nina "+newline+" -1.5"+degC+" "+greateq+" index "+great+" -2.0"+degC,\
           "~F22~Very Strong La Nina "+newline+" index "+lesseq+" -2.0"+degC/)

gsn_labelbar_ndc(wks,9,labels(::-1),0.81,0.8,lbres)	; draw right labelbar column

frame(wks)      
;*******************************************************************
geom_value=" 80x80+930+700" 
;system( "composite -geometry "+geom_value+" cmcc_logo_bw.jpg "+plname+".png "+plname+".png")
system( "touch "+plname+"_DONE")

end
