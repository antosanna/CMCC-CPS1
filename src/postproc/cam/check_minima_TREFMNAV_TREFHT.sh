#!/bin/sh -l
#--------------------------------
#BSUB -J check_min
#BSUB -P 0490
#BSUB -M 25000
#BSUB -o logs/check_min.%J.out
#BSUB -e logs/check_min.%J.err
#BSUB -q s_medium

#this one will be run after poisson fixing and to the C3S products, namely to tas (t2m) in order to guarantee that nowhere the tas could be lower than tmin (which in principle could happen, with the correction made)
. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/load_ncl
set -euvx

caso=$1
#caso=sps4_199305_001
#HEALED_DIR=/work/cmcc/cp1/scratch/fix_SPS4/fix_spikes/fixed_from_spikes/$caso
HEALED_DIR=$2


yyyy=`echo $caso|cut -d '_' -f2|cut -c 1-4`
st=`echo $caso|cut -d '_' -f2|cut -c 5-6`
mem=`echo $caso|cut -d '_' -f3|cut -c2-3`
#to be defined a scratch working dir
inputascii_all=$HEALED_DIR/list_spikes_all.txt



# this will be the very last after the iterative poisson correction
export inputascii=$inputascii_all
export input_daily_time=$HEALED_DIR/$caso.cam.h3.${yyyy}-${st}.TREFMNAV.nc
export inputh3=$HEALED_DIR/$caso.cam.h3.${yyyy}-${st}.zip.nc
export inputh1=$HEALED_DIR/$caso.cam.h1.${yyyy}-${st}.zip.pre_check_tmin.nc
export checkfile_tmin_t2m=$HEALED_DIR/check_consistency_tminVSt2m_${caso}.DONE
mv $HEALED_DIR/$caso.cam.h1.${yyyy}-${st}.zip.nc $inputh1


export dstFileName=$HEALED_DIR/$caso.cam.h1.${yyyy}-${st}.zip.nc
if [[ -f $dstFileName ]]
then
   rm $dstFileName
fi

rsync -av $DIR_POST/cam/check_minima_TREFMNAV_TREFHT.ncl $HEALED_DIR/check_minima_TREFMNAV_TREFHT.ncl
ncl $HEALED_DIR/check_minima_TREFMNAV_TREFHT.ncl

if [[ ! -f $checkfile_tmin_t2m ]] 
then
   body="$HEALED_DIR/check_minima_TREFMNAV_TREFHT.ncl did not complete successfully"
   title=$body
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -s $yyyy$st -r "only" -E 0$mem
   exit 1
fi

if [[ -f $checkfile_tmin_t2m ]] && [[ ! -f $HEALED_DIR/$caso.cam.h1.${yyyy}-${st}.zip.nc ]]
then
    touch $HEALED_DIR/no_action_needed_consistency_${caso}.DONE
# in this case file was not written by $HEALED_DIR/check_minima_TREFMNAV_TREFHT.ncl
    mv $inputh1 $HEALED_DIR/$caso.cam.h1.${yyyy}-${st}.zip.nc
fi
