#!/bin/sh -l 

# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. ${DIR_UTIL}/descr_ensemble.sh 1993  #THIS SCRIPT SHOULD RUN
                                      #ONLY FOR HINDCASTS
#. $DIR_UTIL/load_nco
#. $DIR_UTIL/load_cdo

set -evxu

caso=$1
dir_cases_remote=$2

st=`echo $caso|cut -d '_' -f2 |cut -c5-6`
yyyy=`echo $caso|cut -d '_' -f2 |cut -c1-4`
#
startdate=$yyyy$st
ens=`echo $caso|cut -d '_' -f 3 `
member=`echo $ens|cut -c2,3` 


chmod -R u+w $DIR_ARCHIVE/$caso
ic=`ncdump -h $DIR_ARCHIVE/$caso/atm/hist/$caso.cam.h0.$yyyy-$st.zip.nc|grep "ic ="|cut -d '=' -f2-|cut -d ';' -f1`

# get check_qa_start from dictionary
# directory creation
outdirC3S=${WORK_C3S}/$yyyy$st/
set +euvx
. $dictionary
set -euvx
mkdir -p $outdirC3S
mkdir -p $dir_cases_remote/$caso/logs

# get   check_oceregrid from dictionary
mkdir -p $SCRATCHDIR/regrid_C3S/$caso/NEMO
if [[ ! -f $check_oceregrid ]]
then
    sed -e "s:CASO:$caso:g;s:IC:$ic:g;s:OUTDIRC3S:$outdirC3S:g" $DIR_POST/nemo/interp_ORCA2_1X1_gridT2C3S_template.sh > $dir_cases_remote/$caso/interp_ORCA2_1X1_gridT2C3S_${caso}.sh
    chmod u+x $dir_cases_remote/$caso/interp_ORCA2_1X1_gridT2C3S_${caso}.sh
    ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_s -S qos_resv -M 8000 -j interp_ORCA2_1X1_gridT2C3S_${caso} -l $dir_cases_remote/$caso/logs/ -d ${dir_cases_remote}/$caso -s interp_ORCA2_1X1_gridT2C3S_${caso}.sh 

fi
# get   check_iceregrid from dictionary
mkdir -p $SCRATCHDIR/regrid_C3S/$caso/CICE
if [[ ! -f $check_iceregrid ]]
then
   sed -e "s:CASO:$caso:g;s:ICs:$ic:g;s:OUTDIRC3S:$outdirC3S:g" $DIR_POST/cice/interp_cice2C3S_template.sh > $dir_cases_remote/$caso/interp_cice2C3S_${caso}.sh
   chmod u+x $dir_cases_remote/$caso/interp_cice2C3S_${caso}.sh
    ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_s -S qos_resv -M 4000 -j interp_cice2C3S_${caso} -l $dir_cases_remote/$caso/logs/ -d ${dir_cases_remote}/$caso -s interp_cice2C3S_${caso}.sh 
fi 

#***********************************************************************
# Standardization for CLM 
#***********************************************************************
wkdir_clm=$SCRATCHDIR/regrid_C3S/$caso/CLM
mkdir -p ${wkdir_clm}
# get check_postclm  from dictionary

#if [[ ! -f $check_postclm ]]
if [[ ! -f $dir_cases_remote/$caso/logs/${caso}_clm_C3SDONE ]]
then
  
   cd ${wkdir_clm}
   ft="h1"
   case $ft in
       h1 ) mult=1 ;; # for land h1 is daily, multiplier=1
   esac
   finalfile_clm=$DIR_ARCHIVE/$caso/lnd/hist/$caso.clm2.$ft.$yyyy-$st.zip.nc
   if [[ ! -f $finalfile_clm ]]
   then

        input="$caso $ft $yyyy $st ${wkdir_clm} ${finalfile_clm} $dir_cases_remote/$caso/logs/${caso}_clm_C3SDONE $ic"
        # ADD the reservation for serial !!!
        ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_m -S qos_resv -t "24" -M 5000 -j create_clm_files_${ft}_${caso} -l ${dir_cases_remote}/$caso/logs/ -d ${DIR_POST}/clm -s create_clm_files.sh -i "$input"
        

        echo "start of postpc_clm "`date`
#        input="${finalfile_clm} $ens $startdate $outdirC3S $caso $check_postclm ${wkdir_clm} 0"
        input="${finalfile_clm} $ens $startdate $outdirC3S $caso $dir_cases_remote/$caso/logs/${caso}_clm_C3SDONE ${wkdir_clm} $ic"
        # ADD the reservation for serial !!!
        ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_l -M 12000 -S qos_resv -t "24" -p create_clm_files_${ft}_${caso} -j postpc_clm_${caso} -l $dir_cases_remote/$caso/logs/ -d ${DIR_POST}/clm -s postpc_clm.sh -i "$input"

   else
    # meaning that preproc files have been done by create_clm_files.sh
    # so submit without dependency
        
        echo "start of postpc_clm "`date`
        input="${finalfile_clm} $ens $startdate $outdirC3S $caso $dir_cases_remote/$caso/logs/${caso}_clm_C3SDONE ${wkdir_clm} $ic"
        # ADD the reservation for serial !!!
        ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_l -M 12000 -S qos_resv -t "24" -j postpc_clm_${caso} -l $dir_cases_remote/$caso/logs/ -d ${DIR_POST}/clm -s postpc_clm.sh -i "$input"
   fi
fi


#***********************************************************************
# Cam files archiving
#***********************************************************************
# Standardization for CAM 
#***********************************************************************
wkdir_cam=$SCRATCHDIR/regrid_C3S/$caso/CAM
mkdir -p ${wkdir_cam}
#get check_all_camC3S_done from dictionary
#if [[ ! -f $check_all_camC3S_done ]]
if [[ ! -f $dir_cases_remote/$caso/logs/${caso}_all_cam_C3SDONE ]]
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
         ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_m -S qos_resv -t "24" -M 4000 -j create_cam_files_${ft}_${caso} -l $dir_cases_remote/$caso/logs/ -d ${DIR_POST}/cam -s create_cam_files.sh -i "$input"
         input="$finalfile $caso $outdirC3S ${wkdir_cam} $ft"
             # ADD the reservation for serial !!!
         ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_m -S qos_resv -t "24" -M ${req_mem} -p create_cam_files_${ft}_${caso} -j regrid_cam_${ft}_${caso} -l $dir_cases_remote/$caso/logs/ -d ${DIR_POST}/cam -s regridFV_C3S.sh -i "$input"
      else
   # meaning that preproc files have been done by create_cam_files.sh
   # so submit without dependency
         input="$finalfile $caso $outdirC3S ${wkdir_cam} $ft"
             # ADD the reservation for serial !!!
         ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_m -S qos_resv -t "24" -M ${req_mem} -j regrid_cam_${ft}_${caso} -l $dir_cases_remote/$caso/logs/ -d ${DIR_POST}/cam -s regridFV_C3S.sh -i "$input"
      fi
            
   done
   
   # now wait that all of the ft files have been regridded
   while `true`
   do
      if [[ `ls ${check_regridC3S_type}_h?_DONE|wc -l` -eq 4 ]]
      then
#         touch $check_all_camC3S_done
         touch $dir_cases_remote/$caso/logs/${caso}_all_cam_C3SDONE
         break
      fi
      sleep 60
   done
fi # if on $check_all_camC3S_done 
while `true`
do
#   if [[ -f $check_postclm ]] && [[ -f $check_iceregrid ]] && [[ -f $check_oceregrid ]] && [[ -f $check_all_camC3S_done ]]
   if [[ -f $dir_cases_remote/$caso/logs/${caso}_clm_C3SDONE ]] && [[ -f $check_iceregrid ]] && [[ -f $check_oceregrid ]] && [[ -f $dir_cases_remote/$caso/logs/${caso}_all_cam_C3SDONE ]]
   then
      break
   fi
   sleep 60
done
#touch $check_pp_C3S
touch $dir_cases_remote/$caso/logs/postproc_C3S_${caso}_DONE
real="r"${member}"i00p00"
#this should be redundant after $check_pp_C3S but we keep it
allC3S=`ls $outdirC3S/*${real}.nc|wc -l`
if [[ $allC3S -eq $nfieldsC3S ]] 
then
   ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_l -M 3000 -t "24" -S qos_resv -j C3Schecker_${caso} -l ${DIR_LOG}/$typeofrun/${startdate} -d ${DIR_POST}/C3S_standard -s C3Schecker.sh -i "$member $outdirC3S $startdate $caso"
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
# now rm file not necessary for archiving
# NOT SURE WE NEED
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
if [[ -d $SCRATCHDIR/regrid_C3S/$caso ]]
then
   rm -rf $SCRATCHDIR/regrid_C3S/$caso
fi
echo "Done."

exit 0

