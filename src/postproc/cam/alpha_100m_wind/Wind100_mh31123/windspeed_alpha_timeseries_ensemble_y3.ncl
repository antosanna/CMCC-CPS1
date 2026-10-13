begin

;------ Select the region
lat1 = 20  ; Southern boundary (degrees)
lat2 = 70   ; Northern boundary (degrees)
lon1 = -20
lon2 = 45

;------------------------plot-timeseries---------------------------
     pathplot = "/work/csp/mh31123/scratch/Wind100/Data_wind/plot/"
     pathfile = "/work/csp/mh31123/scratch/Wind100/Data_wind/"
wks = gsn_open_wks("X11", pathplot + "Multi_Timeseries_of_Alpha_Jan_1993_2022_2")
res = True
res@gsnFrame = False 
res@gsnDraw = False
res@gsnMaximize = True
res@tmXTBorderOn = True
res@tmYRBorderOn = True
res@tmYUseLeft = True
res@vpXF = 0.25
res@vpYF = 0.6
res@vpWidthF = 0.8
res@vpHeightF = 0.4
res@tmXBLabelDeltaF = 1
res@tmXBLabelFontHeightF = 0.015
res@xyLineColor = "Black"
res@xyLineThicknessF = 3
res@tiMainFontHeightF = 0.023  
res@tiMainString = "Alpha Time Series of Jan(1993-2022)" 
res@tiXAxisString = "Time(hour)"
res@tiYAxisString = "Alpha Parameter"
res@gsnLeftAxis = False
res@gsnRightAxis = False
res@tiYAxisFont            =  21
res@tiYAxisFontAspectF     =  1.3
res@tiYAxisFontHeightF     =  0.012
res@tiXAxisFont            =  21
res@tiXAxisFontAspectF     =  1.3
res@tiXAxisFontHeightF     =  0.012
res@tmXBLabelFontAspectF   =  1.3
res@tmXBLabelFontHeightF   =  0.012
;res@pmLegendDisplayMode    = "Always"
res@lgLabelFontHeightF     =  0.01
  res@pmLegendWidthF         =  0.32            ;-- set legend width
  res@pmLegendHeightF        =  0.06            ;-- set legend height
  res@pmLegendOrthogonalPosF =  0.14            ;-- move legend up
  res@pmLegendParallelPosF   =  0.42            ;-- move legend right
res@tmXBTickSpacingF  =  1
res@tmYLMinorPerMajor        =   4
res@tmXBMinorPerMajor        =   4               ;-- draw 4 minor tickmarks between
;-------------- Loop over each year
    do year = 1993, 2022, 1
     anno=sprinti("%0.4i", year)
      fill= pathfile+"remapped_wind_era5_"+anno+"01_renamed.nc"
      ;--------------Open file
      file_handle = addfiles(fill, "r")     
      ListSetType(file_handle, "join")   
; Access variables
u10 = file_handle[:]->u10(0,:,:,:)
v10 = file_handle[:]->v10(0,:,:,:)
u100 = file_handle[:]->u100(0,:,:,:)
v100 = file_handle[:]->v100(0,:,:,:)
      lat = file_handle[:]->lat(0,:)
      lon = file_handle[:]->lon(0,:)
      rad = 4.0*atan(1.0)/180.0
      clat = cos(lat({lat1:lat2})*rad)
  rad=4.0*atan(1.0)/180.0
  clat   = cos(lat({lat1:lat2})*rad)
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
 ; lat_reshape=reshape(lat,(/12,nlat/))
  ; lon_reshape=reshape(lon,(/12,nlon/))


time=new((/nt/),"float",-999)
do t=0,(nt)-1
  time(t)=t
end do

time@units = "hours since 1993-1-1 00:00:00"
ntime=dimsizes(time)
;printVarSummary(time)
;print("time:"+time) 
     ; ----------Calculate wind speed at 10 and 100 meters
wind_10m_data = sqrt(u10^2 + v10^2)
wind_100m_data = sqrt(u100^2 + v100^2)
copy_VarMeta(u10,wind_10m_data)
wind_10m_data!0="time"
wind_10m_data&time=time
wind_10m_data!1="lat"
wind_10m_data&lat=lat
wind_10m_data!2="lon"
wind_10m_data&lon=lon
copy_VarMeta(u100,wind_100m_data)
wind_100m_data!0="time"
wind_100m_data&time=time
wind_100m_data!1="lat"
wind_100m_data&lat=lat
wind_100m_data!2="lon"
wind_100m_data&lon=lon

;------------- Calculate alpha
alpha=wind_10m_data
alpha = log(wind_100m_data / wind_10m_data) / log(100/10)

; Assign coordinates for alpha
alpha!0 = "time"
alpha&time = time
alpha!1 = "lat"
alpha&lat = lat
alpha!2 = "lon"
alpha&lon = lon
;---------save alpha of Janury
;alpha_filename=pathplot+"alpha_Jan.nc"
;alpha_file=addfile(alpha_filename,"c")
;alpha_file->alpha=alpha
;delete(alpha_file)
;print("alpha has been saved to :"+alpha_filename) 
;printVarSummary(alpha)
;------- Calculate area-averaged alpha for the specified regionssign coordinates

   alpha_europe = wgt_areaave_Wrap(alpha(:, {lat1:lat2}, {lon1:lon2}), clat, 1.0, 1)
alpha_europe!0="time"
alpha_europe&time=time
;printVarSummary(alpha_europe)
;--------------- Open a new plot for all 30 years

plot0= gsn_csm_xy(wks,time,alpha_europe, res)
  draw(plot0)
;delete(file_handle)
end do
frame(wks)
end

