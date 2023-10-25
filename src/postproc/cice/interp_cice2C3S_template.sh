#!/bin/sh -l
. $HOME/.bashrc
# load variables from descriptor
. $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/load_ncl

#NEW 202103: inserimento di un if su checkfile per cui l'interpolazione viene fatta solo se non esiste

caso=$1
export ic="$2"
export outdirC3S=$3
INPUT=$4
running=$5 # 0 if running; 1 if off-line

set -exv
ens=`echo $caso|cut -d '_' -f3|cut -c 2,3`
export real="r"${ens}"i00p00"
export st=`echo $caso|cut -d '_' -f 2|cut -c 5-6`
export yyyy=`echo $caso|cut -d '_' -f 2|cut -c 1-4`
set +evxu
if [ $yyyy -ge ${iniy_fore} ]
then
   . $DIR_SPS35/descr_forecast.sh
else
   . $DIR_SPS35/descr_hindcast.sh
fi
set -evxu

export checkfile=$outdirC3S/interp_cice2C3S_through_nemo.ncl_${real}_ok
#NEW 202103  +
if [ -f $checkfile ] 
then
# se il checkfile e' piu' vecchio del DMO rimuovi e rifai
   cd $INPUT
   for file in ${caso}*cice.h.*nc
   do
      if [[ $file -nt ${checkfile} ]]
      then
         rm $checkfile
         break 
      fi  
   done
fi
#NEW 202103  -
if [ ! -f $checkfile ]
then
   export C3S_table_ocean2d="$DIR_POST/nemo/C3S_table_ocean2d.txt"
   export lsmfile="$REPOGRID/lsm_${SPSsystem}_cam_h1_reg1x1_0.5_359.5.nc"
   export meshmaskfile="$REPOSITORY/mesh_mask_from2000.nc"
   export srcGridName="$REPOSITORY/ORCA_SCRIP_gridT.nc"
   export dstGridName="$REPOSITORY/World1deg_SCRIP_gridT.nc"
   export wgtFile="$REPOSITORY/ORCA_2_World_SCRIP_gridT.nc"
   
   export C3Satts="$DIR_TEMPL/C3S_globalatt.txt"
   export yyyytoday=`date +%Y`
   export mmtoday=`date +%m`
   export ddtoday=`date +%d`
   export Htoday=`date +%H`
   export Mtoday=`date +%M`
   export Stoday=`date +%S`
   cd $INPUT
   #TAKES 3'
   input=${caso}.cice.nc 
   if [ ! -f $input ] 
   then
      inputlist=`ls ${caso}*cice.h.*nc`
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
     title="${SPSSYS} forecast ERROR"
     body="C3S $checkfile not produced for case $caso. \n
             Script is ${DIR_POST}/cice/$scriptname"
     ${DIR_SPS35}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
     exit
   else
     rm $inputfile
   fi
fi
if [ $running -eq 1 ]  # 0 if running; 1 if off-line
then
     rm $INPUT/$caso.cice.*
fi  
exit 0
