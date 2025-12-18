#!/bin/sh -l 

# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. ${DIR_UTIL}/load_nco                # to get command $compress
. ${DIR_UTIL}/descr_ensemble.sh $1  #THIS SCRIPT SHOULD RUN
                                      #ONLY FOR HINDCASTS

set -evxu

for ens in {001..025}
do 
   caso=sps4_200302_${ens}
# only in this special case DIR_CASES must be redefined for it can be different
# for the different machines the case could have been done on.
dir_cases=$DIR_CASES
# this modification will affect $dictionary too!!!!

st=`echo $caso|cut -d '_' -f2 |cut -c5-6`
yyyy=`echo $caso|cut -d '_' -f2 |cut -c1-4`
ic=`ncdump -h $DIR_ARCHIVE/$caso/atm/hist/$caso.cam.h0.$yyyy-$st.zip.nc|grep "ic ="|cut -d '=' -f2-|cut -d ';' -f1 |cut -d '"' -f2`
#
startdate=$yyyy$st
ens=`echo $caso|cut -d '_' -f 3 `
member=`echo $ens|cut -c2,3` 

HEALED_DIR=$HEALED_DIR_ROOT/$caso/CAM/healing
#HEALED_DIR_ROOT=/work/cmcc/cp1/CPS/CMCC-CPS1/fixed_from_spikes/
# THIS MUST BE KEPT FOR CERISE
chmod -R u+w $DIR_ARCHIVE/$caso

outdirC3S=${WORK_CERISE}/$yyyy$st/

set +euvx
. $dictionary
set -euvx
mkdir -p $outdirC3S
dirlog=$dir_cases/$caso/logs
mkdir -p $dirlog

#***********************************************************************
# Standardization for CLM
#***********************************************************************
wkdir_clm=$SCRATCHDIR/regrid_CERISE_phase2/$caso/CLM
mkdir -p ${wkdir_clm}
# get check_postclm  from dictionary


   cd ${wkdir_clm}
   filetyp="h2"
   jobIDall=""
   for ft in $filetyp ; do

       case $ft in
           h1) mult=1 ; req_mem=50000 ;;
           h2) mult=4 ; req_mem=25000 ;;
           h3) mult=1 ; req_mem=5000;; # for land both h1 and h3 are daily (h1 averaged and h3 instantaneous), multiplier=1
       esac
       flag_for_type=${check_postclm_type}_${ft}_DONE2
       finalfile_clm=$DIR_ARCHIVE/$caso/lnd/hist/$caso.clm2.$ft.$yyyy-$st.zip.nc
       input="$caso $ft ${wkdir_clm} ${finalfile_clm} ${flag_for_type} $ic $mult"
       ${DIR_UTIL}/submitcommand.sh -m $machine -q $parallelq_m -S qos_resv  -M ${req_mem} -j create_clm_files2_${ft}_${caso} -l ${dir_cases}/$caso/logs/ -d ${DIR_POST}/clm -s create_clm_files.sh -i "$input"
       jobIDall+=" `${DIR_UTIL}/findjobs.sh -m $machine -n create_clm_files_${ft}_${caso} -i yes`"
       echo "start of postpc_clm "`date`
       input="${finalfile_clm} $ens $startdate $outdirC3S $caso ${flag_for_type} ${wkdir_clm} $ic $ft"
       # ADD the reservation for serial !!!
       ${DIR_UTIL}/submitcommand.sh -p create_clm_files2_${ft}_${caso} -m $machine -q $parallelq_l -M ${req_mem} -S qos_resv -j postpc_clm_${ft}_${caso} -l $dir_cases/$caso/logs/ -d ${DIR_POST}/clm -s postpc_clm_CERISE_mrlsl.sh -i "$input"
   done

done
echo "Done."

exit 0
