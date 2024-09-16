load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl" 
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
;************************************************
;************************************************
;  BEGIN MAIN
;************************************************
begin
;************************************************
; variable and file handling
;************************************************
   varm=getenv("varm")
   st=getenv("st")
   startdate=getenv("startdate")
   year=getenv("year")
   fileroot=getenv("fileroot")
   varname=getenv("varname")
   filename=fileroot+"_S"+startdate+"0100_"+varname+"_"
   diri=getenv("diri")
   fili = systemfunc("cd "+diri+" ; ls "+filename+"r??i00p00.nc")
   print(fili)
   filostd=getenv("filostd")   ;with full path
   outfile=getenv("outfile")   ;with full path
   checkfile=getenv("checkfilestd")   
   nens=toint(getenv("nens"))
   ifirst=toint(getenv("ifirst"))
   
   nmon = 6
   nfils = dimsizes(fili)
; checl file number
   if(nfils.ne.nens)then
     print("file number should be "+nens+" but found only "+nfils)
     exit
   end if
   
 
   filin=diri+"/"+fili(0)
   fi = addfile (filin, "r")
   x = fi->$varm$
   ndims=dimsizes(x)
   rank=dimsizes(ndims)
   if ( rank.eq.4 )then
      nlev=ndims(1)
      nlat=ndims(2)
      nlon=ndims(3)
   else
      nlat=ndims(1)
      nlon=ndims(2)
   end if
     
   time = fi->time
   utc_date = ut_calendar(time, 0)
   month  = tointeger(utc_date(:,1))

;initialize arrays only for the first year of climatology

   if(ifirst.eq.1)then
      if ( rank.eq.4 )then
         xmeanmon=new((/nmon,nlev,nlat,nlon/),typeof(x),"No_FillValue")
         xM2mon=new((/nmon,nlev,nlat,nlon/),typeof(x),"No_FillValue")
      else
         xmeanmon=new((/nmon,nlat,nlon/),typeof(x),"No_FillValue")
         xM2mon=new((/nmon,nlat,nlon/),typeof(x),"No_FillValue")
      end if
      xmeanmon=0.
      xM2mon=0.
      mon=new(nmon,"integer",1)
      delete(mon@_FillValue)
   else
      fi = addfile (filostd,"r")
      xmeanmon = fi->xmeanmon
      xM2mon = (fi->$varm$)^2
      mon=fi->mon
      xM2mon=xM2mon*(conform(xM2mon,mon,0)-1)
   end if

   do nf=0,nfils-1
      filin=diri+"/"+fili(nf)
      print(" ------ " + filin)
      fi = addfile (filin, "r")
      x = fi->$varm$
      time = fi->time
      utc_date = ut_calendar(time, 0)
      month  = tointeger(utc_date(:,1))
; initialize month index
      ic=0
; first leadtime
      if ( rank.eq.4 )then
         delta = x(0,:,:,:) - xmeanmon(0,:,:,:)
         xmeanmon(0,:,:,:) = xmeanmon(0,:,:,:)+delta/mon(0)
         xM2mon(0,:,:,:) = xM2mon(0,:,:,:)+delta*(x(0,:,:,:) - xmeanmon(0,:,:,:))
      else
; this only for dbg+
;   fout  = addfile ("/work/csp/sp2/scratch/C3S_statistics/tmp/check.nc", "c")  ; open output file
;   fout->x = x
;   fout->xmeanmon = xmeanmon
         delta = x(0,:,:) - xmeanmon(0,:,:)
         xmeanmon(0,:,:) = xmeanmon(0,:,:)+delta/mon(0)
         xM2mon(0,:,:) = xM2mon(0,:,:)+delta*(x(0,:,:) - xmeanmon(0,:,:))
;   fout->delta = delta
;   fout->xM2mon = xM2mon
;         print("I am here")
; this only for dbg-
      end if
; following leadtimes
      print("---mese "+month(0))
      do i=1,dimsizes(month)-1
         if ( month(i).ne.month(i-1) ) then
            print("month changing")
            print("---mese "+month(i))
            ic=ic+1
            if (ic.eq.nmon) then
               ic=nmon-1
            end if
         end if
         if ( rank.eq.4 )then
            delta = x(i,:,:,:) - xmeanmon(ic,:,:,:)
            xmeanmon(ic,:,:,:) = xmeanmon(ic,:,:,:)+delta/mon(ic)
            xM2mon(ic,:,:,:) = xM2mon(ic,:,:,:)+delta*(x(i,:,:,:) - xmeanmon(ic,:,:,:))
         else
             delta = x(i,:,:) - xmeanmon(ic,:,:)
             xmeanmon(ic,:,:) = xmeanmon(ic,:,:)+delta/mon(ic)
             xM2mon(ic,:,:) = xM2mon(ic,:,:)+delta*(x(i,:,:) - xmeanmon(ic,:,:))
         end if
         mon(ic)=mon(ic)+1
      end do
      print(" ------ ok ")
      print(" ")

   end do 
   std= sqrt(xM2mon / (conform(xM2mon,mon,0) - 1))

   dimNames = getvardimnames(x)
   rank=dimsizes(dimsizes(x))
   if ( rank.eq.4 ) then
      copy_VarMeta(x(0:nmon-1,:,:,:),std)
      copy_VarMeta(x(0:nmon-1,:,:,:),xmeanmon)
   else
      copy_VarMeta(x(0:nmon-1,:,:),std)
      copy_VarMeta(x(0:nmon-1,:,:),xmeanmon)
   end if
   
   if ( isfilepresent(checkfile)) then    ; remove if exists
       system("/bin/rm " + checkfile)    ; remove if exists
   end if
   ;#######
   
   lat=fi->lat
   lon=fi->lon
   if ( rank.eq.4 ) then
      if ( dimNames(1) .eq. "depth" ) then
         depth=fi->depth
      else
         plev=fi->plev
      end if
   end if
   leadtime=fi->leadtime
   time=fi->time
   reftime=fi->reftime
   hcrs=fi->hcrs
   realization=fi->realization


;*******************************************************************

   if ( isfilepresent(outfile)) then    ; remove if exists
      system("/bin/rm " + outfile)    ; remove if exists
   end if
   fout  = addfile (outfile, "c")  ; open output file
   setfileoption("nc","Format","NetCDF4Classic")
   setfileoption("nc","CompressionLevel",6)
   setfileoption("nc","preFill",False)

   globalAtt             = True
   globalAtt@title       = "Standard dev computed by stdev_on_line.ncl. https://it.m.wikipedia.org/wiki/Algoritmi_per_il_calcolo_della_varianza"
   fileattdef( fout, globalAtt )

   fout->lat    = lat
   fout->lon    = lon
   fout->$varm$ = std
   fout->xmeanmon = xmeanmon
   fout->mon = mon

   if ( rank.eq.4 ) then
      if ( dimNames(1) .eq. "depth" ) then
         fout->depth=depth
      else
         fout->plev=plev
      end if
   end if
;
   system("touch " + checkfile)    
;***********************************************
end
