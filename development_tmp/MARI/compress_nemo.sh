#!/usr/bin/sh -l
#BSUB  -J compress_nemo
#BSUB  -q s_short
#BSUB  -n 1 
#BSUB  -o /work/csp/cp1/scratch/MARI/logs/compress_nemo.stdout.%J  
#BSUB  -e /work/csp/cp1/scratch/MARI/logs/compress_nemo.stderr.%J  
#BSUB  -P 0574
#BSUB  -M 5000

. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
. ${DIR_UTIL}/load_nco
set -euvx
CASE=sps4_199507_018
CASEROOT=$DIR_CASES/$CASE
#
# go back to CASEROOT
cd $CASEROOT

yyyy=`echo $CASE|cut -d '_' -f2|cut -c 1-4`
st=`echo $CASE|cut -d '_' -f2|cut -c 5-6`
yyyystdd=$yyyy${st}15
for mon in `seq 0 $(($nmonfore - 1))`
do
   curryear=`date -d "$yyyystdd + $mon month" +%Y`
   currmon=`date -d "$yyyystdd + $mon month" +%m`
   set +euvx
   . $dictionary
   set -euvx
   
# add your frequencies and grids. The script skip them if not present
   for frq in 1m 1d
   do
      for grd in T U V W ptr
      do
             
            if [[ `ls  $DIR_ARCHIVE/$CASE/ocn/hist/${CASE}_${frq}_${curryear}${currmon}*_grid_${grd}.zip.nc |wc -l` -eq 0 ]] 
            then
                if [[ `ls  $DIR_ARCHIVE/$CASE/ocn/hist/${CASE}_${frq}_${curryear}${currmon}*_grid_${grd}.nc |wc -l` -eq 1 ]] 
                then
                    data_now=`ls -t $DIR_ARCHIVE/$CASE/ocn/hist/${CASE}_${frq}_${curryear}${currmon}*_grid_${grd}.nc|rev|cut -d '_' -f3-4|rev`
                    $compress $DIR_ARCHIVE/$CASE/ocn/hist/${CASE}_${frq}_${data_now}_grid_${grd}.nc $DIR_ARCHIVE/$CASE/ocn/hist/${CASE}_${frq}_${data_now}_grid_${grd}.zip.nc
                    statzip=$?
                    if [[ $statzip -eq 0 ]]
                    then
                       #mv $DIR_ARCHIVE/$CASE/ocn/hist/${CASE}_${frq}_${data_now}_grid_${grd}.nc $DIR_ARCHIVE/$CASE/ocn/hist/${CASE}_${frq}_${data_now}_grid_${grd}.nc_deleteme
                       rm $DIR_ARCHIVE/$CASE/ocn/hist/${CASE}_${frq}_${data_now}_grid_${grd}.nc 
                    fi 
               fi
            fi
      done
      for grd in scalar
      do
         nscalar=`ls $DIR_ARCHIVE/$CASE/ocn/hist/${CASE}_${frq}_${curryear}${currmon}*_${grd}.nc |wc -l` 
         if [[ $nscalar -eq 1 ]] ; then
            finalfile=`ls $DIR_ARCHIVE/$CASE/ocn/hist/${CASE}_${frq}_${curryear}${currmon}*_${grd}.nc`
            headscalarfile=`echo $finalfile|sed 's/.nc//g'`
#           mv $finalfile $headscalarfile.nc
            if [[ ! -f $headscalarfile.zip.nc ]] 
            then
                $compress $headscalarfile.nc $headscalarfile.zip.nc
                statzip=$?
                if [[ $statzip -eq 0 ]]
                then
                    #mv $headscalarfile.nc $headscalarfile.nc_deleteme
                    rm $headscalarfile.nc 
                fi
            fi
         fi
      done
   done
done

