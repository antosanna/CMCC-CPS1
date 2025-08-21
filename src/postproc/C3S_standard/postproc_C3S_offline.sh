#!/bin/sh -l 

# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. ${DIR_UTIL}/load_nco                # to get command $compress
. ${DIR_UTIL}/descr_ensemble.sh $1  #THIS SCRIPT SHOULD RUN
                                      #ONLY FOR HINDCASTS

set -evxu

caso=$2
# only in this special case DIR_CASES must be redefined for it can be different
# for the different machines the case could have been done on.
dir_cases=$3
# this modification will affect $dictionary too!!!!

st=`echo $caso|cut -d '_' -f2 |cut -c5-6`
yyyy=`echo $caso|cut -d '_' -f2 |cut -c1-4`
#
startdate=$yyyy$st
ens=`echo $caso|cut -d '_' -f 3 `
member=`echo $ens|cut -c2,3` 

HEALED_DIR=$HEALED_DIR_ROOT/$caso
#HEALED_DIR_ROOT=/work/cmcc/cp1/CPS/CMCC-CPS1/fixed_from_spikes/
# THIS MUST BE KEPT FOR CERISE
chmod -R u+w $DIR_ARCHIVE/$caso
ic=`ncdump -h $DIR_ARCHIVE/$caso/atm/hist/$caso.cam.h0.$yyyy-$st.zip.nc|grep "ic ="|cut -d '=' -f2-|cut -d ';' -f1 |cut -d '"' -f2`

outdirC3S=${WORK_C3S}/$yyyy$st/

set +euvx
. $dictionary
set -euvx
mkdir -p $outdirC3S
dirlog=$dir_cases/$caso/logs
mkdir -p $dirlog

#***********************************************************************
# Standardization for NEMO 
#***********************************************************************
mkdir -p $SCRATCHDIR/regrid_C3S/$caso/NEMO
if [[ ! -f $check_oceregrid ]]
then
    sed -e "s:CASO:$caso:g;s:IC:$ic:g;s:OUTDIRC3S:$outdirC3S:g" $DIR_POST/nemo/interp_ORCA2_1X1_gridT2C3S_template.sh > $dir_cases/$caso/interp_ORCA2_1X1_gridT2C3S_${caso}.sh
    chmod u+x $dir_cases/$caso/interp_ORCA2_1X1_gridT2C3S_${caso}.sh

    ${DIR_UTIL}/submitcommand.sh -m $machine -q $parallelq_m -S qos_resv -M 7500 -j interp_ORCA2_1X1_gridT2C3S_${caso} -l $dir_cases/$caso/logs/ -d ${dir_cases}/$caso -s interp_ORCA2_1X1_gridT2C3S_${caso}.sh -i "$dirlog"

fi
# 
#***********************************************************************
# Standardization for CICE 
#***********************************************************************
mkdir -p $SCRATCHDIR/regrid_C3S/$caso/CICE
if [[ ! -f $check_iceregrid ]]
then
   sed -e "s:CASO:$caso:g;s:ICs:$ic:g;s:OUTDIRC3S:$outdirC3S:g" $DIR_POST/cice/interp_cice2C3S_template.sh > $dir_cases/$caso/interp_cice2C3S_${caso}.sh
   chmod u+x $dir_cases/$caso/interp_cice2C3S_${caso}.sh
    ${DIR_UTIL}/submitcommand.sh -m $machine -q $parallelq_s -S qos_resv -M 4000 -j interp_cice2C3S_${caso} -l $dir_cases/$caso/logs/ -d ${dir_cases}/$caso -s interp_cice2C3S_${caso}.sh
fi

#***********************************************************************
# Standardization for CLM
#***********************************************************************
wkdir_clm=$SCRATCHDIR/regrid_C3S/$caso/CLM
mkdir -p ${wkdir_clm}
# get check_postclm  from dictionary

if [[ ! -f $check_all_postclm ]]
then

   cd ${wkdir_clm}
   filetyp="h1 h2 h3"
   jobIDall=""
   for ft in $filetyp ; do

       case $ft in
           h1) mult=1 ; req_mem=50000 ;;
           h2) mult=4 ; req_mem=20000 ;;
           h3) mult=1 ; req_mem=5000;; # for land both h1 and h3 are daily (h1 averaged and h3 instantaneous), multiplier=1
       esac
       flag_for_type=${check_postclm_type}_${ft}_DONE
       finalfile_clm=$DIR_ARCHIVE/$caso/lnd/hist/$caso.clm2.$ft.$yyyy-$st.zip.nc
       input="$caso $ft ${wkdir_clm} ${finalfile_clm} ${flag_for_type} $ic $mult"
       ${DIR_UTIL}/submitcommand.sh -m $machine -q $parallelq_m -S qos_resv  -M ${req_mem} -j create_clm_files_${ft}_${caso} -l ${dir_cases}/$caso/logs/ -d ${DIR_POST}/clm -s create_clm_files.sh -i "$input"
       jobIDall+=" `${DIR_UTIL}/findjobs.sh -m $machine -n create_clm_files_${ft}_${caso} -i yes`"
       if [[ $ft == "h2" ]]
       then
# contains additional variables for CERISE, not operational
          continue
       fi
       echo "start of postpc_clm "`date`
       finalfile_clm=$DIR_ARCHIVE/$caso/lnd/hist/$caso.clm2.$ft.$yyyy-$st.zip.nc
       input="${finalfile_clm} $ens $startdate $outdirC3S $caso ${flag_for_type} ${wkdir_clm} $ic $ft"
       # ADD the reservation for serial !!!
       ${DIR_UTIL}/submitcommand.sh -m $machine -q $parallelq_l -M ${req_mem} -p create_clm_files_${ft}_${caso} -S qos_resv -j postpc_clm_${ft}_${caso} -l $dir_cases/$caso/logs/ -d ${DIR_POST}/clm -s postpc_clm.sh -i "$input"
   done
fi


#***********************************************************************
# Cam files archiving
#***********************************************************************
# Standardization for CAM 
#***********************************************************************
wkdir_cam=$SCRATCHDIR/regrid_C3S/$caso/CAM
mkdir -p ${wkdir_cam}
if [[ ! -f $check_all_camC3S_done ]]
then
   jobIDall_cam=""
   filetyp="h0 h1 h2 h3 h4"
   for ft in $filetyp
   do
      finalfile=$DIR_ARCHIVE/$caso/atm/hist/$caso.cam.$ft.$yyyy-$st.zip.nc
      inputfile=$DIR_ARCHIVE/$caso/atm/hist/$caso.cam.$ft.$yyyy-$st-01-00000.nc
      input="$caso $ft ${wkdir_cam} $finalfile $ic" 
      ${DIR_UTIL}/submitcommand.sh -m $machine -q $parallelq_m -S qos_resv -M 4000 -j create_cam_files_${ft}_${caso} -l $dir_cases/$caso/logs/ -d ${DIR_POST}/cam -s create_cam_files.sh -i "$input"
      jobIDall_cam+=" `${DIR_UTIL}/findjobs.sh -m $machine -n create_cam_files_${ft}_${caso} -i yes`"
   done
# before running this script it maybe happen that clean4C3S.sh has been run so those flags might have been deleted
#   while [[ ! -f ${check_merge_cam_files}_h1 ]] || [[ ! -f ${check_merge_cam_files}_h2 ]] || [[ ! -f ${check_merge_cam_files}_h3 ]]
   while [[ `${DIR_UTIL}/findjobs.sh -N ${caso} -n create_cam_files -c yes` -ne 0 ]]
   do
      sleep 60 #for test
      #sleep 600
   done   
   for jobid in $jobIDall_cam
   do
       if [[ `${DIR_UTIL}/findjobs.sh -j $jobid -a EXIT |wc -w` -ne 0 ]] 
       then
          ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$jobid create_cam_files exited" -t "[C3S] ERROR: ${caso} create cam exited" 
          exit 1
       fi
   done
             #now fix for spikes on $HEALED_DIR
             # we want to archive the DMO with spikes
             # this is an iterative procedure that might requires a few cycles (up to 3 I guess)
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
   input="$caso $dir_cases"
# now moved to $DIR_C3S from $DIR_POST/cam since it heals also clm files
   ${DIR_UTIL}/submitcommand.sh -m $machine -q $parallelq_m -S qos_resv -M 40000 -j fix_spikes_DMO_single_member_cam.h3_${caso} -l $dir_cases/$caso/logs/ -d ${DIR_C3S} -s fix_spikes_DMO_single_member.sh -i "$input"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "submitted" -t "fix_spikes_DMO_single_member_cam.h3_${caso} submitted" -r "only" -s $yyyy$st
   while `true`
   do
      if [ -f $HEALED_DIR/${caso}.cam.h1.DONE -a -f $HEALED_DIR/${caso}.cam.h2.DONE -a -f $HEALED_DIR/${caso}.cam.h3.DONE -a -f $HEALED_DIR/${caso}.cam.h4.DONE ] || [ -f $HEALED_DIR/${caso}.too_many_it.EXIT ]
      then
         break
      fi
      sleep 600
   done  
   if [[ -f $HEALED_DIR/${caso}.too_many_it.EXIT ]]
   then
      exit
   fi

   if [[ ! -f $HEALED_DIR/${caso}.NO_SPIKE ]] ; then
      ${DIR_POST}/cam/check_minima_TREFMNAV_TREFHT.sh $caso $HEALED_DIR
   fi 
# TREATMENT COMPLETED
   touch $dir_cases/$caso/logs/spike_treatment_${caso}_DONE
# h2 is the file requiring more time to be postprocessed
   for ft in h0 h1 h3 h2
   do
      
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
             # ADD the reservation for serial !!!
      ${DIR_UTIL}/submitcommand.sh -m $machine -q $parallelq_m -S qos_resv  -M ${req_mem} -j regrid_cam_${ft}_${caso} -l $dir_cases/$caso/logs/ -d ${DIR_POST}/cam -s regridFV_C3S.sh -i "$input"
            
   done
#  now apply fix for isobaric level T on ft=h2 
   checkfileextrap=$HEALED_DIR/logs/extrapT_${caso}_DONE
   inputextrap="$caso $checkfileextrap"
   req_mem=8000
   ${DIR_UTIL}/submitcommand.sh -m $machine -q $parallelq_m -S qos_resv  -M ${req_mem} -p regrid_cam_h2_${caso} -j extrapT_SPS4_${caso} -l $HEALED_DIR/logs/ -d ${DIR_POST}/cam -s extrapT_SPS4.sh -i "$inputextrap"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "submitted" -t "extrapT_SPS4_${caso} submitted" -r "only" -s $yyyy$st
   
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
fi # if on $check_all_camC3S_done 

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
#
#check_pp_C3S=$DIR_CASES/$caso/logs/postproc_C3S_${caso}_DONE - it is $check_pp_C3S in dictionary, here explicit for remote cases
touch $dir_cases/$caso/logs/postproc_C3S_${caso}_DONE 

real="r"${member}"i00p00"
#this should be redundant after $check_pp_C3S but we keep it
allC3S=`ls $outdirC3S/*${real}.nc|wc -l`
if [[ $allC3S -eq $nfieldsC3S ]]
then
   #MUST BE ON A SERIAL to write c3s daily files on /data
   ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_l -M 3000 -S qos_resv -j C3Schecker_${caso} -l ${DIR_LOG}/$typeofrun/${startdate} -d ${DIR_POST}/C3S_standard -s C3Schecker.sh -i "$member $outdirC3S $startdate $dir_cases"
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
               $compress $ff $finalf
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
chmod u-w -R $DIR_ARCHIVE/$caso/


echo "Done."

exit 0
