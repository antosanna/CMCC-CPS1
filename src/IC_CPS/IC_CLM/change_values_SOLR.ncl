begin
  
  sfile=getenv("sfile")
  data=getenv("data")
  template=getenv("templateSOLR")
  checkfile_SR=getenv("checkfile_SR")

  ;--remove old checkfile
  if (isfilepresent(checkfile_SR)) then
     system("/bin/rm " + checkfile_SR)
  end if



  ins = addfile(sfile,"r")

  ftemp = addfile(template,"r")
  vt = ins->time
  mm=dimsizes(vt)
  nt=mm(0)
  FSDS = ins->dswrf

  outfile=getenv("outfile")
  system("/bin/rm -f "+outfile)   ; remove any pre-existing file
  ncdf     = addfile(outfile ,"c")  ; open output netCDF file

  vNamestemp = getfilevarnames (ftemp) ; get names of all variables on file
  print(vNamestemp)
  nNamestemp = dimsizes (vNamestemp)   ; number of variables on the file


;     do something with Vnew

  do n=0,nNamestemp-1              ; loop thru each variable
     v=ftemp->$vNamestemp(n)$        ; read the varible to memory
     printVarSummary(v)
     if ( vNamestemp(n) .eq. "FSDS" ) then
         print("entro")
         vout=FSDS
         copy_VarMeta(v(0:nt-1,:,:),vout)
         ncdf->$vNamestemp(n)$=vout
         delete(vout)
     else if ( vNamestemp(n) .eq. "lon" ) then
         print("do nothing")
     else if ( vNamestemp(n) .eq. "lat" ) then
         print("do nothing")
     else if ( vNamestemp(n) .eq. "time" ) then
         print("do nothing")
     else
         ncdf->$vNamestemp(n)$=v
     end if
     end if
     end if
     end if
     delete(v)
  end do

  time           = vt
  time@units = data
  time!0         = "time"
  time@calendar  = "noleap"

  ncdf->time=time

; touch file to state that the process is correctly finished
  system("touch "+checkfile_SR)

end
