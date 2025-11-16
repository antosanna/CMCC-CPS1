#!/bin/bash
. $HOME/.bashrc
. $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/descr_ensemble.sh 1993
set -euvx

#listacasi="sps4_201005_002"
#LOG_FILE=$DIR_LOG/hindcast/clean4CERISE_listofcases_`date +%Y%m%d%H%M`.log
LOG_FILE=$DIR_LOG/hindcast/clean4CERISE_05_`date +%Y%m%d%H%M`.log
exec 3>&1 1>>${LOG_FILE} 2>&1
cnt=0
st=05
dbg=0
for yyyy in {2002..2015}
do
   startdate=$yyyy$st
   outdirC3S=${WORK_CERISE}/$yyyy$st
for member in {01..25}
do
   caso=sps4_${yyyy}${st}_0${member}
   echo $caso
set +euvx
   . $DIR_UTIL/descr_ensemble.sh $yyyy
set -euvx
# remove temporary directory for spike "treatment"
   if [[ -d $HEALED_DIR_ROOT/$caso ]]
   then
      rm -rf $HEALED_DIR_ROOT/$caso
   fi

# flag for isobaric level extrapolation
   if [[ -f $DIR_CASES/$caso/logs/extrapT_${caso}_DONE ]]
   then
      rm $DIR_CASES/$caso/logs/extrapT_${caso}_DONE 
   fi
# flag for spike treatment
   if [[ -f $DIR_CASES/$caso/logs/spike_treatment_${caso}_DONE ]]
   then
      rm $DIR_CASES/$caso/logs/spike_treatment_${caso}_DONE 
   fi
   
   if [[ -f $DIR_CASES/$caso/logs/run_moredays_${caso}_DONE ]] 
   then
         if [[ -f $DIR_TEMP/CERISE_phase2_postproc_offline_$caso ]] ; then
            echo "cleaning $DIR_TEMP/CERISE_phase2_postproc_offline_$caso"
            if [[ $dbg -eq 0 ]] ; then
              rm $DIR_TEMP/CERISE_phase2_postproc_offline_$caso
            fi
         fi
         if [[ -d $SCRATCHDIR/regrid_CERISE_phase2/$caso/ ]] ; then
            echo "cleaning $SCRATCHDIR/regrid_CERISE_phase2/$caso"
            if [[ $dbg -eq 0 ]] ; then
               rm -rf $SCRATCHDIR/regrid_CERISE_phase2/$caso/*
               rmdir $SCRATCHDIR/regrid_CERISE_phase2/$caso
            fi
         fi
         if [[ -d $SCRATCHDIR/C3Schecker/hindcast/$yyyy$st/$member/ ]] ; then
            echo "cleaning $SCRATCHDIR/C3Schecker/hindcast/$yyyy$st/$member"
            if [[ $dbg -eq 0 ]] ; then        
               rm -rf $SCRATCHDIR/C3Schecker/hindcast/$yyyy$st/$member/*
               rmdir $SCRATCHDIR/C3Schecker/hindcast/$yyyy$st/$member
            fi
         fi 
         if [[ -f $DIR_CASES/$caso/logs/postproc_CERISE_phase2_${caso}_DONE ]] ; then       
            echo "cleaning $DIR_CASES/$caso/logs/postproc_CERISE_phase2_${caso}_DONE" 
            if [[ $dbg -eq 0 ]] ; then
               rm -f $DIR_CASES/$caso/logs/postproc_CERISE_phase2_${caso}_DONE
            fi
         fi
         if [[ -f $SCRATCHDIR/CMCC-CPS1/temporary/CERISE_phase2_postproc_offline_${caso}  ]]  
         then
             echo "cleaning $SCRATCHDIR/CMCC-CPS1/temporary/CERISE_phase2_postproc_offline_${caso}"
             if [[ $dbg -eq 0 ]] ; then
                rm $SCRATCHDIR/CMCC-CPS1/temporary/CERISE_phase2_postproc_offline_${caso}
             fi  
         fi   

         old_c3s_files=`ls $outdirC3S/cmcc_CERISE-CMCC-CM3-v${versionSPS}_${typeofrun}_S${startdate}0100*r${member}i00p00.nc |wc -l`
         old_c3s_sha=`ls $outdirC3S/cmcc_CERISE-CMCC-CM3-v${versionSPS}_${typeofrun}_S${startdate}0100*r${member}i00p00.sha256 |wc -l`
         if [[ ${old_c3s_files} -ne 0 ]] ; then
            echo "cleaning $old_c3s_files files in $outdirC3S"
            if [[ $dbg -eq 0 ]] ; then
               rm -f $outdirC3S/cmcc_CERISE-CMCC-CM3-v${versionSPS}_${typeofrun}_S${startdate}0100*r${member}i00p00.nc
            fi
         fi
         if [[ ${old_c3s_sha} -ne 0 ]] ; then
            echo "cleaning $old_c3s_sha sha256 files in $outdirC3S"
            if [[ $dbg -eq 0 ]] ; then
               rm -f $outdirC3S/cmcc_CERISE-CMCC-CM3-v${versionSPS}_${typeofrun}_S${startdate}0100*r${member}i00p00.sha256
            fi  
         fi  
         if [[ `ls $outdirC3S/all_checkers_ok_0${member} |wc -l` -ne 0  ]]  
         then
              echo "cleaning $outdirC3S/all_checkers_ok_0${member}"
              if [[ $dbg -eq 0 ]] ; then
                 rm $outdirC3S/all_checkers_ok_0${member}
              fi
         fi

         cnt=$(($cnt + 1 ))
   else
         echo "some problem with case $caso: not  completed "
   fi   
done
done


echo "Cleaning before offline C3S postprocessing completed for $cnt cases"
