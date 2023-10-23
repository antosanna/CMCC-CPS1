begin  
;***********************************************
; read in data from GRIB file
;***********************************************

   dir  = getenv("wdir_ecmwf")
   yyyy=toint(getenv("yr"))
   mm=toint(getenv("mo"))
   var=getenv("var")  ; will be an or acc_fc
   fileko=getenv("fileko")
   fileok_ncl="check_timestep_raw.ncl_ok"

   ;--remove old checkfile
   if (isfilepresent(fileok_ncl)) then
     system("/bin/rm -f" + fileok_ncl)
   end if

   fil  = getenv("file_eda")
   in  = addfile(dir+fil, "r")
   TIME  = in->time
   TIME!0= "time"
   ntime=dimsizes(TIME)
   
   time  = cd_calendar(TIME, -3)          ; change to date syntax
   time!0= "time"
   time@units = "yyyymmddhh"
   time@calendar=TIME@calendar

   ;;refTIME is the reference one 
   refTIME=new(ntime,typeof(TIME))
   if(var.eq."acc_fc") then
      refTIME(0)=3
      if (mm.eq.1) then
        mmm1=12
        yyyym1=yyyy-1
      else
        mmm1=toint(mm)-1
        yyyym1=yyyy
      end if 
      lastdayofmmm1=days_in_month(toint(yyyym1),toint(mmm1))
      refTIME@units="hours since "+yyyym1+"-"+sprinti("%.2i",mmm1)+"-"+lastdayofmmm1+" 18:00:00"
      refTIME@calendar=TIME@calendar
   else
     refTIME(0)=0
     refTIME@units="hours since "+yyyy+"-"+mm+"-1 00:00:00"
     refTIME@calendar=TIME@calendar
   end if

   do k=1,ntime-1
    if(var.eq."acc_fc") then
      refTIME(k)=3+refTIME(k-1)   ; 3-hourly accumulation
    else
      refTIME(k)=3+refTIME(k-1)    ; 3-hourly snapshot
    end if 
   end do
   reftime  = cd_calendar(refTIME, -3)          ; change to date syntax
   reftime@units="yyyymmddhh"
   reftime!0= "time"
   reftime@units = "yyyymmddhh"
   reftime@calendar=TIME@calendar

   if (var.eq."acc_fc") then
      if(reftime(0).ne.time(0))
         print("First timestep")
         print(time(0))
         print("Should be "+reftime(0))
         system("touch "+fileko)
         exit
      else
         print(time(0))
         print("First check ok: the first time value in the read time variable is the expected one")
      end if
   else 
      if (reftime(0).ne.time(0)) then
         print("First timestep "+time(0))
         print("Should be "+ reftime(0))
         system("touch "+fileko)
         exit
      else
         print("First timestep "+time(0))
         print("First check ok: the first time value in the read time variable is the expected one")
      end if
   end if
   

   ttt=venn2_intersection(TIME,refTIME)
   print(ttt)
   if (dimsizes(ttt).ne.dimsizes(TIME)) then
      diff=venn2_difference(TIME,refTIME)
      print("The two timeseries differ for value "+diff)
      print("corresponding to ncl index "+get1Dindex(TIME,diff))
      print("Read timeseries is not correct")
      print("should be "+dimsizes(TIME)+" but is "+dimsizes(ttt))
      system("touch "+fileko)
      exit
   else
      print("Second check ok: the read time variable is the expected one")
   end if

   ; flag - ncl succesfully exited
   system("touch "+fileok_ncl)
end

