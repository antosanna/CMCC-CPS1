#!/bin/bash
. $HOME/.bashrc
. $DIR_UTIL/descr_CPS.sh


LOG_FILE=$DIR_LOG/hindcast/REMOVE_FROM_LEONARDO_CASES_TRANSFERRED_08_`date +%Y%m%d%H%M`
exec 3>&1 1>>${LOG_FILE} 2>&1

set -euvx
listacasi="sps4_199308_023 sps4_199308_026 sps4_199408_007 sps4_199408_020 sps4_199408_026 sps4_199408_030 sps4_199508_002 sps4_199508_009 sps4_199508_012 sps4_199508_013 sps4_199508_030 sps4_199608_004 sps4_199608_006 sps4_199608_007 sps4_199608_012 sps4_199608_017 sps4_199608_020 sps4_199608_025 sps4_199608_028 sps4_199708_003 sps4_199708_007 sps4_199708_011 sps4_199708_012 sps4_199708_013 sps4_199708_014 sps4_199708_015 sps4_199708_020 sps4_199708_022 sps4_199808_011 sps4_199808_018 sps4_199808_024 sps4_199808_028 sps4_200008_015 sps4_201108_002 sps4_201108_003 sps4_201108_004 sps4_201108_008 sps4_201208_015 sps4_201208_016 sps4_201208_017 sps4_201208_018 sps4_201208_019 sps4_201208_020 sps4_202208_004 sps4_202208_005 sps4_202208_006 sps4_202208_007 sps4_202208_011 sps4_202208_013 sps4_202208_018 sps4_202208_019 sps4_202208_020 sps4_202208_021 sps4_202208_022"
echo $listacasi

for caso in $listacasi ; do

 if [[ -f ${DIR_ARCHIVE}/$caso.transfer_from_Leonardo_DONE ]] ; then
    if [[ ! -z `ls -A ${DIR_ARCHIVE}/$caso` ]]; then
        echo $caso   
        rm -r ${DIR_ARCHIVE}/$caso/*
    fi
    if [[ -d ${WORK_CPS}/$caso ]]
    then
       rm -r ${WORK_CPS}/$caso
    fi
  fi

done
echo "Succesfully removed $listacasi"
