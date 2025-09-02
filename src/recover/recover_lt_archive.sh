#!/bin/sh -l
#-----------------------------------------------------------------------
# Update template postproc and submit .case.lt_archive
#-----------------------------------------------------------------------
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

set -euxv
mkdir -p $DIR_LOG/hindcast/recover

dorelaunch=0
if [[ $# -eq 0 ]]
then
   listofcases="sps4_199611_015 sps4_199811_016 sps4_199811_017 sps4_199911_004 sps4_200011_013 sps4_200011_027 sps4_200011_028 sps4_200011_029 sps4_200011_030 sps4_200111_001 sps4_200111_003"
   LOG_FILE=$DIR_LOG/hindcast/recover/recover_lt_archive_`date +%Y%m%d%H%M`
else
   listofcases=$1
   if [[ `echo $listofcases|wc -w` -eq 1 ]]
   then
      LOG_FILE=$DIR_LOG/hindcast/recover/recover_lt_archive_${listofcases}_`date +%Y%m%d%H%M`
   else
      LOG_FILE=$DIR_LOG/hindcast/recover/recover_lt_archive_`date +%Y%m%d%H%M`
   fi
fi
exec 3>&1 1>>${LOG_FILE} 2>&1
for caso in $listofcases 
do
  if [[ ! -d $DIR_CASES/$caso ]] ; then
    continue
  fi
  yyyy=`echo $caso|cut -d'_' -f2 |cut -c1-4`
  st=`echo $caso|cut -d'_' -f2 |cut -c5-6`
  filename=$DIR_CASES/$caso/logs/ic_${caso}.txt
  while read line; do ic=`echo $line`; done < $filename
  outdirC3S=$DIR_ARCHIVE/C3S/$yyyy$st/
  echo $ic
  echo $outdirC3S
  cd $DIR_CASES/$caso
# to refresh lt_achive from template
#ANTO
#module unload bzip2 libbsd lz4 pkgconf parallel-netcdf zlib-ng
#if [[ $machine == "leonardo" ]]
#then
#   module use -p $modpath
#fi
#ANTO-
#  ./case.setup --reset
  ./xmlchange BUILD_COMPLETE=TRUE
  ./xmlchange NEMO_REBUILD=TRUE
  ./xmlchange STOP_OPTION=nmonths
  
  #in order to relaunch lt_archive with the right syntax, we keep the command as appear in preview_run (for portability)
  cmd=`./preview_run |grep case.lt_archive|tail -1`
  #this is needed to remove the dependency from model run
  if [[ $machine == "zeus" ]] || [[ $machine == "juno" ]] || [[ $machine == "cassandra" ]]
  then
     cmd_nodep="$(echo "${cmd/"-ti -w 'done(1)'"/}")"
  elif [[ $machine == "leonardo" ]]  
  then
     cmd_nodep="$(echo "${cmd/"--dependency=afterok:2"/}")"  #--dependency=afterok:2
  fi  
  eval ${cmd_nodep}


#  ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_m -S $qos -t "6" -M 15000 -j lt_archive -l $DIR_CASES/$caso/logs/ -d ${DIR_CASES}/$caso -s .case.lt_archive 
done

exit 0
