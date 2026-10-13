begin

;------ Select the region
lat1 = 20  ; Southern boundary (degrees)
lat2 = 70   ; Northern boundary (degrees)
lon1= -20
lon2= 45
;--------Loop over each month and year

do year= 1999,2000
do month= 01,12
anno=sprinti("%0.4i", year)
mon=sprinti("%0.2i",month)
pathfile="/work/csp/mh31123/scratch/Wind100/Data_wind/"
pathplot="/work/csp/mh31123/scratch/Wind100/Data_wind/plot/"
all_filem=pathfile+"remapped_wind_era5_"+anno+mon+"_renamed.nc"
end do
end do 

;-----open file
file_handle=addfiles(all_filem,"r")
ListSetType(file_handle,"join")
;----access u10 and v10

	u10=file_handle[:]->u10(0,:,:,:)
	v10=file_handle[:]->v10(0,:,:,:)
	u100=file_handle[:]->u100(0,:,:,:) 
	v100=file_handle[:]->v100(0,:,:,:) 
	lat = file_handle[:]->lat(0,:)
lon = file_handle[:]->lon(0,:)
	rad=4.0*atan(1.0)/180.0
clat   = cos(lat({lat1:lat2})*rad)
	time=file_handle[:]->time 


dims_u10 = dimsizes(u10)
	nt= dims_u10(0)      ; every 6 hour
	nlat = dims_u10(1)  ; latitude
	nlon = dims_u10(2)  ; longitude 

dims_v10 = dimsizes(v10)
	nt = dims_v10(0)  ; every 6 hour
	nlat = dims_v10(1)  ; latitude
	nlon = dims_v10(2)  ; longitude

dims_u100 = dimsizes(u100)
	nt = dims_u100(0)  ; every 6 hour
	nlat = dims_u100(1)  ; latitude
	nlon = dims_u100(2)  ; longitude

dims_v100 = dimsizes(v100)
	nt = dims_v100(0)  ; every 6 hour
	nlat = dims_v100(1)  ; latitude
	nlon = dims_v100(2)  ; longitude

	TIME = yyyymmddhh_time(1999, 2000, 6, "integer")
	t = TIME({1999110100:2000050100})    ; coordinate subscripting

;time=new((/nt/),"float",-999)
;do t=0,(nt)-1
 ; time(t)=t
;end do

; Calculate wind speed at 10 and 100 meters

wind_10m_data = sqrt(u10^2 + v10^2)
wind_100m_data = sqrt(u100^2 + v100^2)

wind_10m_data!0="time"
wind_10m_data&time=time
wind_10m_data!1="lat"
wind_10m_data&lat=lat
wind_10m_data!2="lon"
wind_10m_data&lon=lon

wind_100m_data!0="time"
wind_100m_data&time=time
wind_100m_data!1="lat"
wind_100m_data&lat=lat
wind_100m_data!2="lon"
wind_100m_data&lon=lon

;------calculate alpha 
alpha=wind_10m_data
alpha=log(wind_100m_data / wind_10m_data)/log(100/10)
alpha!0="time"
alpha&time=time
alpha!1="lat"
alpha&lat=lat
alpha!2="lon"
alpha&lon=lon
;alpha_clim=dim_avg_n_Wrap(alpha,0)
    alpha_europe = wgt_areaave_Wrap(alpha(:, {lat1:lat2}, {lon1:lon2}), clat, 1.0, 1)

;copy_VarMeta(alpha(:,0,0),alpha_europe)


;-------------------------------plot-section1--------------------------------
pathplot="/work/csp/mh31123/scratch/Wind100/Data_wind/plot/"
;------------------------plot-timeseries---------------------------
  wks = gsn_open_wks("png",pathplot+"Timeseries_of_Alpha_Nov_1999")
 
  res = True
  res@gsnMaximize           = True
res@tiMainFontHeightF        = 0.023  
res@tmXBLabels        = time  ; Use time values for X-axis labels
res@tmXTBorderOn             = True
res@tmYRBorderOn             = True
res@tmYUseLeft               = True
res@vpXF                     = 0.15
res@vpYF                     = 0.9
res@vpWidthF                 = 0.8
res@vpHeightF                = 0.4
res@tmXBLabelDeltaF          = 1
res@tmXBLabelFontHeightF     = 0.015
res@xyLineColor     = "Blue"
res@xyLineThicknessF= 3
  
  res@tmXBLabels        = time                ; labels themselves
  res@tmLabelAutoStride = True                    ; nice stride on labels

 res@gsnCenterString = " Times series (6 month) of ALpha for startdate:1-Nov-1999"
 plot  = gsn_csm_xy(wks,time,alpha_europe,res)
end


