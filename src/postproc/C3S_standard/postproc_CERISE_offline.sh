#!/bin/sh -l 

# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. ${DIR_UTIL}/descr_ensemble.sh 1993  #THIS SCRIPT SHOULD RUN
                                      #ONLY FOR HINDCASTS
. $DIR_UTIL/load_nco
#. $DIR_UTIL/load_cdo

set -evxu

caso=$1
dir_cases=$2
dbg=$3

st=`echo $caso|cut -d '_' -f2 |cut -c5-6`
yyyy=`echo $caso|cut -d '_' -f2 |cut -c1-4`
#
startdate=$yyyy$st
ens=`echo $caso|cut -d '_' -f 3 `
member=`echo $ens|cut -c2,3` 


#chmod -R u+w $DIR_ARCHIVE1/$caso
ic=`ncdump -h $DIR_ARCHIVE1/$caso/atm/hist/$caso.cam.h0.$yyyy-$st.zip.nc|grep "ic ="|cut -d '=' -f2-|cut -d ';' -f1 |cut -d '"' -f2`

# get check_qa_start from dictionary
# directory creation
outdirCERISE=${WORK_CERISE}/$yyyy$st/
set +euvx
. $dictionary
set -euvx
mkdir -p $outdirCERISE
mkdir -p $dir_cases/$caso/logs
dirlog=$dir_cases/$caso/logs
#***********************************************************************
# Standardization for CLM 
#***********************************************************************
wkdir_clm=$SCRATCHDIR/regrid_CERISE/$caso/CLM
mkdir -p ${wkdir_clm}
# get check_postclm  from dictionary

if [[ ! -f $check_all_postclm ]]
then
  
   cd ${wkdir_clm}
   filetyp="h2 h3"
   for ft in $filetyp ; do

       case $ft in
           h2) mult=1 ; req_mem=20000 ;;
           h3) mult=1 ; req_mem=1000;; # for land both h1 and h3 are daily (h1 averaged and h3 instantaneous), multiplier=1
       esac
       flag_for_type=${check_postclm_type}_${ft}_DONE
#       finalfile_clm=$HEALED_DIR_ROOT1/$caso/$caso.clm2.$ft.$yyyy-$st.zip.nc
       finalfile_clm=$DIR_ARCHIVE1/$caso/lnd/hist/$caso.clm2.$ft.$yyyy-$st.zip.nc
       if [[ ! -f $finalfile_clm ]]
       then
          body="$finalfile_clm does not exist"
          title="[CPS1] ERROR! postproc_CERISE.sh in $caso"
          ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" 
          exit

       else
       # meaning that preproc files have been done by create_clm_files.sh
       # so submit without dependency
        
          echo "start of postpc_clm "`date`

          input="${finalfile_clm} $ens $startdate $outdirCERISE $caso ${flag_for_type} ${wkdir_clm} $ic $ft"
          # ADD the reservation for serial !!!
          ${DIR_UTIL}/submitcommand.sh -m $machine -q $parallelq_m -M ${req_mem} -S qos_resv  -j postpc_clm_CERISE_${ft}_${caso} -l $dir_cases/$caso/logs/ -d ${DIR_POST}/clm -s postpc_clm_CERISE.sh -i "$input"
       fi
   done

   while `true`
   do
       if [[ `ls ${check_postclm_type}_??_DONE |wc -l` -eq 2 ]]
       then
          #touch $dir_cases/$caso/logs/${caso}_clm_C3SDONE
          touch $check_all_postclm
          break
       fi  
       sleep 60
    done   

fi

   while `true`
   do
       if [[ `ls ${check_postclm_type}_??_DONE |wc -l` -eq 2 ]]
       then
          #touch $dir_cases/$caso/logs/${caso}_clm_C3SDONE
          touch $check_all_postclm
          break
       fi
       sleep 60
    done

#***********************************************************************
# Cam files archiving
#***********************************************************************
# Standardization for CAM 
#***********************************************************************
wkdir_cam=$SCRATCHDIR/regrid_CERISE/$caso/CAM
mkdir -p ${wkdir_cam}
#get check_all_camC3S_done from dictionary
#if [[ ! -f $check_all_camC3S_done ]]
#if [[ ! -f $dir_cases/$caso/logs/${caso}_all_cam_C3SDONE ]]
if [[ ! -f $check_all_camC3S_done ]]
then
   filetyp="h1 h4 h2 h3"
   for ft in $filetyp
   do
      case $ft in
          h1)req_mem=6000;;
          h2)req_mem=4000;;
          h3)req_mem=3000;;
          h4)req_mem=5000;;
      esac
   #get check_regridC3S_type from dictionary
      if [[ -f ${check_regridC3S_type}_${ft}_DONE ]]
      then
   # meaning that preproc files have been done by create_cam_files.sh
   # and regridded by regridFV_C3S.sh
         continue
      fi
#      finalfile=$HEALED_DIR_ROOT1/$caso/$caso.cam.$ft.$yyyy-$st.zip.nc
      finalfile=$DIR_ARCHIVE1/$caso/atm/hist/$caso.cam.$ft.$yyyy-$st.zip.nc
      if [[ ! -f $finalfile ]]
      then
          body="$finalfile does not exist"
          title="[CPS1] ERROR! postproc_CERISE.sh in $caso"
          ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" 
          exit
      else
   # meaning that preproc files have been done by create_cam_files.sh
   # so submit without dependency
         input="$finalfile $caso $outdirCERISE ${wkdir_cam} $ft $ic"
             # ADD the reservation for serial !!!
         ${DIR_UTIL}/submitcommand.sh -m $machine -q $parallelq_m -S qos_resv  -M ${req_mem} -j regrid_cam_${ft}_${caso} -l $dir_cases/$caso/logs/ -d ${DIR_POST}/cam -s regridFV_CERISE.sh -i "$input"
      fi
            
   done
   
   # now wait that all of the ft files have been regridded
   while `true`
   do
      if [[ `ls ${check_regridC3S_type}_h?_DONE|wc -l` -eq 4 ]]
      then
         touch $check_all_camC3S_done
#         touch $dir_cases/$caso/logs/${caso}_all_cam_C3SDONE
         break
      fi
      sleep 60
   done
fi # if on $check_all_camC3S_done 

while `true`
do
   if [[ -f $check_all_postclm ]] && [[ -f $check_all_camC3S_done ]]
#   if [[ -f $dir_cases/$caso/logs/${caso}_clm_C3SDONE ]] && [[ -f $check_iceregrid ]] && [[ -f $check_oceregrid ]] && [[ -f $dir_cases/$caso/logs/${caso}_all_cam_C3SDONE ]]
   then
      break
   fi
   sleep 60
done
#touch $check_pp_C3S
touch $dir_cases/$caso/logs/postproc_CERISE_${caso}_DONE
real="r"${member}"i00p00"
#this should be redundant after $check_pp_C3S but we keep it
exit

# test up to here

allC3S=`ls $outdirCERISE/*${real}.nc|wc -l`
if [[ $allC3S -eq $nfieldsC3S ]] 
then
   #MUST BE ON A SERIAL to write c3s daily files on /data
   ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_l -M 3000 -S qos_resv -j C3Schecker_${caso} -l ${DIR_LOG}/$typeofrun/${startdate} -d ${DIR_POST}/C3S_standard -s C3Schecker.sh -i "$member $outdirCERISE $startdate"
else
   if [[ $allC3S -eq $(($nfieldsC3S - 1 )) ]] && [[ -f $check_no_SOLIN ]]
   then
      body="$caso exited before C3Schecker.sh in postproc_CERISE.sh because the case $caso does not contain SOLIN. Must be created"
      title="[CPS1] ERROR! postproc_CERISE.sh exiting before no SOLIN in $caso"
      ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "only" -s $yyyy$st
      exit 2
   else
      body="$caso exited before C3Schecker.sh in postproc_CERISE.sh because the number of postprocessed files is $allC3S instead of required $nfieldsC3S"
      title="[CPS1] ERROR! $caso exiting before $DIR_C3S/C3Schecker.sh"
      ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "only" -s $yyyy$st
      exit 1
   fi
fi

if [[ $dbg -eq 1 ]]
then
   exit
fi
input="$caso"
${DIR_UTIL}/submitcommand.sh -m $machine -q $parallelq_m -S qos_resv  -M ${req_mem} -j c3s2cerise_${caso} -l $dir_cases/$caso/logs/ -d ${DIR_C3S} -s c3s2cerise.sh -i "$input"
for realm in CAM CLM
do
   if [[ `ls $SCRATCHDIR/regrid_CERISE/$caso/$realm/*nc |wc -l` -gt 0 ]]
   then
      rm -rf $SCRATCHDIR/regrid_CERISE/$caso/$realm/*nc
   fi  
   if [[ $realm == "CLM" ]]
   then
         if [[ -d $SCRATCHDIR/regrid_CERISE/$caso/$realm/reg1x1 ]] ; then
            if [[ `ls $SCRATCHDIR/regrid_CERISE/$caso/$realm/reg1x1/*nc |wc -l` -gt 0 ]]
            then
               rm -rf $SCRATCHDIR/regrid_CERISE/$caso/$realm/reg1x1/*nc
            fi
         fi  
   fi  
done

echo "Done."

exit 0

