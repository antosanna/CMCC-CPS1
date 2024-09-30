#!/bin/sh -l
#-------------------------------------------------------------------------------
# Use: create_edaFORC.sh [yyyy] [mm] [member] [dbg]
#   yyyy     year of month preceding start-date
#   mm       month preceding start-date
#   member      tag for EDA member
#   backup   for backup IC tag
#   checkfe 
#   dbg    OPTIONAL (0/1)
#
# In operational production, this script is launched in $DIR_LND_IC by launch_forced_run_EDA.sh
#-------------------------------------------------------------------------------
#In CLMCRUNCEP mode the CRUNCEP dataset is used and all of it's data is on a 6-hourly interval. 
# Like CLM_QIAN the dataset is divided into those three data streams: solar, precipitation, and everything else (temperature, pressure, humidity and wind). 
# The time-stamps of the data were also adjusted so that they are the beginning of the interval for solar, and the middle for the other two.
# you need to include time 00:00 of following month first day to do the 3hourly interpolation for: temperature, pressure, humidity, wind and preci
# BUT NOT FOR SOLAR
# This is true in principle BUT EDA accumulated fields (prec and solar) refer to the following 6hour interval so the exact timing should be 3,9,15... instead of 0,6,12,18
# SO WE HAVE TO INTERPOLATE SOLAR BUT NOT PREC

# the proc forsees 2 checks on the time axis: one on the raw data just after download (check_timestep_raw_eda.ncl) and the other after the time interpolation (check_timestep.ncl)
#------------------------------------------------
#-------------------------------------------------------------
# load variables from descriptor
#-------------------------------------------------------------
#------------------------------------------------
set +euxv     
# MANDATORY!! if not set the script exits because if sourced 
# does not recognize $PROMPT 
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. ${DIR_UTIL}/load_cdo
. ${DIR_UTIL}/load_nco
. ${DIR_UTIL}/load_ncl
set -euxv

dbg=${6:-0}

#-----------------------------------
# INPUT SECTION
#-----------------------------------
yr=$1      #year of month preceding start-date
m=$2      #month preceding start-date
member=$3
backup=$4
checkfile=$5

####definition to be checked/included in descr_CPS.sh
forcDIReda_ens=${forcDIReda}/EDA_n$member
mkdir -p ${forcDIReda_ens}
forcDIReda_bkup=${forcDIReda}/EDA_n${member}_backup
WORKDIR_LAND=$SCRATCHDIR/WORK_LAND_IC
mkdir -p ${WORKDIR_LAND}
REPOSITORY=$MYCESMDATAROOT/CMCC-${CPSSYS}/files4${CPSSYS}
freq_forcings=8 #3hourly -> 8 per day
#------------------------------------------------
#-------------------------------------------------------------
# Set time variables
#-------------------------------------------------------------
#------------------------------------------------
mo=`printf '%.2d' $((10#$m))`

if [[ $yr$mo -eq 196906 ]] ; then
   st=07     #`date -d ' '$yy${mm}01' + 1 month' +%m`
   yyyy=1969 #`date -d ' '$yy${mm}01' + 1 month' +%Y`
else
  st=`date -d ' '$yr${mo}01' + 1 month' +%m`
  yyyy=`date -d ' '$yr${mo}01' + 1 month' +%Y`
fi

set +euvx
. ${DIR_UTIL}/descr_ensemble.sh $yyyy
set -euvx

if [[ $backup -eq 0 ]]  #operational
then
  forcDIR=${forcDIReda_ens}
  wdir=workdir_eda${member}
  jobname=launchFREDA0${member}_${yyyy}${st}
  preffix="clmforc.EDA${member}.0.5d"
  title_tag="[CLMIC]"
elif [[ $backup -eq 1 ]]  #backup mode
then
  forcDIR=$forcDIReda_bkup
  wdir=workdir_eda${member}_bkup
  jobname=launchFREDA0${member}_${yyyy}${st}_bkup
  preffix="clmforc.EDA${member}.backup.0.5d"
  title_tag="[CLMIC-backup]"
elif [[ $backup -gt 1 ]]  #backup mode
then
  body="create_edaFORC.sh: backup input not well defined. Exiting now"
  title="[CLMIC] ${CPSSYS} forecast error"
  echo $body
  ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r $typeofrun -s $yyyy$st
  exit 1
fi

if [ $dbg -eq 1 ]
then
   forcDIR=$SCRATCHDIR/forc4CLM_eda${member}
   if [ ! -d $forcDIR ]
   then
       echo "Missing folder $forcDIR. Note that you are in dbg mode."
       exit 1
   fi
fi
#-----------------------------------
#-----------------------------------
# create workdir and link necessary scripts
#-------------------------------------------------------------
#------------------------------------------------
[ -d ${WORKDIR_LAND}/${wdir} ] && rm -rf ${WORKDIR_LAND}/${wdir}
mkdir -p ${WORKDIR_LAND}/${wdir}

cd ${WORKDIR_LAND}/${wdir}
ln -sf ${DIR_LND_IC}/change_values_TPQWL.ncl .
ln -sf ${DIR_LND_IC}/change_values_PREC.ncl .
ln -sf ${DIR_LND_IC}/change_values_SOLR.ncl .
ln -sf ${DIR_LND_IC}/shum_ptd.ncl .

#----------------------------------------------
# rm preexisting ko files
#----------------------------------------------
for var in wind.10m air.2m shum.2m pres.sfc an acc_fc prate.sfc dswrf.sfc
do
   if [ -f check_timestep_${var}${yr}${mo}_ko ]
   then
      rm check_timestep_${var}${yr}${mo}_ko
   fi  
done


nday=31
if [ $m -eq 11 -o $m -eq 4 -o $m -eq 6 -o $m -eq 9 ]
then
   nday=30
elif [ $m -eq 2 ]
then
   nday=28
fi
tstep=`expr $nday \* 8`   #248

#------------------------------------------------
#-------------------------------------------------------------
# Copy and process required files
#-------------------------------------------------------------
#------------------------------------------------       
DIRDATA=$DATA_ECACCESS/EDA/FORC4CLM/3hourly/

#------------------------------------------------
# Get inst data from repository
#------------------------------------------------
if [ ! -f $DIRDATA/eda_forcings_an_${yr}${mo}_n${member}.grib ] ; then
      if [ -f $DIRDATA/eda_forcings_an_${yr}${mo}_n${member}.grib.gz ] ; then
         gunzip $DIRDATA/eda_forcings_an_${yr}${mo}_n${member}.grib.gz 
      else
         body="create_edaFORC.sh: EDA INST FIELDS (file eda_forcings_an_${yr}${mo}_n${member}.grib ) MISSING "
         title="${title_tag} ${CPSSYS} forecast warning"
         echo $body
         ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r $typeofrun -s $yyyy$st
         jobID=`${DIR_UTIL}/findjobs.sh -m $machine -n $jobname -i yes`
         ${DIR_UTIL}/killjobs.sh -m $machine -i "$jobID"
         exit 1
      fi
fi

#------------------------------------------------
# Copy instantaneous vars and separate variables
#------------------------------------------------
cdo -R -f nc copy $DIRDATA/eda_forcings_an_${yr}${mo}_n${member}.grib eda_forcings_an_${yr}${mo}_n${member}.nc
export yr=$yr
export mo=$mo
export var="an"
export file_eda=eda_forcings_an_${yr}${mo}_n${member}.nc
export fileko=check_timestep_${var}${yr}${mo}_n${member}_ko
export wdir_ecmwf=${WORKDIR_LAND}/$wdir/

#TO BE REPLACED !!

ncl ${DIR_LND_IC}/check_timestep_raw_eda.ncl
if [ ! -f  check_timestep_raw.ncl_ok ]
then
   body="create_edaFORC.sh: something went wrong with check_timestep_raw_eda.ncl for EDA AN FIELDS"
   title="${title_tag} ${CPSSYS} forecast error"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r $typeofrun -s $yyyy$st
   jobID=`${DIR_UTIL}/findjobs.sh -m $machine -n $jobname -i yes`
   ${DIR_UTIL}/killjobs.sh -m $machine -i "$jobID"
   exit 1
fi

if [ -f $fileko ]
then
   body="create_edaFORC.sh: EDA AN FIELDS (file eda_forcings_an_${yr}${mo}_n${member}.nc ) has problems in the time axis "
   title="${title_tag} ${CPSSYS} forecast error"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r $typeofrun -s $yyyy$st
   jobID=`${DIR_UTIL}/findjobs.sh -m $machine -n $jobname -i yes`
   ${DIR_UTIL}/killjobs.sh -m $machine -i "$jobID"
   exit 1
fi

ncrename -O -v var167,air -v var134,pres eda_forcings_an_${yr}${mo}_n${member}.nc
cdo selname,air eda_forcings_an_${yr}${mo}_n${member}.nc air.2m.gauss.${yr}${mo}_n${member}.nc
cdo selname,pres eda_forcings_an_${yr}${mo}_n${member}.nc pres.sfc.gauss.${yr}${mo}_n${member}.nc
cdo selname,var165 eda_forcings_an_${yr}${mo}_n${member}.nc uwnd.10m.gauss.${yr}${mo}_n${member}.nc
cdo selname,var166 eda_forcings_an_${yr}${mo}_n${member}.nc vwnd.10m.gauss.${yr}${mo}_n${member}.nc

#------------------------------------------------
# Calculate specific humidity
#------------------------------------------------
# Data-related variables for ncl
export infile1=eda_forcings_an_${yr}${mo}_n${member}.nc
export outfile=shum.2m.gauss.${yr}${mo}_n${member}.nc
# use ncl to create our final file
ncl shum_ptd.ncl

#------------------------------------------------
# set time axis to select needed month
#------------------------------------------------
for var in air.2m shum.2m pres.sfc uwnd.10m vwnd.10m 
do
      cdo settunits,days ${var}.gauss.${yr}${mo}_n${member}.nc ${var}.gauss.${yr}-${mo}_n${member}.nc
      rm ${var}.gauss.${yr}${mo}_n${member}.nc
done

#------------------------------------------------
# Get acc data from repository
#------------------------------------------------
if [ ! -f $DIRDATA/eda_forcings_acc_fc_${yr}${mo}_n${member}.grib ] ; then
      if [ -f $DIRDATA/eda_forcings_acc_fc_${yr}${mo}_n${member}.grib.gz ] ; then
         gunzip $DIRDATA/eda_forcings_acc_fc_${yr}${mo}_n${member}.grib.gz
      else
         body="create_edaFORC.sh: EDA ACC FIELDS (file $DIRDATA/eda_forcings_acc_fc_${yr}${mo}_n${member}.grib ) MISSING "
         title="${title_tag} ${CPSSYS} forecast warning"
         echo $body
         ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r $typeofrun -s $yyyy$st
         jobID=`${DIR_UTIL}/findjobs.sh -m $machine -n $jobname -i yes`
         ${DIR_UTIL}/killjobs.sh -m $machine -i "$jobID"
         exit 1
      fi
fi

#------------------------------------------------
# select needed month and time periods
#------------------------------------------------
#
cdo -R -f nc copy $DIRDATA/eda_forcings_acc_fc_${yr}${mo}_n${member}.grib eda_forcings_acc_fc_${yr}${mo}_n${member}.nc
export yr=$yr
export mo=$mo
export var=acc_fc
export fileko=check_timestep_${var}${yr}${mo}_n${member}_ko
export wdir_ecmwf=${WORKDIR_LAND}/$wdir/
export file_eda=eda_forcings_acc_fc_${yr}${mo}_n${member}.nc
ncl ${DIR_LND_IC}/check_timestep_raw_eda.ncl
if [ ! -f  check_timestep_raw.ncl_ok ]
then
   body="create_edaFORC.sh: something went wrong with check_timestep_raw_eda.ncl for EDA ACC FIELDS"
   title="${title_tag} ${CPSSYS} forecast error"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r $typeofrun -s $yyyy$st
   jobID=`${DIR_UTIL}/findjobs.sh -m $machine -n $jobname -i yes`
   ${DIR_UTIL}/killjobs.sh -m $machine -i "$jobID"
   exit 1
fi

if [ -f $fileko ]
then
   body="create_edaFORC.sh: EDA ACC FIELDS (file eda_forcings_acc_fc_${yr}${mo}_n${member}.nc ) HAS PROBLEMS IN THE TIME AXIS "
   title="${title_tag} ${CPSSYS} forecast error"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r $typeofrun -s $yyyy$st
   jobID=`${DIR_UTIL}/findjobs.sh -m $machine -n $jobname -i yes`
   ${DIR_UTIL}/killjobs.sh -m $machine -i "$jobID"
   exit 1 
fi
#PERFORM HERE NEW ACCUMULATION!!!
#cdo -O -timselsum,6 eda_forcings_acc_fc_${yr}${mo}.nc eda_forcings_acc_fc_${yr}${mo}_6hourly.nc 

#EDA files already accumulated over 3 hour intervals - we have to compute the averages and set the time tag consistently
#accumulated fields give the sum, divide by 10800 to have averages
cdo -O divc,10800 eda_forcings_acc_fc_${yr}${mo}_n${member}.nc eda_forcings_fc_${yr}${mo}_n${member}_mean3h.nc
############################################################
#now treat separately solar_rad and prec
#var228 = prec in meters
cdo -mulc,1000 -selname,var228 eda_forcings_fc_${yr}${mo}_n${member}_mean3h.nc prec.sfc.gauss.${yr}-${mo}_n${member}_tmp.nc
ncrename -O -v var228,prate prec.sfc.gauss.${yr}-${mo}_n${member}_tmp.nc prate.sfc.gauss.${yr}-${mo}_n${member}_tmp.nc
rm prec.sfc.gauss.${yr}-${mo}_n${member}_tmp.nc
##var169 = sol rad
cdo -selname,var169 eda_forcings_fc_${yr}${mo}_n${member}_mean3h.nc solar.sfc.gauss.${yr}-${mo}_n${member}_tmp.nc
ncrename -O -v var169,dswrf solar.sfc.gauss.${yr}-${mo}_n${member}_tmp.nc dswrf.sfc.gauss.${yr}-${mo}_n${member}_tmp.nc
rm solar.sfc.gauss.${yr}-${mo}_n${member}_tmp.nc 

#### fix time axis 

#solar rad -> tag at the beg of the interval  (from 00  1st of the month to 21 last of the month) 
#precip ->  tag in the mid of the interval    (from 1.30 1st of the month to 22.30 last of the month)

##WHAT WE WANT:
#SOLAR RAD: 0.00 is average in the interval 00-03 (accumulation btw 00 and 03 divided by 10800 sec) etc
#PRECIP:    1.30 is average in the interval 00-03 (accumulation btw 00 and 03 divided by 10800 sec) etc

##WHAT WE HAVE:
#from the retrieve these fields are tagged at the end of the accum interval (03 is accumulation  btw 00 and 03 )
#SOLAR  RAD: we need to shiftback the time axis of 180 minutes (3 hours)
#PRECIP: we need to shiftback the time axis of 90 minutes (1.5 hours)

for var in dswrf.sfc prate.sfc
do
  if [ "$var" == "prate.sfc" ] 
  then
      cdo shifttime,-90minutes $var.gauss.${yr}-${mo}_n${member}_tmp.nc $var.gauss.${yr}-${mo}_n${member}.nc
      rm $var.gauss.${yr}-${mo}_n${member}_tmp.nc
  else
      cdo shifttime,-180minutes $var.gauss.${yr}-${mo}_n${member}_tmp.nc $var.gauss.${yr}-${mo}_n${member}.nc
      rm $var.gauss.${yr}-${mo}_n${member}_tmp.nc
  fi

done

for var in air.2m shum.2m pres.sfc uwnd.10m vwnd.10m dswrf.sfc prate.sfc
do
      tstepfile=`cdo -ntime $var.gauss.${yr}-${mo}_n${member}.nc`
      #in nco the timestep goes  from 0 to tstepfile-1
      if [ "$var" == "prate.sfc" ]; then 
         cdo setreftime,${yr}-${mo}-01,00:00 $var.gauss.${yr}-${mo}_n${member}.nc tmp$var.nc
         echo "tstepfile $tstepfile"
         echo "tstep $tstep"
         if [ $tstepfile -lt $tstep ]
         then
             #--> ncks -O -d time,2 means first day of month at 03 (ncks starts from 0)
             echo "$tstepfile -lt $tstep"
             tsel=$(($tstepfile - 3))
             ncks -O -d time,2,$tsel tmp$var.nc tmp2$var.nc
         else
             tsel=$(($tstep + 1)) #tstep +1 (+1: starting from the third one, but counting from 0)
             echo $tsel
             ncks -O -d time,2,$tsel tmp$var.nc tmp2$var.nc
         fi
         cdo settunits,days tmp2$var.nc $var.gauss.${yr}-${mo}_n${member}_tstep.nc

      elif [ "$var" == "dswrf.sfc" ]; then
         if [ $tstepfile -lt $tstep ]
         then
             tsel=$(($tstepfile - 3)) #i want to get rid of the first two and of the last two time steps
             ncks -O -d time,2,$tsel $var.gauss.${yr}-${mo}_n${member}.nc $var.gauss.${yr}-${mo}_n${member}_tstep.nc
         else
             tsel=$(($tstep + 1)) #
             ncks -O -d time,2,$tsel $var.gauss.${yr}-${mo}_n${member}.nc $var.gauss.${yr}-${mo}_n${member}_tstep.nc
         fi

      else  #instantaneous fields
         echo "instantaneous fields"
         echo "tstepfile $tstepfile"
         echo "tstep $tstep"
         if [ $tstepfile -le $tstep ] 
         then
             nt_var=`cdo ntime $var.gauss.${yr}-${mo}_n${member}.nc`

             last_h=`cdo showtime -seltimestep,${nt_var} $var.gauss.${yr}-${mo}_n${member}.nc |cut -d ':' -f1`
             nmb_tstep=$((${last_h}/3))
             #in this way I go back to the last available complete day (comprising the midnight of the following day for the last time interpolation)
             tsel=$(($tstepfile - ${nmb_tstep} - 1)) 
             ncks -O -d time,0,$tsel $var.gauss.${yr}-${mo}_n${member}.nc $var.gauss.${yr}-${mo}_n${member}_tstep.nc
         else  #usually for a 31day month, tstepfile=249 (248+00 of the first of following month)
             tsel=$(($tstep))  #from 0 to $tsel meaning everything
             ncks -O -d time,0,$tsel $var.gauss.${yr}-${mo}_n${member}.nc $var.gauss.${yr}-${mo}_n${member}_tstep.nc
         fi
      fi
      #------------------------------------------------
      # bilinear interpolation to template grid
      #------------------------------------------------
      cdo remapbil,$REPOGRID/targetgrid $var.gauss.${yr}-${mo}_n${member}_tstep.nc $var.${yr}-${mo}_n${member}_grid.nc
      #rm $var.gauss.${yr}-${mo}_n${member}_tstep.nc
      #------------------------------------------------
      # ensure correct longitudes
      #------------------------------------------------
      cdo sellonlatbox,0,360,-90,90 $var.${yr}-${mo}_n${member}_grid.nc $var.${yr}-${mo}_n${member}_map.nc
      rm $var.${yr}-${mo}_n${member}_grid.nc
      cdo invertlat $var.${yr}-${mo}_n${member}_map.nc $var.${yr}-${mo}_n${member}_map_invert.nc
      rm $var.${yr}-${mo}_n${member}_map.nc
done  #end loop over variables
#-----------------------------------------------}
# calculate wind values from its x and y components
#------------------------------------------------
cdo -O merge uwnd.10m.${yr}-${mo}_n${member}_map_invert.nc vwnd.10m.${yr}-${mo}_n${member}_map_invert.nc cruncepv7_wind_${yr}-${mo}_n${member}.nc
rm uwnd.10m.${yr}-${mo}_n${member}_map_invert.nc vwnd.10m.${yr}-${mo}_n${member}_map_invert.nc
cdo expr,'WIND=sqrt(var165*var165+var166*var166);' cruncepv7_wind_${yr}-${mo}_n${member}.nc wind.10m.${yr}-${mo}_n${member}_map_invert.nc
rm cruncepv7_wind_${yr}-${mo}_n${member}.nc

#------------------------------------------------
#-------------------------------------------------------------
# Create final files from templates
#-------------------------------------------------------------
#------------------------------------------------

for var in wind.10m air.2m shum.2m pres.sfc dswrf.sfc
do

      if [ "$var" == "dswrf.sfc" ]
      then
         cdo setreftime,${yr}-${mo}-01,00:00 $var.${yr}-${mo}_n${member}_map_invert.nc $var.${yr}-${mo}_n${member}_map_invert.tmp.nc
         cdo settunits,days $var.${yr}-${mo}_n${member}_map_invert.tmp.nc $var.${yr}-${mo}_n${member}_final.nc
      else

         #temperature,wind etc are analysis i.e. instantenous values at 00,03,06,12 etc    
         #we need to interpolate in time to select the request timing
         cdo intntime,2 $var.${yr}-${mo}_n${member}_map_invert.nc $var.${yr}-${mo}_n${member}_1.5hours.nc
         #rm $var.${yr}-${mo}_n${member}_map_invert.nc
         endtstep=`cdo -ntime $var.${yr}-${mo}_n${member}_1.5hours.nc`

         #now the time steps are 00,01.30,03,04,30,06,07.30,09..etc: we  need to start from the second one
         cdo seltimestep,2/$endtstep/2 $var.${yr}-${mo}_n${member}_1.5hours.nc $var.${yr}-${mo}_n${member}_final.nc
         cdo setreftime,${yr}-${mo}-01,00:00 $var.${yr}-${mo}_n${member}_final.nc $var.${yr}-${mo}_n${member}_final.tmp.nc
         cdo settunits,days $var.${yr}-${mo}_n${member}_final.tmp.nc $var.${yr}-${mo}_n${member}_final.nc
         rm $var.${yr}-${mo}_n${member}_final.tmp.nc
     fi



done

wfile=wind.10m.${yr}-${mo}_n${member}_final.nc
tfile=air.2m.${yr}-${mo}_n${member}_final.nc
qfile=shum.2m.${yr}-${mo}_n${member}_final.nc
pfile=pres.sfc.${yr}-${mo}_n${member}_final.nc
for var in wind.10m air.2m shum.2m pres.sfc 
do
   export wdir2check=$WORKDIR_LAND/$wdir/
   export yr=$yr
   export mo=$mo
   export var=$var
   export file2check=${var}.${yr}-${mo}_n${member}_final.nc
   export fileko=check_timestep_${var}${yr}${mo}_ko
   ncl $DIR_LND_IC/check_timestep.ncl

   if [ ! -f  check_timestep.ncl_ok ]
   then
      body="create_edaFORC.sh: something went wrong with check_timestep.ncl for EDA variable $var"
      echo $body
      title="${title_tag} ${CPSSYS} forecast error"
      ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r $typeofrun -s $yyyy$st
      jobID=`${DIR_UTIL}/findjobs.sh -m $machine -n $jobname -i yes`
      ${DIR_UTIL}/killjobs.sh -m $machine -i "$jobID"
      exit 1
   fi

   if [ -f $fileko ]
   then
      body="create_edaFORC.sh: $var.${yr}-${mo}_final.nc file has problems in the time axis"
      title="${title_tag} ${CPSSYS} forecast ERROR"
      echo $body
      ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r $typeofrun -s $yyyy$st
      jobID=`${DIR_UTIL}/findjobs.sh -m $machine -n $jobname -i yes`
      ${DIR_UTIL}/killjobs.sh -m $machine -i "$jobID"
      exit 1
   fi
done
#before manipulating the file check that the timeseries is correct and 
#complete until now 
#------------------------------------------------
# Your data possibly do not cover entirely the previous month. If so will perform an analysis stopped to the last available forcing day
#------------------------------------------------
do_complete_clm=1
do_incomplete_clm=0
lastdayw=`$DIR_LND_IC/last_forcing_day.sh $wfile $nday $yr $mo $freq_forcings`
#lastdayw=`prinf '%.2d' $lastdayw`
lastdayt=`$DIR_LND_IC/last_forcing_day.sh $tfile $nday $yr $mo $freq_forcings`
#lastdayt=`prinf '%.2d' $lastdayt`
min1=$(( lastdayw < lastdayt ? lastdayw : lastdayt ))
lastdayq=`$DIR_LND_IC/last_forcing_day.sh $qfile $nday $yr $mo $freq_forcings`
#lastdayq=`prinf '%.2d' $lastdayq`
lastdayp=`$DIR_LND_IC/last_forcing_day.sh $pfile $nday $yr $mo $freq_forcings`
#lastdayp=`prinf '%.2d' $lastdayp`
min2=$(( lastdayq < lastdayp ? lastdayq : lastdayp ))
lastday=$(( min1 < min2 ? min1 : min2 ))
export pfile=${pfile}
export tfile=${tfile}
export qfile=${qfile}
export wfile=${wfile}
export data="days since ${yr}-${mo}-01 00:00:00"
export outfile=temp.${yr}-${mo}_n${member}.nc

#------------------------------------------------
# copy the reference file !!!! TO BE UPDATED
#------------------------------------------------
export templateTPQWL=$REPOSITORY/templates4CLM/TPHWL/clmforc.GSWP3.c2011.0.5x0.5.TPQWL.1901-${mo}.nc
export templatePREC=$REPOSITORY/templates4CLM/Precip/clmforc.GSWP3.c2011.0.5x0.5.Prec.1901-${mo}.nc
export templateSOLR=$REPOSITORY/templates4CLM/Solar/clmforc.GSWP3.c2011.0.5x0.5.Solr.1901-${mo}.nc
#------------------------------------------------
# Create TPQWL file
#------------------------------------------------
# use ncl to create our final file
export checkfile_TP=change_values_TPQWL_${yr}-${mo}_n${member}_done

ncl change_values_TPQWL.ncl 
# check that everything went OK OR send mail
if [ ! -f $checkfile_TP ]
then
     body="create_edaFORC.sh: Something went wrong with EDA change_values_TPQWL.ncl in $WORKDIR_LAND " 
     echo $body
     title="${title_tag} ${CPSSYS} forecast warning"
     ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r $typeofrun -s $yyyy$st
     jobID=`${DIR_UTIL}/findjobs.sh -m $machine -n $jobname -i yes`
     ${DIR_UTIL}/killjobs.sh -m $machine -i "$jobID"
     exit 1
fi
# move to final dir and clean temporary files
cdo -f nc2 copy $outfile tempzip.${yr}-${mo}_n${member}.nc
#in preffix member tag already included
ncatted -a calendar,time,m,c,"noleap" tempzip.${yr}-${mo}_n${member}.nc ${preffix}.TPQWL.${yr}-${mo}.nc

######  
######

#------------------------------------------------
# Create PREC file
#------------------------------------------------
# select the required variable in our file and in the reference one, use persistence
var=prate.sfc
precfile=$var.${yr}-${mo}_n${member}_map_invert.nc
ln -sf $precfile $var.${yr}-${mo}_n${member}_final.nc
export yr=$yr
export mo=$mo
export var=prate.sfc
export file2check=$var.${yr}-${mo}_n${member}_final.nc
export wdir2check=${WORKDIR_LAND}/$wdir/
export fileko=check_timestep_${var}${yr}${mo}_n${member}_ko
ncl $DIR_LND_IC/check_timestep.ncl

if [ ! -f  check_timestep.ncl_ok ]
then
  body="create_edaFORC.sh: something went wrong with check_timestep.ncl for EDA variable $var"
  title="${title_tag} ${CPSSYS} forecast error"
  ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r $typeofrun -s $yyyy$st
  jobID=`${DIR_UTIL}/findjobs.sh -m $machine -n $jobname -i yes`
  ${DIR_UTIL}/killjobs.sh -m $machine -i "$jobID"
  exit 1
fi

if [ -f $fileko ]
then
   body="create_edaFORC.sh: $var.${yr}-${mo}_n${member}_final.nc has problems in the time axis"
   title="${title_tag} ${CPSSYS} forecast ERROR"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r $typeofrun -s $yyyy$st
   jobID=`${DIR_UTIL}/findjobs.sh -m $machine -n $jobname -i yes`
   ${DIR_UTIL}/killjobs.sh -m $machine -i "$jobID"
   exit 1
fi

lastdayprec=`${DIR_LND_IC}/last_forcing_day.sh $precfile $nday $yr $mo $freq_forcings`
#lastdayprec=`prinf '%.2d' $lastdayprec`
min=$(( lastday < lastdayprec ? lastday : lastdayprec ))
lastday=$min
export precfile=${precfile}
export outfile=prec.${yr}-${mo}.nc
export checkfile_PR=change_values_PREC_${yr}-${mo}_n${member}_done
# use ncl to create our final file
ncl change_values_PREC.ncl 
# check that everything went OK OR send mail
if [ ! -f $checkfile_PR ]
then
     body="create_edaFORC.sh: Something went wrong with EDA change_values_PREC.ncl in $WORKDIR_LAND"
     title="${title_tag} ${CPSSYS} forecast warning"
     ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r $typeofrun -s $yyyy$st
     exit 1
fi
# move to final dir and clean temporary files
cdo -f nc2 copy $outfile preczip.${yr}-${mo}_n${member}.nc
ncatted -a calendar,time,m,c,"noleap" preczip.${yr}-${mo}_n${member}.nc ${preffix}.Prec.$yr-$mo.nc




#------------------------------------------------
# Create SOLR file
#------------------------------------------------
# select the required variable in our file and in the reference one, use persistence
sfile=dswrf.sfc.${yr}-${mo}_n${member}_final.nc
export yr=$yr
export mo=$mo
export var=dswrf.sfc
export fileko=check_timestep_${var}${yr}${mo}_n${member}_ko
export wdir2check=$WORKDIR_LAND/$wdir/
export file2check=$sfile
ncl $DIR_LND_IC/check_timestep.ncl

if [ ! -f  check_timestep.ncl_ok ]
then
  body="create_edaFORC.sh: something went wrong with check_timestep.ncl for EDA variable $var"
  title="${title_tag} ${CPSSYS} forecast error"
  ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r $typeofrun -s $yyyy$st
  jobID=`${DIR_UTIL}/findjobs.sh -m $machine -n $jobname -i yes`
  ${DIR_UTIL}/killjobs.sh -m $machine -i "$jobID"
  exit 1
fi

if [ -f $fileko ]
then
   body="create_edaFORC.sh: $var.${yr}-${mo}_n${member}_final.nc has problems in the time axis"
   title="${title_tag} ${CPSSYS} forecast ERROR"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r $typeofrun -s $yyyy$st
   jobID=`${DIR_UTIL}/findjobs.sh -m $machine -n $jobname -i yes`
   ${DIR_UTIL}/killjobs.sh -m $machine -i "$jobID"
   exit 1
fi

lastdays=`${DIR_LND_IC}/last_forcing_day.sh $sfile $nday $yr $mo $freq_forcings`
#lastdays=`prinf '%.2d' $lastdays`
min=$(( lastday < lastdays ? lastday : lastdays ))
lastday=$min
export sfile=${sfile}
export outfile=sol.${yr}-${mo}_n${member}.nc
export checkfile_SR=change_values_SOLR_${yr}-${mo}_n${member}_done
# use ncl to create our final file
ncl change_values_SOLR.ncl
# check that everything went OK OR send mail
if [ ! -f $checkfile_SR ]
then
     body="create_edaFORC.sh: Something went wrong with ERA5 change_values_SOLR.ncl in $WORKDIR_LAND "
     title="${title_tag} ${CPSSYS} forecast warning"
     ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r $typeofrun -s $yyyy$st
     exit 1
fi
# move to final dir and clean temporary files
cdo -f nc2 copy $outfile solzip.${yr}-${mo}_n${member}.nc
ncatted -a calendar,time,m,c,"noleap" solzip.${yr}-${mo}_n${member}.nc ${preffix}.Solr.$yr-$mo.nc


if [[ $lastday -ne 999 ]] 
then
    if [[ "$typeofrun" == "hindcast" ]]
    then
       echo ""
       echo "**********************************************************"
       echo "we should not be here!!! EXIT"
       echo "**********************************************************"
       exit 1
    fi  
    echo ""
    echo "**********************************************************"
    echo "The forcing timeseries do not cover the entire month $mo: going to do miniforecast"
    echo "**********************************************************"
    echo ""
    do_incomplete_clm=1
    do_complete_clm=0
fi

if [[ $do_complete_clm -eq 1 && "$typeofrun" != "hindcast" ]]
then
   cd ${WORKDIR_LAND}/${wdir}
   #here we want to copy the last day of the actual month to the first day of the following month 
   #(to ensure persistency for clm interpolation)
   #we want to keep the file template, without recallin the ncl scripts
   
   #step 1. select the last day (i.e. last four time step) of the actual month
   numbstep=`cdo -ntime ${preffix}.TPQWL.$yr-$mo.nc`
   laststep=$(($numbstep -1))
   lastdaystep=$(($numbstep -8))
   ncks -d time,$lastdaystep,$laststep ${preffix}.TPQWL.$yr-$mo.nc ${preffix}.TPQWL.$yr-$mo.last_day.nc
   cdo shifttime,+24hours ${preffix}.TPQWL.$yr-$mo.last_day.nc ${preffix}.TPQWL.$yr-$mo.last_day.tmp.nc
   cdo setreftime,$yyyy-$st-01 ${preffix}.TPQWL.$yr-$mo.last_day.tmp.nc ${preffix}.TPQWL.$yr-$mo.last_day.nc
   rm ${preffix}.TPQWL.$yr-$mo.last_day.tmp.nc
   
   #step 2. copy the template file for the following month from $forcDIR/
   #(it has been renamend as $namefile.nc in the launch script)
   nccopy -k 2 $forcDIR/TPHWL/${preffix}.TPQWL.${yyyy}-$st.nc ${preffix}.TPQWL.${yyyy}-$st.nc
   
   #TPQWL should be at 03,09,15,21 but in template (sometimes!) it is at 00,06,12,18
   tstep_st=`cdo -showtime -seltimestep,1 ${preffix}.TPQWL.${yyyy}-$st.nc`
   tstep_check=`echo $tstep_st|cut -d '_' -f 2|cut -c 1-2`
   if [ $tstep_check -eq '00' ] ; then
     cdo shifttime,+3hours ${preffix}.TPQWL.${yyyy}-$st.nc ${preffix}.TPQWL.${yyyy}-$st.tmp2.nc
     mv ${preffix}.TPQWL.${yyyy}-$st.tmp2.nc ${preffix}.TPQWL.${yyyy}-$st.nc
   fi
   
   #step 3. select the first day and the rest of the month
   numbstep=`cdo -ntime ${preffix}.TPQWL.${yyyy}-$st.nc`
   laststep=$(($numbstep -1))
   ncks -d time,8,$laststep ${preffix}.TPQWL.${yyyy}-$st.nc ${preffix}.TPQWL.${yyyy}-$st.nofirst.nc
   ncks -d time,0,7 ${preffix}.TPQWL.${yyyy}-$st.nc ${preffix}.TPQWL.${yyyy}-$st.first.nc
   
   #step 4. ONLY the values of the field(s) are substitute: 
   #from the last_day (month m) to the first day (month m+1) 
   #ncks options keep the attributes and the dimensions of month m+1 file: 
   #-M (NOT copy global attributes) -m (NOT copy varialbe attributes) -C (NOT copy dimensions)
   ncks -M -m -C -A -v TBOT,QBOT,WIND,PSRF ${preffix}.TPQWL.$yr-$mo.last_day.nc ${preffix}.TPQWL.${yyyy}-$st.first.nc
   ncks -O --mk_rec_dmn time ${preffix}.TPQWL.${yyyy}-$st.first.nc ${preffix}.TPQWL.${yyyy}-$st.first.nc
   ncks -O --mk_rec_dmn time ${preffix}.TPQWL.${yyyy}-$st.nofirst.nc ${preffix}.TPQWL.${yyyy}-$st.nofirst.nc
   
   #append the new first day of month m+1 to the rest of the month
   ncrcat ${preffix}.TPQWL.${yyyy}-$st.first.nc ${preffix}.TPQWL.${yyyy}-$st.nofirst.nc ${preffix}.TPQWL.${yyyy}-$st.nozip.nc
   cdo -f nc2 copy ${preffix}.TPQWL.${yyyy}-$st.nozip.nc ${preffix}.TPQWL.${yyyy}-$st.nc
   
   rm ${preffix}.TPQWL.${yyyy}-$st.nozip.nc
   rm ${preffix}.TPQWL.${yyyy}-$st.first.nc
   rm ${preffix}.TPQWL.${yyyy}-$st.nofirst.nc
   rm ${preffix}.TPQWL.$yr-$mo.last_day.nc
   
   #step 1. select the last day (i.e. last four time step) of the actual month
   numbstep=`cdo -ntime ${preffix}.Prec.$yr-$mo.nc`
   laststep=$(($numbstep -1))
   lastdaystep=$(($numbstep -8))
   ncks -d time,$lastdaystep,$laststep ${preffix}.Prec.$yr-$mo.nc ${preffix}.Prec.$yr-$mo.last_day.nc
   cdo shifttime,+24hours ${preffix}.Prec.$yr-$mo.last_day.nc ${preffix}.Prec.$yr-$mo.last_day.tmp.nc
   cdo setreftime,$yyyy-$st-01 ${preffix}.Prec.$yr-$mo.last_day.tmp.nc ${preffix}.Prec.$yr-$mo.last_day.nc
   rm ${preffix}.Prec.$yr-$mo.last_day.tmp.nc
   
   #step 2. copy the template file for the following month from $forcDIR/
   #(it has been renamend as $namefile.nc in the launch script)
   nccopy -k 2 $forcDIR/Precip/${preffix}.Prec.${yyyy}-$st.nc ${preffix}.Prec.${yyyy}-$st.nc
   
   #prec should be at 03,09,15,21 but in template (sometimes!) it is at 00,06,12,18
   tstep_st=`cdo -showtime -seltimestep,1 ${preffix}.Prec.${yyyy}-$st.nc`
   tstep_check=`echo $tstep_st|cut -d '_' -f 2|cut -c 1-2`
   if [ $tstep_check -eq '00' ] ; then
     cdo shifttime,+3hours ${preffix}.Prec.${yyyy}-$st.nc ${preffix}.Prec.${yyyy}-$st.tmp2.nc
     mv ${preffix}.Prec.${yyyy}-$st.tmp2.nc ${preffix}.Prec.${yyyy}-$st.nc
   fi
   
   #step 3. select the first day and the rest of the month
   numbstep=`cdo -ntime ${preffix}.Prec.${yyyy}-$st.nc`
   laststep=$(($numbstep -1))
   ncks -d time,8,$laststep ${preffix}.Prec.${yyyy}-$st.nc ${preffix}.Prec.${yyyy}-$st.nofirst.nc
   ncks -d time,0,7 ${preffix}.Prec.${yyyy}-$st.nc ${preffix}.Prec.${yyyy}-$st.first.nc
   
   #step 4. ONLY the values of the field(s) are substitute: 
   #from the last_day (month m) to the first day (month m+1) 
   #ncks options keep the attributes and the dimensions of month m+1 file: 
   #-M (NOT copy global attributes) -m (NOT copy varialbe attributes) -C (NOT copy dimensions)
   ncks -M -m -C -A -v PRECTmms ${preffix}.Prec.$yr-$mo.last_day.nc ${preffix}.Prec.${yyyy}-$st.first.nc
   
   ncks -O --mk_rec_dmn time ${preffix}.Prec.${yyyy}-$st.first.nc ${preffix}.Prec.${yyyy}-$st.first.nc
   ncks -O --mk_rec_dmn time ${preffix}.Prec.${yyyy}-$st.nofirst.nc ${preffix}.Prec.${yyyy}-$st.nofirst.nc
   #append the new first day of month m+1 to the rest of the month
   ncrcat ${preffix}.Prec.${yyyy}-$st.first.nc ${preffix}.Prec.${yyyy}-$st.nofirst.nc ${preffix}.Prec.${yyyy}-$st.nozip.nc
   cdo -f nc2 copy ${preffix}.Prec.${yyyy}-$st.nozip.nc ${preffix}.Prec.${yyyy}-$st.nc
   
   rm ${preffix}.Prec.${yyyy}-$st.nozip.nc
   rm ${preffix}.Prec.${yyyy}-$st.first.nc
   rm ${preffix}.Prec.${yyyy}-$st.nofirst.nc
   rm ${preffix}.Prec.$yr-$mo.last_day.nc
   ######
   #step 1. select the last day (i.e. last four time step) of the actual month
   numbstep=`cdo -ntime ${preffix}.Solr.$yr-$mo.nc`
   laststep=$(($numbstep -1))
   lastdaystep=$(($numbstep -8))
   ncks -d time,$lastdaystep,$laststep ${preffix}.Solr.$yr-$mo.nc ${preffix}.Solr.$yr-$mo.last_day.nc
   cdo shifttime,+24hours ${preffix}.Solr.$yr-$mo.last_day.nc ${preffix}.Solr.$yr-$mo.last_day.tmp.nc
   cdo setreftime,$yyyy-$st-01 ${preffix}.Solr.$yr-$mo.last_day.tmp.nc ${preffix}.Solr.$yr-$mo.last_day.nc
   rm ${preffix}.Solr.$yr-$mo.last_day.tmp.nc
   
   #step 2. copy the template file for the following month from $forcDIR/
   #(it has been renamend as $namefile.nc in the launch script)
   nccopy -k 2 $forcDIR/Solar/${preffix}.Solr.${yyyy}-$st.nc ${preffix}.Solr.${yyyy}-$st.nc
   
   #step 3. select the first day and the rest of the month
   numbstep=`cdo -ntime ${preffix}.Solr.${yyyy}-$st.nc`
   laststep=$(($numbstep -1))
   ncks -d time,8,$laststep ${preffix}.Solr.${yyyy}-$st.nc ${preffix}.Solr.${yyyy}-$st.nofirst.nc
   ncks -d time,0,7 ${preffix}.Solr.${yyyy}-$st.nc ${preffix}.Solr.${yyyy}-$st.first.nc
   
   #step 4. ONLY the values of the field(s) are substitute: 
   #from the last_day (month m) to the first day (month m+1) 
   #ncks options keep the attributes and the dimensions of month m+1 file: 
   #-M (NOT copy global attributes) -m (NOT copy varialbe attributes) -C (NOT copy dimensions)
   ncks -M -m -C -A -v FSDS ${preffix}.Solr.$yr-$mo.last_day.nc ${preffix}.Solr.${yyyy}-$st.first.nc
   #append the new first day of month m+1 to the rest of the month
   ncks -O --mk_rec_dmn time ${preffix}.Solr.${yyyy}-$st.first.nc ${preffix}.Solr.${yyyy}-$st.first.nc
   ncks -O --mk_rec_dmn time ${preffix}.Solr.${yyyy}-$st.nofirst.nc ${preffix}.Solr.${yyyy}-$st.nofirst.nc
   ncrcat ${preffix}.Solr.${yyyy}-$st.first.nc ${preffix}.Solr.${yyyy}-$st.nofirst.nc ${preffix}.Solr.${yyyy}-$st.nozip.nc
   cdo -f nc2 copy ${preffix}.Solr.${yyyy}-$st.nozip.nc ${preffix}.Solr.${yyyy}-$st.nc
   
   rm ${preffix}.Solr.${yyyy}-$st.nozip.nc
   rm ${preffix}.Solr.${yyyy}-$st.first.nc
   rm ${preffix}.Solr.${yyyy}-$st.nofirst.nc
   rm ${preffix}.Solr.$yr-$mo.last_day.nc
   mv ${preffix}.Prec.${yyyy}-$st.nc $forcDIR/Precip/
   mv ${preffix}.Solr.${yyyy}-$st.nc $forcDIR/Solar/
   mv ${preffix}.TPQWL.${yyyy}-$st.nc $forcDIR/TPHWL/

fi

######
mv ${preffix}.Prec.$yr-$mo.nc $forcDIR/Precip/
mv ${preffix}.Solr.$yr-$mo.nc  $forcDIR/Solar/
mv ${preffix}.TPQWL.$yr-$mo.nc $forcDIR/TPHWL/

chmod a+x $forcDIR/Precip/${preffix}.Prec.$yr-$mo.nc
chmod a+x $forcDIR/Solar/${preffix}.Solr.$yr-$mo.nc
chmod a+x $forcDIR/TPHWL/${preffix}.TPQWL.$yr-$mo.nc
touch $checkfile
