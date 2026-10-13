begin

;------ Load files

;--------Loop over each month and year
do year= 1993,2022
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
  ;rad=4.0*atan(1.0)/180.0  ;convert degree to radian
   lat = file_handle[:]->lat(0,:)
   lon = file_handle[:]->lon(0,:)

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

time@units = "hours since 1993-1-1 00:00:00" 
ntime=dimsizes(time)

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

;------ Save wind_10m_data and wind_100m_data to an output file
;output_file ="/work/csp/mh31123/scratch/Wind100/wind_output_file.nc"
;fout = addfile(output_file, "c")

;----- Add variables to the output file
;fout->wind_10m_data = wind_10m_data
;fout->wind_100m_data = wind_100m_data
; Close the output file
;delete(fout)

;------calculate alpha 
alpha=wind_10m_data
alpha=log(wind_100m_data / wind_10m_data)/log(100/10)
;output_alpha="/work/csp/mh31123/scratch/Wind100/wind_ratio.nc"

alpha!0="time"
alpha&time=time
alpha!1="lat"
alpha&lat=lat
alpha!2="lon"
alpha&lon=lon

;----- Add variables to the output file
;fout_ratio=addfile(output_alpha,"c")
;fout_ratio->alpha = alpha
;delete(fout_ratio)

alpha_clim=dim_avg_n_Wrap(alpha,0)
;-------caculate Ws100 to compare with the wind_100m
Ws_100m=wind_10m_data
do t=0,nt-1
  Ws_100m(t,:,:)=wind_10m_data(t,:,:) *(100/10)^(alpha_clim)
end do
printVarSummary(Ws_100m)
printVarSummary(alpha_clim)
;----------------test single component
;u_100m=u10
;do t=0,nt-1
;  u_100m(t,:,:)=u10(t,:,:) *(100/10)^(alpha_clim)
;end do
;v_100m=v10
;do t=0,nt-1
 ; v_100m(t,:,:)=v10(t,:,:) *(100/10)^(alpha_clim)
;end do
;delta_u100=u10
;----compare wind_100m and Ws_100m
delta_w100=wind_100m_data
delta_w100_20=delta_w100(20,:,:)
;wind_10m_data_10=wind_10m_data(10,:,:)
wind_100m_data_20 = wind_100m_data(20,:,:)
Ws_100m_20 = Ws_100m(20,:,:)
;u10_10=u10(10,:,:)
;u_100m_10=u_100m(10,:,:)
;u100_10=u100(10,:,:)

;delta_u100_10=u_100m_10 - u10_10
delta_w100_20=Ws_100m_20 - wind_100m_data_20


;printVarSummary(delta_w100_10)
;print("delta:"+delta_w100_0)
;print("dimdelta:"+dimsizes(delta_w100_0))
;-------------------------------plot--------------------------------
wks = gsn_open_wks("png",pathplot+"delta_w100_20_europe")
  res                     = True
 res@cnFillOn                    = True                 ; turn on color
 res@cnLinesOn                   = False                ; no contour lines
 res@cnFillPalette               = "gui_default"   ; set color map

 res@cnLevelSelectionMode        = "ManualLevels"       ; manual levels
 res@cnMinLevelValF              = ".1"
 res@cnMaxLevelValF              = "2.1"
 res@cnLevelSpacingF             = ".3"

 res@pmTickMarkDisplayMode       = "Always"             ; turn on tick marks

 res@gsnAddCyclic                = True                ; regional data
   
  ;res@cnInfoLabelOn       = False           ; turn off cn info label
  res@cnLineLabelsOn      = False
 ; res@lbLabelBarOn        = True           ; turn off individual cb's
  res@mpMinLatF            = 20
  res@mpMaxLatF            = 75
  res@mpMinLonF            = -20
  res@mpMaxLonF            = 45
  ;res@gsnRightString   = ""
  res@gsnCenterString = " The diff between w100m and w100(by alpha) for t=20 "
 ; res@cnLevelSelectionMode="ExplicitLevels"
 ; res@cnLevels     = (/1,1.1,1.2,1.3,1.4,1.5,1.6,1.7,1.8,2,2.1,2.2/)
  plot = gsn_csm_contour_map(wks,delta_w100_20,res)

end


