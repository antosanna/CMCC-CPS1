;***************************************************************
; NCL script
; interp in time days -1 and +1 wrt to spike occurrence and replace
; values of input var only for the specific timesteps
;***************************************************************

begin

  inputascii=getenv("inputascii")
  data = readAsciiTable(inputascii,1,"string",3)
  it_spike    = tointeger(str_get_field(data,1,";"))
  nn   = dimsizes(it_spike)  ; this has rank=2
  n_spike   = nn(0)
  delete(nn)


  checkfile=getenv("checkfile_tmin_t2m")
  srcFileNameh1   = getenv("inputh1") ;6hourly outputs
  dstFileName   = getenv("dstFileName")

  print("-----procedure to treat spikes "+n_spike)

  daily_time_FileName   = getenv("input_daily_time") ; daily-output 
  src_time=addfile(daily_time_FileName,"r")
  timeday=src_time->time
  dateday=cd_calendar(timeday,-3)


  srcFileNameh3   = getenv("inputh3") ; daily-output 
  src_h3=addfile(srcFileNameh3,"r")

  print("Checking consistency between tmin and t2m: ")
  print("SRC 6hourly:"+srcFileNameh1)
  src_h1=addfile(srcFileNameh1,"r")
  exists = isfilepresent(dstFileName)
  if(exists) then
     print("---going to remove "+dstFileName)
     system("rm -f "+dstFileName)
  end if

  frq="6hr"
  print("----going to process "+frq)
  time6hr=src_h1->time
  nt6h=dimsizes(time6hr)
  lat=src_h1->lat
  lon=src_h1->lon
  nlon=dimsizes(lon)
  nlat=dimsizes(lat)
  date6hr=cd_calendar(time6hr,-2)
  date6hrHH=cd_calendar(time6hr,-3)
  t2m=src_h1->TREFHT
  print("SRC daily:"+srcFileNameh1)
  src_h1=addfile(srcFileNameh1,"r")
  tmin=src_h3->TREFMNAV

; span the whole day from the first index of time ind_spike_t2m 
; that will be identified in the loop
  incr=3
  do is=0,n_spike-1
     print("----now processing "+it_spike(is,0))
     itnow=it_spike(is,0)
     spike_date_tmin=cd_calendar(timeday(itnow),-3)
;this one always refers to the 12:00
     ind_spike_tmin=get1Dindex(dateday, spike_date_tmin)
     ind_spike_t2m=get1Dindex(date6hrHH, spike_date_tmin)
; take the first snapshot of the actual day
     ind_spike_t2m=ind_spike_t2m-1
    
     print("index for tmin "+ind_spike_t2m)
     print("index for t2m "+ind_spike_tmin)
     print("date for tmin "+dateday(ind_spike_tmin))
     print("date for t2m "+date6hrHH(ind_spike_t2m))

     do i=ind_spike_t2m,min((/ind_spike_t2m+incr,nt6h-1/))
        t2m(i,:,:)=where(t2m(i,:,:).lt.tmin(ind_spike_tmin,:,:),tmin(ind_spike_tmin,:,:),t2m(i,:,:))
     end do
;     mm=dimsizes(t2m)
;     nlon=mm(2)
;     nlat=mm(1)
;     do ii=0,nlon-1
;     do jj=0,nlat-1
;     do i=ind_spike_t2m,min((/ind_spike_t2m+incr,nt6h-1/))
;        print("date under exame  "+date6hrHH(i))
;        if(t2m(i,jj,ii).lt.tmin(ind_spike_tmin,jj,ii))then
;           print("inconsistency date "+date6hrHH(i))
;           print("t2m was  "+t2m(i,jj,ii)+ "< tmin  "+tmin(ind_spike_tmin,jj,ii))
;           print("point is index lat"+ jj+" lon "+ii )
;           print("")
;
;        end if
;     end do
;     end do
;     end do
  end do   ;loop on spikes
  diff = (src_h1->TREFHT - t2m)
  if(any(diff.ne.0.))then
     print("there are diffs!")
     setfileoption("nc","Format","NetCDF4Classic")
     setfileoption("nc","CompressionLevel",6)
     setfileoption("nc","preFill",False)
     dstFileName=getenv("dstFileName")
     dst_file=addfile(dstFileName,"c")
     vNames   = getfilevarnames(src_h1)       ; get an array of file variable names on the given file
     nvars=dimsizes(vNames)
     do k=0,nvars-1   ; first on vars for there can be more than 1 spike
;loop on spikes
        if(vNames(k).eq."TREFHT")then
           copy_VarMeta(src_h1->$vNames(k)$,t2m)
           dst_file->$vNames(k)$ = t2m
;        dst_file->diff = (src_h1->$vNames(k)$ - t2m)
        else
           dst_file->$vNames(k)$ = src_h1->$vNames(k)$
        end if
     end do
  else
     print("no action needed!")
  end if
  system("touch "+checkfile)
  print("touched file "+checkfile)
end
