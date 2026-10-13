begin

;------ Select the region
lat1 = 20  ; Southern boundary (degrees)
lat2 = 70   ; Northern boundary (degrees)
lon1 = -20
lon2 = 45

;------------------------plot-timeseries---------------------------
pathplot = "/work/csp/mh31123/scratch/Wind100/Data_wind/plot/"

; Loop over each 30-year period
do year= 1993,2022
anno = sprinti("%0.4i", year)
; Loop over each month
  do month = 11, 6, 12  ; Start from November to June of the next year
      mon = sprinti("%0.2i", month)
      pathfile = "/work/csp/mh31123/scratch/Wind100/Data_wind/"
      all_filem = pathfile + "remapped_wind_era5_" + anno + mon + "_renamed.nc"
      ; Open file
      file_handle = addfiles(all_filem, "r")
      ListSetType(file_handle, "join")

      ; Access u10 and v10
      u10 = file_handle[:]->u10(0,:,:,:)
      v10 = file_handle[:]->v10(0,:,:,:)
      u100 = file_handle[:]->u100(0,:,:,:)
      v100 = file_handle[:]->v100(0,:,:,:)
      lat = file_handle[:]->lat(0,:)
      lon = file_handle[:]->lon(0,:)
      rad = 4.0*atan(1.0)/180.0
      clat = cos(lat({lat1:lat2})*rad)
      time = file_handle[:]->time
     ; printVarSummary(time)
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

;time=new((/nt/),"float",-999)
;do t=0,(nt)-1
;  time(t)=t
;end do

;time@units = "hours since 1993-1-1 00:00:00"
;ntime=dimsizes(time)


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

; Calculate alpha
alpha=wind_10m_data
alpha = log(wind_100m_data / wind_10m_data) / log(100/10)

; Assign coordinates for alpha
alpha!0 = "time"
alpha&time = time
alpha!1 = "lat"
alpha&lat = lat
alpha!2 = "lon"
alpha&lon = lon
 ;------------time renge--------
;        start_date = year * 10000 + 1101   ; November 1st of the current year
 ;       end_date = (year + 1) * 10000 + 601 ; June 1st of the next year
 ;  time_subset=where((time.ge.start_date).and.(time.le.end_date),True, -9999)
;time_subset!0 = "time"
;time_subset&time = time
;------- Calculate area-averaged alpha for the specified regionssign coordinates

      alpha_europe = wgt_areaave_Wrap(alpha(:, {lat1:lat2}, {lon1:lon2}), clat, 1.0, 1)
alpha_europe!0="time"
alpha_europe&time=time
;printVarSummary(alpha_europe)
;--------- Open a new plot for each 30-year period
wks = gsn_open_wks("png", pathplot+"Timeseries_of_Alpha_New_"+ sprinti("%0.4i", year))
plot=new(29,graphic)
  res = True
res@gsnFrame  = False 
res@gsnDraw   = False

  res@gsnMaximize           = True
  res@tiMainFontHeightF     = 0.023  
  res@tiMainString          =""     
  res@tmXTBorderOn          = True
  res@tmYRBorderOn          = True
  res@tmYUseLeft            = True
  res@vpXF                  = 0.15
  res@vpYF                  = 0.9
  res@vpWidthF              = 0.8
  res@vpHeightF             = 0.4
  res@tmXBLabelDeltaF       = 1
  res@tmXBLabelFontHeightF  = 0.015
  res@xyLineColor           = "Blue"
  res@xyLineThicknessF      = 3
       res@title = "Alpha Time Series " 
       res@tiXAxisString= "Time"
       res@tiYAxisString = "Alpha Parameter"
  
start_year = 1993
  end_year = 2022

 ; printVarSummary(alpha_europe)
  years = new((/end_year - start_year + 1/), integer)
  N=dimsizes(years)
   do i = 0,dimsizes(years)-1
    years(i) = start_year + i

 plot0= gsn_csm_xy(wks,time,alpha_europe(0), res)
 ;plot1=gsn_csm_xy(wks,time,alpha_europe(i),res)
 ;  overlay(plot(0),plot1) 
   end do
 end do
end do

 draw(plot0)
 frame(wks)
end

