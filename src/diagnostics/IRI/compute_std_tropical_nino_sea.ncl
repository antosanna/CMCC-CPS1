begin
inpf=getenv("hind_anom_file")
dstFileName=getenv("outfile")

;nino3.4 area
lat1n=getenv("lat1n")
lat2n=getenv("lat2n")
lon1n=getenv("lon1n")
lon2n=getenv("lon2n")

;tropical band area
lat1t=getenv("lat1t")
lat2t=getenv("lat2t")
lon1t=getenv("lon1t")
lon2t=getenv("lon2t")

;info for netcdf attributes
sysname=getenv("sysname")
iniy_hind=getenv("iniy")
endy_hind=getenv("endy")

inf=addfile(inpf,"r")
sst_anom=inf->tso ;(year, ens, time, lat, lon)
lat=inf->lat
lon=inf->lon

rad    = 4.0*atan(1.0)/180.0
clat   = cos(lat*rad)
copy_VarMeta(lat,clat)

dims=dimsizes(sst_anom)
nyea=dims(0)
nens=dims(1)
ntime=dims(2)
nlat=dims(3)
nlon=dims(4)

sst_resh=reshape(sst_anom,(/nens*nyea,ntime,nlat,nlon/))

time=ispan(0,ntime-1,1) 
time@long_name="Time elapsed since the start of the forecast"
time@units="months" 

sst_resh!1="time"
sst_resh&time=time

sst_resh!2="lat"
sst_resh&lat=lat

sst_resh!3="lon"
sst_resh&lon=lon

sst_trop=wgt_areaave_Wrap(sst_resh(:,:,{lat1t:lat2t},{lon1t:lon2t}), clat({lat1t:lat2t}), 1.0, 0)

sst_nin34=wgt_areaave_Wrap(sst_resh(:,:,{lat1n:lat2n},{lon1n:lon2n}), clat({lat1n:lat2n}), 1.0, 0)
sst_roni=sst_nin34-sst_trop

nsea=4
sea=ispan(0,nsea-1,1) 
sst_trop_sea=new((/nens*nyea,nsea/),typeof(sst_trop))
sst_nin34_sea=new((/nens*nyea,nsea/),typeof(sst_nin34))
sst_roni_sea=new((/nens*nyea,nsea/),typeof(sst_roni))
do l=0,nsea-1
   sst_trop_sea(:,l)=dim_avg_n(sst_trop(:,l:l+2),1)
   sst_nin34_sea(:,l)=dim_avg_n(sst_nin34(:,l:l+2),1)
   sst_roni_sea(:,l)=dim_avg_n(sst_roni(:,l:l+2),1)
end do

sst_std_trop=dim_stddev_n_Wrap(sst_trop_sea,0)
sst_std_nin34=dim_stddev_n_Wrap(sst_nin34_sea,0)
sst_std_roni=dim_stddev_n_Wrap(sst_roni_sea,0)

factor=sst_std_nin34/sst_std_roni
copy_VarMeta(sst_std_roni,factor)
printVarSummary(factor)

;;;;now creating netcdf file with std_nino34, std_tropical and RONI standardization factor

if(isfilepresent(dstFileName)) then
   system("rm "+dstFileName)
end if
setfileoption("nc","Format","NetCDF4Classic")
setfileoption("nc","CompressionLevel",6)
setfileoption("nc","preFill",False)
dst_file=addfile(dstFileName,"c")    
setfileoption(dst_file,"DefineMode",True)

globalAtt             = True
globalAtt@history     = systemfunc("date") + ": ncl compute_std_tropical_nino.ncl"
globalAtt@title       = "Climatological standardization factors for RONI computation on CMCC-"+sysname
globalAtt@summary ="Seasonal standard deviation of the average SST over the Nino3.4 box, over the Tropical (-20.,+20.) band, and of the relative nino index (SST_nino34-SST_tropics) computed across all the hindcast members ("+tostring(nens)+" ensembles, "+iniy_hind+"-"+endy_hind+" reference period) for each leadtime. For final RONI weightening the ratio std(nino34)/std(nino34-tropical) is also included."
fileattdef( dst_file, globalAtt )

dimNames = (/"time"/)
dimSizes = (/nsea/)
dimUnlim = (/ True/)
filedimdef(dst_file,dimNames,dimSizes,dimUnlim)

filevardef(dst_file,"time",typeof(time),"time")
filevardef(dst_file,"std_nino34",typeof(sst_std_nin34),"time")
filevardef(dst_file,"std_tropical",typeof(sst_std_trop),"time")
filevardef(dst_file,"std_relnino",typeof(sst_std_roni),"time")
filevardef(dst_file,"roni_factor",typeof(factor),"time")

;---Define each variable's attributes.
filevarattdef(dst_file,"time",sea)
filevarattdef(dst_file,"roni_factor",factor)
filevarattdef(dst_file,"std_nino34",sst_std_nin34)
filevarattdef(dst_file,"std_relnino",sst_std_roni)
filevarattdef(dst_file,"std_tropical",sst_std_trop)

dst_file->time= (/sea/)
dst_file->roni_factor = (/factor/)
dst_file->std_nino34 = (/sst_std_nin34/)
dst_file->std_tropical = (/sst_std_trop/)
dst_file->std_relnino = (/sst_std_roni/)
end
