
creation_date = systemfunc("date +%Y%m%d")
rootPath="/work/csp/cp1/scratch/SCWACCM_forcing/workdir/"
outFile="SCWACCM_forcing_zm_L70_2014-2101_SSP5-8.5_c"+creation_date+".nc"
if(isfilepresent(rootPath+outFile)) then
  system("rm -f "+rootPath+outFile)
end if

years = ispan(2010,2100,10)
nYears = dimsizes(years)
nMonths=nYears*12

years(0)=2015
years(nYears-1)=2098
inFile="QRS_TOT_tseries.nc"
print("opening "+rootPath+inFile)
ncidin = addfile(rootPath+inFile,"r")
print("reading time")
inTime=ncidin->time
;print(inTime)
;2014+2024-2094+2100
print("reading date")
inDate=ncidin->date
inYears=inDate/10000
print(inYears)
;2015+2020-2090+2098
print("reading lev")
lev=ncidin->lev
nLev=dimsizes(lev)
print("reading lat")
lat=ncidin->lat
nLat=dimsizes(lat)

ncidout = addfile(rootPath+outFile,"c")
;print("creating unlimited time dimension")
filedimdef(ncidout,"time",-1,True)

copyVars=(/"gw","hyai","hyam","hybi","hybm","ilev","P0"/)

do i = 0,dimsizes(copyVars)-1
  print("copying "+copyVars(i) +" from reference hist file")
  refin=addfile("/data/inputs/CESM/inputdata/atm/waccm/waccm_forcing/SCWACCM_forcing_zm_L70_1849-2015_CMIP6ensAvg_c181011.nc","r")
  ncidout->$copyVars(i)$=refin->$copyVars(i)$
end do 

time=round(inTime(0:nMonths-1),3)
copy_VarAtts(inTime,time)
time4date = round(inTime(0:nMonths-1),3)
copy_VarAtts(inTime,time4date)

printVarSummary(time4date)
delete(time4date@bounds)
delete(time@bounds)

do y = 0,nYears-1
  print("year "+years(y))
  iTime = ind(inYears.eq.years(y))
  print("index " + iTime)
  if (dimsizes(iTime).ne.12) then
    print("FATAL: 12 months not found")
    printVarSummary(iTime)
    exit
  end if
  if (y.eq.0) then
    offset=365 ;first year - time is ok as it is 
  else if (y.eq.nYears-1) then
    offset=-365 ; last year - time is one year behind (2100 but we want it tagged as 2101)
  else
    offset=4*365 ;middle of the interval - back of 4 years (48 month)
  end if
  end if
  do month=0,11
    time4date(y*12+month)=round(inTime(iTime(month)),3)-offset
  end do
end do

date=cd_calendar(time4date,-2)
date!0="time"
date&time=time
print(" date: "+date+", time: "+time+"   ,time4date:  "+time4date)
ncidout->date=date

print("copying PS")

inFile="PS_tseries.nc"
print("opening "+rootPath+inFile)
ncidin = addfile(rootPath+inFile,"r")
PSin=ncidin->PS
PS=new((/nMonths,nLat/),typeof(PSin)) ; (time, lat)
copy_VarAtts(PSin,PS)
PS!0="time"
PS!1="lat"

PS&time=time
PS&lat=lat
PS=(/PSin/)
ncidout->PS=PS

interpVars=(/"CO2","H","NO","O","O2","O3","QRS_TOT"/)
shortVar=new((/nMonths,nLev,nLat/),typeof(PSin))

do i = 0,dimsizes(interpVars)-1
  inFile=interpVars(i)+"_tseries.nc"
  print("reading "+interpVars(i))
  ncidin = addfile(rootPath+inFile,"r")
  fullVar=ncidin->$interpVars(i)$
  print("creating short variable")
  copy_VarAtts(fullVar,shortVar)
  
  shortVar!0="time"
  shortVar!1="lev"
  shortVar!2="lat"
  
  shortVar&time=time
  shortVar&lev=lev
  shortVar&lat=lat

  shortVar=(/fullVar/)
  ncidout->$interpVars(i)$=shortVar

end do

print("adding metadata")
; For a nicer looking netCDF, create a "new line" character.
nl = integertochar(10)  ; newline character

ncidout@data_title="Prescribed SC-WACCM forcings for SSP5-8.5 simulations, 2014-2101"
ncidout@data_summary="CO2, H, NO, O, O2, O3, PS, and QRS_TOT from CMIP6 WACCM scenario case:"+nl+\
  "    b.e21.BWHIST.f09_g17.CMIP6-historical-WACCM.001"+nl+\
  "Original files: 5 days zonal mean output retrieved from NCAR cluster and saved in"+nl+\
  "/data/csp/cp1/CMCC-CPS1/inputs/WACCM_SSP585_day5_zm.tar"+nl+\
  " "+nl+\
  "Time structure as in"+nl+\
  "$CESMDATAROOT/inputdata/atm/cam/tracer_cnst/tracer_cnst_halons_3D_L70_2014-2101_CMIP6-SSP5-8.5_c190307.nc:"+nl+\
  "Seasonal cycles every 10 years averaged over 9 years centered on date"+nl+\
  "Year 2014 from year 2015 output"+nl+\
  "Year 2101 from average of years 2096-2100"
ncidout@creation_date = nl+systemfunc("date")
ncidout@data_script = nl+"Converted from data_source_files by programs"+nl+\
        "    create_SCWACCM_forcing.sh"+nl+\
        "    conform_SCWACCM_forcing.ncl"
ncidout@data_filename=outFile

print("closing "+outFile)
delete(ncidout)
