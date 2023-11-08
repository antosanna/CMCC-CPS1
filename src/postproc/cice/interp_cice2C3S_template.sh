#!/bin/sh -l
. $HOME/.bashrc
# load variables from descriptor
. $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/load_ncl


export ic=`cat $DIR_CASES/CASO/logs/ic_CASO.txt`
export outdirC3S=OUTDIRC3S
INPUT=${DIR_ARCHIVE}/CASO/ice/hist

export checkfile=$1
running=$2   # 0 if running; 1 if off-line

set -exv
ens=`echo CASO|cut -d '_' -f3|cut -c 2,3`
export real="r"${ens}"i00p00"
export st=`echo CASO|cut -d '_' -f 2|cut -c 5-6`
export yyyy=`echo CASO|cut -d '_' -f 2|cut -c 1-4`
set +evxu
$DIR_UTIL/descr_ensemble.sh $yyyy
set -evxu

#NEW 202103  +
if [ -f $checkfile ] 
then
# se il checkfile e' piu' vecchio del DMO rimuovi e rifai
   cd $INPUT
   for file in CASO*cice.h.*nc
   do
      if [[ $file -nt ${checkfile} ]]
      then
         rm $checkfile
         break 
      fi  
   done
else
   export C3S_table_ocean2d="$DIR_POST/nemo/C3S_table_ocean2d.txt"
   export lsmfile="$REPOGRID/SPS4_C3S_LSM.nc"
   export meshmaskfile="$CESMDATAROOT/inputdata/ocn/nemo/tn0.25v3/grid/ORCA025L75_mesh_mask.nc"
   export srcGridName="$REPOGRID/ORCA_SCRIP_gridT.nc"
   export dstGridName="$REPOGRID/World1deg_SCRIP_gridT.nc"
   export wgtFile="$REPOGRID/ORCA_2_World_SCRIP_gridT.nc"
   
   export C3Satts="$DIR_TEMPL/C3S_globalatt.txt"
   export yyyytoday=`date +%Y`
   export mmtoday=`date +%m`
   export ddtoday=`date +%d`
   export Htoday=`date +%H`
   export Mtoday=`date +%M`
   export Stoday=`date +%S`
   cd $INPUT
   #TAKES 3'
   input=CASO.cice.nc 
   if [ ! -f $input ] 
   then
      inputlist=`ls CASO*cice.h.*nc`
   #echo "inizio ncrcat " `date`
      ncrcat -O $inputlist $input
   #echo 'fine ncrcat ' `date`
   fi
   scriptname=interp_cice2C3S_through_nemo.ncl
   
   #this one will be compressed via ncks at the end
   prefix=`sed -n 4p $DIR_TEMPL/C3S_globalatt.txt |cut -d '=' -f2|cut -d ':' -f1|awk '{$1=$1};1'`
   export fore_type=$typeofrun
   export frq="mon"
   export level="ocean2d"
   
   export ini_term="cmcc_${prefix}_${typeofrun}_S${yyyy}${st}0100"
   
   export inputfile=$INPUT/$input
   export nmonfore=$nmonfore
   
   echo "---------------------------------------------"
   echo "launching $scriptname "`date`
   echo "---------------------------------------------"
   ncl ${DIR_POST}/cice/$scriptname
   echo "---------------------------------------------"
   echo "executed $scriptname "`date`
   echo "---------------------------------------------"

   if [ ! -f $checkfile ]
   then
     title="[C3S] ${CPSSYS} forecast ERROR"
     body="ERROR in standardization of CICE files for case CASO. 
           Script is ${DIR_POST}/cice/$scriptname"
     ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
     exit
   else
     rm $inputfile
   fi
fi
if [ $running -eq 1 ]  # 0 if running; 1 if off-line
then
     rm $INPUT/CASO.cice.*
fi  
exit 0
