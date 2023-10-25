#!/bin/sh -l 

# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

set -evx


set +euvx
. ${DIR_UTIL}/descr_ensemble.sh YYYY
set -euvx
ens=`echo CASO|cut -d '_' -f 3|cut -c 2-3`

resty=`date -d YYYYST01' + '$nmonfore' month' +%Y`
restm=`date -d YYYYST01' + '$nmonfore' month' +%m`

#---------------------------------------
# check that all the files for internal purposes have been 
# correctly produced 
#---------------------------------------
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
narchptr_ocn=`ls $DIR_ARCHIVE/CASO/ocn/hist/CASO* | grep "_ptr" |wc -l`
narchsca_ocn=`ls $DIR_ARCHIVE/CASO/ocn/hist/CASO* | grep "_sca" |wc -l`
narch_ice=`ls $FINALARCHIVE/CASO/ice/hist/CASO* | wc -l`
if [ $n_lnd -ne $nmonfore ] || [ $(($n_ice + $narch_ice)) -ne $nmonfore ] || [ $n_rof -ne $nmonfore ] || [ $n_atm -ne $nmonfore ] || [ $(($n1d_ocn +  $narch1d_ocn)) -ne $(($nmonfore * 2)) ] || [ $(($n1m_ocn + $narch1m_ocn)) -ne $(($nmonfore * 4)) ] || [ $(($nptr_ocn +  $narchptr_ocn)) -ne $nmonfore ] || [ $(($nsca_ocn +  $narchsca_ocn)) -ne $nmonfore ]
then
       body= "CASO Number of output monthly output files is not the expected one \n
           atm expected $nmonfore, got $n_atm in $DIR_ARCHIVE,  \n
           ocn 1d expected $(($nmonfore * 2)), got $n1d_ocn in $DIR_ARCHIVE,  $narch1d_ocn in $FINALARCHIVE \n
           ocn scalar expected $nmonfore, got $nsca_ocn in $DIR_ARCHIVE,  $narchsca_ocn in $FINALARCHIVE \n
           ocn ptr expected $nmonfore, got $nptr_ocn in $DIR_ARCHIVE,  $narchptr_ocn in $FINALARCHIVE \n
           ocn 1m expected $(($nmonfore * 4)), got $n1m_ocn in $DIR_ARCHIVE, $narch1m_ocn in $FINALARCHIVE \n
           ice expected $nmonfore, got $n_ice in $DIR_ARCHIVE, $narch_ice in $FINALARCHIVE \n
           lnd expected $nmonfore, got $n_lnd in $DIR_ARCHIVE, \n
           rof expected $nmonfore, got $n_rof in $DIR_ARCHIVE, \n
           YOU MUST RESUBMIT THE CASE"
       title="${CPSSYS} $typeofrun ERROR"
       ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" 
#---------------------------------------
# if not exit 3
#---------------------------------------
       exit 3
fi
#---------------------------------------
# archive restart
#---------------------------------------
mkdir -p $FINALARCHIVE/CASO/rest
#mkdir -p $ARCHIVE/CASO/rest
# do not --remove-source-files, since it's used by make_${SPSSYS}_C3S_b_moredays.sh !
#rsync -auv $DIR_ARCHIVE/CASO/rest/${resty}-${restm}-01-00000 $ARCHIVE/CASO/rest/
rsync -auv $DIR_ARCHIVE/CASO/rest/${resty}-${restm}-01-00000 $FINALARCHIVE/CASO/rest/
exit
sed 's/ic="leapic"/ic="'$ic'"/g;s/EXPleap/'CASO'/g' $DIR_SPS35/lt_archive_C3S_moredays.sh > $DIR_CASES/CASO/lt_archive_C3S_moredays.sh
chmod u+x $DIR_CASES/CASO/lt_archive_C3S_moredays.sh

${DIR_SPS35}/make_${SPSSYS}_C3S_b_moredays.sh CASO YYYY $st $ic
