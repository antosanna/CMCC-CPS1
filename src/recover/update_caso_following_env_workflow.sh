#!/bin/sh -l
#-----------------------------------------------------------------------
# Determine necessary environment variables
#-----------------------------------------------------------------------
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. ${DIR_UTIL}/load_nco

set -euxv
LOG_FILE=$DIR_LOG/hindcast/recover/update_caso_following_env_workflow_`date +%Y%m%d%H%M`
exec 3>&1 1>>${LOG_FILE} 2>&1

listofcases="sps4_199308_011 sps4_199308_007 sps4_199308_008 sps4_199308_012 sps4_199308_004 sps4_199308_035 sps4_199408_004 sps4_199308_005"
for caso in $listofcases 
do
  if [[ ! -d $DIR_CASES/$caso ]] ; then
    continue
  fi
  cd $DIR_CASES/$caso
  rsync -auv $DIR_TEMPL/env_workflow_sps4.xml_${env_workflow_tag} $DIR_CASES/$caso/env_workflow.xml
  ./case.setup --reset
  ./xmlchange BUILD_COMPLETE=TRUE
  
 #if env_workflow has to be updated and the moredays have to be rerun, 
 #the dependency for the final lt_archive
 #./xmlchange --subgroup case.lt_archive dependency=case.st_archive
 #with this recover is lost!!
 #ask Anto or Mari for more info (hopefully!!!)
done

exit 0
