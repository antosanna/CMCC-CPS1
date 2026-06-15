#!/bin/sh -l
#BSUB -P 0784
#BSUB -q s_medium
#BSUB -J monthly_maxmin
#BSUB -e /work/cmcc/cp1//CPS/CMCC-CPS1/logs/DIAGS/C3S_statistics/monthly_maxmin_%J.err
#BSUB -o /work/cmcc/cp1//CPS/CMCC-CPS1/logs/DIAGS/C3S_statistics/monthly_maxmin_%J.out
#BSUB -M 10000
. ~/.bashrc
. $DIR_UTIL/load_cdo
. $DIR_UTIL/load_nco
set -euvx
st=$1
var=$2
echo $st
dbg=0 #just one cycle to check
fileroot=cmcc_CMCC-CM3-v20231101_hindcast
         
for st in $st
do
   for var in ${var}
   do
      echo " postprocessing $var"
      case $var in
         tso | clt | sitemptop | tsl | tdps | psl | tas | uas | vas | prw | ua100m | va100m)freq=6hour;;
         tauu | tauv | tasmax | tasmin | wsgmax | lwepr | lweprc | lweprsn | lwesnw | rss | rst| rsds | rlds | sic | rls | rlt | lwee | mrlsl | mrroab | mrroas | rhosn | hfls | hfss | snc) freq=1day;;
         zg | ta | ua | va | hus) freq=12hour;;
         mlotstheta001 | mlotstheta003 | sithick | sos | sot300 | thetaot300 | zos | t14d | t17d | t20d | t26d | t28d )freq=1month;;
      esac
      listaflag=" "
      counter=0
      for yyyy in `seq $iniy_hind $endy_hind`
      do
         if [[ -f ${OUTDIR_DIAG}/C3S_statistics/$st/$yyyy/${var}/maxminDONE_${var}_${yyyy}${st} ]]
         then
            listaflag+=" ${OUTDIR_DIAG}/C3S_statistics/$st/$yyyy/${var}/maxminDONE_${var}_${yyyy}${st}"
             counter=$((counter + 1))
         fi
      done
      for flag in min max
      do
         if [[ -f $OUTDIR_DIAG/C3S_statistics/$st/$var/${fileroot}_${st}.${iniy_hind}-${endy_hind}_${var}_${flag}.monthly.C3S.nc ]]
         then
            continue
         fi
         mkdir -p $OUTDIR_DIAG/C3S_statistics/$st/$var
         outfile=$OUTDIR_DIAG/C3S_statistics/$st/$var/${fileroot}_${st}.${iniy_hind}-${endy_hind}_${var}_${flag}.nc
         if [[ ! -f $outfile ]]
         then
            if [[ $flag == "max" ]]
            then
               listaf=" "
               for yyyy in `seq $iniy_hind $endy_hind`
               do
                  listaf+=" "`ls ${OUTDIR_DIAG}/C3S_statistics/$st/$yyyy/${var}/${fileroot}_S${yyyy}${st}_*${var}_max.nc`
               done
               nces -O -y max -v ${var} ${listaf} ${outfile}
            elif [[ $flag == "min" ]]
            then
               listaf=" "
               for yyyy in `seq $iniy_hind $endy_hind`
               do
                  listaf+=" "`ls ${OUTDIR_DIAG}/C3S_statistics/$st/$yyyy/${var}/${fileroot}_S${yyyy}${st}_*${var}_min.nc`
               done
               nces -O -y min -v ${var} ${listaf} ${outfile}
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
         if [[ ! -f $OUTDIR_DIAG/C3S_statistics/$st/$var/${fileroot}_${st}.${iniy_hind}-${endy_hind}_${var}_${flag}.monthly.C3S.nc ]]
         then
            $DIR_UTIL/sendmail.sh -m $machine -e antonella.sanna@cmcc.it -M "C3S statistics not done for ${var} $st" -t "Message from compute_maxmin_monthly_refperiod.sh: WARNING $var"

            exit
         fi
      done
      if [[ $dbg -eq 1 ]]
      then
         exit 0
      fi
   done
done
