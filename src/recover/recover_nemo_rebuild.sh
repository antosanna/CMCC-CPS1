#!/usr/bin/sh -l
##BSUB  -J nemo_rebuild
##BSUB  -n 1 
##BSUB  -o /work/csp/sps-dev/scratch/recover//logs/recover/nemo_rebuild.stdout.%J  
##BSUB  -e /work/csp/sps-dev/scratch/recover/logs/recover/nemo_rebuild.stderr.%J  
##BSUB  -R "span[ptile=1]"
##BSUB  -P 0574
. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
set -euvx
CASE=$1
# this is the number of parallel postprocessing you want to set
N=1
st=`echo $CASE|cut -d '_' -f2|cut -c5-6`
stdate=`echo $CASE|cut -d '_' -f2`"01"
# activate needed env
set +euvx 
module purge 
module purge 
. $DIR_UTIL/condaactivation.sh
condafunction activate $envcondanemo
set -euvx    # keep this instruction after conda activation
mm=0
while [[ $mm -lt $nmonfore ]]
do
   curryearmon=`date "-d $stdate + $mm month" +%Y%m`
   n_list_months_to_rebuild=`ls $DIR_ARCHIVE/$CASE/ocn/hist/*_${curryearmon}01_${curryearmon}??_*_0000.nc|wc -l`
   if [[ $n_list_months_to_rebuild -ne 0 ]]
   then
      list_months_to_rebuild=`ls $DIR_ARCHIVE/$CASE/ocn/hist/*${curryearmon}01_${curryearmon}??_*_0000.nc`
      for ff in $list_months_to_rebuild
      do
         fileroot=`echo $ff|rev|cut -d '_' -f2-|rev`
         $mpirun4py_nemo_rebuild -n $N python $DIR_NEMO_REBUILD/nemo_rebuild.py -i $fileroot
   # if correctly merged remove single files
      if [[ -f $fileroot.nc ]] 
      then
         rm $fileroot_0???.nc
      fi
      done
   fi
   mm=$(($mm + 1))
done
set +euvx
condafunction deactivate $envcondanemo
set -euvx
list_files_to_compress=`ls $DIR_ARCHIVE/$CASE/ocn/hist/*.nc`
for ff in $list_files_to_compress
do
    if [[ "$ff" =~ "zip" ]]; then
       continue
    fi
    zipfinalfile=`echo $ff|sed 's/.nc/.zip.nc/g'`
    $DIR_UTIL/compress.sh $ff $zipfinalfile
    rm $ff
done

