#!/bin/sh -l
#BSUB -P 0490
#BSUB -M 1000
#BSUB -J check_EDA_CLM
#BSUB -e /work/cmcc/cp1//CPS/CMCC-CPS1/logs/forecast/check_ICs/check_EDA_CLM_%J.err
#BSUB -o /work/cmcc/cp1//CPS/CMCC-CPS1/logs/forecast/check_ICs/check_EDA_CLM_%J.out
#-------------------------------------------------------------------------------
#------------------------------------------------
set +euxv     
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. ${DIR_UTIL}/load_cdo
. ${DIR_UTIL}/load_ncl
set -euxv


#-----------------------------------
# INPUT SECTION
#-----------------------------------
yyyy=`date +%Y`
st=`date +%m`
stdate=$yyyy$st
yr=`date -d ' '$yyyy${st}15' - 1 month' +%Y`
mo=`date -d ' '$yyyy${st}15' - 1 month' +%m`

#------------------------------------------------

#------------------------------------------------
#-------------------------------------------------------------
# Copy and process required files
#-------------------------------------------------------------
#------------------------------------------------       
DIRDATA=$DATA_ECACCESS/EDA/FORC4CLM/3hourly/


#------------------------------------------------
# Copy instantaneous vars and separate variables
#------------------------------------------------
if [[ -d $SCRATCHDIR/check_EDA_CLM ]]
then
   rm -rf $SCRATCHDIR/check_EDA_CLM
fi
mkdir -p $SCRATCHDIR/check_EDA_CLM
cd $SCRATCHDIR/check_EDA_CLM
export wdir_ecmwf=$SCRATCHDIR/check_EDA_CLM/
export yr=$yr
export mo=$mo
title_tag="[CLMIC]"
for member in 1 2 3
do
   for ftype in an acc_fc
   do
#------------------------------------------------
# Get inst data from repository
#------------------------------------------------
      if [ ! -f $DIRDATA/eda_forcings_${ftype}_${yr}${mo}_n${member}.grib ] ; then
         if [ -f $DIRDATA/eda_forcings_${ftype}_${yr}${mo}_n${member}.grib.gz ] ; then
            gunzip $DIRDATA/eda_forcings_${ftype}_${yr}${mo}_n${member}.grib.gz 
         else
            body="create_edaFORC.sh: EDA INST FIELDS (file eda_forcings_${ftype}_${yr}${mo}_n${member}.grib ) MISSING "
            title="${title_tag} ${CPSSYS} forecast warning"
            echo $body
            ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r $typeofrun -s $yyyy$st
         fi
      fi
      cdo -R -f nc copy $DIRDATA/eda_forcings_${ftype}_${yr}${mo}_n${member}.grib $SCRATCHDIR/check_EDA_CLM/eda_forcings_${ftype}_${yr}${mo}_n${member}.nc
      export file_eda=eda_forcings_${ftype}_${yr}${mo}_n${member}.nc
      export fileko=check_timestep_${ftype}${yr}${mo}_n${member}_ko

      export var=$ftype
      ncl ${DIR_LND_IC}/check_timestep_raw_eda.ncl
      if [[ ! -f  check_timestep_raw.ncl_ok ]]
      then
         if [[ -f $fileko ]]
         then
            body="$DIR_LND_IC/check_timestep_raw_eda.ncl: EDA AN FIELDS (file eda_forcings_${ftype}_${yr}${mo}_n${member}.nc ) has problems in the time axis "
            echo "ERROR IN EDA CLM RAWDATA: $body" >>$DIR_REP/$stdate/check_IC_${stdate}.txt
            title="${title_tag} ${CPSSYS} forecast error"
            ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r $typeofrun -s $yyyy$st
            exit 1
         fi
      else
         echo "----- $ftype raw data for perturbation $member CLM ok" >>$DIR_REP/$stdate/check_IC_${stdate}.txt
         rm check_timestep_raw.ncl_ok
      fi
   done
done
