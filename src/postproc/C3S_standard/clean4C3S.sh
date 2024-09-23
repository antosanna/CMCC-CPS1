#!/bin/bash
. $HOME/.bashrc
. $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/descr_ensemble.sh 1993
set -euvx


st=12
LOG_FILE=$DIR_LOG/hindcast/clean4C3S_${st}_`date +%Y%m%d%H%M`.log
exec 3>&1 1>>${LOG_FILE} 2>&1

dbg=0

listacasi=`ls -d $DIR_ARCHIVE/sps4_????${st}_0??`
cnt=0
for dd in $listacasi ; do
   caso=`basename $dd` 
   echo $caso
#   st=`echo $caso|cut -d '_' -f 2|cut -c 5-6`
   yyyy=`echo $caso|cut -d '_' -f 2|cut -c 1-4`
   member=`echo $caso|cut -d '_' -f 3|cut -c 2-3`  
   startdate=$yyyy$st
   outdirC3S=${WORK_C3S}/$yyyy$st

   #sps4_201312_023.transfer_from_Leonardo_DONE
   flag_from_remote=`ls $DIR_ARCHIVE/${caso}.transfer_from_*_DONE |wc -l`
   if [[ -f $DIR_CASES/$caso/logs/run_moredays_${caso}_DONE ]] || [[ ${flag_from_remote} -eq 1 ]] ; then
         if [[ -f $DIR_TEMP/C3S_postproc_offline_$caso ]] ; then
            echo "cleaning $DIR_TEMP/C3S_postproc_offline_$caso"
            if [[ $dbg -eq 0 ]] ; then
              rm $DIR_TEMP/C3S_postproc_offline_$caso
            fi
         fi
         if [[ -d $SCRATCHDIR/regrid_C3S/$caso/ ]] ; then
            echo "cleaning $SCRATCHDIR/regrid_C3S/$caso"
            if [[ $dbg -eq 0 ]] ; then
               rm -rf $SCRATCHDIR/regrid_C3S/$caso/*
               rmdir $SCRATCHDIR/regrid_C3S/$caso
            fi
         fi
         if [[ -d $SCRATCHDIR/C3Schecker/hindcast/$yyyy$st/$member/ ]] ; then
            echo "cleaning $SCRATCHDIR/C3Schecker/hindcast/$yyyy$st/$member"
            if [[ $dbg -eq 0 ]] ; then        
               rm -rf $SCRATCHDIR/C3Schecker/hindcast/$yyyy$st/$member/*
               rmdir $SCRATCHDIR/C3Schecker/hindcast/$yyyy$st/$member
            fi
         fi 
         if [[ -f $DIR_CASES/$caso/logs/postproc_C3S_${caso}_DONE ]] ; then       
            echo "cleaning $DIR_CASES/$caso/logs/postproc_C3S_${caso}_DONE" 
            if [[ $dbg -eq 0 ]] ; then
               rm -f $DIR_CASES/$caso/logs/postproc_C3S_${caso}_DONE
            fi
         fi
         if [[ $flag_from_remote -eq 1 ]] ; then
            mach=`ls $DIR_ARCHIVE/${caso}.transfer_from_*_DONE |rev|cut -d '_' -f2 |rev`
            dir_cases_remote=/work/cmcc/$USER/CPS/CMCC-CPS1/cases_from_${mach}
            if [[ -f $dir_cases_remote/$caso/logs/postproc_C3S_${caso}_DONE ]] ; then
               echo "cleaning $dir_cases_remote/$caso/logs/postproc_C3S_${caso}_DONE"           
               if [[ $dbg -eq 0 ]] ; then
                  rm $dir_cases_remote/$caso/logs/postproc_C3S_${caso}_DONE
               fi
            fi
         fi
         if [[ -f $SCRATCHDIR/CMCC-CPS1/temporary/C3S_postproc_remote_${caso}  ]]  
         then
             echo "cleaning $SCRATCHDIR/CMCC-CPS1/temporary/C3S_postproc_remote_${caso}"
             if [[ $dbg -eq 0 ]] ; then
                rm $SCRATCHDIR/CMCC-CPS1/temporary/C3S_postproc_remote_${caso}
             fi
         fi   
         if [[ -f $SCRATCHDIR/CMCC-CPS1/temporary/C3S_postproc_offline_${caso}  ]]  
         then
             echo "cleaning $SCRATCHDIR/CMCC-CPS1/temporary/C3S_postproc_offline_${caso}"
             if [[ $dbg -eq 0 ]] ; then
                rm $SCRATCHDIR/CMCC-CPS1/temporary/C3S_postproc_offline_${caso}
             fi  
         fi   

         if [[ -f $outdirC3S/no_SOLIN_in_${caso} ]] ; then
             echo "cleaning $outdirC3S/no_SOLIN_in_${caso}"
             if [[ $dbg -eq 0 ]] ; then
                rm -f $outdirC3S/no_SOLIN_in_${caso}
             fi
         fi
         old_c3s_files=`ls $outdirC3S/cmcc_CMCC-CM3-v${versionSPS}_${typeofrun}_S${startdate}0100*r${member}i00p00.nc |wc -l`
         if [[ ${old_c3s_files} -ne 0 ]] ; then
            echo "cleaning $old_c3s_files files in $outdirC3S"
            if [[ $dbg -eq 0 ]] ; then
               rm -f $outdirC3S/cmcc_CMCC-CM3-v${versionSPS}_${typeofrun}_S${startdate}0100*r${member}i00p00.nc
            fi
         fi
         if [[ `ls $outdirC3S/all_checkers_ok_0${member} |wc -l` -ne 0  ]]  
         then
              echo "cleaning $outdirC3S/all_checkers_ok_0${member}"
              if [[ $dbg -eq 0 ]] ; then
                 rm $outdirC3S/all_checkers_ok_0${member}
              fi
         fi

         if [[ -f $SCRATCHDIR/wk_C3S_daily/$yyyy$st/C3S_daily_mean_2d_${member}_ok ]]
         then
            echo "cleaning $SCRATCHDIR/wk_C3S_daily/$yyyy$st/C3S_daily_mean_2d_${member}_ok"
            if [[ $dbg -eq 0 ]] ; then
              rm $SCRATCHDIR/wk_C3S_daily/$yyyy$st/C3S_daily_mean_2d_${member}_ok
            fi
         fi

         cnt=$(($cnt + 1 ))
   else
         echo "some problem with case $caso: neither completed on Juno (missing check_run_moredays flag)  nor transferred from remote (missing flag)"
   fi   
done


echo "Cleaning before offline C3S postprocessing completed for $cnt cases"
