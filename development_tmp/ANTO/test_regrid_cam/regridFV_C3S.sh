#!/bin/sh -l
##BSUB -P 0490
##BSUB -J test
##BSUB -e logs/test_%J.err
##BSUB -o logs/test_%J.out
# this script can be run in dbg mode but always with submitcommand
# THIS HAS TO BE REVIEWED!!!!!!
. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/load_ncl
. $DIR_UTIL/load_nco
set -euvx

#==================================================
mymail=antonella.sanna@cmcc.it
yyyy=1993
st=01
caso=sps4_${yyyy}${st}_001
export inputFV=$DIR_ARCHIVE1/$caso/atm/hist/$caso.cam.h4.${yyyy}-${st}.zip.nc
export outdirC3S=$SCRATCHDIR/ANTO/test_regrid_cam
mkdir -p $outdirC3S
wkdir=$outdirC3S
export type=h4
export ic="minnie"
member=`echo $caso|cut -d '_' -f 3|cut -c 2,3`

set +euvx
. $DIR_UTIL/descr_ensemble.sh $yyyy
set -euvx

startdate=$yyyy$st
export fore_type=$typeofrun
export outputgrid="reg1x1"
export srcGridName=$REPOGRID/srcGrd_FV.nc
export dstGridName=$REPOGRID/dstGrd_${outputgrid}.nc
export wgtFileName=$REPOGRID/CAMFV05_2_${outputgrid}_bilinear_C3S.nc
export wgtFileNameCons=$REPOGRID/CAMFV05_2_${outputgrid}_conserve_C3S.nc
export lsmFileName=$REPOGRID/SPS4_C3S_LSM.nc
export alphaFileName=$REPOSITORY/alpha_100m_wind/mean_alpha_${st}.nc
export version=$versionSPS
export real="r"${member}"i00p00"
export last_term="_"${real}".nc"
export C3Stable="$DIR_POST/cam/C3S_table.txt"
export C3Satts="$DIR_TEMPL/C3S_globalatt.txt"
export CERISEatts="$DIR_TEMPL/CERISE_globalatt.txt"
export GCM_and_version=${GCM_name}-v${version}
export ini_term=cmcc_${GCM_and_version}_${typeofrun}_S${yyyy}${st}0100
export CERISE_ini_term=cmcc_CERISE_${GCM_and_version}_${typeofrun}_S${yyyy}${st}0100

set +euvx
. $dictionary
set -euvx
#check_ncl_regrid_type=$wkdir/regridSE_C3S.ncl_${type}_${real}_ok
#check_no_SOLIN=$outdirC3S/no_SOLIN_in_${caso} 
#----------------------------------------
# INPUT TO BE REGRIDDED
#----------------------------------------
case $type
in
    h1)  export frq=6hr;;
    h2)  export frq=12hr;;
    h3)  export frq=day;;
    h4)  export frq=3hr;;
    h0)  export frq=fix;;
esac
if [[ $type == "h3" ]]
then
   isSOLINin=`ncdump -h $inputFV|grep SOLIN|wc -l`
   if [[ $isSOLINin -eq 0 ]]
   then
       
       export C3Stable="$wkdir/C3S_table_noSOLIN.txt"
       #remove last line of C3Stable - which MUST be SOLIN
       sed '$ d' $DIR_POST/cam/C3S_table.txt > $C3Stable
       touch $check_no_SOLIN
       solinfile_n=`ls $outdirC3S/${ini_term}_atmos_day_surface_rsdt_r??i00p00.nc |wc -l`
       if [[ ${solinfile_n} -ne 0 ]] ; then

             solinfile_templ=`ls $outdirC3S/${ini_term}_atmos_day_surface_rsdt_r??i00p00.nc |tail -1`
             solinfile_templ_name=`basename ${solinfile_templ}`
#             rsync -auv $solinfile_templ $SCRATCHDIR/regrid_C3S/$caso/CAM/
             rsync -auv $solinfile_templ $outdirC3S
             real_templ=`echo $solinfile_templ_name |rev|cut -d '_' -f1 |rev|cut -d '.' -f1`
             solinfile_new_name=${ini_term}_atmos_day_surface_rsdt${last_term}
             #this syntax for ncap2 change the first 9 characters of realization, preserving the white spaces
#             ncap2 -Oh -s 'realization(0:8)="r'$member'i00p00"' $SCRATCHDIR/regrid_C3S/$caso/CAM/$solinfile_templ_name $SCRATCHDIR/regrid_C3S/$caso/CAM/${solinfile_new_name}
             ncap2 -Oh -s 'realization(0:8)="r'$member'i00p00"' $outdirC3S/$solinfile_templ_name $outdirC3S/${solinfile_new_name}
#             ncatted -Oh -a ic,global,o,c,"$ic" $SCRATCHDIR/regrid_C3S/$caso/CAM/${solinfile_new_name}
             ncatted -Oh -a ic,global,o,c,"$ic" $outdirC3S/${solinfile_new_name}
#             rsync -auv $SCRATCHDIR/regrid_C3S/$caso/CAM/${solinfile_new_name} $outdirC3S
       else
             echo "NO SOLIN file to be used as template for case $caso, which does not have SOLIN ouput in $type cam output file."
             body="NO SOLIN file to be used as template for case $caso, which does not have SOLIN ouput in $type cam output file. Exiting now. When at least one member in $outdirC3S will have completed SOLIN postproc, delete $DIR_TEMP/C3S_postproc_offline_${caso} to allow automatic resubmission. "
             title="[C3S] ${CPSSYS} forecast warning "
             ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "$typeofrun" -s $yyyy$st
             if [[ -f ${DIR_TEMP}/C3S_postproc_offline_${caso} ]] 
             then
                  #kill the launcher to allow for new submission
                  postproc_C3Sid=`${DIR_UTIL}/findjobs.sh -m $machine -n postproc_C3S_offline_${caso} -i yes`
                  set +e
                  $DIR_UTIL/killjobs.sh -m $machine -i ${postproc_C3Sid}
                  set -euvx  
             fi
             exit
       fi
   fi
fi

export checkfile=$SCRATCHDIR/ANTO/test_regrid_cam/${caso}_${type}_DONE

#if [[ -f $checkfile ]]
#then
#   if [[ $inputFV -nt $checkfile ]]
#   then
#      if [[ $dbg -eq 0 ]]
#      then
## in operational mode rm to recompute
#         rm $checkfile
#      else
## otherwise just send informative email
#         body="$inputFV newer than $checkfile"
#         title="[C3S] ${CPSSYS} forecast warning "
#         ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "$typeofrun" -s $yyyy$st
#      fi
#   fi    
#fi    
# if check file does not exist run the ncl script
if [ ! -f ${checkfile} ] 
then
#   export checkfile=${check_regridC3S_type}_${type}_DONE
#   cp $DIR_POST/cam/regridFV_C3S_template.ncl $wkdir/regridFV_C3S.$type.ncl
   cp regridFV_C3S_template.ncl $wkdir/regridFV_C3S.$type.ncl
   sed -i "s/TYPEIN/$type/g;s/MEMBER/$real/g;s/FRQIN/$frq/g" $wkdir/regridFV_C3S.$type.ncl
   ncl $wkdir/regridFV_C3S.$type.ncl
fi
if [ -f ${checkfile} ]
then
   echo "regridFV_C3S.ncl completed successfully for $type and $real"
else
# if check file does not exist send ERROR email
   touch ${check_regridC3S_type}_${type}_ERROR
   body="regridFV_C3S.ncl anomalously exited for start-date ${yyyy}${st}, file type $type and member $real "
   title="[C3S] ${CPSSYS} forecast ERROR"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "$typeofrun" -s $yyyy$st
   exit
fi
echo "$0 completed"
exit 0
