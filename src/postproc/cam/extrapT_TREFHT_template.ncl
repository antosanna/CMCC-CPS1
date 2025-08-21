
external EX "ncl_libraries/extrapTZ_SPS4.so"

begin

st=getenv("st") ;"05"
year=getenv("year") ;"2017"
EE=getenv("member") ;"02"
inputta=getenv("inputta")
print("---TA from "+inputta)
inputt2m=getenv("inputt2m")
print("---TREFHT from "+inputt2m)
inputoro=getenv("inputoro")
print("---orography from "+inputoro)
filePS=getenv("inputPS")
print("----PS from "+filePS)  ; a CCM file
;
mon=toint(st)
fccm = addfile (inputoro,"r")
oro = tofloat(fccm->orog)                  ; orography
lon=fccm->lon
lat=fccm->lat
fccm = addfile (inputta , "r")  ; a CCM file
T3    = tofloat(fccm->ta(:,:,:,:)) ;read all levels
time = fccm->time
uc_date=cd_calendar(time,0)
fccm = addfile (inputt2m,"r")
TS    = tofloat(fccm->TREFHT(:,:,:)) 
dimTS=dimsizes(TS)

mm=dimsizes(T3)
ni=mm(3)
nj=mm(2)
nlev=mm(1)
nt=mm(0)

pnew=(/100000.,92500./)
nlev2fix=dimsizes(pnew)
; All values where surface pressure is below the 
; actual value (1000, 925) are set to mask and there the algorithm is 
; not applied 
fccm = addfile (filePS , "r")  ; a CCM file
PS = fccm->PS(:,:,:)
Tout=T3

doT=1
doZ=0
pnew=(/1000.,925./)
EX:: vertinterp(nlev2fix,pnew,ni,nj,nlev,nt,Tout,doT,Tout,doZ,PS,TS,oro)
mask3d=T3*0.
do l=0,nt-1
   do k=0,nlev2fix-1  ; these are the plevs 1000., 925. where extrap is to be done
      mask3d(l,k,:,:)=where(oro.gt.1300.,1,0)
   end do
end do
mask3dlarge=mask3d
;######################################
T_orog=T3
;replace values only where orography is higher than 1300m
T_orog(:,0:nlev2fix-1,:,:)=where(mask3d(:,0:nlev2fix-1,:,:).eq.1.,Tout(:,0:nlev2fix-1,:,:),T3(:,0:nlev2fix-1,:,:))
dbg=0
if (dbg.eq.1)then
   outputdbg="/work/cmcc/cp1/scratch/extrapT/extrapT_mask_orog.nc"
   if (fileexists(outputdbg)) then
      system("/bin/rm -f "+outputdbg)
   end if
   setfileoption("nc", "Format",  "NetCDF4Classic")
   setfileoption("nc","CompressionLevel",6)
   ncdfdbg     = addfile(outputdbg ,"c")  ; open output netCDF file
   ncdfdbg->lon=lon
   ncdfdbg->lat=lat
   T_orog!0="time"
   T_orog!1="plev"
   T_orog!2="lat"
   T_orog!3="lon"
   ncdfdbg->Torig=T3
   ncdfdbg->T=T_orog
   ncdfdbg->T1000=T_orog(:,0,:,:)
   ncdfdbg->T1000orig=T3(:,0,:,:)
   diff1=T_orog(:,0,:,:)-T3(:,0,:,:)
   ncdfdbg->diff1000_orig_1=diff1
   ncdfdbg->T925=T_orog(:,1,:,:)
   ncdfdbg->T925orig=T3(:,1,:,:)
   diff1=T_orog(:,1,:,:)-T3(:,1,:,:)
   ncdfdbg->diff925_orig_1=diff1
   ncdfdbg->mask3d=mask3d(:,1,:,:)
end if

outputta=getenv("outputta")
system("/bin/rm -f "+outputta)
setfileoption("nc", "Format",  "NetCDF4Classic")
setfileoption("nc","CompressionLevel",6)
setfileoption("nc","preFill",False)
 ncdf     = addfile(outputta ,"c")  ; open output netCDF file
print("---TA output file "+outputta)
filedimdef(ncdf,(/"leadtime","plev","lat","lon","bnds","str31"/),(/nt,nlev,nj,ni,2,31/),(/False,False,False,False,False,False/))

; make time and UNLIMITED dimension      ; recommended  for most applications
fccm = addfile (inputta, "r")  ; a CCM file
vNamestemp = getfilevarnames (fccm)
nNamestemp = dimsizes (vNamestemp)
do n=0,nNamestemp-1              ; loop thru each variable
   v=fccm->$vNamestemp(n)$
   if( vNamestemp(n) .eq. "ta" ) then
      copy_VarMeta(v,T_orog)
      v=T_orog
      delete(v@_FillValue)
      delete(v@calendar)
   end if
   ncdf->$vNamestemp(n)$=v
   delete(v)
end do
globalatt=getvaratts(fccm)
do i=0,dimsizes(globalatt)-1
;attribute contents
   ncdf@$globalatt(i)$ = fccm@$globalatt(i)$
;attributes to new file
end do

checkfile=getenv("checkfile")
system("touch "+checkfile)

end
