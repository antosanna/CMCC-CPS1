#!/bin/sh -l
#-----------------------------------------------------------------------
# Update template postproc and submit .case.lt_archive
#-----------------------------------------------------------------------
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

set -euxv
mkdir -p $DIR_LOG/hindcast/recover
LOG_FILE=$DIR_LOG/hindcast/recover/recover_st_archive_`date +%Y%m%d%H%M`
exec 3>&1 1>>${LOG_FILE} 2>&1

if [[ $# -eq 0 ]]
then
   listofcases="sps4_199307_003 sps4_199307_006 sps4_199307_008 sps4_199307_009"
else
   listofcases=$1
fi
for caso in $listofcases 
do
  if [[ ! -d $DIR_CASES/$caso ]] ; then
    continue
  fi
  cd $DIR_CASES/$caso
  
  #upload $dictionary
  st=`echo $caso|cut -d '_' -f 2|cut -c 5-6`
  yyyy=`echo $caso|cut -d '_' -f 2|cut -c 1-4`
  member=`echo $caso|cut -d '_' -f 3|cut -c 2-3`

  CASEROOT=$DIR_CASES/$caso/
  outdirC3S=$DIR_ARCHIVE/C3S/$yyyy$st/
  set +uevx
  . $dictionary
  set -euvx
  if [[ ! -f  $check_6months_done ]] ; then
       #is st_archive during monthly run. launch with dependency nemo_rebuild and lt_archive

       #in order to relaunch st_archive with the right syntax, we keep the command as appear in preview_run (for portability)
       cmd=`./preview_run |grep case.st_archive|tail -1`
       #this is needed to remove the dependency from model run
       if [[ $machine == "cassandra" ]] || [[ $machine == "juno" ]]
       then
          cmd_nodep="$(echo "${cmd/"-ti -w 'done(0)'"/}")"
          eval ${cmd_nodep}
          ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_m -p st_archive.$caso  -t "1" -M 1500 -j nemo_rebuild.$caso -l $DIR_CASES/$caso/logs/ -d ${DIR_CASES}/$caso -s .case.nemo_rebuild
        ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_m -p nemo_rebuild.$caso -t "6" -M 15000 -j lt_archive.$caso -l $DIR_CASES/$caso/logs/ -d ${DIR_CASES}/$caso -s .case.lt_archive 

       elif [[ $machine == "leonardo" ]] 
       then
          cmd_nodep="$(echo "${cmd/"--dependency=afterok:0"/}")"
          cmd_nemo=`./preview_run |grep nemo_rebuild|tail -1`
          cmd_ltarc=`./preview_run |grep .case.lt_archive|tail -1`
          eval ${cmd_nodep}
          st_arch_jobid=`$DIR_UTIL/findjobs.sh -m $machine -n st_archive.${caso} -i yes` 
          cmd_nemo_dep="$(echo "${cmd_nemo/"--dependency=afterok:1"/"--dependency=${st_arch_jobid}"}")"
          eval ${cmd_nemo_dep}
          nemo_reb_jobid=`$DIR_UTIL/findjobs.sh -m $machine -n nemo_rebuild.${caso} -i yes`
          cmd_ltarc_dep="$(echo "${cmd_ltarc/"--dependency=afterok:2"/"--dependency=${nemo_reb_jobid}"}")"
          eval ${cmd_ltarc_dep}

       fi
  else
    #is st_archive after moredays.. launch with dependency lt_arch_moredays
       cmd=`./preview_run |grep case.st_archive|tail -1`
       if [[ $machine == "cassandra" ]] || [[ $machine == "juno" ]]
       then
          cmd_nodep="$(echo "${cmd/"-ti -w 'done(0)'"/}")"
          eval ${cmd_nodep}
          ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_m -t "6" -M 25000 -p st_archive.$caso -j lt_archive_moredays.$caso -l $DIR_CASES/$caso/logs/ -d ${DIR_CASES}/$caso -s .case.lt_archive_moredays 
       elif [[ $machine == "leonardo" ]]  
       then
          cmd_nodep="$(echo "${cmd/"--dependency=afterok:0"/}")"
          eval ${cmd_nodep}  
          st_arch_jobid=`$DIR_UTIL/findjobs.sh -m $machine -n st_archive.${caso} -i yes` 
          cmd_ltarc=`./preview_run |grep .case.lt_archive_moredays |tail -1`
          if [[ ${cmd_ltarc} == "" ]] ; then
              ./xmlchange NEMO_REBUILD=FALSE
              ./xmlchange --subgroup case.lt_archive_moredays prereq=1
              cmd_ltarc=`./preview_run |grep .case.lt_archive_moredays |tail -1` 
          fi
          cmd_ltarc_dep="$(echo "${cmd_ltarc/"--dependency=afterok:1"/"--dependency=${st_arch_jobid}"}")"   
          eval ${cmd_ltarc_dep} 
       fi  
 
  fi     
done

exit 0
