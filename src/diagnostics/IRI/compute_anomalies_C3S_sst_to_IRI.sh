#!/bin/sh -l

. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
. ${DIR_UTIL}/load_cdo
set -euvx

yyyy=$1
st=$2 #2 figures
varm=$3  
flag_done=${4}
DATASET=$5
dbg=${6}

set +euvx
. ${DIR_UTIL}/descr_ensemble.sh $yyyy
set -euvx


rclone_tag=${yyyy}${st}
if [[ ${typeofrun} == "forecast" ]] && [[ ${is_backup} -eq 1 ]]  
then
     rclone_tag=${yyyy}${st}_backup
fi
DIR_RCLONE=${typeofrun}/${rclone_tag}  


climdir=$WORK_SCORES/monthly/$varm/C3S/clim
pctldir=$WORK_SCORES/pctl
workdir=$SCRATCHDIR/diag_C3S/$varm/$yyyy$st
dirplots=$SCRATCHDIR/diag_C3S/forecast_plots/$yyyy$st
anomclimdir=$WORK_SCORES/monthly/$varm/C3S/anom
anomdir=$DIR_FORE_ANOM/$yyyy$st
mkdir -p $anomdir $dirplots

ncapsuleyyyystDONE=`ls -1 ${DIR_LOG}/${typeofrun}/$yyyy$st/diagnostics/capsule_${yyyy}${st}_${varm}_DONE* | wc -l`

$DIR_DIAG_C3S/C3S_lead2Mmonth_capsule_notify.sh  $yyyy $st $workdir $anomdir $varm $dbg ${DIR_LOG}/${typeofrun}/$yyyy$st/diagnostics
       
# if this flag is missing: you are running for the first time
if [ ! -f ${DIR_LOG}/${typeofrun}/$yyyy$st/diagnostics/capsule_${yyyy}${st}_${varm}_DONE ] ; then
   ncapsuleyyyystDONE=`ls -1 ${DIR_LOG}/${typeofrun}/$yyyy$st/diagnostics/capsule_${yyyy}${st}_0??_${varm}_DONE* | wc -l`  
         #if flags for single members are all present - remove them and put the one for entire startdate
   if [ $ncapsuleyyyystDONE -eq $nrunC3Sfore ] ; then
      rm ${DIR_LOG}/${typeofrun}/$yyyy$st/diagnostics/capsule_${yyyy}${st}_0??_${varm}_DONE*
      touch ${DIR_LOG}/${typeofrun}/$yyyy$st/diagnostics/capsule_${yyyy}${st}_${varm}_DONE

   else 
         #if flags for single members are not all present - something goes wrong! send mail and exit  
      ncapsyyyystDONEfound=`ls -1 ${DIR_LOG}/${typeofrun}/$yyyy$st/diagnostics/capsule_${yyyy}${st}_???_${varm}_DONE | wc -l`            
      title="[diags] ${CPSSYS} $typeofrun capsule ERROR"
      body="$ncapsyyyystDONEfound file $varm found of the $nrunC3Sfore expected for $yyyy$st $typeofrun"
      ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r $typeofrun -s $yyyy$st
      exit 1
   fi     
fi
       #now check if anomalies have been computed -same logic as before
nanomyyyystDONE=`ls -1 ${DIR_LOG}/${typeofrun}/$yyyy$st/diagnostics/anom_${SPSSystem}_${yyyy}${st}_${varm}_DONE* | wc -l`
       #if this flag is missing - is the first time you run this routine
$DIR_DIAG/IRI/anom_${CPSSYS}_C3S_sst.1993-2020.sh $yyyy $st $climdir $workdir $anomdir $varm $dbg ${DIR_LOG}/${typeofrun}/$yyyy$st/diagnostics

