#!/bin/sh -l
#BSUB -P 0490
#BSUB -q s_medium
#BSUB -J monthly_maxmin
#BSUB -e /work/cmcc/cp1//CPS/CMCC-CPS1/logs/DIAGS/C3S_statistics/monthly_maxmin_%J.err
#BSUB -o /work/cmcc/cp1//CPS/CMCC-CPS1/logs/DIAGS/C3S_statistics/monthly_maxmin_%J.out
#BSUB -M 10000
. ~/.bashrc
. $DIR_UTIL/load_cdo
. $DIR_UTIL/load_nco
set -euvx
dbg=0 #just one cycle to check
fileroot=cmcc_CMCC-CM3-v20231101_hindcast
C3Stable_cam=$DIR_POST/cam/C3S_table.txt
C3Stable_clm=$DIR_POST/clm/C3S_table_clm.txt
C3Stable_oce1=$DIR_POST/nemo/C3S_table_ocean2d_others.txt
C3Stable_oce2=$DIR_POST/nemo/C3S_table_ocean2d_t14d.txt
C3Stable_oce3=$DIR_POST/nemo/C3S_table_ocean2d_t17d.txt
C3Stable_oce4=$DIR_POST/nemo/C3S_table_ocean2d_t20d.txt
C3Stable_oce5=$DIR_POST/nemo/C3S_table_ocean2d_t26d.txt
C3Stable_oce6=$DIR_POST/nemo/C3S_table_ocean2d_t28d.txt
{
read 
while IFS=, read -r flname C3S dim lname sname units freq type realm addfact coord cell varflg
do
      var_arrayC3S+=("$C3S")
done } < $C3Stable_cam
{
while IFS=, read -r flname C3S realm prec coord lname sname units freq level addfact coord2 cell
do
   var_arrayC3S+=("$C3S")
done } < $C3Stable_clm
{
read 
while IFS=, read -r flname C3S lname sname units realm level addfact coord cell varflg reflev model fillval
do
   var_arrayC3S+=("$C3S")
done } < $C3Stable_oce1
{
read 
while IFS=, read -r flname C3S lname sname units realm level addfact coord cell varflg reflev model fillval
do
   var_arrayC3S+=("$C3S")
done } < $C3Stable_oce2
{
read 
while IFS=, read -r flname C3S lname sname units realm level addfact coord cell varflg reflev model fillval
do
   var_arrayC3S+=("$C3S")
done } < $C3Stable_oce3
{
read 
while IFS=, read -r flname C3S lname sname units realm level addfact coord cell varflg reflev model fillval
do
   var_arrayC3S+=("$C3S")
done } < $C3Stable_oce4
{
read 
while IFS=, read -r flname C3S lname sname units realm level addfact coord cell varflg reflev model fillval
do
   var_arrayC3S+=("$C3S")
done } < $C3Stable_oce5
{
read 
while IFS=, read -r flname C3S lname sname units realm level addfact coord cell varflg reflev model fillval
do
   var_arrayC3S+=("$C3S")
done } < $C3Stable_oce6

         
echo ${var_arrayC3S[@]}
for st in 10
do
   for var in ${var_arrayC3S[@]}
   do
      echo " postprocessing $var"
      case $var in
         tso | sitemptop | tsl | tdps | psl | tas | uas | vas | prw | ua100m | va100m)freq=6hour;;
         tauu | tauv | tasmax | tasmin | wsgmax | lwepr | lweprc | lweprsn | lwesnw | rss | rsds | rlds | sic | rls | rlt | lwee | mrroab | mrroas | rhosn | hfls | hfss) freq=1day;;
         zg | ta | ua | va | hus) freq=12hour;;
         mlotstheta001 | mlotstheta003 | sithick | sos | sot300 | thetaot300 | zos | t14d | t17d | t20d | t26d | t28d )freq=1month;;
      esac
      if [[ `ls $OUTDIR_DIAG/C3S_statistics/$st/????/$var/maxminDONE_${var}_????$st |wc -l` -ne 30 ]]
      then
         $DIR_UTIL/sendmail.sh -m $machine -e antonella.sanna@cmcc.it -M "single year statistics missing for ${var} $st. First run $DIR_DIAG_C3S/statistics/launch_maxmin_single_year.sh" -t "missing maxminDONE_${var}_????$st"
         continue
      fi
      for flag in min max
      do
         if [[ -f $OUTDIR_DIAG/C3S_statistics/$st/$var/${fileroot}_${st}.${iniy_hind}-${endy_hind}_${var}_${flag}.monthly.C3S.nc ]]
         then
            continue
         fi
         mkdir -p $OUTDIR_DIAG/C3S_statistics/$st/$var
         outfile=$OUTDIR_DIAG/C3S_statistics/$st/$var/${fileroot}_${st}.${iniy_hind}-${endy_hind}_${var}_${flag}.nc
         if [[ -f $outfile ]]
         then
            continue
         else
            if [[ $flag == "max" ]]
            then
               nces -O -y max -v ${var} ${OUTDIR_DIAG}/C3S_statistics/$st/19??/${var}/${fileroot}_S????${st}_*${var}_max.nc ${OUTDIR_DIAG}/C3S_statistics/$st/20[012]?/${var}/${fileroot}_S????${st}_*${var}_max.nc  ${outfile}
            elif [[ $flag == "min" ]]
            then
               nces -O -y min -v ${var} ${OUTDIR_DIAG}/C3S_statistics/$st/19??/${var}/${fileroot}_S????${st}_*${var}_min.nc ${OUTDIR_DIAG}/C3S_statistics/$st/20[012]?/${var}/${fileroot}_S????${st}_*${var}_min.nc  ${outfile}
            fi
         fi
         
         if [[ ! -f $SCRATCHDIR/C3S_statistics/${fileroot}_${st}.${iniy_hind}-${endy_hind}_${var}_${flag}.fixed.nc ]]
         then
            cdo settaxis,${iniy_hind}-$st-01,00:00:00,$freq $outfile $SCRATCHDIR/C3S_statistics/${fileroot}_${st}.${iniy_hind}-${endy_hind}_${var}_${flag}.tmp.nc
            cdo setreftime,${iniy_hind}-$st-01,00:00:00 $SCRATCHDIR/C3S_statistics/${fileroot}_${st}.${iniy_hind}-${endy_hind}_${var}_${flag}.tmp.nc $SCRATCHDIR/C3S_statistics/${fileroot}_${st}.${iniy_hind}-${endy_hind}_${var}_${flag}.fixed.nc
            rm $SCRATCHDIR/C3S_statistics/${fileroot}_${st}.${iniy_hind}-${endy_hind}_${var}_${flag}.tmp.nc 
         fi 
         cdo splitmon $SCRATCHDIR/C3S_statistics/${fileroot}_${st}.${iniy_hind}-${endy_hind}_${var}_${flag}.fixed.nc $SCRATCHDIR//C3S_statistics/${fileroot}_${st}.${iniy_hind}-${endy_hind}_${var}_${flag}.fixed.
         if [[ $flag == "max" ]]
         then
            cdo monmax $SCRATCHDIR//C3S_statistics/${fileroot}_${st}.${iniy_hind}-${endy_hind}_${var}_${flag}.fixed.nc $SCRATCHDIR//C3S_statistics/${fileroot}_${st}.${iniy_hind}-${endy_hind}_${var}_${flag}.monthly.nc
         elif [[ $flag == "min" ]]
         then
            cdo monmin $SCRATCHDIR//C3S_statistics/${fileroot}_${st}.${iniy_hind}-${endy_hind}_${var}_${flag}.fixed.nc $SCRATCHDIR//C3S_statistics/${fileroot}_${st}.${iniy_hind}-${endy_hind}_${var}_${flag}.monthly.nc
         fi
         cdo splitmon $SCRATCHDIR//C3S_statistics/${fileroot}_${st}.${iniy_hind}-${endy_hind}_${var}_${flag}.monthly.nc $SCRATCHDIR//C3S_statistics/${fileroot}_${st}.${iniy_hind}-${endy_hind}_${var}_${flag}.monthly_
         if [[ ! -f $SCRATCHDIR//C3S_statistics/zeros.$var.$st.$freq.nc ]]
         then
            cdo sub $SCRATCHDIR//C3S_statistics/${fileroot}_${st}.${iniy_hind}-${endy_hind}_${var}_${flag}.fixed.nc $SCRATCHDIR//C3S_statistics/${fileroot}_${st}.${iniy_hind}-${endy_hind}_${var}_${flag}.fixed.nc $SCRATCHDIR//C3S_statistics/zeros.$var.$st.$freq.nc
            cdo splitmon $SCRATCHDIR//C3S_statistics/zeros.$var.$st.$freq.nc $SCRATCHDIR//C3S_statistics/zeros.$var.${st}.${freq}_
         fi 
         for mm in `seq $st $(($((10#$st)) + 6))`
         do
            if [[ $mm -gt 12 ]]
            then
               mm=$(($mm - 12))
            fi
            mm=`printf '%.2d' $mm`
            if [[ ! -f $SCRATCHDIR//C3S_statistics/zeros.$var.$st.${freq}_${mm}.nc ]]
            then
               cdo splitmon $SCRATCHDIR//C3S_statistics/zeros.$var.$st.${freq}.nc $SCRATCHDIR//C3S_statistics/zeros.$var.${st}.${freq}_
            fi
            cdo add $SCRATCHDIR//C3S_statistics/zeros.$var.${st}.${freq}_${mm}.nc $SCRATCHDIR//C3S_statistics/${fileroot}_${st}.${iniy_hind}-${endy_hind}_${var}_${flag}.monthly_${mm}.nc $SCRATCHDIR//C3S_statistics/${fileroot}_${st}.${iniy_hind}-${endy_hind}_${var}_${flag}.monthly.$mm.nc
         done
         cdo -O mergetime $SCRATCHDIR/C3S_statistics/${fileroot}_${st}.${iniy_hind}-${endy_hind}_${var}_${flag}.monthly.??.nc $OUTDIR_DIAG/C3S_statistics/$st/$var/${fileroot}_${st}.${iniy_hind}-${endy_hind}_${var}_${flag}.monthly.C3S.nc
      done
      if [[ $dbg -eq 1 ]]
      then
         exit 0
      fi
   done
done
