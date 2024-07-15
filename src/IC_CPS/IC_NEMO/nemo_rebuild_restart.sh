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
poce1=$((10#$(($poce - 1))))
yy_assim=`date -d ' '$yyyy${st}15' - 1 month' +%Y`
mm_assim=`date -d ' '$yyyy${st}15' - 1 month' +%m`
# add your frequencies and grids. The script skip them if not present
case $poce1 in
   0) OUTDIR=$DIR_REST_OIS/SLAMB$poce1/MONTHLY_RESTARTS/${yy_assim}${mm_assim}/
      #IC for startdate 202212 saved in the operational runs (OPSLAMB0,OPSLAMB1,OPSLAMB4 and OPSLAMB5)
      #even if also the others OPSLAMBs are present (e.g. OPSLAB1,OPSLAMB2 etc) 
      #the numeration has been conserved consistent with the SLAMBs run (0,1,4,5)
      if [[ "$st" == "12" ]] && [[ $yyyy -eq 2022 ]]
      then
           OUTDIR=$DIR_REST_OIS/OPSLAMB$poce1/MONTHLY_RESTARTS/${yy_assim}${mm_assim}/
      fi 
      ;;
   1) OUTDIR=$DIR_REST_OIS/SLAMB$poce1/MONTHLY_RESTARTS/${yy_assim}${mm_assim}/
      if [[ "$st" == "12" ]] && [[ $yyyy -eq 2022 ]]
      then
           OUTDIR=$DIR_REST_OIS/OPSLAMB$poce1/MONTHLY_RESTARTS/${yy_assim}${mm_assim}/
      fi 
      ;;
   2) OUTDIR=$DIR_REST_OIS/SLAMB4/MONTHLY_RESTARTS/${yy_assim}${mm_assim}/
      if [[ "$st" == "01" ]] && [[ $yyyy -eq 1993 ]]
      then
        OUTDIR=$DIR_REST_OIS/MB4/MONTHLY_RESTARTS/${yy_assim}${mm_assim}/
      elif [[ "$st" == "12" ]] && [[ $yyyy -eq 2022 ]]
      then
        OUTDIR=$DIR_REST_OIS/OPSLAMB4/MONTHLY_RESTARTS/${yy_assim}${mm_assim}/
      fi
      ;;
   3) OUTDIR=$DIR_REST_OIS/SLAMB5/MONTHLY_RESTARTS/${yy_assim}${mm_assim}/
      if [[ "$st" == "01" ]] && [[ $yyyy -eq 1993 ]]
      then
        OUTDIR=$DIR_REST_OIS/MB5/MONTHLY_RESTARTS/${yy_assim}${mm_assim}/
      elif [[ "$st" == "12" ]] && [[ $yyyy -eq 2022 ]]
      then
        OUTDIR=$DIR_REST_OIS/OPSLAMB5/MONTHLY_RESTARTS/${yy_assim}${mm_assim}/
      fi
      ;;
esac
if [[ ! -d $OUTDIR ]]
then
   exit 0
fi
mkdir -p $IC_NEMO_CPS_DIR/$st
TMPNEMOREST=$SCRATCHDIR/nemo_rebuild/restart/$yyyy$st
mkdir -p $TMPNEMOREST
listaf=`ls $OUTDIR/*_restart_0???.nc`
nf=`ls $OUTDIR/*_restart_0???.nc|wc -l`
rootname=`basename $OUTDIR/*_restart_0000.nc|rev|cut -d '_' -f2-|rev`
N=1
 
if [[ ! -f $IC_NEMO_CPS_DIR/$st/${CPSSYS}.nemo.r.$yyyy-${st}-01-00000.$poce.nc ]]
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
     ncatted -a DELAY_fwb,global,d,, $TMPNEMOREST/${rootname}.nc $IC_NEMO_CPS_DIR/$st/${CPSSYS}.nemo.r.$yyyy-${st}-01-00000.$poce.nc
   fi
fi

if [[ ! -f ${IC_CICE_CPS_DIR}/$st/${CPSSYS}.cice.r.${yyyy}-${st}-01-00000.${poce}.nc ]]
then
   nf_ice=`ls $OUTDIR/*.cice.r.*.nc |wc -l`
   if [[ ${nf_ice} -eq 1 ]] ; then
       listaf_ice=`ls $OUTDIR/*.cice.r.${yyyy}-${st}*.nc`  #19930731_SLAMB1.cice.r.1993-08-01-00000.nc  
       for ff in ${listaf_ice} 
       do
          rsync -auv $ff ${IC_CICE_CPS_DIR}/$st/${CPSSYS}.cice.r.${yyyy}-${st}-01-00000.${poce}.nc 
       done
   fi
fi
set +euvx
condafunction deactivate $envcondanemo
