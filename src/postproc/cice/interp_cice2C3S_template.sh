#!/bin/sh -l
. $HOME/.bashrc
# load variables from descriptor
. $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/load_ncl
. $DIR_UTIL/load_nco


export ic=ICs
export outdirC3S=OUTDIRC3S
INPUT=${DIR_ARCHIVE}/CASO/ice/hist
wkdir=${SCRATCHDIR}/CPS/CMCC-CPS1/regrid_cice/
mkdir -p $wkdir


set -exv
member=`echo CASO|cut -d '_' -f3|cut -c 2,3`
export real="r"${member}"i00p00"
export st=`echo CASO|cut -d '_' -f 2|cut -c 5-6`
export yyyy=`echo CASO|cut -d '_' -f 2|cut -c 1-4`
caso=CASO #needed for dictionary 
set +evxu
. $DIR_UTIL/descr_ensemble.sh $yyyy
. $dictionary
set -evxu

export check_iceregrid
#NEW 202103  +
if [ -f $check_iceregrid ] 
then
# se il checkfile e' piu' vecchio del DMO rimuovi e rifai
   cd $INPUT
   for file in CASO*cice.h.*nc
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
   export inputfile=$wkdir/CASO.cice.nc 
   if [ ! -f $inputfile ] 
   then
      inputlist=" "
      for mon in `seq 0 $(($nmonfore - 1))`
      do
         curryear=`date -d "$yyyy${st}15 + $mon month" +%Y`
         currmon=`date -d "$yyyy${st}15 + $mon month" +%m`
         inputlist+=" CASO.cice.h.${curryear}-${currmon}.zip.nc"
      done
   #echo "inizio ncrcat " `date`
      ncrcat -O $inputlist $inputfile
   #echo 'fine ncrcat ' `date`
   fi
   scriptname=interp_cice2C3S_through_nemo.ncl
   
   #this one will be compressed via ncks at the end
   prefix=`sed -n 4p $DIR_TEMPL/C3S_globalatt.txt |cut -d '=' -f2|cut -d ':' -f1|awk '{$1=$1};1'`
   export fore_type=$typeofrun
   export frq="mon"
   export level="ocean2d"
   
   export ini_term="cmcc_${prefix}_${typeofrun}_S${yyyy}${st}0100"
   
   export nmonfore=$nmonfore
   
   echo "---------------------------------------------"
   echo "launching $scriptname "`date`
   echo "---------------------------------------------"
   ncl ${DIR_POST}/cice/$scriptname
   echo "---------------------------------------------"
   echo "executed $scriptname "`date`
   echo "---------------------------------------------"

   if [ ! -f $check_iceregrid ]
   then
     title="[C3S] ${CPSSYS} forecast ERROR"
     body="ERROR in standardization of CICE files for case CASO. 
           Script is ${DIR_POST}/cice/$scriptname"
     ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "$typeofrun" -s $yyyy$st -E 0$member
     exit
   else
     rm $inputfile
   fi
fi
exit 0
