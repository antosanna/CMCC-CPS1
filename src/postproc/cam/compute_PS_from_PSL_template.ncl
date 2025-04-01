
external EX "ncl_libraries/invert_cpslec.so"

begin

st=getenv("st")
year=getenv("yyyy")
EE=getenv("ens")
inputts=getenv("inputts")
print("---TS from "+inputts)
inputpsl=getenv("inputpsl")
print("---PSL from "+inputpsl)
inputoro=getenv("inputoro")
print("---orography from "+inputoro)
;
mon=toint(st)
fccm = addfile (inputoro,"r")
oro = tofloat(fccm->orog)                  ; orography
lon=fccm->lon
lat=fccm->lat
fccm = addfile (inputpsl,"r")
psl    = tofloat(fccm->PSL) 
dimpsl=dimsizes(psl)
fccm = addfile (inputts,"r")
ts    = tofloat(fccm->TS) 
dimtas=dimsizes(ts)

ni=dimpsl(2)
nj=dimpsl(1)
nt=dimpsl(0)


PS=psl
do it=0,nt-1
   EX::invert_cpslec(ni,nj, oro, PS(it,:,:), ts(it,:,:), psl(it,:,:))
end do


outputPS=getenv("outputPS")
print("---output file is from "+outputPS)
if (fileexists(outputPS)) then
   system("/bin/rm -f "+outputPS)
end if
setfileoption("nc", "Format",  "NetCDF4Classic")
setfileoption("nc","CompressionLevel",6)
setfileoption("nc","preFill",False)
ncdf     = addfile(outputPS ,"c")  ; open output netCDF file
filedimdef(ncdf,(/"time","lat","lon"/),(/nt,nj,ni/),(/True,False,False/))

fAtt               = True            ; assign file attributes
fAtt@title         = "6hourly PS computed from PSL with invert_cpslec.F90 (modified version of upsl_dp.f)"
fAtt@source_file   = inputpsl
fAtt@creation_date = systemfunc ("date")
fileattdef(ncdf, fAtt)      ; copy file attributes

; make time and UNLIMITED dimension      ; recommended  for most applications
PS!0="time"
PS!1="lat"
PS!2="lon"
ncdf->PS=PS
ncdf->lon=lon
ncdf->lat=lat


end
