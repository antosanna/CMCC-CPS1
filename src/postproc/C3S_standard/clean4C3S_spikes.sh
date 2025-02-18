#!/bin/bash
. $HOME/.bashrc
. $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/descr_ensemble.sh 1993
set -eux


LOG_FILE=$DIR_LOG/hindcast/clean4C3S_spikes_`date +%Y%m%d%H%M`.log
exec 3>&1 1>>${LOG_FILE} 2>&1

dbg=0 #dbg 1 just echo, dbg 0 real cleaning

listacasi="sps4_199711_008 sps4_199911_027 sps4_202211_028"
#"sps4_199311_012 sps4_199311_029 sps4_199511_004 sps4_199511_025 sps4_199611_002 sps4_199611_017 sps4_199611_018 sps4_199611_024 sps4_199711_008 sps4_199711_014 sps4_199811_007 sps4_199811_009 sps4_199811_010 sps4_199911_023 sps4_199911_027 sps4_200011_005 sps4_200111_012 sps4_200211_002 sps4_200211_027 sps4_200311_010 sps4_200311_014 sps4_200311_017 sps4_200511_025 sps4_200511_027 sps4_200611_024 sps4_200611_026 sps4_200711_005 sps4_200711_009 sps4_200811_009 sps4_201011_018 sps4_201111_015 sps4_201211_008 sps4_201211_026 sps4_201211_028 sps4_201411_020 sps4_201411_029 sps4_201411_030 sps4_201511_026 sps4_201611_001 sps4_201611_029 sps4_201711_023 sps4_201711_026 sps4_201711_027 sps4_201711_028 sps4_201811_014 sps4_201811_015 sps4_201811_016 sps4_201911_004 sps4_201911_010 sps4_202011_006 sps4_202111_003 sps4_202111_018 sps4_202111_024 sps4_202111_028 sps4_202111_030 sps4_202211_017 sps4_202211_023 sps4_202211_028 sps4_202211_029"
cnt=0
case_notready=""
for caso in $listacasi ; do
   echo $caso
   st=`echo $caso|cut -d '_' -f 2|cut -c 5-6`
   yyyy=`echo $caso|cut -d '_' -f 2|cut -c 1-4`
   member=`echo $caso|cut -d '_' -f 3|cut -c 2-3`  
   startdate=$yyyy$st
   outdirC3S=${WORK_C3S}/$yyyy$st

   #here we want to recognize spike cases re-run on Leonardo
   #so we check only the cases transferred from Leonardo
   flag_spike=`ls $DIR_TEMP/${caso}.redone4spike|wc -l`
   flag_from_remote=`ls $DIR_ARCHIVE/${caso}.transfer_from_Leonardo_DONE |wc -l`
   if [[ ${flag_spike} -eq 1 ]] ; then
#   if [[ ${flag_from_remote} -eq 1 ]] && [[ ${flag_spike} -eq 1 ]] ; then
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
            mach="Leonardo"
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
         if [[ $dbg -eq 0 ]] ; then
             touch $DIR_TEMP/clean4C3S_spike_${caso}_DONE
         fi
         cnt=$(($cnt + 1 ))
   else
         echo "some problem with case $caso: neither completed on Juno (missing check_run_moredays flag)  nor transferred from remote (missing flag)"
         case_notready+="$caso "
   fi   
done


echo "Cleaning before offline C3S postprocessing completed for $cnt cases"
if [[ "${case_notready}" != "" ]]
then
  echo "Still missing ${case_notready}"
fi
