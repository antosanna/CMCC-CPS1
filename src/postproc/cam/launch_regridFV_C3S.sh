#!/bin/sh -l
##BSUB -P 0784
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
inputFV=$1   # finalfile in parent script
caso=$2
outdirC3S=$3
wkdir=$4
ftype=$5 
ic="$6"
nsimdays=$7
dir_cases=$8


st=`echo $caso|cut -d '_' -f 2|cut -c 5-6`
yyyy=`echo $caso|cut -d '_' -f 2|cut -c 1-4`
member=`echo $caso|cut -d '_' -f 3|cut -c 2,3`
real="r"${member}"i00p00"

set +euvx
. $DIR_UTIL/descr_ensemble.sh $yyyy
set -euvx

if [[ $caso =~ "ext" ]]; then
   init=185
   ext=1
   end_term=_slicetime4440to11712.nc
   if [[ $ftype == "h3" ]]
   then
      init=186
      end_term=_slicetime4452to11700.nc
   fi
else
   ext=0
   init=0
   end_term=.nc
fi
C3Stable="$DIR_POST/cam/C3S_table.txt"

set +euvx
. $dictionary
set -euvx
#check_ncl_regrid_type=$wkdir/regridSE_C3S.ncl_${ftype}_${member}_ok
#check_no_SOLIN=$outdirC3S/no_SOLIN_in_${caso} 
#----------------------------------------
# INPUT TO BE REGRIDDED
#----------------------------------------
mkdir -p $SCRATCHDIR/regrid_C3S/$caso/CAM
if [[ $ftype == "h3" ]]
then
   if [[ -f $check_no_SOLIN ]]
   then
      rm $check_no_SOLIN 
   fi
   isSOLINin=`ncdump -h $inputFV|grep SOLIN|wc -l`
   if [[ $isSOLINin -eq 0 ]]
   then
       
       C3Stable="$wkdir/C3S_table_noSOLIN.txt"
       #remove last line of C3Stable - which MUST be SOLIN
       sed '$ d' $DIR_POST/cam/C3S_table.txt > $C3Stable
       touch $check_no_SOLIN
       solinfile_n=`ls $outdirC3S/${ini_term}_atmos_day_surface_rsdt_r??i00p00.nc |wc -l`
       if [[ ${solinfile_n} -ne 0 ]] ; then

             solinfile_templ=`ls $outdirC3S/${ini_term}_atmos_day_surface_rsdt_r??i00p00.nc |tail -1`
             solinfile_templ_name=`basename ${solinfile_templ}`
             rsync -auv $solinfile_templ $SCRATCHDIR/regrid_C3S/$caso/CAM/
             real_templ=`echo $solinfile_templ_name |rev|cut -d '_' -f1 |rev|cut -d '.' -f1`
             end_term=_slicetime4452to11700.nc
             solinfile_new_name=${ini_term}_atmos_day_surface_rsdt${end_term}
             #this syntax for ncap2 change the first 9 characters of realization, preserving the white spaces
             ncap2 -Oh -s 'realization(0:8)="r'$member'i00p00"' $SCRATCHDIR/regrid_C3S/$caso/CAM/$solinfile_templ_name $SCRATCHDIR/regrid_C3S/$caso/CAM/${solinfile_new_name}
             ncatted -Oh -a ic,global,o,c,"$ic" $SCRATCHDIR/regrid_C3S/$caso/CAM/${solinfile_new_name}
             rsync -auv $SCRATCHDIR/regrid_C3S/$caso/CAM/${solinfile_new_name} $outdirC3S
       else
             echo "NO SOLIN file to be used as template for case $caso, which does not have SOLIN ouput in $ftype cam output file."
             body="NO SOLIN file to be used as template for case $caso, which does not have SOLIN ouput in $ftype cam output file. Exiting now. When at least one member in $outdirC3S will have completed SOLIN postproc, delete $DIR_TEMP/C3S_postproc_offline_${caso} to allow automatic resubmission. "
             title="[C3S] ${CPSSYS} forecast warning "
             ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "$typeofrun" -s $yyyy$st -E 0$member
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

checkfile=${check_regridC3S_type}_${ftype}_DONE

if [[ -f $checkfile ]] && [[ $inputFV -nt $checkfile ]]
then
   rm $checkfile
elif [[ -f $checkfile ]] && [[ $checkfile -nt $inputFV ]]
then
   exit 0
fi    
# if check file does not exist run the ncl script
iere=/users_home/cmcc/cp2/CPS/CMCC-CPS1/development_tmp/ANTO/C3S_extended
if [[ ! -f ${checkfile} ]] 
then
#   export checkfile=${check_regridC3S_type}_${ftype}_DONE
#   cp $DIR_POST/cam/regridFV_C3S_template.ncl $wkdir/regridFV_C3S.$ftype.ncl
    case $ftype
    in
        h1)  frq=6hr;;
        h2)  frq=12hr;;
        h3)  frq=day;;
        h0)  frq=fix;;
    esac
    listofvars=`cat $C3Stable |grep $frq|cut -d ',' -f2`
    n_listofvars=`cat $C3Stable |grep $frq|wc -l`
    n_counter=0
    for var in $listofvars
    do
       if  [[ $caso =~ "ext" ]] && { [[ "$var" == "orog" ]] || [[ $var == "sftlf" ]]; }
       then
          continue
       fi
       if   [[ "$var" == "sic" ]]  && [[ $caso =~ "ext" ]]
       then
          end_term=_slicetime4440to11688.nc
       fi
       if   [[ $var == "rsdt" ]]  && [[ $caso =~ "ext" ]]
       then
          end_term=_slicetime4452to11700.nc
       fi
       checkfilevar=${check_regridC3S_type}_${ftype}_${var}_DONE
       script=$wkdir/$var/regridFV_C3S.$ftype.$var.ncl
       mkdir -p $wkdir/$var
       cp $DIR_POST/cam/regridFV_C3S_single_template.ncl $script
       sed -i "s/TYPEIN/$ftype/g;s/MEMBER/$real/g;s/FRQIN/$frq/g" $script
       script=$wkdir/$var/regridFV_C3S.$ftype.$var.sh
       cp $DIR_POST/cam/regridFV_C3S_single_template.sh $script
       sed -i "s:INPUT:$inputFV:g;s:OUTDIR:$outdirC3S:g;s:WKDIR:$wkdir/$var:g;s:TYPE:$ftype:g;s:IC:\"$ic\":g;s:NDAYS:$nsimdays:g;s:VAR:$var:g;s:INIT:$init:g;s:END_TERM:$end_term:g;s:CASO:$caso:g;s:CHECKF:$checkfilevar:g;s:EXT:$ext:g;s:TABLE:$C3Stable:g" $script
       chmod u+x $wkdir/$var/regridFV_C3S.$ftype.$var.sh
       req_mem=10000
       if [[ $var == "tso" ]]
       then 
          req_mem=15000
       fi
       ${DIR_UTIL}/submitcommand.sh -m $machine -q $parallelq_m -S $qos  -M ${req_mem} -j regrid_cam_${ftype}_${var}_${caso} -l $dir_cases/$caso/logs/ -d $wkdir/$var -s regridFV_C3S.$ftype.$var.sh 
       n_counter=$((n_counter + 1))
# CHECK MAX NUMBER OF SUBMITTED JOBS
       if [[ $n_counter -eq 999999 ]]
       then
          :
       fi
    done
fi
for var in $listofvars
do
   while `true`
   do
      if [[ -f ${checkfilevar} ]]
      then
         break
      fi  
      sleep 120 
    done
done
touch $checkfile

#if [[ -f ${checkfile} ]]
#then
   echo "regridFV_C3S.ncl completed successfully for $ftype and $member"
#else
## if check file does not exist send ERROR email
#   touch ${check_regridC3S_type}_${ftype}_ERROR
#   body="regridFV_C3S.ncl anomalously exited for start-date ${yyyy}${st}, file type $ftype and member $member "
#   title="[C3S] ${CPSSYS} forecast ERROR"
#   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "$typeofrun" -s $yyyy$st -E 0$member
#   exit
#fi
echo "$0 completed"
exit 0
