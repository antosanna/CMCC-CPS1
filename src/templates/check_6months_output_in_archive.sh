#!/bin/sh -l 

# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh


set +euvx
. ${DIR_UTIL}/descr_ensemble.sh YYYY
set -euvx

function Count_files
{
   n_lnd=`ls $DIR_ARCHIVE/CASO/lnd/hist/CASO* | grep "clm2.h0"| grep zip | wc -l`
# EquT are already zip; Tglobal will be by interp_ORCA2_1X1_gridT2C3S.sh
   n1d_ocn=`ls $DIR_ARCHIVE/CASO/ocn/hist/CASO* | grep "1d_"  | wc -l`
   n1m_ocn=`ls $DIR_ARCHIVE/CASO/ocn/hist/CASO* | grep "_1m_" | grep "grid_[TUVW]" |wc -l`
   nptr_ocn=`ls $DIR_ARCHIVE/CASO/ocn/hist/CASO* | grep "_ptr" |wc -l`
   nsca_ocn=`ls $DIR_ARCHIVE/CASO/ocn/hist/CASO* | grep "_sca" |wc -l`
   n_ice=`ls $DIR_ARCHIVE/CASO/ice/hist/CASO* | wc -l`
   n_rof=`ls $DIR_ARCHIVE/CASO/rof/hist/CASO*zip* | wc -l`
   n_atm=`ls $DIR_ARCHIVE/CASO/atm/hist/CASO* | grep cam.h0| grep zip | wc -l`
# EquT are already zip; Tglobal will be by interp_ORCA2_1X1_gridT2C3S.sh
   narch1d_ocn=`ls $FINALARCHIVE/CASO/ocn/hist/CASO* | grep "1d_"  | wc -l`
   narch1m_ocn=`ls $FINALARCHIVE/CASO/ocn/hist/CASO* | grep "_1m_" | grep "grid_[TUVW]" |wc -l`
   narchptr_ocn=`ls $FINALARCHIVE/CASO/ocn/hist/CASO* | grep "_ptr" |wc -l`
   narchsca_ocn=`ls $FINALARCHIVE/CASO/ocn/hist/CASO* | grep "_sca" |wc -l`
   narch_ice=`ls $FINALARCHIVE/CASO/ice/hist/CASO* | wc -l`
   if [ $n_lnd -ne $nmonfore ] || [ $(($n_ice + $narch_ice)) -ne $nmonfore ] || [ $n_rof -ne $nmonfore ] || [ $n_atm -ne $nmonfore ] || [ $(($n1d_ocn +  $narch1d_ocn)) -ne $(($nmonfore * 2)) ] || [ $(($n1m_ocn + $narch1m_ocn)) -ne $(($nmonfore * 4)) ] || [ $(($nptr_ocn +  $narchptr_ocn)) -ne $nmonfore ] || [ $(($nsca_ocn +  $narchsca_ocn)) -ne $nmonfore ]
       return 1
   else
       return 0
   fi
   
}
ens=`echo CASO|cut -d '_' -f 3|cut -c 2-3`

resty=`date -d YYYYMM01' + '$nmonfore' month' +%Y`
restm=`date -d YYYYMM01' + '$nmonfore' month' +%m`

#---------------------------------------
# check that all the files for internal purposes have been 
# correctly produced 
#---------------------------------------
flag_Count_files=`Count_files`
if [[ $flag_Count_files -eq 1 ]]
then
# if files are not in the expected number try and recover.
    $DIR_RECOVER/recover6months_pp.sh CASO
    flag_Count_files=`Count_files`
# Count again: if files are not in the expected number send mail and exit
    if [[ $flag_Count_files -eq 1 ]]
    then
       body="CASO Number of output monthly output files is not the expected one \n
           atm expected $nmonfore, got $n_atm in $DIR_ARCHIVE/CASO/atm/hist,  \n
           ocn 1d expected $(($nmonfore * 2)), got $n1d_ocn in $DIR_ARCHIVE/CASO/ocn/hist,  $narch1d_ocn in $FINALARCHIVE/CASO/ocn/hist \n
           ocn scalar expected $nmonfore, got $nsca_ocn in $DIR_ARCHIVE/CASO/ocn/hist,  $narchsca_ocn in $FINALARCHIVE/CASO/ocn/hist \n
           ocn ptr expected $nmonfore, got $nptr_ocn in $DIR_ARCHIVE/CASO/ocn/hist,  $narchptr_ocn in $FINALARCHIVE/CASO/ocn/hist \n
           ocn 1m 3d expected $(($nmonfore * 4)), got $n1m_ocn in $DIR_ARCHIVE/CASO/ocn/hist, $narch1m_ocn in $FINALARCHIVE/CASO/ocn/hist \n
           ice expected $nmonfore, got $n_ice in $DIR_ARCHIVE/CASO/ice/hist, $narch_ice in $FINALARCHIVE/CASO/ice/hist \n
           lnd expected $nmonfore, got $n_lnd in $DIR_ARCHIVE/CASO/lnd/hist, \n
           rof expected $nmonfore, got $n_rof in $DIR_ARCHIVE/CASO/rof/hist, \n
           YOU MUST RESUBMIT THE CASE"
       title="${CPSSYS} $typeofrun ERROR"
       ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" 
#---------------------------------------
# if not exit 3
#---------------------------------------
       exit 3
    fi
fi
touch $check_6months_done
#---------------------------------------
# archive restart
#---------------------------------------
mkdir -p $FINALARCHIVE/CASO/rest
rsync -auv $DIR_ARCHIVE/CASO/rest/${resty}-${restm}-01-00000 $FINALARCHIVE/CASO/rest/
