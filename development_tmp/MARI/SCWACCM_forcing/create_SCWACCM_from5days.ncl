;CODE_PATH=getenv("codepath")
;commonlib=CODE_PATH+"/common.ncl"
;load $commonlib
creation_date = systemfunc("date +%Y%m%d")

print("starting script "+get_script_name())

;rootPath = getenv("in_dir")

;inFile = getenv("in_file")
;outFile = getenv("out_file")
inpdir="/work/csp/cp1/scratch/SCWACCM_forcing/gpfs/fs1/p/acom/acom-climate/cesm2/postprocess/b.e21.BWSSP585cmip6.f09_g17.CMIP6-SSP5-8.5-WACCM.001/atm/proc/tseries/day_5_zm/" 

years = ispan(2014,2100,10)
nYears = dimsizes(years)
nMonths=nYears*12

yearstring="20450101-20541227"
caseid="b.e21.BWSSP585cmip6.f09_g17.CMIP6-SSP5-8.5-WACCM.001"
vars=(/"CO2","H","NO","O","O2","O3","PS","QRS_TOT"/)
do v = 0,dimsizes(vars)-1
   ff=addfile(inpdir+caseid+".cam.h7."+vars(v)+"."+yearString+".nc")
   tmp=ff->$vars(v)$
   xMonthAvg = calculate_monthly_values(tmp, "avg", 0, False)
   tenyearavg=clmMonTLL(xMonthAvg)
   printVarSummary(clmMonTLL)
   exit()
done

;TBM
years(0)=1849
years(nYears-2)=2013
years(nYears-1)=2014

print("opening "+rootPath+inFile)
ncidin = addfile(rootPath+inFile,"r")
print("reading time")
inTime=ncidin->time
print("reading date")
inDate=ncidin->date
inYears=inDate/10000
print("reading lev")
lev=ncidin->lev
print("reading lat")
lat=ncidin->lat

command("rm "+rootPath+outFile)
ncidout = addfile(rootPath+outFile,"c")
; Create an UNLIMITED record dimension in the output netCDF file.  This is critical if  
;  the user plans to ever use NCO to concatenate the file along the time/record dimension.
  print("creating unlimited time dimension")
filedimdef(ncidout,"time",-1,True)





;      xMonthAvg = calculate_monthly_values(x, "avg", 0, False)

exit()
command("rm "+rootPath+outFile)
ncidout = addfile(rootPath+outFile,"c")
; Create an UNLIMITED record dimension in the output netCDF file.  This is critical if 
;  the user plans to ever use NCO to concatenate the file along the time/record dimension.
  print("creating unlimited time dimension")
filedimdef(ncidout,"time",-1,True)

copyVars=(/"gw","hyai","hyam","hybi","hybm","ilev","P0"/)

do i = 0,dimsizes(copyVars)-1
  print("copying "+copyVars(i))
  ncidout->$copyVars(i)$=ncidin->$copyVars(i)$
end do 

time = inTime(0:nMonths-1)
copy_VarAtts(inTime,time)
delete(time@bounds)

do y = 0,nYears-1
  print("year "+years(y))
  iTime = ind(inYears.eq.years(y))
  if (dimsizes(iTime).ne.12) then
    print("FATAL: 12 months not found")
    printVarSummary(iTime)
    exit
  end if
  do month=0,11
    time(y*12+month)=inTime(iTime(month))
    if (y.eq.nYears-1) then
      time(y*12+month)=time(y*12+month)+365 ; 2014->2015
    end if
  end do
end do

date=cd_calendar(time,-2)
date!0="time"
date&time=time
print(" date: "+date+", time: "+time)
ncidout->date=date

print("copying PS")
PSin=ncidin->PS
PS=PSin(0:nMonths-1,:,:) ; (time, lat, lon)
copy_VarAtts(PSin,PS)

PS!0="time"
PS!1="lat"
PS!2="lon"

PS&time=time
PS&lat=lat
PS&lon=lon
PS=0.0

print("Copying 1849 PS values from piControl file")
PS(0:11,:,:)=ncidPI->PS

do y = 1,nYears-3
  print("year "+years(y))
  iTime = ind(inYears.eq.years(y))
  if (dimsizes(iTime).ne.12) then
    print("FATAL: 12 months not found")
    printVarSummary(iTime)
    exit
  end if
  do month=0,11
    m=y*12+month
    do cycleYear=-4,4
      yind=iTime(month)+cycleYear*12
;        print(yind+" "+inDate(yind))
      PS(m,:,:)=PS(m,:,:)+PSin(yind,:,:)/9.0
    end do
  end do
end do
print("Averaging PS 2012-2014 for 2013 and 2015")
iTime = ind(inYears.eq.2014)
iTime2 = ind(inYears.eq.2013)
iTime3 = ind(inYears.eq.2012)
y2=nYears-2
PS(y2*12:y2*12+11,:,:)=(PSin(iTime,:,:)+PSin(iTime2,:,:)+PSin(iTime3,:,:))/3.0
y1=nYears-1
PS(y1*12:y1*12+11,:,:)=PS(y2*12:y2*12+11,:,:)
print("writing PS")
ncidout->PS=PS
    
interpVars=(/"O3","OH","NO3","HO2","HALONS"/)
do i = 0,dimsizes(interpVars)-1
  print("copying "+interpVars(i))
  fullVar=ncidin->$interpVars(i)$
  shortVar=fullVar(0:nMonths-1,:,:,:) ; (time, lev, lat, lon)
  copy_VarAtts(fullVar,shortVar)
  
  shortVar!0="time"
  shortVar!1="lev"
  shortVar!2="lat"
  shortVar!3="lon"
  
  shortVar&time=time
  shortVar&lev=lev
  shortVar&lat=lat
  shortVar&lon=lon
  shortVar=0.0

  print("Copying 1849 "+interpVars(i)+" values from piControl file")
  shortVar(0:11,:,:,:)=ncidPI->$interpVars(i)$
  do y = 1,nYears-3
    print("year "+years(y))
    iTime = ind(inYears.eq.years(y))
    if (dimsizes(iTime).ne.12) then
      print("FATAL: 12 months not found")
      printVarSummary(iTime)
      exit
    end if
    do month=0,11
      m=y*12+month
      do cycleYear=-4,4
        yind=iTime(month)+cycleYear*12
        print(yind+" "+inDate(yind))
        shortVar(m,:,:,:)=shortVar(m,:,:,:)+fullVar(yind,:,:,:)/9.0
      end do
    end do
  end do
  print("Averaging "+interpVars(i)+" 2012-2014 for 2013 and 2015")
  iTime = ind(inYears.eq.2014)
  iTime2 = ind(inYears.eq.2013)
  iTime3 = ind(inYears.eq.2012)
  y2=nYears-2
  shortVar(y2*12:y2*12+11,:,:,:)=(fullVar(iTime,:,:,:)+\
          fullVar(iTime2,:,:,:)+fullVar(iTime3,:,:,:))/3.0
  y1=nYears-1
  shortVar(y1*12:y1*12+11,:,:,:)=shortVar(y2*12:y2*12+11,:,:,:)        
  
  ncidout->$interpVars(i)$=shortVar
end do
print("closing "+piControlPath+piControlFile)
delete(ncidPI)

print("adding metadata")
; For a nicer looking netCDF, create a "new line" character.
nl = integertochar(10)  ; newline character
  
ncidout@input_method = "INTERP_MISSING_MONTHS"
ncidout@creation_date     = nl+systemfunc("date")
ncidout@cesm_contact = nl+"Mike Mills, NCAR ACOM, mmills@ucar.edu" ;
ncidout@data_script = nl+"Converted from data_source_files by programs"+nl+\
        "    CreateTracerCnstFile.ncl"+nl+\
        "    TracerCnstFileCMIP6ensembleAverage[1-7].ncl"+nl+\
        "    TracerCnstFileCMIP6ensembleFinish.ncl"+nl+\
        "    "+get_script_name()+nl+\
        "SVN path: https://svn.code.sf.net/p/codescripts/code/trunk/ncl/cam_forcing"
ncidout@data_creator = nl+"Mike Mills, NCAR ACOM, mmills@ucar.edu" ;
ncidout@data_summary= nl+\
  "O3, OH, NO3, HO2, and HALONS from CMIP6 WACCM historical ensemble cases:"+nl+\
  "    b.e21.BWHIST.f09_g17.CMIP6-historical-WACCM.001"+nl+\
  "    b.e21.BWHIST.f09_g17.CMIP6-historical-WACCM.002"+nl+\
  "    b.e21.BWHIST.f09_g17.CMIP6-historical-WACCM.003"+nl+\
  "Seasonal cycles every 10 years averaged over 9 years centered on date"+nl+\
  "Year 1849 from piControl file: "+piControlFile+nl+\
  "Years 2013 and 2015 averaged from 2012-2014 output."
ncidout@data_title="Tracer constituents for historical simulations, 1849-2015"

print("closing "+outFile)
delete(ncidout)
print("closing "+inFile)
delete(ncidin)
exit

