;*v**************************************************************
; NCL script
; regrid 6hr vars from ne60np4 to reg1x1
; for masked variables define and apply the mask after interpolation
;***************************************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
load "$HOME//SPS/CMCC-SPS3.5/src/templates/C3S_globalatt.ncl"

begin

; define the number of days you want to have at the end
   ndays=184
; define the frequency of outputs
   ifreq6=4
   ifreq12=2

; define the t-axis in days
   time=todouble(fspan(0.5,ndays-0.5,ndays))
; get instruction from key_file
   inpdir=keyword_values(key_path, "inpdir","string")
   outdir=keyword_values(key_path, "outdir","string")
   wkdir=keyword_values(key_path, "wkdir","string")
   year=keyword_values(key_path, "year","string")
   st=keyword_values(key_path, "st","string")
   typeofrun=keyword_values(key_path, "typeofrun","string")
   member=getenv("member")
   startdate=year+st
   time@units="days since "+year+"-"+st+"-01T00:00:00Z"
   print("OUTPUT DIR: "+outdir)

; NOW INPUT FILE 6HOURLY
   varname6=keyword_values(key_path, "varname6","string")
   realm6=keyword_values(key_path, "realm6","string")
   lev=keyword_values(key_path, "lev","integer")
   nvar=dimsizes(varname6)

   do k=0,nvar-1
      srcFileName=inpdir+"cmcc_CMCC-CM2-v20191201_"+typeofrun+"_S"+startdate+"0100_"+realm6(k)+"_6hr_surface_"+varname6(k)+"_r"+member+"i00p00.nc"
      src_file=addfile(srcFileName,"r")
      print("SRC:"+srcFileName)

      vNames = getfilevarnames (src_file) ; get names of all variables on file
      nNames = dimsizes (vNames)   ; number of variables on the file
      
      do n=0,nNames-1              ; loop thru each variable
         v = src_file->$vNames(n)$        ; read the varible to memory
         
         dimv = dimsizes(v)        ; dimension size of the variable
         rank = dimsizes(dimv)     ; rank [ie: number of dimensions]
         if ( rank.eq.3) then
            dstFileName=outdir+"/cmcc_CMCC-CM2-v20191201_"+typeofrun+"_S"+startdate+"0100_"+realm6(k)+"_day_surface_"+varname6(k)+"_r"+member+"i00p00.nc"
            print("DST:"+dstFileName)
            if(isfilepresent(dstFileName)) then
               system("rm "+dstFileName)
            end if
            setfileoption("nc","Format","NetCDF4Classic")
            setfileoption("nc","CompressionLevel",6)
            setfileoption("nc","preFill",False)
            dst_file=addfile(dstFileName,"c")    
            setfileoption(dst_file,"DefineMode",True)
            filedimdef(dst_file,(/"time","lat","lon"/), (/ndays,dimv(1),dimv(2)/), (/False,False,False/))
            filevardef(dst_file,varname6(k),"float", (/ "time", "lat", "lon" /)  )
            var_daymean=new((/ndays,dimv(1),dimv(2)/),"float")

            dumAtts = new( 1, "float")
            dumAtts@long_name = v@long_name
            dumAtts@standard_name = v@standard_name
            dumAtts@units = v@units
            if(isatt(v,"missing_value")) then
               dumAtts@missing_value = 1.e+20
               dumAtts@_FillValue = 1.e+20
            else
               delete(dumAtts@_FillValue)
               delete(dumAtts@missing_value)
            end if

            filevarattdef( dst_file, varname6(k), dumAtts )
            ic=0
            ifreq=ifreq6
            do it=0,ndays-1
               var_daymean(it,:,:)=tofloat(dim_avg_n(v(ic:ic+ifreq,:,:),0))
;               print("output time in days "+time(it))
;               print("averaging "+v&leadtime(ic:ic+ifreq))
;               print(" ")
               ic=ic+ifreq  ; count time 0:00 twice because we have
                            ; snapshot (eg daily mean for 6hrly is
                            ; given averaging 0,6,12,18,0)
            end do
            dst_file->$vNames(n)$=(/var_daymean/)
            dst_file->lat=src_file->lat
            dst_file->lon=src_file->lon
            time!0="time"
            dst_file->time=time
            delete(var_daymean)
         end if 
         delete(v)
         delete(dimv)
         delete(rank)
      end do
      delete(vNames)
      delete(nNames)
   end do
   delete(varname6)
   delete(realm6)

; NOW INPUT FILE 12HOURLY
   varname12=keyword_values(key_path, "varname12","string")
   realm12=keyword_values(key_path, "realm12","string")
; define different plevs for different fields
; only one level for hus: 850
   levvalues1=tointeger(keyword_values(key_path, "levvalues1","string"))
; 3 levels for zg: 850, 500, 200
   levvalues3=tointeger(keyword_values(key_path, "levvalues3","string"))
; 4 levels for ta, ua, va: 925, 850, 500, 200
   levvalues4=tointeger(keyword_values(key_path, "levvalues4","string"))
   delete(nvar)
   nvar=dimsizes(varname12)

   do k=0,nvar-1
      srcFileName=inpdir+"cmcc_CMCC-CM2-v20191201_"+typeofrun+"_S"+startdate+"0100_"+realm12(k)+"_12hr_pressure_"+varname12(k)+"_r"+member+"i00p00.nc"
      src_file=addfile(srcFileName,"r")
      print("SRC:"+srcFileName)

      vNames = getfilevarnames (src_file) ; get names of all variables on file
      nNames = dimsizes (vNames)   ; number of variables on the file
      
      do n=0,nNames-1              ; loop thru each variable
         v = src_file->$vNames(n)$        ; read the varible to memory
         
         dimv = dimsizes(v)        ; dimension size of the variable
         rank = dimsizes(dimv)     ; rank [ie: number of dimensions]
         if ( rank.eq.4) then
            dstFileName=outdir+"cmcc_CMCC-CM2-v20191201_"+typeofrun+"_S"+startdate+"0100_"+realm12(k)+"_day_pressure_"+varname12(k)+"_r"+member+"i00p00.nc"
            print("DST:"+dstFileName)
            if(isfilepresent(dstFileName)) then
               system("rm "+dstFileName)
            end if
            setfileoption("nc","Format","NetCDF4Classic")
            setfileoption("nc","CompressionLevel",6)
            setfileoption("nc","preFill",False)
            dst_file=addfile(dstFileName,"c")    
            setfileoption(dst_file,"DefineMode",True)
            filedimdef(dst_file,(/"time","plev","lat","lon"/), (/ndays,lev(k),dimv(2),dimv(3)/), (/False,False,False,False/))
            filevardef(dst_file,varname12(k),"float", (/ "time", "plev","lat", "lon" /)  )
            var_daymean=new((/ndays,lev(k),dimv(2),dimv(3)/),"float")

            dumAtts = new( 1, "float")
            dumAtts@long_name = v@long_name
            dumAtts@standard_name = v@standard_name
            dumAtts@units = v@units

            filevarattdef( dst_file, varname12(k), dumAtts )
            ic=0
            ifreq=ifreq12
            do it=0,ndays-1
               do il=0,lev(k)-1
                  if (lev(k).eq.4) then
                     var_daymean(it,il,:,:)=tofloat(dim_avg_n(v(ic:ic+ifreq,{levvalues4(il)},:,:),0))
                     plev=levvalues4(0:lev(k)-1)
                  else if (lev(k).eq.3) then
                     print(il)
                     print(levvalues3(il))
                     var_daymean(it,il,:,:)=tofloat(dim_avg_n(v(ic:ic+ifreq,{levvalues3(il)},:,:),0))
                     plev=levvalues3(0:lev(k)-1)
                  else if (lev(k).eq.1) then
                     var_daymean(it,il,:,:)=tofloat(dim_avg_n(v(ic:ic+ifreq,{levvalues1(il)},:,:),0))
                     plev=levvalues1(0:lev(k)-1)
                  end if
                  end if
                  end if
               end do
;               print("output time in days "+time(it))
;               print("averaging "+v&leadtime(ic:ic+ifreq))
;               print(" ")
               ic=ic+ifreq
            end do
            dst_file->$vNames(n)$=(/var_daymean/)
            dst_file->lat=src_file->lat
            dst_file->lon=src_file->lon
            plev!0="plev"
            print(plev)
            dst_file->plev=plev
            time!0="time"
            dst_file->time=time
            delete(var_daymean)
            delete(plev)
         end if 
         delete(v)
         delete(dimv)
         delete(rank)
      end do
      delete(vNames)
      delete(nNames)
  end do
; touch file to state that the process is correctly finished
  print("creating "+wkdir+"/C3S_daily_mean_2d.ncl_"+member+"_ok")
  system("touch "+wkdir+"/C3S_daily_mean_2d.ncl_"+member+"_ok")

end
