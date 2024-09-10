#!/bin/sh -l 
# script to run the postprocessing C3S on Juno offline
# this should run only for hindcasts!

# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

set -euvx

LOG_FILE=$DIR_LOG/hindcast/launch_postproc_C3S_offline.`date +%Y%m%d%H%M`
exec 3>&1 1>>${LOG_FILE} 2>&1

here=$PWD
if [[ -f $DIR_TEMP/launch_postproc_C3S_offline_on ]]
then
   exit
fi

nmb_postproc_run=`$DIR_UTIL/findjobs.sh -m $machine -n postproc_C3S_offline -c yes`
if [[ ${nmb_postproc_run} -ge 10 ]] ; then
   exit
fi

touch $DIR_TEMP/launch_postproc_C3S_offline_on

#cd $DIR_ARCHIVE/

debug=1

st=10
for yyyy in `seq $iniy_hind $endy_hind`
do

    listofcases=`ls -d $DIR_ARCHIVE/sps4_$yyyy$st_0??`

    for caso in $listofcases
    do 
       set +euvx
       . $dictionary
       set -euvx
       n_flag_remote=`ls $DIR_ARCHIVE/${caso}.transfer_from_*_DONE |wc -l`
       if [[  $n_flag_remote -ne 0 ]] ; then
          echo "$caso not run on Juno, skip"
          continue
       fi
         
       if [[ -f $check_pp_C3S ]]
       then
          continue
       fi  

       flag_postproc_offline=$DIR_TEMP/C3S_postproc_offline_$caso
       if [[ -f ${flag_postproc_offline} ]] 
       then
           continue
       else
           touch ${flag_postproc_offline}
       fi

       mkdir -p $DIR_LOG/hindcast/C3S_postproc
       ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_l -M 1000 -d ${DIR_UTIL} -j postproc_C3S_offline_$caso -s postproc_C3S_offline.sh -l $DIR_LOG/hindcast/C3S_postproc -i $caso
#   $DIR_UTIL/postproc_C3S_offline.sh $caso 
       if [[ $debug -eq 1 ]]
       then
           rm $DIR_TEMP/launch_postproc_C3S_offline_on
           exit
       fi
       nsubmit=`$DIR_UTIL/findjobs.sh -m $machine -n postproc_C3S -c yes` 
   #nsubmit=$(($nsubmit + 1))
       if [[ $nsubmit -eq 10 ]]
       then
           rm $DIR_TEMP/launch_postproc_C3S_offline_on
           exit
       fi
  
    done
done
rm $DIR_TEMP/launch_postproc_C3S_offline_on
