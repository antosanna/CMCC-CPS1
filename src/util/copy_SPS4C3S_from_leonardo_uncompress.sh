#!/bin/sh -l
#BSUB -J copy_SPS4C3S_from_leonardo_uncompress
#BSUB -q s_download
#BSUB -o /work/cmcc/cp1/CPS/CMCC-CPS1/logs/leonardo_transfer/copy_SPS4C3S_from_leonardo_uncompress.out.%J  
#BSUB -e /work/cmcc/cp1/CPS/CMCC-CPS1/logs/leonardo_transfer/copy_SPS4C3S_from_leonardo_uncompress.err.%J  
#BSUB -P 0784
#BSUB -M 1000

. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh

module load $modulepass
set -uvx

job_run=`$DIR_UTIL/findjobs.sh -m $machine -n copy_SPS4C3S_from_leonardo_uncompress -c yes`
if [[ $job_run -gt 1 ]]
then
   exit 0
fi

yyyy=`date +%Y`
st=`date +%m` 

outdirC3S=${WORK_C3S}/${yyyy}${st}
mkdir -p $outdirC3S

dir_leo_c3s=/leonardo_work/CMCC_2026/CMCC-CM/archive/C3S/${yyyy}${st}/
dir_leo_push=/leonardo_work/$account_SLURM/CPS/CMCC-CPS1/push
dir_leo_daily=/leonardo_work/$account_SLURM/CMCC_SPS4/C3S_daily

outdir=${SCRATCHDIR}/Leonardo_transfer_${yyyy}${st}
mkdir -p $outdir

touchfile=${outdir}/C3Scopy_uncompress_from_Leonardo_${yyyy}${st}_DONE
if [[ -f $touchfile ]] 
then
    echo "C3S copy and uncompression already run, exiting now" 
    exit 0
fi


mv_tar=1  #if mv_tar=0 only uncompressing phase is run

if [[ ${mv_tar} -eq 1 ]] 
then
  rsync -auv --rsh="sshpass -f $HOME/.sshpasswd ssh -l a07cmc00" a07cmc00@data.leonardo.cineca.it:${dir_leo_c3s}/tar_C3S_${yyyy}${st}_DONE ${outdir}
  #this flag will be present only if tarC3S.sh is completed on Leonardo 
  if [[ ! -f ${outdir}/tar_C3S_${yyyy}${st}_DONE ]]
  then
  # tar not yet completed
      exit 0   
  fi 
  cd $pushdir
  rsync -auv --rsh="sshpass -f $HOME/.sshpasswd ssh -l a07cmc00" a07cmc00@data.leonardo.cineca.it:${dir_leo_push}/$yyyy$st $pushdir
  cd $FINALARCHC3S
  rsync -auv --rsh="sshpass -f $HOME/.sshpasswd ssh -l a07cmc00" a07cmc00@data.leonardo.cineca.it:${dir_leo_daily}/$yyyy$st $FINALARCHC3S
fi

if [[ -d $pushdir/${yyyy}${st} ]]
then 
   cd $pushdir/${yyyy}${st}
   listatar=`ls *.tar`
   for tt in $listatar
   do
      rsync -auv $pushdir/${yyyy}${st}/$tt ${outdirC3S}/.
      cd ${outdirC3S}
      tar -xvf ${outdirC3S}/$tt 
      namvar=`echo $tt |rev |cut -d '_' -f2 |rev`
      num_nc=`ls *S${yyyy}${st}0100_*_${namvar}_*.nc |wc -l`
      num_sha=`ls *S${yyyy}${st}0100_*_${namvar}_*.sha256 |wc -l`
      if [[ ${num_nc} -eq 50 ]] && [[ ${num_sha} -eq 50 ]] ; then
          rm ${outdirC3S}/$tt
      fi
   done
   touch $touchfile
fi
