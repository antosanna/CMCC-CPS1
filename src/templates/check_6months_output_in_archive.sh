#!/bin/sh -l 

# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh


caso=CASO
set +euvx
. ${DIR_UTIL}/descr_ensemble.sh YYYY
. $dictionary
set -euvx

function Count_files()
{
   ic=$1
   n_lnd=`ls $DIR_ARCHIVE/CASO/lnd/hist/CASO*.nc | grep "clm2.h0"| grep zip | wc -l`
# EquT are already zip; Tglobal will be by interp_ORCA2_1X1_gridT2C3S.sh
   n1d_ocn=`ls $DIR_ARCHIVE/CASO/ocn/hist/CASO*.nc | grep "1d_"  | wc -l`
   n1m_ocn=`ls $DIR_ARCHIVE/CASO/ocn/hist/CASO*.nc | grep "_1m_" | grep "grid_[TUVW]" |wc -l`
#TEMPORARY COMMENTED BECAUSE OF BUG IN MULTIPLE FILE 20240115
#   nptr_ocn=`ls $DIR_ARCHIVE/CASO/ocn/hist/CASO*.nc | grep "_ptr" |wc -l`
   nsca_ocn=`ls $DIR_ARCHIVE/CASO/ocn/hist/CASO*.nc | grep "_sca" |wc -l`
   n_ice=`ls $DIR_ARCHIVE/CASO/ice/hist/CASO*.nc | wc -l`
   n_rof=`ls $DIR_ARCHIVE/CASO/rof/hist/CASO*zip*.nc | wc -l`
   n_atm=`ls $DIR_ARCHIVE/CASO/atm/hist/CASO*.nc | grep cam.h0| grep zip | wc -l`
# EquT are already zip; Tglobal will be by interp_ORCA2_1X1_gridT2C3S.sh
#   if [ $n_lnd -ne $nmonfore ] || [ $n_ice  -ne $nmonfore ] || [ $n_rof -ne $nmonfore ] || [ $n_atm -ne $nmonfore ] || [ $n1d_ocn -ne $(($nmonfore * 2)) ] || [ $n1m_ocn -ne $(($nmonfore * 4)) ] || [ $nptr_ocn -ne $nmonfore ] || [ $nsca_ocn -ne $nmonfore ]
   if [ $n_lnd -ne $nmonfore ] || [ $n_ice  -ne $nmonfore ] || [ $n_rof -ne $nmonfore ] || [ $n_atm -ne $nmonfore ] || [ $n1d_ocn -ne $(($nmonfore * 2)) ] || [ $n1m_ocn -ne $(($nmonfore * 4)) ] || [ $nsca_ocn -ne $nmonfore ]
   then
       ret=1
       if [[ $ic -eq 2 ]]
       then
#TEMPORARY COMMENTED BECAUSE OF BUG IN MULTIPLE FILE 20240115
#           ocn ptr expected $nmonfore, got $nptr_ocn in $DIR_ARCHIVE/CASO/ocn/hist,  \n
           body="CASO Number of output monthly output files is not the expected one \n
           atm expected $nmonfore, got $n_atm in $DIR_ARCHIVE/CASO/atm/hist,  \n
           ocn 1d expected $(($nmonfore * 2)), got $n1d_ocn in $DIR_ARCHIVE/CASO/ocn/hist,   \n
           ocn scalar expected $nmonfore, got $nsca_ocn in $DIR_ARCHIVE/CASO/ocn/hist,  \n
           ocn 1m 3d expected $(($nmonfore * 4)), got $n1m_ocn in $DIR_ARCHIVE/CASO/ocn/hist,  \n
           ice expected $nmonfore, got $n_ice in $DIR_ARCHIVE/CASO/ice/hist,  \n
           lnd expected $nmonfore, got $n_lnd in $DIR_ARCHIVE/CASO/lnd/hist, \n
           rof expected $nmonfore, got $n_rof in $DIR_ARCHIVE/CASO/rof/hist, \n
           YOU MUST RESUBMIT THE CASE"
           title="${CPSSYS} $typeofrun ERROR"
           ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "$typeofrun" -s YYYYmese
       fi
   else
       ret=0
   fi
   echo $ret
   
}


#---------------------------------------
# check that all the files for internal purposes have been 
# correctly produced 
#---------------------------------------
ic=1
flag_Count_files=$( Count_files $ic )
if [[ $flag_Count_files -eq 1 ]]
then
# if files are not in the expected number try and recover.
    $DIR_RECOVER/recover_6months_pp.sh CASO
    ic=2
    flag_Count_files=$( Count_files $ic )
    if [[ $flag_Count_files -eq 1 ]]
    then
       exit 3
    fi
# Count again: if files are not in the expected number send mail and exit
fi
touch $check_6months_done
exit 0
