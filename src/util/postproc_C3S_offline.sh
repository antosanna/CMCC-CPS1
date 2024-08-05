#!/bin/sh -l 

# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

set -evxu

caso=$1
ic="`cat $DIR_CASES/$caso/logs/ic_${caso}.txt`"

st=`echo $caso|cut -d '_' -f2 |cut -c5-6`
yyyy=`echo $caso|cut -d '_' -f2 |cut -c1-4`
set +euvx
   . ${DIR_UTIL}/descr_ensemble.sh $yyyy
set -euvx
#
startdate=$yyyy$st
ens=`echo $caso|cut -d '_' -f 3 `
member=`echo $ens|cut -c2,3` 

set +euvx
. $dictionary
set -euvx

# directory creation
outdirC3S=${WORK_C3S}/$yyyy$st/
mkdir -p $outdirC3S

# get   check_oceregrid from dictionary
mkdir -p $SCRATCHDIR/regrid_C3S/$caso/NEMO
if [[ ! -f $check_oceregrid ]]
then
    ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_s -S qos_resv -M 8000 -j interp_ORCA2_1X1_gridT2C3S_${caso} -l $DIR_CASES/$caso/logs/ -d ${DIR_CASES}/$caso -s interp_ORCA2_1X1_gridT2C3S_${caso}.sh 

fi
# get   check_iceregrid from dictionary
mkdir -p $SCRATCHDIR/regrid_C3S/$caso/CICE
if [ ! -f $check_iceregrid ]
then
    ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_s -S qos_resv -M 4000 -j interp_cice2C3S_${caso} -l $DIR_CASES/$caso/logs/ -d ${DIR_CASES}/$caso -s interp_cice2C3S_${caso}.sh 
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
   filetyp="h1 h3"
   for ft in $filetyp ; do

      case $ft in
          h1 ) mult=1 ;; # for land h1 is daily, multiplier=1
          h3 ) mult=1 ;; # for land h3 is daily, multiplier=1
      esac
      flag_for_type=${check_postclm_type}_${ft}_DONE
      finalfile_clm=$DIR_ARCHIVE/$caso/lnd/hist/$caso.clm2.$ft.$yyyy-$st.zip.nc
      if [[ ! -f $finalfile_clm ]]
      then
            input="$caso $ft $yyyy $st ${wkdir_clm} ${finalfile_clm} ${flag_for_type} $ic"
            # ADD the reservation for serial !!!
            ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_m -S qos_resv -t "24" -M 5000 -j create_clm_files_${ft}_${caso} -l ${DIR_CASES}/$caso/logs/ -d ${DIR_POST}/clm -s create_clm_files.sh -i "$input"

           echo "start of postpc_clm "`date`
           input="${finalfile_clm} $ens $startdate $outdirC3S $caso ${flag_for_type} ${wkdir_clm} $ic $ft"  
           # ADD the reservation for serial !!!
           ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_l -M 12000 -S qos_resv -t "24" -p create_clm_files_${ft}_${caso} -j postpc_clm_${ft}_${caso} -l $DIR_CASES/$caso/logs/ -d ${DIR_POST}/clm -s postpc_clm.sh -i "$input"
      else
           echo "start of postpc_clm "`date`
           input="${finalfile_clm} $ens $startdate $outdirC3S $caso ${flag_for_type} ${wkdir_clm} $ic $ft"
           # ADD the reservation for serial !!!
           ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_l -M 12000 -S qos_resv -t "24" -j postpc_clm_${ft}_${caso} -l $DIR_CASES/$caso/logs/ -d ${DIR_POST}/clm -s postpc_clm.sh -i "$input"
      fi
    done 
    while `true`
    do
       if [[ `ls ${check_postclm_type}_??_DONE |wc -l` -eq 2 ]]
       then
          touch ${check_all_postclm}
          break
       fi  
       sleep 60
    done   
 
fi


#***********************************************************************
# Cam files archiving
#***********************************************************************
# Standardization for CAM 
#***********************************************************************
wkdir_cam=$SCRATCHDIR/regrid_C3S/$caso/CAM
mkdir -p ${wkdir_cam}
#get check_all_camC3S_done from dictionary
if [[ ! -f $check_all_camC3S_done ]]
then
   filetyp="h0 h1 h2 h3"
   for ft in $filetyp
   do
      case $ft in
          h0)req_mem=500;;
          h1)req_mem=9000;;
          h2)req_mem=4000;;
          h3)req_mem=1500;;
      esac
   #get check_regridC3S_type from dictionary
      if [[ -f ${check_regridC3S_type}_${ft}_DONE ]]
      then
   # meaning that preproc files have been done by create_cam_files.sh
   # and regridded by regridFV_C3S.sh
         continue
      fi
      finalfile=$DIR_ARCHIVE/$caso/atm/hist/$caso.cam.$ft.$yyyy-$st.zip.nc
      if [[ ! -f $finalfile ]]
      then
         input="$caso $ft $yyyy $st $member ${wkdir_cam} $finalfile $ic" 
             # ADD the reservation for serial !!!
         ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_m -S qos_resv -t "24" -M 4000 -j create_cam_files_${ft}_${caso} -l $DIR_CASES/$caso/logs/ -d ${DIR_POST}/cam -s create_cam_files.sh -i "$input"
         input="$finalfile $caso $outdirC3S ${wkdir_cam} $ft"
             # ADD the reservation for serial !!!
         ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_m -S qos_resv -t "24" -M ${req_mem} -p create_cam_files_${ft}_${caso} -j regrid_cam_${ft}_${caso} -l $DIR_CASES/$caso/logs/ -d ${DIR_POST}/cam -s regridFV_C3S.sh -i "$input"
      else
   # meaning that preproc files have been done by create_cam_files.sh
   # so submit without dependency
         input="$finalfile $caso $outdirC3S ${wkdir_cam} $ft"
             # ADD the reservation for serial !!!
         ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_m -S qos_resv -t "24" -M ${req_mem} -j regrid_cam_${ft}_${caso} -l $DIR_CASES/$caso/logs/ -d ${DIR_POST}/cam -s regridFV_C3S.sh -i "$input"
      fi
            
   done
   
   # now wait that all of the ft files have been regridded
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
   if [[ -f $check_all_postclm ]] && [[ -f $check_iceregrid ]] && [[ -f $check_oceregrid ]] && [[ -f $check_all_camC3S_done ]]
   then
      break
   fi
   sleep 60
done
touch $check_pp_C3S
real="r"${member}"i00p00"
#this should be redundant after $check_pp_C3S but we keep it
allC3S=`ls $outdirC3S/*${real}.nc|wc -l`
if [[ $allC3S -eq $nfieldsC3S ]] 
then
   ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_l -M 3000 -t "24" -S qos_resv -j C3Schecker_${caso} -l ${DIR_LOG}/$typeofrun/${startdate} -d ${DIR_POST}/C3S_standard -s C3Schecker.sh -i "$member $outdirC3S $startdate"
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
#***********************************************************************
if [ -d $WORK_CPS/$caso ]
then
  cd $WORK_CPS/$caso
  rm -rf run
  rm -rf bld
  cd $WORK_CPS
  rmdir $caso
fi
# now rm file not necessary for archiving
if [[ `ls $DIR_ARCHIVE/$caso/rof/hist/$caso.hydros.h0.????-??.nc |wc -l` -ge 1 ]] ; then
   rm $DIR_ARCHIVE/$caso/rof/hist/$caso.hydros.h0.????-??.nc
fi
if [[ `ls  $DIR_ARCHIVE/$caso/lnd/hist/$caso.clm2.h0.????-??.nc |wc -l` -ge 1 ]] ; then
   rm $DIR_ARCHIVE/$caso/lnd/hist/$caso.clm2.h0.????-??.nc
fi
if [[ `ls $DIR_ARCHIVE/$caso/atm/hist/$caso.cam.h0.????-??.nc |wc -l` -ge 1 ]] ; then
   rm $DIR_ARCHIVE/$caso/atm/hist/$caso.cam.h0.????-??.nc
fi
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
#
for realm in CAM CLM NEMO CICE
do
   if [[ `ls $SCRATCHDIR/regrid_C3S/$caso/$realm/*nc |wc -l` -gt 0 ]]
   then
      rm -rf $SCRATCHDIR/regrid_C3S/$caso/$realm/*nc
   fi  
done

echo "Done."

exit 0

