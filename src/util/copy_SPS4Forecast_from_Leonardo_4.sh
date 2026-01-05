#!/bin/sh -l
#BSUB -J copy_SPS4Forecast_from_Leonardo_4
#BSUB -q s_download
#BSUB -o /work/cmcc/cp1/CPS/CMCC-CPS1/logs/leonardo_transfer/copy_SPS4Forecast_from_Leonardo_4.out.%J  
#BSUB -e /work/cmcc/cp1/CPS/CMCC-CPS1/logs/leonardo_transfer/copy_SPS4Forecast_from_Leonardo_4.err.%J  
#BSUB -P 0490
#BSUB -M 1000

. $HOME/.bashrc
. $DIR_UTIL/descr_CPS.sh
# First check that no other this script is running
#load module for sshpass
module load intel-2021.6.0/sshpass/.1.06-zarp3
set -uvx

job_run=`$DIR_UTIL/findjobs.sh -m $machine -n copy_SPS4Forecast_from_Leonardo_4 -c yes`
if [[ $job_run -gt 1 ]]
then
   exit 0
fi

yyyy=`date +%Y`
st=`date +%m`
leo_dir=/leonardo_work/CMCC_2025/CMCC-CM/archive/
leo_dir_CASES=/leonardo_work/CMCC_2025//CPS/CMCC-CPS1/cases
leo_dir_temp=/leonardo_work/CMCC_2025/scratch/CMCC-CPS1/temporary
#if submit_tarC3S started, stop the copy from Leonardo to avoid issues with renumbering

if [[ -f ${DIR_LOG}/forecast/${yyyy}${st}/submit_tar_C3S_${yyyy}${st}_started ]] ; then
   echo "submit_tarC3S started, no extra cases to be copied. Exiting now."
   exit 0
fi

# get the list of completed cases (produced daily in cron on Leonardo)
outdir=${SCRATCHDIR}/Leonardo_transfer_${yyyy}${st}
mkdir -p $outdir
lista_today_1=" "
for ens in {028..036} ; do
   caso=sps4_${yyyy}${st}_${ens}

   checkfile=$DIR_ARCHIVE/$caso.transfer_from_Leonardo_DONE
   if [[ -f $checkfile ]]
   then
      continue
   fi
   rsync -auv --rsh="sshpass -f $HOME/.sshpasswd ssh -l a07cmc00" a07cmc00@data.leonardo.cineca.it:${leo_dir_CASES}/$caso/logs/run_moredays_${caso}_DONE ${outdir}
   stat=$?
   if [[ $stat -ne 0 ]]
   then
      continue
   fi 
   if [[ ! -f ${outdir}/run_moredays_${caso}_DONE ]]
   then
      continue
   fi
   rsync -auv --rsh="sshpass -f $HOME/.sshpasswd ssh -l a07cmc00" a07cmc00@data.leonardo.cineca.it:${leo_dir}/$caso $DIR_ARCHIVE
   stat=$?
   if [[ $stat -eq 0 ]]
   then
      chmod -R ug-w ${DIR_ARCHIVE}/$caso
      touch $checkfile
      rsync -auv --rsh="sshpass -f $HOME/.sshpasswd ssh -l a07cmc00" $checkfile a07cmc00@data.leonardo.cineca.it:${leo_dir}/
      dim=`du -hs $DIR_ARCHIVE/$caso|cut -c 1-3`
      if [[ $dim -lt 256 ]]
      then
         if [[ `ls $DIR_ARCHIVE/$caso/rest/*tar.gz |wc -l` -eq 1 ]] && [[ $dim -ge 130 ]]
         then
            echo "restart compressed and .h* files removed $dim"
         else
            continue
         fi
      fi
   else
      continue
   fi

done
