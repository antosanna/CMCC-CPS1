#!/bin/sh -l
#BSUB -P 0490
#BSUB -q s_medium
#BSUB -J SeaIce_ICs_plot
#BSUB -o /work/cmcc/cp1//CPS/CMCC-CPS1/logs/tests/SeaIce_ICs_plot_%J.out
#BSUB -e /work/cmcc/cp1//CPS/CMCC-CPS1/logs/tests/SeaIce_ICs_plot_%J.err
#BSUB -M 5000
# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. ${DIR_UTIL}/load_nco
. ${DIR_UTIL}/load_cdo
set -exvu

dbg=0
export yyyy=$1 #`date +%Y`
export st=$2 #`date +%m`
diff=${3:-0} #if diff=0 plot diff mod-obs/ diff=1 plot full value
set +euvx
. ${DIR_UTIL}/descr_ensemble.sh $yyyy
set -euvx
export yym1=`date -d "$yyyy${st}01 -1 month" +%Y`
export stm1=`date -d "$yyyy${st}01 -1 month" +%m`

wkdir=$SCRATCHDIR/${typeofrun}/${yyyy}${st}/IC_CICE
mkdir -p ${wkdir}
export ddm1=`date -d "$yyyy${st}01 -3 day" +%d` #latency of three days


export fnamemesh="$CESMDATAROOT/inputdata/ocn/nemo/tn0.25v3/grid/ORCA025L75_mesh_mask.nc"
#regridding obs to model grid
if [[ $yyyy -lt 2021 ]] ; then
  tag=ice
else
  tag=ice2
fi
if [[ `ls $WOIS/inputdata/SIC/OSISAF/${yym1}/${tag}_nh_${yym1}${stm1}??.nc.gz |wc -l` -ne 0 ]] ; then
     fileobs=`ls $WOIS/inputdata/SIC/OSISAF/${yym1}/${tag}_nh_${yym1}${stm1}??.nc.gz |tail -1`
     filename=`basename $fileobs |rev|cut -d '.' -f2-|rev`
elif [[ `ls $WOIS/inputdata/SIC/OSISAF/${yym1}/${tag}_nh_${yym1}${stm1}??.nc |wc -l` -ne 0 ]] ; then
     fileobs=`ls $WOIS/inputdata/SIC/OSISAF/${yym1}/${tag}_nh_${yym1}${stm1}??.nc |tail -1`
     filename=`basename $fileobs`
fi

if [[ ! -f $wkdir/${filename} ]]
then 
   rsync -auv $fileobs $wkdir
   if [[ -f $wkdir/${filename}.gz ]] ; then
      gzip -d $wkdir/${filename}.gz
   fi
fi
export typerun=$typeofrun
dateobs=`echo $filename |rev |cut -d '.' -f2|cut -d '_' -f1 |rev`
export ddobs=`echo ${dateobs} | cut -c7-8`
export obsregfile=${wkdir}/sic_osisaf_nh_${dateobs}_regrid.nc
if [[ ! -f $obsregfile ]] ; then
   targetgridfile=${REPOGRID}/grid_cice.txt
   obsgridfile=${REPOGRID}/osisaf_grid.txt
   cdo -O  remapcon,${targetgridfile} -setgrid,${obsgridfile} -selname,ice_conc ${wkdir}/$filename ${obsregfile}
fi
#rsync -auv ${IC_CICE_CPS_DIR}/${st}/*${yyyy}-${st}*nc $wkdir
export nic=`ls ${IC_CICE_CPS_DIR}/${st}/*${yyyy}-${st}*nc |wc -l`
export dirciceic="${IC_CICE_CPS_DIR}/${st}/"   
export pltype="png"

#operationally always plot full value and diff with obs
#in dbg mode it is possible to choose what to plot with the diff flag (default value=0)
if [[ $dbg -eq 0 ]] ; then
   pltname_diff="${wkdir}/${CPSSYS}_sic_obs_IC_diff_$yyyy${st}.${pltype}"
   pltname_full="${wkdir}/${CPSSYS}_sic_obs_IC_$yyyy${st}.${pltype}"
   export pltname=${pltname_diff}
   if [[ -f $pltname ]] ; then
       rm $pltname
   fi
   ncl ${DIR_OCE_IC}/check_obs_and_restart_seaice_diff.ncl

   export pltname=${pltname_full}
   if [[ -f $pltname ]] ; then
     rm $pltname
   fi  
   ncl ${DIR_OCE_IC}/check_obs_and_restart_seaice.ncl
else

   if [[ $diff -eq 0 ]] ; then
      export pltname="${wkdir}/${CPSSYS}_sic_obs_IC_diff_$yyyy${st}.${pltype}"
      if [[ -f $pltname ]] ; then
        rm $pltname
      fi
      ncl ${DIR_OCE_IC}/check_obs_and_restart_seaice_diff.ncl
   else
      export pltname="${wkdir}/${CPSSYS}_sic_obs_IC_$yyyy${st}.${pltype}"
      if [[ -f $pltname ]] ; then
         rm $pltname
      fi  
      ncl ${DIR_OCE_IC}/check_obs_and_restart_seaice.ncl
   fi
fi
