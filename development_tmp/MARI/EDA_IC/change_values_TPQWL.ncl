begin
  
  tfile=getenv("tfile")
  qfile=getenv("qfile")
  wfile=getenv("wfile")
  pfile=getenv("pfile")
  data=getenv("data")
  template=getenv("templateTPQWL")
  checkfile_TP=getenv("checkfile_TP")

  ;--remove old checkfile
  if (isfilepresent(checkfile_TP)) then
     system("/bin/rm " + checkfile_TP)
  end if

  int = addfile(tfile,"r")
  inr = addfile(pfile,"r")
  inq = addfile(qfile,"r")
  inw = addfile(wfile,"r")

  ftemp = addfile(template,"r")
  vt = int->time
  air = int->air
  nn=dimsizes(air)
  nt=nn(0)
  pres = inr->pres
  mm=dimsizes(pres)
  if(mm(0).lt.nt)then
     nt=mm(0)
  end if
  shum = inq->shum
  ll=dimsizes(shum)
  if(ll(0).lt.nt)then
     nt=ll(0)
  end if
  WIND = inw->WIND
  kk=dimsizes(WIND)
  if(kk(0).lt.nt)then
     nt=kk(0)
  end if

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
     if ( vNamestemp(n) .eq. "TBOT" ) then
         vout=air(0:nt-1,:,:)
         copy_VarMeta(v(0:nt-1,:,:),vout)
;         ncdf->$vNamestemp(n)$=(/vout/)
         ncdf->$vNamestemp(n)$=vout
         delete(vout)
     else if ( vNamestemp(n) .eq. "QBOT" ) then
         vout=shum(0:nt-1,:,:)
         copy_VarMeta(v(0:nt-1,:,:),vout)
         ncdf->$vNamestemp(n)$=vout
         delete(vout)
     else if ( vNamestemp(n) .eq. "PSRF" ) then
         vout=pres(0:nt-1,:,:)
         copy_VarMeta(v(0:nt-1,:,:),vout)
         ncdf->$vNamestemp(n)$=vout
         delete(vout)
     else if ( vNamestemp(n) .eq. "WIND" ) then
         vout=WIND(0:nt-1,:,:)
         copy_VarMeta(v(0:nt-1,:,:),vout)
         ncdf->$vNamestemp(n)$=vout
         delete(vout)
     else if ( vNamestemp(n) .eq. "FLDS" ) then
         ncdf->$vNamestemp(n)$=v(0:nt-1,:,:)
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
  system("touch "+ checkfile_TP)

end
