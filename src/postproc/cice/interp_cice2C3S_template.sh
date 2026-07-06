#!/bin/sh -l
. $HOME/.bashrc
# load variables from descriptor
. $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/load_ncl
. $DIR_UTIL/load_nco


set -exvu
export ic=ICs
export outdirC3S=OUTDIRC3S
caso=CASO
INPUT=${DIR_ARCHIVE}/${caso}/ice/hist
wkdir=${SCRATCHDIR}/CPS/CMCC-CPS1/regrid_cice/
mkdir -p $wkdir


member=`echo ${caso}|cut -d '_' -f3|cut -c 2,3`
export real="r"${member}"i00p00"
export st=`echo ${caso}|cut -d '_' -f 2|cut -c 5-6`
export yyyy=`echo ${caso}|cut -d '_' -f 2|cut -c 1-4`
set +evxu
. $DIR_UTIL/descr_ensemble.sh $yyyy
. $dictionary
set -evxu

if [[ $caso =~ "ext" ]]; then
#first timestep in 6hr outputs is 181.25 days 4350
# 6hourly  export end_term=_slicetime4350to11712.nc
# --> should become 4440-

# 181.5 -->4356 end=11712
# 12hourly  export end_term=_slicetime4356to11712.nc
# --> should become 4440-

# 182 -->4368 end=11712
# daily  export end_term=_slicetime4368to11712.nc
# --> should become 4440-

# for monthly should be 4716 and end is 11304 
   export end_term=_slicetime4716to11304.nc
   export init=182
   firstm=$nmonfore
   lastm=$(($nmonfore + $nmonforext - 1))
else
   firstm=0
   export init=0
   lastm=$(($nmonfore - 1))
   export end_term=.nc
fi

export check_iceregrid
#NEW 202103  +
if [[ -f $check_iceregrid ]]
then
# se il checkfile e' piu' vecchio del DMO rimuovi e rifai
   cd $INPUT
   for file in ${caso}*cice.h.*nc
   do
      if [[ $file -nt ${check_iceregrid} ]]
      then
         rm $check_iceregrid
         break 
      fi  
   done
else
   export C3S_table_ocean2d="$DIR_POST/nemo/C3S_table_ocean2d_others.txt"
   export lsmfile="$REPOGRID/SPS4_C3S_LSM.nc"
   export meshmaskfile="$CESMDATAROOT/inputdata/ocn/nemo/tn0.25v3/grid/ORCA025L75_mesh_mask.nc"
   export srcGridName="$REPOGRID/ORCA_SCRIP_gridT.nc"
   export dstGridName="$REPOGRID/World1deg_SCRIP_gridT.nc"
   export wgtFile="$REPOGRID/ORCA_2_World_SCRIP_gridT.nc"
   
   export C3Satts="$DIR_TEMPL/C3S_globalatt.txt"
   cd $INPUT
   #TAKES 3'
   export inputfile=$wkdir/${caso}.cice.nc 
   if [[ ! -f $inputfile ]]
   then
      inputlist=" "
      for mon in `seq $firstm $lastm`
      do
         curryear=`date -d "$yyyy${st}15 + $mon month" +%Y`
         currmon=`date -d "$yyyy${st}15 + $mon month" +%m`
         inputlist+=" ${caso}.cice.h.${curryear}-${currmon}.zip.nc"
      done
   #echo "inizio ncrcat " `date`
      ncrcat -O $inputlist $inputfile
   #echo 'fine ncrcat ' `date`
   fi
   scriptname=interp_cice2C3S_through_nemo.ncl
   
   #this one will be compressed via ncks at the end
   prefix=`sed -n 4p $DIR_TEMPL/C3S_globalatt.txt |cut -d '=' -f2|cut -d ':' -f1|awk '{$1=$1};1'`
#ANTO not used; keeped just for sake of safety for forecast 20260331
   export fore_type=$typeofrun
   export frq="mon"
   export level="ocean2d"
   
   export ini_term="cmcc_${prefix}_${typeofrun}_S${yyyy}${st}0100"
   
   echo "---------------------------------------------"
   echo "launching $scriptname "`date`
   echo "---------------------------------------------"
   ncl ${DIR_POST}/cice/$scriptname
   echo "---------------------------------------------"
   echo "executed $scriptname "`date`
   echo "---------------------------------------------"

   if [[ ! -f $check_iceregrid ]]
   then
     title="[C3S] ${CPSSYS} forecast ERROR"
     body="ERROR in standardization of CICE files for case ${caso}. 
           Script is ${DIR_POST}/cice/$scriptname"
     ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "$typeofrun" -s $yyyy$st -E 0$member
     exit
   else
     rm $inputfile
   fi
fi
exit 0
