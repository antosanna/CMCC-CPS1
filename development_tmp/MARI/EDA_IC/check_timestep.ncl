begin  
;***********************************************
; read in data from GRIB file
;***********************************************
   dir  = getenv("wdir2check")
   yyyy=getenv("yr")
   mm=getenv("mo")
   var=getenv("var")  ; will be air.2m, dswrf.sfc, wind.10m, etc
   fil=getenv("file2check")
   fileko=getenv("fileko") 
   fileok_ncl="check_timestep.ncl_ok"

   print("buh")
   ;--remove old checkfile
   if (isfilepresent(fileok_ncl)) then
     system("/bin/rm -f" + fileok_ncl)
   end if

   in  = addfile(dir+fil, "r")
   TIME  = in->time
   TIME!0= "time"

   time  = cd_calendar(TIME, 0)          ; change to date syntax
   time!0= "time"
   time@units = "yyyymmddhhmm"

   ntime=dimsizes(TIME)
   refTIME=new(ntime,typeof(TIME))
   refTIME(0)=TIME(0)
   refTIME@units="days since "+yyyy+"-"+mm+"-1 00:00:00"
   
   do k=1,ntime-1
      refTIME(k)=0.125+refTIME(k-1)
   end do

   reftime  = cd_calendar(refTIME,0)          ; change to date syntax
   reftime@units="yyyymmddhhmm"
   reftime!0= "time"


   refyear   = tointeger(reftime(0,0))    ; Convert to integer for
   refmonth  = tointeger(reftime(0,1))    ; use sprinti 
   refday    = tointeger(reftime(0,2))
   refhour   = tointeger(reftime(0,3))
   refminute = tointeger(reftime(0,4))
   date_str = sprinti("%0.4i", refyear) + sprinti("%0.2i", refmonth) + sprinti("%0.2i", refday) + sprinti("%0.2i", refhour) + sprinti("%0.2i", refminute)
 
   print(date_str) 



   if (var.eq."dswrf.sfc") then
      
      if(date_str.ne.yyyy+mm+"010000") then
         print("First timestep")
         print(date_str)
         print("Should be "+yyyy+mm+"010000")
         system("touch "+fileko) 
         exit
      else
         print("First check ok: the first time value in the read time variable is the expected one")
      end if
   else 
      if (date_str.ne.yyyy+mm+"010130") then
         print("First timestep")
         print(date_str)
         print("Should be "+yyyy+mm+"010130")
         system("touch "+fileko) 
         exit
      else
         print("First check ok: the first time value in the read time variable is the expected one")
      end if
   end if

   ttt=venn2_intersection(TIME,refTIME)
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

