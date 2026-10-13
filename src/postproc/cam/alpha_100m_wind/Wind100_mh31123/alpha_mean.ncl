begin
;--------Loop over each month and year
do year= 1993,2022
  do month= 01,12 
   anno=sprinti("%0.4i", year)
   mon=sprinti("%0.2i",month)
pathfile="/data/cmcc/mh31123/Data_alpha/alpha_185days/"
pathplot="/work/csp/mh31123/scratch/Wind100/Data_alpha/plot/"
   all_filem=pathfile+"alpha_"+anno+mon+".nc"
end do
end do

file_handle=addfiles(all_filem,"r")
ListSetType(file_handle,"join")

;printVarSummary(all_filem)

;----access alpha

   alpha=file_handle[:]->alpha(0,:,:,:) 
  ;rad=4.0*atan(1.0)/180.0  ;convert degree to radian
   lat = file_handle[:]->lat(0,:)
   lon = file_handle[:]->lon(0,:)

    dims_alpha = dimsizes(alpha)
    nt= dims_alpha(0)      ; every 6 hour
    nlat = dims_alpha(1)  ; latitude
    nlon = dims_alpha(2)  ; longitude 
    

time=new((/nt/),"float",-999)
do t=0,(nt)-1
  time(t)=t
end do

time@units = "hours since 1993-1-1 00:00:00" 
ntime=dimsizes(time)
alpha!0="time"
alpha&time=time
alpha!1="lat"
alpha&lat=lat
alpha!2="lon"
alpha&lon=lon

printVarSummary(alpha)
;mean_alpha=dim_avg_n_Wrap(alpha,0)
;mean_alpha!0="time"
;mean_alpha&time=time
;mean_alpha!1="lat"
;mean_alpha&lat=lat
;mean_alpha!2="lon"
;mean_alpha&lon=lon

;printVarSummary(mean_alpha)

;----- Add variables to the output file
;output_alpha="/work/csp/mh31123/scratch/Wind100/Data_alpha/alpha_185days/monthly/mean_alpha.nc"
;fout=addfile(output_alpha,"c")
;fout->alpha = alpha
;alpha!0="time"
;alpha&time=time
;alpha!1="lat"
;alpha&lat=lat
;alpha!2="lon"
;alpha&lon=lon
;printVarSummary(alpha)
 
end


