#!/bin/sh -l 

# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. ${DIR_UTIL}/load_nco                # to get command $compress
. ${DIR_UTIL}/descr_ensemble.sh 1993  #THIS SCRIPT SHOULD RUN
                                      #ONLY FOR HINDCASTS

set -evxu

caso=$1
# only in this special case DIR_CASES must be redefined for it can be different
# for the different machines the case could have been done on.
dir_cases=$2
# this modification will affect $dictionary too!!!!
flag=$3

st=`echo $caso|cut -d '_' -f2 |cut -c5-6`
yyyy=`echo $caso|cut -d '_' -f2 |cut -c1-4`
#
startdate=$yyyy$st
ens=`echo $caso|cut -d '_' -f 3 `
member=`echo $ens|cut -c2,3` 

HEALED_DIR=$HEALED_DIR_ROOT/$caso
#HEALED_DIR_ROOT=/work/cmcc/cp1/CPS/CMCC-CPS1/fixed_from_spikes/
chmod -R u+w $DIR_ARCHIVE/$caso
ic=`ncdump -h $DIR_ARCHIVE/$caso/atm/hist/$caso.cam.h0.$yyyy-$st.zip.nc|grep "ic ="|cut -d '=' -f2-|cut -d ';' -f1 |cut -d '"' -f2`

outdirC3S=${WORK_C3S}/$yyyy$st/

set +euvx
. $dictionary
set -euvx
mkdir -p $outdirC3S
dirlog=$dir_cases/$caso/logs
mkdir -p $dirlog

# the removal must be done here because if the below precedures remain pending it might happen that the following check on the existence of the (old) checkfiles is verified

for ft in h1 h2 h3 h4
do  
   for mod in cam 
   do  
      if [[ -f $HEALED_DIR/${caso}.$mod.$ft.DONE ]]
      then
            rm $HEALED_DIR/${caso}.$mod.$ft.DONE
       fi  
   done
done
if [[ -f $HEALED_DIR/${caso}.NO_SPIKE ]]
then
      rm $HEALED_DIR/${caso}.NO_SPIKE
fi  


input="$caso"
if [[ $flag -eq 1 ]]
then
# healing for too many iterations
   ${DIR_UTIL}/submitcommand.sh -m $machine -q $parallelq_m -S $qos -M 40000 -j continue_fixing_after_it_limit_${caso} -l $dir_cases/$caso/logs/ -d ${DIR_POST}/cam -s continue_fixing_after_it_limit.sh -i "$input"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$caso : continue_fixing_after_it_limit_${caso} submitted" -r "only" -s $yyyy$st
elif [[ $flag -eq 2 ]]
then
# healing for spike discovered in C3S
   ${DIR_UTIL}/submitcommand.sh -m $machine -q $parallelq_m -S $qos -M 40000 -j fixing_after_C3S_spike_${caso} -l $dir_cases/$caso/logs/ -d ${DIR_POST}/cam -s fixing_after_C3S_spike.sh -i "$input"
fi
# check on presence of checkfile for healing
while `true`
do
      if [[ -f $HEALED_DIR/${caso}.cam.h1.DONE ]] && [[ -f $HEALED_DIR/${caso}.cam.h2.DONE ]] && [[ -f $HEALED_DIR/${caso}.cam.h3.DONE ]] && [[ -f $HEALED_DIR/${caso}.cam.h4.DONE ]]
      then
         break
      fi
      sleep 600
done  

if [[ ! -f $HEALED_DIR/${caso}.NO_SPIKE ]] ; then
      ${DIR_POST}/cam/check_minima_TREFMNAV_TREFHT.sh $caso $HEALED_DIR
fi 
# TREATMENT COMPLETED
if [[ $flag -eq 1 ]] 
then
   touch $dir_cases/$caso/logs/spike_treatment_after_it_limit_${caso}_DONE
elif [[ $flag -eq 2 ]] 
then
   touch $dir_cases/$caso/logs/spike_treatment_after_C3S_detection_${caso}_DONE
fi
wkdir_cam=$SCRATCHDIR/regrid_C3S/$caso/CAM
# h2 is the file requiring more time to be postprocessed
set +euvx
. $dictionary
set -euvx
if [[ -f $check_all_postclm ]]
then
   rm $check_all_postclm
fi
if [[ -f $check_all_camC3S_done ]]
then
   rm $check_all_camC3S_done
fi
if [[ -f $check_pp_C3S ]]
then
   rm $check_pp_C3S
fi
#to handle remote cases
if [[ -f $dir_cases/$caso/logs/postproc_C3S_${caso}_DONE ]]
then
   rm $dir_cases/$caso/logs/postproc_C3S_${caso}_DONE
fi



if [[ $flag -eq 1 ]] ; then
#if recover for too many iteration, then h0 never treated by regrid
   listft_cam="h0 h1 h2 h3" 
elif [[ $flag -eq 2 ]] ; then
#if recover for spike in C3S, h0 may be skipped
   listft_cam="h1 h2 h3"
fi

for ft in ${listft_cam}
do
   if [[ -f ${check_regridC3S_type}_${ft}_DONE ]]
   then
      rm ${check_regridC3S_type}_${ft}_DONE
   fi
   case $ft in
       h0)req_mem=1000;;
       h1)req_mem=9000;;
       h2)req_mem=4000;;
       h3)req_mem=1500;;
   esac
   finalfile=$HEALED_DIR/$caso.cam.$ft.$yyyy-$st.zip.nc
   if [[ $ft == "h0" ]]
   then
       finalfile=$DIR_ARCHIVE/$caso/atm/hist/$caso.cam.$ft.$yyyy-$st.zip.nc
   fi
# $HEALED_DIR/${caso}.cam.$ft.DONE is defined in poisson_daily_values.sh
   input="$finalfile $caso $outdirC3S ${wkdir_cam} $ft $ic"
   ${DIR_UTIL}/submitcommand.sh -m $machine -q $parallelq_m -S $qos  -M ${req_mem} -j regrid_cam_${ft}_${caso} -l $dir_cases/$caso/logs/ -d ${DIR_POST}/cam -s regridFV_C3S.sh -i "$input"
            
done
#  now apply fix for isobaric level T on ft=h2 
checkfileextrap=$HEALED_DIR/logs/extrapT_${caso}_DONE
if [[ -f $checkfileextrap ]]
then
   rm $checkfileextrap
fi
inputextrap="$caso $checkfileextrap"
req_mem=8000
${DIR_UTIL}/submitcommand.sh -m $machine -q $parallelq_m -S $qos  -M ${req_mem} -p regrid_cam_h2_${caso} -j extrapT_SPS4_${caso} -l $HEALED_DIR/logs/ -d ${DIR_POST}/cam -s extrapT_SPS4.sh -i "$inputextrap"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$caso : extrapT_SPS4_${caso} submitted" -r "only" -s $yyyy$st
   
while `true`
do
   if [[ -f ${checkfileextrap} ]]
   then
      break
   fi
   sleep 120
done
while `true`
do
   if [[ `ls ${check_regridC3S_type}_h?_DONE|wc -l` -eq 4 ]]
   then
      touch $check_all_camC3S_done
      break
   fi
   sleep 60
done

while `true`
do
   if [[ `ls ${check_postclm_type}_??_DONE |wc -l` -eq 2 ]]
   then
      touch $check_all_postclm
      break
   fi
   sleep 60
done

while `true`
do
   if [[ -f $check_all_postclm ]] && [[ -f $check_iceregrid ]] && [[ -f $check_oceregrid ]] && [[ -f $check_all_camC3S_done ]]
   then
      break
   fi
   sleep 60
done
touch $dir_cases/$caso/logs/postproc_C3S_${caso}_DONE
#touch $check_pp_C3S
real="r"${member}"i00p00"
#this should be redundant after $check_pp_C3S but we keep it
allC3S=`ls $outdirC3S/*${real}.nc|wc -l`
if [[ $allC3S -eq $nfieldsC3S ]]
then
   #MUST BE ON A SERIAL to write c3s daily files on /data
   ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_l -M 3000 -S $qos -j C3Schecker_${caso} -l ${DIR_LOG}/$typeofrun/${startdate} -d ${DIR_POST}/C3S_standard -s C3Schecker.sh -i "$member $outdirC3S $startdate ${dir_cases}"
else
   if [[ $allC3S -eq $(($nfieldsC3S - 1 )) ]] && [[ -f $check_no_SOLIN ]]
   then
      body="$caso exited before C3Schecker.sh in postproc_C3S.sh because the case $caso does not contain SOLIN. Must be created"
      title="[CPS1] ERROR! postproc_C3S.sh exiting before no SOLIN in $caso"
      ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "only" -s $yyyy$st
      exit 2
   else
      body="$caso exited before C3Schecker.sh in postproc_C3S.sh because the number of postprocessed files is $allC3S instead of required $nfieldsC3S"
      title="[CPS1] ERROR! $caso exiting before $DIR_C3S/C3Schecker.sh"
      ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "only" -s $yyyy$st
      exit 1
   fi
fi

for realm in CAM CLM NEMO CICE
do
   if [[ `ls $SCRATCHDIR/regrid_C3S/$caso/$realm/*nc |wc -l` -gt 0 ]]
   then
      rm -rf $SCRATCHDIR/regrid_C3S/$caso/$realm/*nc
   fi
   if [[ $realm == "CLM" ]]
   then
         if [[ -d $SCRATCHDIR/regrid_C3S/$caso/$realm/reg1x1 ]] ; then
            if [[ `ls $SCRATCHDIR/regrid_C3S/$caso/$realm/reg1x1/*nc |wc -l` -gt 0 ]]
            then
               rm -rf $SCRATCHDIR/regrid_C3S/$caso/$realm/reg1x1/*nc
            fi
         fi
   fi
done

# now rm file not necessary for archiving
for realm in clm2 cam hydros
do
   case $realm in
        clm2)listatypes="h0 h1 h2 h3";dirname=lnd;;
        cam)listatypes="h0 h1 h2 h3 h4";dirname=atm;;
        hydros)listatypes="h0";dirname=rof;;
   esac
   for ft in $listatypes
   do
      if [[ $ft == "h0" ]]
      then
         suff=".nc"
      else
         suff="-01-00000.nc"
      fi
      n_zip=`ls $DIR_ARCHIVE/$caso/$dirname/hist/$caso.$realm.$ft.*zip.nc|wc -l`
      if [[ $n_zip -ne 0 ]]
      then
         listzip=`ls $DIR_ARCHIVE/$caso/$dirname/hist/$caso.$realm.$ft.*zip.nc`
         for ff in $listzip
         do
            rootf=`echo $ff|rev|cut -d '.' -f3-|rev`
            if [[ -f $rootf$suff ]]
            then
               rm $rootf$suff
               echo "$rootf$suff removed"
            fi
         done
      else
         n=`ls $DIR_ARCHIVE/$caso/$dirname/hist/$caso.$realm.$ft.*[0-9].nc|wc -l`
         if [[ $n -ne 0 ]]
         then
            list=`ls $DIR_ARCHIVE/$caso/$dirname/hist/$caso.$realm.$ft.*[0-9].nc`
            for ff in $list
            do
               finalf=`echo "${ff/$suff/.zip.nc}"`
               echo "compress $ff $finalf"
               ${DIR_UTIL}/compress.sh $ff $finalf
               rm $ff
               echo "$ff removed"
            done
         fi
      fi
   done   #type
done  #realm
if [[ `ls $DIR_ARCHIVE/$caso/ocn/hist/${caso}_1d_????????_????????_grid_T_0???.nc |wc -l` -ge 1 ]] ; then
  rm $DIR_ARCHIVE/$caso/ocn/hist/${caso}_1d_????????_????????_grid_T_0???.nc
fi
if [[ `ls  $DIR_ARCHIVE/$caso/ocn/hist/${caso}_1d_????????_????????_grid_EquT_T_0???.nc |wc -l` -ge 1 ]] ; then
   rm $DIR_ARCHIVE/$caso/ocn/hist/${caso}_1d_????????_????????_grid_EquT_T_0???.nc
fi
if [[ `ls $DIR_ARCHIVE/$caso/rest/????-??-01-00000/ic_for_${caso}_00000001_restart.nc |wc -l` -ge 1 ]] ; then
   rm $DIR_ARCHIVE/$caso/rest/????-??-01-00000/ic_for_${caso}_00000001_restart.nc
fi
if [[ -d $DIR_TEMP/$caso ]]
then
   rm -rf $DIR_TEMP/$caso
fi
chmod -R u-w $DIR_ARCHIVE/$caso/


echo "Done."

exit 0
