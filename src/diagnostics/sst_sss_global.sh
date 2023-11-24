#!/bin/sh -l

# TAKES ALMOST 10'
. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/load_cdo
function write_help
{
  echo "Use: monitor_forecast.sh [<yyyy>] [<st>]"
}
launchdir=$DIR_DIAG
if [[ $# -eq 0 ]]
then
  write_help
  exit
fi
   
set -euvx
yyyy=$1
st=$2
. $DIR_UTIL/descr_ensemble.sh $yyyy
set -euvx
outdir=$DIR_TEMPL_NEMOPLOT/$yyyy$st
mkdir -p $outdir
# clean the output files before start if they exist
cntseries=$(ls -1 $outdir/*_ss?_series.nc | wc -l)
if [ $cntseries -gt 0 ]; then
  rm $outdir/*_ss?_series.nc
fi

# gather DMO nemo files in all possible directories
ARCHIVE1=$DIR_ARCHIVE
ARCHIVE3=$FINALARCHIVE
cnt=0
for ens in `seq -w 01 $nrunmax`
do
   caso=${SPSSystem}_${yyyy}${st}_0${ens}
   for var in sss sst
   do
      if [ -f $outdir/${caso}_${var}_series.nc ]
      then
         rm $outdir/${caso}_${var}_series.nc
      fi
   done
   head=''
   if [ ! -f $outdir/tarea_surf_sum_miss.nc ]
   then
     maskfile="$CESMDATAROOT/inputdata/ocn/nemo/tn0.25v3/grid/ORCA025L75_mesh_mask.nc"
     cdo sellevidx,1 $maskfile $outdir/mesh_mask_surf.nc
     cdo expr,'area=(e1t*e2t*tmask)' $outdir/mesh_mask_surf.nc $outdir/tarea_surf.nc
     rm $outdir/mesh_mask_surf.nc
     cdo -setctomiss,0 $outdir/tarea_surf.nc $outdir/tarea_surf_miss.nc
     rm $outdir/tarea_surf.nc
     cdo fldsum $outdir/tarea_surf_miss.nc $outdir/tarea_surf_sum_miss.nc
   fi
   if [ `ls $ARCHIVE1/$caso/ocn/hist/${caso}_1m_*grid_T*|wc -l` -ne 0 ]
   then
      cd $ARCHIVE1/$caso/ocn/hist/
   elif [ `ls $ARCHIVE3/$caso/ocn/hist/${caso}_1m_*grid_T*|wc -l` -ne 0 ]
   then
      cd $ARCHIVE3/$caso/ocn/hist/
   else
      continue
   fi
   listaf=`ls ${caso}_1m_*grid_T*`
   for file in $listaf
   do
      head="${file%_*}"
      head="${head%_*}"
#temperature
      if [ -f $outdir/${head}_sst_fldmean.nc ]
      then
        nt=`cdo -ntime $outdir/${head}_sst_fldmean.nc`
        if [ $nt -gt $nmonfore ]
        then
           rm $outdir/${head}_sst_fldmean.nc
        fi
      fi
      if [ ! -f $outdir/${head}_sst_fldmean.nc ]
      then
         cdo -selvar,tos $file $outdir/${head}_sst.nc
         cdo -setctomiss,0 $outdir/${head}_sst.nc $outdir/${head}_sst_miss.nc
         cdo mul $outdir/${head}_sst_miss.nc $outdir/tarea_surf_miss.nc $outdir/${head}_sst_miss_wg.nc
         cdo fldsum $outdir/${head}_sst_miss_wg.nc $outdir/${head}_sst_sum_miss.nc
         cdo div $outdir/${head}_sst_sum_miss.nc $outdir/tarea_surf_sum_miss.nc $outdir/${head}_sst_fldmean.nc
         rm $outdir/${head}_sst_miss_wg.nc $outdir/${head}_sst.nc $outdir/${head}_sst_miss.nc $outdir/${head}_sst_sum_miss.nc
      fi
#salinity
      if [ -f $outdir/${head}_sss_fldmean.nc ]
      then
        nt=`cdo -ntime $outdir/${head}_sss_fldmean.nc`
        if [ $nt -gt $nmonfore ]
        then
           rm $outdir/${head}_sst_fldmean.nc
        fi
      fi
      if [ ! -f $outdir/${head}_sss_fldmean.nc ]
      then
         cdo -selvar,sos $file $outdir/${head}_sss.nc
         cdo -setctomiss,0 $outdir/${head}_sss.nc $outdir/${head}_sss_miss.nc
         cdo mul $outdir/${head}_sss_miss.nc $outdir/tarea_surf_miss.nc $outdir/${head}_sss_miss_wg.nc
         cdo fldsum $outdir/${head}_sss_miss_wg.nc $outdir/${head}_sss_sum_miss.nc
         cdo div $outdir/${head}_sss_sum_miss.nc $outdir/tarea_surf_sum_miss.nc $outdir/${head}_sss_fldmean.nc
         rm $outdir/${head}_sss_miss_wg.nc $outdir/${head}_sss.nc $outdir/${head}_sss_miss.nc $outdir/${head}_sss_sum_miss.nc
      fi
   done
   if [ -f $outdir/${head}_sst_fldmean.nc ] 
   then
     cdo -O -mergetime $outdir/${caso}_1m_??????01_????????_sst_fldmean.nc $outdir/${caso}_sst_series.nc
   fi
   if [ -f $outdir/${head}_sss_fldmean.nc ] 
   then
      cdo -O -mergetime $outdir/${caso}_1m_??????01_????????_sss_fldmean.nc $outdir/${caso}_sss_series.nc
   fi
   cnt=$(( $cnt +1 ))
   # if processed member are $nrunC3Sfore exit (manage forecast 54 members)
   if [ $cnt -ge $nrunC3Sfore ]
   then
      break
   fi
done
$launchdir/plot_nemo_series.sh $yyyy $st
