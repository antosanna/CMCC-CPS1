#!/usr/bin/sh -l
. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/load_nco
# activate needed env
#TEMPORARY
if [[ $machine -ne "juno" ]]
then
   echo "we cannot run this script here because files are in Juno"
   exit
fi
. $DIR_UTIL/condaactivation.sh
condafunction activate $envcondanemo
set -euvx    # keep this instruction after conda activation
#INPUT:
yyyy=$1
st=$2
poce=$3
poce1=$((10#$poce - 1)) #one digit and one figure less
yy_assim=`date -d ' '$yyyy${st}15' - 1 month' +%Y`
mm_assim=`date -d ' '$yyyy${st}15' - 1 month' +%m`
set +euvx
. ${DIR_UTIL}/descr_ensemble.sh $yyyy
set -euvx
nemoic=$IC_NEMO_CPS_DIR/$st/${CPSSYS}.nemo.r.$yyyy-${st}-01-00000.$poce.nc 
ciceic=$IC_CICE_CPS_DIR/$st/${CPSSYS}.cice.r.$yyyy-${st}-01-00000.$poce.nc 
if [[ $typeofrun == "hindcast" ]]
then
   case $poce1 in
      0 | 1) OUTDIR=$DIR_REST_OIS/SLAMB$poce1/MONTHLY_RESTARTS/${yy_assim}${mm_assim}/
         #IC for startdate 202212 saved in the operational runs (OPSLAMB0,OPSLAMB1,OPSLAMB4 and OPSLAMB5)
         #even if also the other OPSLAMBs are present (e.g. OPSLAB1,OPSLAMB2 etc) 
         #the numeration has been conserved consistent with the SLAMBs run (0,1,4,5)
         if [[ "$st" == "12" ]] && [[ $yyyy -eq 2022 ]]
         then
              OUTDIR=$DIR_REST_OIS/OPSLAMB$poce1/MONTHLY_RESTARTS/${yy_assim}${mm_assim}/
         fi 
         ;;
      2 | 3) OUTDIR=$DIR_REST_OIS/SLAMB$(($poce1 + 2))/MONTHLY_RESTARTS/${yy_assim}${mm_assim}/
         if [[ "$st" == "01" ]] && [[ $yyyy -eq 1993 ]]
         then
           OUTDIR=$DIR_REST_OIS/MB$(($poce1 + 2))/MONTHLY_RESTARTS/${yy_assim}${mm_assim}/
         elif [[ "$st" == "12" ]] && [[ $yyyy -eq 2022 ]]
         then
           #OUTDIR=$DIR_REST_OIS/OPSLAMB4/MONTHLY_RESTARTS/${yy_assim}${mm_assim}/
           OUTDIR=$DIR_REST_OIS/OPSLAMB$(($poce1 + 2))/MONTHLY_RESTARTS/${yy_assim}${mm_assim}/
         fi
         ;;
   esac
else
# forecast
   OUTDIR=$SCRATCHDIR/IC/restart_from_ois2_fore/OPSLAMB$poce1/
   if [[ ! -d $OUTDIR ]] 
   then
      last_analysis=`ls -dtr /work/cmcc/cp1/CPS/CMCC-OIS2/run_oce_assim/OPSLAMB$poce1/????????00/run|tail -1`
      OUTDIR=$last_analysis
      nemoic=$IC_NEMO_CPS_DIR/$st/${CPSSYS}.nemo.r.$yyyy-${st}-01-00000.$poce.bkup.nc 
      ciceic=$IC_CICE_CPS_DIR/$st/${CPSSYS}.cice.r.$yyyy-${st}-01-00000.$poce.bkup.nc 
   fi
fi
tag=`ls $OUTDIR/*rest*nc|tail -1|rev|cut -d '_' -f3 |rev`
mkdir -p $IC_NEMO_CPS_DIR/$st
TMPNEMOREST=$SCRATCHDIR/nemo_rebuild/restart/$yyyy$st
mkdir -p $TMPNEMOREST
listaf=`ls $OUTDIR/*${tag}*_restart_0???.nc`
nf=`ls $OUTDIR/*${tag}*_restart_0???.nc|wc -l`
rootname=`basename $OUTDIR/*${tag}*_restart_0000.nc|rev|cut -d '_' -f2-|rev`
N=1
 
if [[ ! -f $nemoic ]]
then
   cd $TMPNEMOREST
   for ff in $listaf
   do 
      rsync -auv $ff .
   done
   
   $mpirun4py_nemo_rebuild -n $N python $DIR_NEMO_REBUILD/nemo_rebuild.py -i $TMPNEMOREST/${rootname}
   if [[ -f $TMPNEMOREST/${rootname}.nc ]]
   then
     # remove DELAY_fwb from OIS restarts
     ncatted -a DELAY_fwb,global,d,, $TMPNEMOREST/${rootname}.nc $nemoic
   fi
fi

if [[ ! -f $ciceic ]]
then
#   f_ice=`ls $OUTDIR/*.cice.r.$yyyy-$st-01-00000.nc`
   f_ice=`ls $OUTDIR/*.cice.r.????-??-??-00000.nc|tail -1`
   rsync -auv $f_ice $ciceic
fi
set +euvx
condafunction deactivate $envcondanemo
