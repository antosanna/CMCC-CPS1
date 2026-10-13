begin

;------ Select the region
lat1 = -90  ; Southern boundary (degrees)
lat2 = 90   ; Northern boundary (degrees)
lon1 = -180
lon2 = 180

;------------------------plot-timeseries---------------------------
     pathplot = "/work/csp/mh31123/scratch/Wind100/Data_wind/plot/"
     pathfile = "/work/csp/mh31123/scratch/Wind100/Data_wind/"

;-------------- Loop over each year
   ;  anno=sprinti("%0.4i", year)
fill1= pathfile+"remapped_wind_era5_199312_renamed.nc"
fill2= pathfile+"remapped_wind_era5_199412_renamed.nc"
fill3= pathfile+"remapped_wind_era5_199512_renamed.nc"
fill4= pathfile+"remapped_wind_era5_199612_renamed.nc"
fill5= pathfile+"remapped_wind_era5_199712_renamed.nc"
fill6= pathfile+"remapped_wind_era5_199812_renamed.nc"
fill7= pathfile+"remapped_wind_era5_199912_renamed.nc"      
fill8= pathfile+"remapped_wind_era5_200012_renamed.nc"
fill9= pathfile+"remapped_wind_era5_200112_renamed.nc"
fill10= pathfile+"remapped_wind_era5_200212_renamed.nc"
fill11= pathfile+"remapped_wind_era5_200312_renamed.nc"
fill12= pathfile+"remapped_wind_era5_200412_renamed.nc"
fill13= pathfile+"remapped_wind_era5_200512_renamed.nc"
fill14= pathfile+"remapped_wind_era5_200612_renamed.nc"
fill15= pathfile+"remapped_wind_era5_200712_renamed.nc"
fill16= pathfile+"remapped_wind_era5_200812_renamed.nc"
fill17= pathfile+"remapped_wind_era5_200912_renamed.nc"
fill18= pathfile+"remapped_wind_era5_201012_renamed.nc"
fill19= pathfile+"remapped_wind_era5_201112_renamed.nc"
fill20= pathfile+"remapped_wind_era5_201212_renamed.nc"
fill21= pathfile+"remapped_wind_era5_201312_renamed.nc"
fill22= pathfile+"remapped_wind_era5_201412_renamed.nc"
fill23= pathfile+"remapped_wind_era5_201512_renamed.nc"
fill24= pathfile+"remapped_wind_era5_201612_renamed.nc"
fill25= pathfile+"remapped_wind_era5_201712_renamed.nc"
fill26= pathfile+"remapped_wind_era5_201812_renamed.nc"
fill27= pathfile+"remapped_wind_era5_201912_renamed.nc"
fill28= pathfile+"remapped_wind_era5_202012_renamed.nc"
fill29= pathfile+"remapped_wind_era5_202112_renamed.nc"
fill30= pathfile+"remapped_wind_era5_202212_renamed.nc"


;--------------Open file
f1 = addfile(fill1, "r")   
f2 = addfile(fill2, "r")    
f3 = addfile(fill3, "r")  
f4 = addfile(fill4, "r")  
f5 = addfile(fill5, "r")  
f6 = addfile(fill6, "r")  
f7 = addfile(fill7, "r")  
f8 = addfile(fill8, "r")  
f9 = addfile(fill9, "r")  
f10 = addfile(fill10, "r")  
f11 = addfile(fill11, "r")  
f12 = addfile(fill12, "r")  
f13 = addfile(fill13, "r")  
f14 = addfile(fill14, "r")  
f15 = addfile(fill15, "r")  
f16 = addfile(fill16, "r")  
f17 = addfile(fill17, "r")  
f18 = addfile(fill18, "r")  
f19 = addfile(fill19, "r")  
f20 = addfile(fill20, "r")  
f21 = addfile(fill21, "r")  
f22 = addfile(fill22, "r")  
f23 = addfile(fill23, "r")  
f24 = addfile(fill24, "r")  
f25 = addfile(fill25, "r")  
f26 = addfile(fill26, "r")  
f27 = addfile(fill27, "r")  
f28 = addfile(fill28, "r")  
f29 = addfile(fill29, "r")
f30 = addfile(fill30, "r")
  

; Access variables
u10_1 = f1->u10(:,:,:)
v10_1 = f1->v10(:,:,:)
u100_1 = f1->u100(:,:,:)
v100_1 = f1->v100(:,:,:)
      lat = f1->lat(:)
      lon = f1->lon(:)

      rad = 4.0*atan(1.0)/180.0
      clat = cos(lat({lat1:lat2})*rad)

  dims_u10_1 = dimsizes(u10_1)
        nt= dims_u10_1(0)      ; every 6 hour
        nlat = dims_u10_1(1)  ; latitude
        nlon = dims_u10_1(2)  ; longitude
  dims_v10_1 = dimsizes(v10_1)
        nt = dims_v10_1(0)  ; every 6 hour
        nlat = dims_v10_1(1)  ; latitude
        nlon = dims_v10_1(2)  ; longitude

  dims_u100_1 = dimsizes(u100_1)
        nt = dims_u100_1(0)  ; every 6 hour
        nlat = dims_u100_1(1)  ; latitude
        nlon = dims_u100_1(2)  ; longitude

  dims_v100_1 = dimsizes(v100_1)
        nt = dims_v100_1(0)  ; every 6 hour
        nlat = dims_v100_1(1)  ; latitude
        nlon = dims_v100_1(2)  ; longitude

time=new((/nt/),"float",-999)
do t=0,(nt)-1
  time(t)=t
end do

time@units = "hours since 1993-1-1 00:00:00"
ntime=dimsizes(time)
;printVarSummary(time)
     ; ----------Calculate wind speed at 10 and 100 meters
wind_10m_data_1 = sqrt(u10_1^2 + v10_1^2)
wind_100m_data_1 = sqrt(u100_1^2 + v100_1^2)
copy_VarMeta(u10_1,wind_10m_data_1)
wind_10m_data_1!0="time"
wind_10m_data_1&time=time
wind_10m_data_1!1="lat"
wind_10m_data_1&lat=lat
wind_10m_data_1!2="lon"
wind_10m_data_1&lon=lon
copy_VarMeta(u100_1,wind_100m_data_1)
wind_100m_data_1!0="time"
wind_100m_data_1&time=time
wind_100m_data_1!1="lat"
wind_100m_data_1&lat=lat
wind_100m_data_1!2="lon"
wind_100m_data_1&lon=lon

;------------- Calculate alpha
alpha_1=wind_10m_data_1
alpha_1 = log(wind_100m_data_1 / wind_10m_data_1) / log(100/10)

; Assign coordinates for alpha
alpha_1!0 = "time"
alpha_1&time = time
alpha_1!1 = "lat"
alpha_1&lat = lat
alpha_1!2 = "lon"
alpha_1&lon = lon
;---- Calculate area-averaged alpha for the specified regionssign coordinates

   alpha_europe1 = wgt_areaave_Wrap(alpha_1(:, {lat1:lat2}, {lon1:lon2}), clat, 1.0, 1)
alpha_europe1!0="time"
alpha_europe1&time=time
;printVarSummary(alpha_europe1)

;--------------------f2----------
u10 = f2->u10(:,:,:)
v10 = f2->v10(:,:,:)
u100 = f2->u100(:,:,:)
v100 = f2->v100(:,:,:)
      lat = f2->lat(:)
      lon = f2->lon(:)

      rad = 4.0*atan(1.0)/180.0
      clat = cos(lat({lat1:lat2})*rad)

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
time=new((/nt/),"float",-999)
do t=0,(nt)-1
  time(t)=t
end do

time@units = "hours since 1994-1-1 00:00:00"
ntime=dimsizes(time)
;printVarSummary(time)
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
;---- Calculate area-averaged alpha for the specified regionssign coordinates

   alpha_europe2 = wgt_areaave_Wrap(alpha(:, {lat1:lat2}, {lon1:lon2}), clat, 1.0, 1)
alpha_europe2!0="time"
alpha_europe2&time=time
;printVarSummary(alpha_europe2)


;--------------------f3----------
u10 = f3->u10(:,:,:)
v10 = f3->v10(:,:,:)
u100 = f3->u100(:,:,:)
v100 = f3->v100(:,:,:)
      lat = f3->lat(:)
      lon = f3->lon(:)

      rad = 4.0*atan(1.0)/180.0
      clat = cos(lat({lat1:lat2})*rad)

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
time=new((/nt/),"float",-999)
do t=0,(nt)-1
  time(t)=t
end do

time@units = "hours since 1995-1-1 00:00:00"
ntime=dimsizes(time)
;printVarSummary(time)
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
;---- Calculate area-averaged alpha for the specified regionssign coordinates

   alpha_europe3 = wgt_areaave_Wrap(alpha(:, {lat1:lat2}, {lon1:lon2}), clat, 1.0, 1)
alpha_europe3!0="time"
alpha_europe3&time=time
;-------------f4
u10 = f4->u10(:,:,:)
v10 = f4->v10(:,:,:)
u100 = f4->u100(:,:,:)
v100 = f4->v100(:,:,:)
      lat = f4->lat(:)
      lon = f4->lon(:)

      rad = 4.0*atan(1.0)/180.0
      clat = cos(lat({lat1:lat2})*rad)

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
time=new((/nt/),"float",-999)
do t=0,(nt)-1
  time(t)=t
end do

time@units = "hours since 1995-1-1 00:00:00"
ntime=dimsizes(time)
;printVarSummary(time)
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
;---- Calculate area-averaged alpha for the specified regionssign coordinates

   alpha_europe4 = wgt_areaave_Wrap(alpha(:, {lat1:lat2}, {lon1:lon2}), clat, 1.0, 1)
alpha_europe4!0="time"
alpha_europe4&time=time
;------------f5
u10 = f5->u10(:,:,:)
v10 = f5->v10(:,:,:)
u100 = f5->u100(:,:,:)
v100 = f5->v100(:,:,:)
      lat = f5->lat(:)
      lon = f5->lon(:)

      rad = 4.0*atan(1.0)/180.0
      clat = cos(lat({lat1:lat2})*rad)

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
time=new((/nt/),"float",-999)
do t=0,(nt)-1
  time(t)=t
end do

time@units = "hours since 1996-1-1 00:00:00"
ntime=dimsizes(time)
;printVarSummary(time)
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
;---- Calculate area-averaged alpha for the specified regionssign coordinates

   alpha_europe5 = wgt_areaave_Wrap(alpha(:, {lat1:lat2}, {lon1:lon2}), clat, 1.0, 1)
alpha_europe5!0="time"
alpha_europe5&time=time
;-----------------f6
u10 = f6->u10(:,:,:)
v10 = f6->v10(:,:,:)
u100 = f6->u100(:,:,:)
v100 = f6->v100(:,:,:)
      lat = f6->lat(:)
      lon = f6->lon(:)

      rad = 4.0*atan(1.0)/180.0
      clat = cos(lat({lat1:lat2})*rad)

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
time=new((/nt/),"float",-999)
do t=0,(nt)-1
  time(t)=t
end do

time@units = "hours since 1995-1-1 00:00:00"
ntime=dimsizes(time)
;printVarSummary(time)
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
;---- Calculate area-averaged alpha for the specified regionssign coordinates

   alpha_europe6 = wgt_areaave_Wrap(alpha(:, {lat1:lat2}, {lon1:lon2}), clat, 1.0, 1)
alpha_europe6!0="time"
alpha_europe6&time=time
;--------f7--------
u10 = f7->u10(:,:,:)
v10 = f7->v10(:,:,:)
u100 = f7->u100(:,:,:)
v100 = f7->v100(:,:,:)
      lat = f7->lat(:)
      lon = f7->lon(:)

      rad = 4.0*atan(1.0)/180.0
      clat = cos(lat({lat1:lat2})*rad)

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
time=new((/nt/),"float",-999)
do t=0,(nt)-1
  time(t)=t
end do

time@units = "hours since 1995-1-1 00:00:00"
ntime=dimsizes(time)
;printVarSummary(time)
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
;---- Calculate area-averaged alpha for the specified regionssign coordinates

   alpha_europe7 = wgt_areaave_Wrap(alpha(:, {lat1:lat2}, {lon1:lon2}), clat, 1.0, 1)
alpha_europe7!0="time"
alpha_europe7&time=time

;-------f8
u10 = f8->u10(:,:,:)
v10 = f8->v10(:,:,:)
u100 = f8->u100(:,:,:)
v100 = f8->v100(:,:,:)
      lat = f8->lat(:)
      lon = f8->lon(:)

      rad = 4.0*atan(1.0)/180.0
      clat = cos(lat({lat1:lat2})*rad)

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
time=new((/nt/),"float",-999)
do t=0,(nt)-1
  time(t)=t
end do

time@units = "hours since 1995-1-1 00:00:00"
ntime=dimsizes(time)
;printVarSummary(time)
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
;---- Calculate area-averaged alpha for the specified regionssign coordinates

   alpha_europe8 = wgt_areaave_Wrap(alpha(:, {lat1:lat2}, {lon1:lon2}), clat, 1.0, 1)
alpha_europe8!0="time"
alpha_europe8&time=time

;-------f9
u10 = f9->u10(:,:,:)
v10 = f9->v10(:,:,:)
u100 = f9->u100(:,:,:)
v100 = f9->v100(:,:,:)
      lat = f9->lat(:)
      lon = f9->lon(:)

      rad = 4.0*atan(1.0)/180.0
      clat = cos(lat({lat1:lat2})*rad)

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
time=new((/nt/),"float",-999)
do t=0,(nt)-1
  time(t)=t
end do

time@units = "hours since 1995-1-1 00:00:00"
ntime=dimsizes(time)
;printVarSummary(time)
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
;---- Calculate area-averaged alpha for the specified regionssign coordinates

   alpha_europe9 = wgt_areaave_Wrap(alpha(:, {lat1:lat2}, {lon1:lon2}), clat, 1.0, 1)
alpha_europe9!0="time"
alpha_europe9&time=time

;---------f10
u10 = f10->u10(:,:,:)
v10 = f10->v10(:,:,:)
u100 = f10->u100(:,:,:)
v100 = f10->v100(:,:,:)
      lat = f10->lat(:)
      lon = f10->lon(:)

      rad = 4.0*atan(1.0)/180.0
      clat = cos(lat({lat1:lat2})*rad)

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
time=new((/nt/),"float",-999)
do t=0,(nt)-1
  time(t)=t
end do

time@units = "hours since 1995-1-1 00:00:00"
ntime=dimsizes(time)
;printVarSummary(time)
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
;---- Calculate area-averaged alpha for the specified regionssign coordinates

   alpha_europe10 = wgt_areaave_Wrap(alpha(:, {lat1:lat2}, {lon1:lon2}), clat, 1.0, 1)
alpha_europe10!0="time"
alpha_europe10&time=time

;-------------------f11-----------
u10 = f11->u10(:,:,:)
v10 = f11->v10(:,:,:)
u100 = f11->u100(:,:,:)
v100 = f11->v100(:,:,:)
      lat = f11->lat(:)
      lon = f11->lon(:)

      rad = 4.0*atan(1.0)/180.0
      clat = cos(lat({lat1:lat2})*rad)

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
time=new((/nt/),"float",-999)
do t=0,(nt)-1
  time(t)=t
end do

time@units = "hours since 1995-1-1 00:00:00"
ntime=dimsizes(time)
;printVarSummary(time)
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
;---- Calculate area-averaged alpha for the specified regionssign coordinates

   alpha_europe11 = wgt_areaave_Wrap(alpha(:, {lat1:lat2}, {lon1:lon2}), clat, 1.0, 1)
alpha_europe11!0="time"
alpha_europe11&time=time
;----------------------f12
u10 = f12->u10(:,:,:)
v10 = f12->v10(:,:,:)
u100 = f12->u100(:,:,:)
v100 = f12->v100(:,:,:)
      lat = f12->lat(:)
      lon = f12->lon(:)

      rad = 4.0*atan(1.0)/180.0
      clat = cos(lat({lat1:lat2})*rad)

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
time=new((/nt/),"float",-999)
do t=0,(nt)-1
  time(t)=t
end do

time@units = "hours since 1995-1-1 00:00:00"
ntime=dimsizes(time)
;printVarSummary(time)
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
;---- Calculate area-averaged alpha for the specified regionssign coordinates

   alpha_europe12 = wgt_areaave_Wrap(alpha(:, {lat1:lat2}, {lon1:lon2}), clat, 1.0, 1)
alpha_europe12!0="time"
alpha_europe12&time=time
;---------------------f13----
u10 = f13->u10(:,:,:)
v10 = f13->v10(:,:,:)
u100 = f13->u100(:,:,:)
v100 = f13->v100(:,:,:)
      lat = f13->lat(:)
      lon = f13->lon(:)

      rad = 4.0*atan(1.0)/180.0
      clat = cos(lat({lat1:lat2})*rad)

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
time=new((/nt/),"float",-999)
do t=0,(nt)-1
  time(t)=t
end do

time@units = "hours since 1995-1-1 00:00:00"
ntime=dimsizes(time)
;printVarSummary(time)
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
;---- Calculate area-averaged alpha for the specified regionssign coordinates

   alpha_europe13 = wgt_areaave_Wrap(alpha(:, {lat1:lat2}, {lon1:lon2}), clat, 1.0, 1)
alpha_europe13!0="time"
alpha_europe13&time=time
;------------------------f14------
u10 = f14->u10(:,:,:)
v10 = f14->v10(:,:,:)
u100 = f14->u100(:,:,:)
v100 = f14->v100(:,:,:)
      lat = f14->lat(:)
      lon = f14->lon(:)

      rad = 4.0*atan(1.0)/180.0
      clat = cos(lat({lat1:lat2})*rad)

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
time=new((/nt/),"float",-999)
do t=0,(nt)-1
  time(t)=t
end do

time@units = "hours since 1995-1-1 00:00:00"
ntime=dimsizes(time)
;printVarSummary(time)
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
;---- Calculate area-averaged alpha for the specified regionssign coordinates

   alpha_europe14 = wgt_areaave_Wrap(alpha(:, {lat1:lat2}, {lon1:lon2}), clat, 1.0, 1)
alpha_europe14!0="time"
alpha_europe14&time=time
;-------------------f15
u10 = f15->u10(:,:,:)
v10 = f15->v10(:,:,:)
u100 = f15->u100(:,:,:)
v100 = f15->v100(:,:,:)
      lat = f15->lat(:)
      lon = f15->lon(:)

      rad = 4.0*atan(1.0)/180.0
      clat = cos(lat({lat1:lat2})*rad)

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
time=new((/nt/),"float",-999)
do t=0,(nt)-1
  time(t)=t
end do

time@units = "hours since 1995-1-1 00:00:00"
ntime=dimsizes(time)
;printVarSummary(time)
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
;---- Calculate area-averaged alpha for the specified regionssign coordinates

   alpha_europe15 = wgt_areaave_Wrap(alpha(:, {lat1:lat2}, {lon1:lon2}), clat, 1.0, 1)
alpha_europe15!0="time"
alpha_europe15&time=time
;---------------f16
u10 = f16->u10(:,:,:)
v10 = f16->v10(:,:,:)
u100 = f16->u100(:,:,:)
v100 = f16->v100(:,:,:)
      lat = f16->lat(:)
      lon = f16->lon(:)

      rad = 4.0*atan(1.0)/180.0
      clat = cos(lat({lat1:lat2})*rad)

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
time=new((/nt/),"float",-999)
do t=0,(nt)-1
  time(t)=t
end do

time@units = "hours since 1995-1-1 00:00:00"
ntime=dimsizes(time)
;printVarSummary(time)
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
;---- Calculate area-averaged alpha for the specified regionssign coordinates

   alpha_europe16 = wgt_areaave_Wrap(alpha(:, {lat1:lat2}, {lon1:lon2}), clat, 1.0, 1)
alpha_europe16!0="time"
alpha_europe16&time=time
;---------------f17
u10 = f17->u10(:,:,:)
v10 = f17->v10(:,:,:)
u100 = f17->u100(:,:,:)
v100 = f17->v100(:,:,:)
      lat = f17->lat(:)
      lon = f17->lon(:)

      rad = 4.0*atan(1.0)/180.0
      clat = cos(lat({lat1:lat2})*rad)

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
time=new((/nt/),"float",-999)
do t=0,(nt)-1
  time(t)=t
end do

time@units = "hours since 1995-1-1 00:00:00"
ntime=dimsizes(time)
;printVarSummary(time)
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
;---- Calculate area-averaged alpha for the specified regionssign coordinates

   alpha_europe17 = wgt_areaave_Wrap(alpha(:, {lat1:lat2}, {lon1:lon2}), clat, 1.0, 1)
alpha_europe17!0="time"
alpha_europe17&time=time
;-------------------f18
u10 = f18->u10(:,:,:)
v10 = f18->v10(:,:,:)
u100 = f18->u100(:,:,:)
v100 = f18->v100(:,:,:)
      lat = f18->lat(:)
      lon = f18->lon(:)

      rad = 4.0*atan(1.0)/180.0
      clat = cos(lat({lat1:lat2})*rad)

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
time=new((/nt/),"float",-999)
do t=0,(nt)-1
  time(t)=t
end do

time@units = "hours since 1995-1-1 00:00:00"
ntime=dimsizes(time)
;printVarSummary(time)
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
;---- Calculate area-averaged alpha for the specified regionssign coordinates

   alpha_europe18 = wgt_areaave_Wrap(alpha(:, {lat1:lat2}, {lon1:lon2}), clat, 1.0, 1)
alpha_europe18!0="time"
alpha_europe18&time=time
;-----------------------f19
u10 = f19->u10(:,:,:)
v10 = f19->v10(:,:,:)
u100 = f19->u100(:,:,:)
v100 = f19->v100(:,:,:)
      lat = f19->lat(:)
      lon = f19->lon(:)

      rad = 4.0*atan(1.0)/180.0
      clat = cos(lat({lat1:lat2})*rad)

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
time=new((/nt/),"float",-999)
do t=0,(nt)-1
  time(t)=t
end do

time@units = "hours since 1995-1-1 00:00:00"
ntime=dimsizes(time)
;printVarSummary(time)
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
;---- Calculate area-averaged alpha for the specified regionssign coordinates

   alpha_europe19 = wgt_areaave_Wrap(alpha(:, {lat1:lat2}, {lon1:lon2}), clat, 1.0, 1)
alpha_europe19!0="time"
alpha_europe19&time=time
;------------------f20
u10 = f20->u10(:,:,:)
v10 = f20->v10(:,:,:)
u100 = f20->u100(:,:,:)
v100 = f20->v100(:,:,:)
      lat = f20->lat(:)
      lon = f20->lon(:)

      rad = 4.0*atan(1.0)/180.0
      clat = cos(lat({lat1:lat2})*rad)

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
time=new((/nt/),"float",-999)
do t=0,(nt)-1
  time(t)=t
end do

time@units = "hours since 1995-1-1 00:00:00"
ntime=dimsizes(time)
;printVarSummary(time)
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
;---- Calculate area-averaged alpha for the specified regionssign coordinates

   alpha_europe20 = wgt_areaave_Wrap(alpha(:, {lat1:lat2}, {lon1:lon2}), clat, 1.0, 1)
alpha_europe20!0="time"
alpha_europe20&time=time
;--------------------f21
u10 = f21->u10(:,:,:)
v10 = f21->v10(:,:,:)
u100 = f21->u100(:,:,:)
v100 = f21->v100(:,:,:)
      lat = f21->lat(:)
      lon = f21->lon(:)

      rad = 4.0*atan(1.0)/180.0
      clat = cos(lat({lat1:lat2})*rad)

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
time=new((/nt/),"float",-999)
do t=0,(nt)-1
  time(t)=t
end do

time@units = "hours since 1995-1-1 00:00:00"
ntime=dimsizes(time)
;printVarSummary(time)
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
;---- Calculate area-averaged alpha for the specified regionssign coordinates

   alpha_europe21 = wgt_areaave_Wrap(alpha(:, {lat1:lat2}, {lon1:lon2}), clat, 1.0, 1)
alpha_europe21!0="time"
alpha_europe21&time=time
;-------------------f22
u10 = f22->u10(:,:,:)
v10 = f22->v10(:,:,:)
u100 = f22->u100(:,:,:)
v100 = f22->v100(:,:,:)
      lat = f22->lat(:)
      lon = f22->lon(:)

      rad = 4.0*atan(1.0)/180.0
      clat = cos(lat({lat1:lat2})*rad)

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
time=new((/nt/),"float",-999)
do t=0,(nt)-1
  time(t)=t
end do

time@units = "hours since 1995-1-1 00:00:00"
ntime=dimsizes(time)
;printVarSummary(time)
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
;---- Calculate area-averaged alpha for the specified regionssign coordinates

   alpha_europe22 = wgt_areaave_Wrap(alpha(:, {lat1:lat2}, {lon1:lon2}), clat, 1.0, 1)
alpha_europe22!0="time"
alpha_europe22&time=time
;----------------------------f23
u10 = f23->u10(:,:,:)
v10 = f23->v10(:,:,:)
u100 = f23->u100(:,:,:)
v100 = f23->v100(:,:,:)
      lat = f23->lat(:)
      lon = f23->lon(:)

      rad = 4.0*atan(1.0)/180.0
      clat = cos(lat({lat1:lat2})*rad)

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
time=new((/nt/),"float",-999)
do t=0,(nt)-1
  time(t)=t
end do

time@units = "hours since 1995-1-1 00:00:00"
ntime=dimsizes(time)
;printVarSummary(time)
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
;---- Calculate area-averaged alpha for the specified regionssign coordinates

   alpha_europe23 = wgt_areaave_Wrap(alpha(:, {lat1:lat2}, {lon1:lon2}), clat, 1.0, 1)
alpha_europe23!0="time"
alpha_europe23&time=time
;---------------------------f24
u10 = f24->u10(:,:,:)
v10 = f24->v10(:,:,:)
u100 = f24->u100(:,:,:)
v100 = f24->v100(:,:,:)
      lat = f24->lat(:)
      lon = f24->lon(:)

      rad = 4.0*atan(1.0)/180.0
      clat = cos(lat({lat1:lat2})*rad)

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
time=new((/nt/),"float",-999)
do t=0,(nt)-1
  time(t)=t
end do

time@units = "hours since 1995-1-1 00:00:00"
ntime=dimsizes(time)
;printVarSummary(time)
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
;---- Calculate area-averaged alpha for the specified regionssign coordinates

   alpha_europe24 = wgt_areaave_Wrap(alpha(:, {lat1:lat2}, {lon1:lon2}), clat, 1.0, 1)
alpha_europe24!0="time"
alpha_europe24&time=time
;-------------------------25
u10 = f25->u10(:,:,:)
v10 = f25->v10(:,:,:)
u100 = f25->u100(:,:,:)
v100 = f25->v100(:,:,:)
      lat = f25->lat(:)
      lon = f25->lon(:)

      rad = 4.0*atan(1.0)/180.0
      clat = cos(lat({lat1:lat2})*rad)

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
time=new((/nt/),"float",-999)
do t=0,(nt)-1
  time(t)=t
end do

time@units = "hours since 1995-1-1 00:00:00"
ntime=dimsizes(time)
;printVarSummary(time)
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
;---- Calculate area-averaged alpha for the specified regionssign coordinates

   alpha_europe25 = wgt_areaave_Wrap(alpha(:, {lat1:lat2}, {lon1:lon2}), clat, 1.0, 1)
alpha_europe25!0="time"
alpha_europe25&time=time
;--------------------------f26
u10 = f26->u10(:,:,:)
v10 = f26->v10(:,:,:)
u100 = f26->u100(:,:,:)
v100 = f26->v100(:,:,:)
      lat = f26->lat(:)
      lon = f26->lon(:)

      rad = 4.0*atan(1.0)/180.0
      clat = cos(lat({lat1:lat2})*rad)

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
time=new((/nt/),"float",-999)
do t=0,(nt)-1
  time(t)=t
end do

time@units = "hours since 1995-1-1 00:00:00"
ntime=dimsizes(time)
;printVarSummary(time)
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
;---- Calculate area-averaged alpha for the specified regionssign coordinates

   alpha_europe26 = wgt_areaave_Wrap(alpha(:, {lat1:lat2}, {lon1:lon2}), clat, 1.0, 1)
alpha_europe26!0="time"
alpha_europe26&time=time
;---------------f27
u10 = f27->u10(:,:,:)
v10 = f27->v10(:,:,:)
u100 = f27->u100(:,:,:)
v100 = f27->v100(:,:,:)
      lat = f27->lat(:)
      lon = f27->lon(:)

      rad = 4.0*atan(1.0)/180.0
      clat = cos(lat({lat1:lat2})*rad)

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
time=new((/nt/),"float",-999)
do t=0,(nt)-1
  time(t)=t
end do

time@units = "hours since 1995-1-1 00:00:00"
ntime=dimsizes(time)
;printVarSummary(time)
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
;---- Calculate area-averaged alpha for the specified regionssign coordinates

   alpha_europe27 = wgt_areaave_Wrap(alpha(:, {lat1:lat2}, {lon1:lon2}), clat, 1.0, 1)
alpha_europe27!0="time"
alpha_europe27&time=time
;----------------f28
u10 = f28->u10(:,:,:)
v10 = f28->v10(:,:,:)
u100 = f28->u100(:,:,:)
v100 = f28->v100(:,:,:)
      lat = f28->lat(:)
      lon = f28->lon(:)

      rad = 4.0*atan(1.0)/180.0
      clat = cos(lat({lat1:lat2})*rad)

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
time=new((/nt/),"float",-999)
do t=0,(nt)-1
  time(t)=t
end do

time@units = "hours since 1995-1-1 00:00:00"
ntime=dimsizes(time)
;printVarSummary(time)
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
;---- Calculate area-averaged alpha for the specified regionssign coordinates

   alpha_europe28 = wgt_areaave_Wrap(alpha(:, {lat1:lat2}, {lon1:lon2}), clat, 1.0, 1)
alpha_europe28!0="time"
alpha_europe28&time=time

;--------------f29
u10 = f29->u10(:,:,:)
v10 = f29->v10(:,:,:)
u100 = f29->u100(:,:,:)
v100 = f29->v100(:,:,:)
      lat = f29->lat(:)
      lon = f29->lon(:)

      rad = 4.0*atan(1.0)/180.0
      clat = cos(lat({lat1:lat2})*rad)

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
time=new((/nt/),"float",-999)
do t=0,(nt)-1
  time(t)=t
end do

time@units = "hours since 1995-1-1 00:00:00"
ntime=dimsizes(time)
;printVarSummary(time)
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
;---- Calculate area-averaged alpha for the specified regionssign coordinates

   alpha_europe29 = wgt_areaave_Wrap(alpha(:, {lat1:lat2}, {lon1:lon2}), clat, 1.0, 1)
alpha_europe29!0="time"
alpha_europe29&time=time

;---------------f30
u10 = f30->u10(:,:,:)
v10 = f30->v10(:,:,:)
u100 = f30->u100(:,:,:)
v100 = f30->v100(:,:,:)
      lat = f30->lat(:)
      lon = f30->lon(:)

      rad = 4.0*atan(1.0)/180.0
      clat = cos(lat({lat1:lat2})*rad)

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
time=new((/nt/),"float",-999)
do t=0,(nt)-1
  time(t)=t
end do

time@units = "hours since 1995-1-1 00:00:00"
ntime=dimsizes(time)
;printVarSummary(time)
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
;---- Calculate area-averaged alpha for the specified regionssign coordinates

   alpha_europe30 = wgt_areaave_Wrap(alpha(:, {lat1:lat2}, {lon1:lon2}), clat, 1.0, 1)
alpha_europe30!0="time"
alpha_europe30&time=time
;printVarSummary(alpha_europe30)
;--------
;n_alpha_europe=30
;do i=1,n_alpha_europe
;f=addfile(alpha_europe(i),"r")
;data_all_years(i,:)=alpha_europe
;end do
;mean=ave(data_all_years,1)

;mean(:)=dim_avg_n((alpha_europe1, alpha_europe2, alpha_europe3, alpha_europe4, alpha_europe5, alpha_europe6, alpha_europe7, alpha_europe8, alpha_europe9, alpha_europe10, alpha_europe11, alpha_europe12, alpha_europe13, alpha_europe14, alpha_europe15, alpha_europe16, alpha_europe17, alpha_europe18, alpha_europe19, alpha_europe20, alpha_europe21, alpha_europe22, alpha_europe23, alpha_europe24, alpha_europe25, alpha_europe26, alpha_europe27, alpha_europe28, alpha_europe29, alpha_europe30),:)
;end do
;alpha_europe_mean=alpha_europe
;alpha_europe_mean(:)=mean(alpha_europe(:))
;--------------- plot
wks = gsn_open_wks("png", pathplot + "Alpha_Timeseries_Dec")
res = True
res@gsnFrame = False 
res@gsnDraw = False
res@gsnMaximize = True
res@trXMaxF     = 130
res@vpWidthF = 0.8
res@vpHeightF = 0.4
res@gsnMaximize = True
res@tmXBTickSpacingF  =  1
res@tmYLMinorPerMajor        =   4
res@tmXBMinorPerMajor        =   4               ;-- draw 4 minor tickmarks between
res@tiMainString            ="Alpha Time Series of Dec(1993-2022)"
res@tiXAxisString = "Time(hour)"
res@tiYAxisString = "Alpha Parameter"
res@xyLineColor              = "blue"

plot0= gsn_csm_xy(wks,time,alpha_europe1, res)

plot1= gsn_csm_xy(wks,time,alpha_europe2, res)
res@xyLineColors           = "red"
plot2= gsn_csm_xy(wks,time,alpha_europe3, res)
res@xyLineColors          ="green"
plot3=gsn_csm_xy(wks,time,alpha_europe4,res)
res@xyLineColors           ="orange"
plot4=gsn_csm_xy(wks,time,alpha_europe5,res)
res@xyLineColors           ="purple"
plot5=gsn_csm_xy(wks,time,alpha_europe6,res)
res@xyLineColors           ="brown"
plot6=gsn_csm_xy(wks,time,alpha_europe7,res)
res@xyLineColors           ="cyan"
plot7=gsn_csm_xy(wks,time,alpha_europe8,res)
res@xyLineColors           ="magenta"
plot8=gsn_csm_xy(wks,time,alpha_europe9,res)
res@xyLineColors           ="pink"
plot9=gsn_csm_xy(wks,time,alpha_europe10,res)
res@xyLineColors           ="dodgerblue"
plot10=gsn_csm_xy(wks,time,alpha_europe11,res)
res@xyLineColors           ="yellow"
plot11=gsn_csm_xy(wks,time,alpha_europe12,res)
res@xyLineColors           ="darkseagreen"
plot12=gsn_csm_xy(wks,time,alpha_europe13,res)
res@xyLineColors           ="darkseagreen4"
plot13=gsn_csm_xy(wks,time,alpha_europe14,res)
res@xyLineColors           ="deeppink4"
plot14=gsn_csm_xy(wks,time,alpha_europe15,res)
res@xyLineColors           = "firebrick"
plot15= gsn_csm_xy(wks,time,alpha_europe16, res)
res@xyLineColors           = "darkviolet"
plot16= gsn_csm_xy(wks,time,alpha_europe17, res)
res@xyLineColors          ="deepskyblue4"
plot17=gsn_csm_xy(wks,time,alpha_europe18,res)
res@xyLineColors           ="darkolivegreen"
plot18=gsn_csm_xy(wks,time,alpha_europe19,res)
res@xyLineColors           ="darkorange3"
plot19=gsn_csm_xy(wks,time,alpha_europe20,res)
res@xyLineColors           ="cornsilk4"
plot20=gsn_csm_xy(wks,time,alpha_europe21,res)
res@xyLineColors           ="cyan4"
plot21=gsn_csm_xy(wks,time,alpha_europe22,res)
res@xyLineColors           ="cornsilk"
plot22=gsn_csm_xy(wks,time,alpha_europe23,res)
res@xyLineColors           ="coral"
plot23=gsn_csm_xy(wks,time,alpha_europe24,res)
res@xyLineColors           ="darkkhaki"
plot24=gsn_csm_xy(wks,time,alpha_europe25,res)
res@xyLineColors           ="chocolate"
plot25=gsn_csm_xy(wks,time,alpha_europe26,res)
res@xyLineColors           ="chartreuse"
plot26=gsn_csm_xy(wks,time,alpha_europe27,res)
res@xyLineColors           ="deepskyblue"
plot27=gsn_csm_xy(wks,time,alpha_europe28,res)
res@xyLineColors           ="darkturquoise"
plot28=gsn_csm_xy(wks,time,alpha_europe29,res)
res@xyLineColors           ="deeppink"
plot29=gsn_csm_xy(wks,time,alpha_europe30,res)
res@xyLineColors           ="darksalmon"
overlay(plot0,plot1)
overlay(plot0,plot2)
overlay(plot0,plot3)
overlay(plot0,plot4)
overlay(plot0,plot5)
overlay(plot0,plot6)
overlay(plot0,plot7)
overlay(plot0,plot8)
overlay(plot0,plot9)
overlay(plot0,plot10)
overlay(plot0,plot11)
overlay(plot0,plot12)
overlay(plot0,plot13)
overlay(plot0,plot14)
overlay(plot0,plot15)
overlay(plot0,plot16)
overlay(plot0,plot17)
overlay(plot0,plot18)
overlay(plot0,plot19)
overlay(plot0,plot20)
overlay(plot0,plot21)
overlay(plot0,plot22)
overlay(plot0,plot23)
overlay(plot0,plot24)
overlay(plot0,plot25)
overlay(plot0,plot26)
overlay(plot0,plot27)
overlay(plot0,plot28)
overlay(plot0,plot29)

draw(plot0)
frame(wks)

end

