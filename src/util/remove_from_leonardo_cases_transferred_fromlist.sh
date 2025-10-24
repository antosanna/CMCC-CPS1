#!/bin/bash
. $HOME/.bashrc
. $DIR_UTIL/descr_CPS.sh


st=04
LOG_FILE=$DIR_LOG/hindcast/REMOVE_FROM_LEONARDO_CASES_TRANSFERRED_${st}_`date +%Y%m%d%H%M`
exec 3>&1 1>>${LOG_FILE} 2>&1
dbg=1 #dbg=1 only test
set -euvx
 if [[ `ls -tr ${DIR_ARCHIVE}/sps4_????${st}_0??.transfer_from_Leonardo_DONE |wc -l` -ne 0 ]] ; then
    cd ${DIR_ARCHIVE}
    lista_flag=`ls -tr sps4_????${st}_0??.transfer_from_Leonardo_DONE`
    listacasi=""
    for flag in $lista_flag ; do
       casename=`echo $flag | cut -d '.' -f1`
       if [[ -f ${DIR_ARCHIVE}/${casename}.transfer_from_Leonardo_DONE ]]
       then
          if [[ -d ${DIR_ARCHIVE}/${casename} ]]
          then
            size=`du -hs $casename `
            dim_dir=`echo $size | awk '{print $1}'`
            if [[ "${dim_dir}" == "256G" ]]  ; then
               listacasi+="$casename "
            fi
          fi
       fi
    done
    if [[ $listacasi != "" ]] ; then

      echo $listacasi
      for caso in $listacasi ; do
          if [[ -f ${DIR_ARCHIVE}/$caso.transfer_from_Leonardo_DONE ]] ; then
                if [[ ! -z `ls -A ${DIR_ARCHIVE}/$caso` ]]; then
                     echo "cleaning $DIR_ARCHIVE/$caso"   
                     if [[ $dbg -eq 0 ]] ; then
                       rm -r ${DIR_ARCHIVE}/$caso/*
                     fi
                fi
                if [[ -d ${WORK_CPS}/$caso ]]
                then
                    echo "cleaning ${WORK_CPS}/$caso"
                    if [[ $dbg -eq 0 ]] ; then
                       rm -r ${WORK_CPS}/$caso
                    fi
                fi
          fi
      done
      if [[ $dbg -eq 0 ]] ; then
         echo "Succesfully removed $listacasi"
      else
         echo "Debug test. List of cases to be removed: $listacasi"
      fi
    else
      echo "No cases to be removed for startdate ${st}"
    fi
fi
