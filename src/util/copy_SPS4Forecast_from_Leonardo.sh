#!/bin/sh -l
#BSUB -J copy_SPS4Forecast_from_Leonardo
#BSUB -q s_download
#BSUB -o /work/cmcc/cp1/CPS/CMCC-CPS1/logs/leonardo_transfer/copy_SPS4Forecast_from_Leonardo.out.%J  
#BSUB -e /work/cmcc/cp1/CPS/CMCC-CPS1/logs/leonardo_transfer/copy_SPS4Forecast_from_Leonardo.err.%J  
#BSUB -P 0784
#BSUB -M 1000

. $HOME/.bashrc
. $DIR_UTIL/descr_CPS.sh
# First check that no other this script is running
#load module for sshpass
module load $modulepass
set -uvx

caso=$1
checkfile=$2
job_run=`$DIR_UTIL/findjobs.sh -m $machine -n copy_SPS4Forecast_from_Leonardo_${caso} -c yes`
if [[ $job_run -gt 1 ]]
then
   exit 0
fi

yyyy=`echo $caso|cut -d '_' -f2|cut -c 1-4`
st=`echo $caso|cut -d '_' -f2|cut -c 5-6`
if [[ $op_machine != "leonardo" ]]
then
   exit 1
fi
if [[ "$machine" == "$repo_machine" ]]
then
    cmd="rsync -auv --rsh="sshpass -f $HOME/.sshpasswd ssh -l a07cmc00""
elif [[ "$machine" == "$bk_machine" ]]
then
   export SSHPASS="a(nU05wgJk"
   cmd="sshpass -e rsync -auv -e ssh"
#    cmd="rsync -auv '-e=sshpass -p a(nU05wgJk ssh'"
fi

leo_dir=/leonardo_work/$account_SLURM/CMCC-CM/archive 
leo_dir_CASES=/leonardo_work/$account_SLURM/CPS/CMCC-CPS1/cases 
leo_dir_REP=/leonardo_work/$account_SLURM/CPS/CMCC-CPS1/logs/REPORTS/$yyyy$st

# get the list of completed cases (produced daily in cron on Leonardo)
outdir=${SCRATCHDIR}/Leonardo_transfer_${yyyy}${st}
mkdir -p $outdir

if [[ -f $checkfile ]]
then
   exit 0
fi
rsync -auv -e="sshpass -p a(nU05wgJk ssh" a07cmc00@data.leonardo.cineca.it:${leo_dir_CASES}/$caso/logs/run_moredays_${caso}_DONE ${outdir}
#-----------------------------------------------------
if [[ "$machine" == "$bk_machine" ]]
then
#-----------------------------------------------------
# only in the bk_machine since in the repo_machine the transfer can involve cases not yet completed but overwritten in change_realization procedure
   if [[ ! -f ${outdir}/run_moredays_${caso}_DONE ]]
   then
# case not yet completed
      exit 0  
   fi
#-----------------------------------------------------
fi
#-----------------------------------------------------

#-----------------------------------------------------
if [[ "$machine" != "$repo_machine" ]]
then
#-----------------------------------------------------
# define in bk_machine a specific $DIR_ARCHIVE in order not to overwrite the local one which could be in use in case of double forecast (one in the op_machine and the other in the bk_machine)
   DIR_ARCHIVE=$DIR_ARCHIVE/Leonardo_${yyyy}${st}
   mkdir -p $DIR_ARCHIVE
#-----------------------------------------------------
fi
#-----------------------------------------------------

rsync -auv -e="sshpass -p a(nU05wgJk ssh" a07cmc00@data.leonardo.cineca.it:${leo_dir}/$caso $DIR_ARCHIVE

dim=`du -hs $DIR_ARCHIVE/$caso|cut -c 1-3`
if [[ $dim =~ "G" ]]
then
  dim=`du -hs $DIR_ARCHIVE/$caso|cut -c 1-2`
fi
# this is the expected dim after postproc_C3S. In case of bkup the copy of DMO could be submitted before the completion of the postproc so this dimension could not be applicable
mindim=80

if [[ $dim -lt $mindim ]]
then
      rsync -auv -e="sshpass -p a(nU05wgJk ssh" a07cmc00@data.leonardo.cineca.it:${leo_dir}/$caso $DIR_ARCHIVE
      if [[ $dim -lt $mindim ]]
      then
         title="[$CPSSYS] WARNING: issue in trasferring $caso from Leonardo to Juno"
         body="Dimensions of copied archived $caso are less than $mindim GB: $dim"
         ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r forecast -s $yyyy$st
         exit
      fi
fi

chmod -R ug-w ${DIR_ARCHIVE}/$caso
touch $checkfile
#-----------------------------------------------------
if [[ "$machine" == "$repo_machine" ]]
then
#-----------------------------------------------------
   $cmd $checkfile a07cmc00@dmover1.leonardo.cineca.it:${leo_dir}/
#-----------------------------------------------------
fi
#-----------------------------------------------------

