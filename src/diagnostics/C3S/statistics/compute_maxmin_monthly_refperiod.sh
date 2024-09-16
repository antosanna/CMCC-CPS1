#!/bin/sh -l
#BSUB -P 0490
#BSUB -q s_medium
#BSUB -J monthly_maxmin
#BSUB -e /work/cmcc/cp1//CPS/CMCC-CPS1/logs/C3S_statistics/monthly_maxmin_%J.err
#BSUB -o /work/cmcc/cp1//CPS/CMCC-CPS1/logs/C3S_statistics/monthly_maxmin_%J.out
#BSUB -M 10000
. ~/.bashrc
. $DIR_UTIL/load_cdo
set -euvx
C3Svar="tso tsl tdps psl tas uas vas tauu tauv tasmax tasmin wsgmax lwepr rss rls rlt zg ta ua va hus prw ua100m va100m mrroas lwee mrroab rhosn hfls mlotstheta001 mlotstheta003 sithick sos sot300 thetaot300 zos t14d t17d t20d t26d t28d"
         
for st in {01..12}
do
   for var in $C3Svar
   do
      case $var in
         tso | tsl | tdps | psl | tas | uas | vas | prw | ua100m | va100m)freq=6hour;;
         tauu | tauv | tasmax | tasmin | wsgmax | lwepr | rss | rls | rlt | lwee | mrroab | mrroas | rhosn | hfls | hfss) freq=day;;
         zg | ta | ua | va | hus) freq=12hour;;
         mlotstheta001 | mlotstheta003 | sithick | sos | sot300 | thetaot300 | zos | t14d | t17d | t20d | t26d | t28d )freq=1month;;
      esac
      for flag in min max
      do
         if [[ -f $OUTDIR_DIAG/C3S_statistics/$st/$var/cmcc_CMCC-CM2-v20191201_hindcast_${st}.1993-2022_${var}_${flag}.monthly.C3S.nc ]]
         then
            continue
         fi
         if [[ ! -f $SCRATCHDIR/C3S_statistics/cmcc_CMCC-CM2-v20191201_hindcast_${st}.1993-2022_${var}_${flag}.fixed.nc ]]
         then
            cdo settaxis,1993-$st-01,00:00:00,$freq $OUTDIR_DIAG/C3S_statistics/$st/$var/cmcc_CMCC-CM2-v20191201_hindcast_${st}.1993-2022_${var}_${flag}.nc $SCRATCHDIR/C3S_statistics/cmcc_CMCC-CM2-v20191201_hindcast_${st}.1993-2022_${var}_${flag}.tmp.nc
            cdo setreftime,1993-$st-01,00:00:00 $SCRATCHDIR/C3S_statistics/cmcc_CMCC-CM2-v20191201_hindcast_${st}.1993-2022_${var}_${flag}.tmp.nc $SCRATCHDIR/C3S_statistics/cmcc_CMCC-CM2-v20191201_hindcast_${st}.1993-2022_${var}_${flag}.fixed.nc
            rm $SCRATCHDIR/C3S_statistics/cmcc_CMCC-CM2-v20191201_hindcast_${st}.1993-2022_${var}_${flag}.tmp.nc 
         fi 
         cdo splitmon $SCRATCHDIR/C3S_statistics/cmcc_CMCC-CM2-v20191201_hindcast_${st}.1993-2022_${var}_${flag}.fixed.nc $SCRATCHDIR//C3S_statistics/cmcc_CMCC-CM2-v20191201_hindcast_${st}.1993-2022_${var}_${flag}.fixed.
         if [[ $flag == "max" ]]
         then
            cdo monmax $SCRATCHDIR//C3S_statistics/cmcc_CMCC-CM2-v20191201_hindcast_${st}.1993-2022_${var}_${flag}.fixed.nc $SCRATCHDIR//C3S_statistics/cmcc_CMCC-CM2-v20191201_hindcast_${st}.1993-2022_${var}_${flag}.monthly.nc
         elif [[ $flag == "min" ]]
         then
            cdo monmin $SCRATCHDIR//C3S_statistics/cmcc_CMCC-CM2-v20191201_hindcast_${st}.1993-2022_${var}_${flag}.fixed.nc $SCRATCHDIR//C3S_statistics/cmcc_CMCC-CM2-v20191201_hindcast_${st}.1993-2022_${var}_${flag}.monthly.nc
         fi
         cdo splitmon $SCRATCHDIR//C3S_statistics/cmcc_CMCC-CM2-v20191201_hindcast_${st}.1993-2022_${var}_${flag}.monthly.nc $SCRATCHDIR//C3S_statistics/cmcc_CMCC-CM2-v20191201_hindcast_${st}.1993-2022_${var}_${flag}.monthly_
         if [[ ! -f $SCRATCHDIR//C3S_statistics/zeros.$var.$st.$freq.nc ]]
         then
            cdo sub $SCRATCHDIR//C3S_statistics/cmcc_CMCC-CM2-v20191201_hindcast_${st}.1993-2022_${var}_${flag}.fixed.nc $SCRATCHDIR//C3S_statistics/cmcc_CMCC-CM2-v20191201_hindcast_${st}.1993-2022_${var}_${flag}.fixed.nc $SCRATCHDIR//C3S_statistics/zeros.$var.$st.$freq.nc
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
            cdo add $SCRATCHDIR//C3S_statistics/zeros.$var.${st}.${freq}_${mm}.nc $SCRATCHDIR//C3S_statistics/cmcc_CMCC-CM2-v20191201_hindcast_${st}.1993-2022_${var}_${flag}.monthly_${mm}.nc $SCRATCHDIR//C3S_statistics/cmcc_CMCC-CM2-v20191201_hindcast_${st}.1993-2022_${var}_${flag}.monthly.$mm.nc
         done
         cdo -O mergetime $SCRATCHDIR/C3S_statistics/cmcc_CMCC-CM2-v20191201_hindcast_${st}.1993-2022_${var}_${flag}.monthly.??.nc $OUTDIR_DIAG/C3S_statistics/$st/$var/cmcc_CMCC-CM2-v20191201_hindcast_${st}.1993-2022_${var}_${flag}.monthly.C3S.nc
      done
   done
done
