#!/bin/sh -l
#BSUB -o ../../../../logs/SIPN/SIPN_diagnostics%J.out  # Appends std output to file %J.out.
#BSUB -e ../../../../logs/SIPN/SIPN_diagnostics%J.err  # Appends std error to file %J.err.
#BSUB -J SIPN_diagnostics
#BSUB -q s_medium       # queue
#BSUB -P 0490
. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/load_cdo
. $DIR_UTIL/load_nco

set -evxu

if [[ `whoami` != "sp2" ]]   #to be defined
then
   echo "YOU ARE NOT MEANT TO RUN THIS SCRIPT! please verifty you are doing the right thing"
   exit 1
fi

yyyy=`date +%Y`
st=`date +%m`
#skipconc=1
#st=11
if [[ $# -eq 1 ]]
then
   yyyy=$1
elif [[ $# -eq 2 ]]
then
   yyyy=$1
   st=$2
fi
launchdir=$DIR_DIAG/SIPN
if [ $yyyy -gt $endy_hind ]
then
   . $DIR_UTIL/descr_forecast.sh
else
   . $DIR_UTIL/descr_hindcast.sh
fi
yyyyp1=`date -d "$yyyy${st}01  + 1 month" +%Y`
stp1=`date -d "$yyyy${st}01  + 1 month" +%m`
dbg=0    # process only one file
if [ "$st" == "11" ]
then
   seas="DJF"
   hem=SH
fi
if [ "$st" == "04" ]
then
   seas="MJJ"
   hem=NH
fi
echo "----- SIPN: Sea-Ice Prediction Network --------------"
echo "----- you are going to process data relative to $yyyy"
echo "----- SIPN postprocessing for ${st}, $seas and $hem hemisphere"
outdir=$OUTDIR_DIAG/SIPN/sea-ice_areas/$yyyy$st/$hem
mkdir -p $outdir
outdircon=$OUTDIR_DIAG/SIPN/concentrations/$yyyy$st/$hem
mkdir -p $outdircon
archdir=$WORK_C3S1/${yyyy}${st}
datadir=$SCRATCHDIR/SIPN/daily
mkdir -p $datadir

case $hem
 in
 NH) export lat1=0.   ; export lat2=90. ;;
 SH) export lat1=-90. ; export lat2=0. ;;
esac

case $st
in
   01)       tstep1=32 ; tstep2=120 ;;
   02)       tstep1=29 ; tstep2=120 ;;
   03|08)    tstep1=32 ; tstep2=122 ;;
   04|06|09) tstep1=31 ; tstep2=122 ;;
   05|07|10) tstep1=32 ; tstep2=123 ;;
   11)       tstep1=31 ; tstep2=120 ;;
   12)       tstep1=32 ; tstep2=121 ;; 
esac

# account for leap year
leap=`$DIR_DIAG/SIPN/isleap.sh $yyyy $st`
if [ $leap -eq 1 ]
then
   case $st
   in
      01)       tstep1=32 ; tstep2=121 ;;
      02)       tstep1=30 ; tstep2=121 ;;
      09)       tstep1=31 ; tstep2=123 ;;
      10)       tstep1=32 ; tstep2=124 ;;
      11)       tstep1=31 ; tstep2=121 ;;
      12)       tstep1=32 ; tstep2=122 ;; 
   esac
fi

export fila=${datadir}/area.nc
if [ ! -f $fila ]
then
   cdo -gridarea cmcc_sic_${yyyy}${st}_001_${seas}_daily.nc ${datadir}/area.nc
fi

cd $datadir

if [[ $skipconc -ne 1 ]]
then
flist=`ls $archdir/cmcc_CMCC-CM2-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_seaIce_day_surface_sic_r*.nc |head -$nrunC3Sfore` 

for ff in $flist 
do
     pp=`echo $ff | cut -d '.' -f1 |cut -d '_' -f9 |     cut -c2-3`
#
     if [ -f $datadir/cmcc_sic_${yyyy}${st}_0${pp}.nc ]
     then
       continue
     fi
     cdo settaxis,${yyyy}-$st-01,12:00,1day $ff sic_${yyyy}${st}_0${pp}_tmp.nc
     cdo setreftime,${yyyy}-$st-01,12:00 sic_${yyyy}${st}_0${pp}_tmp.nc cmcc_sic_${yyyy}${st}_0${pp}.nc
     rm sic_${yyyy}${st}_0${pp}_tmp.nc

   
     if [ $dbg -eq 1 ]
     then
        exit
     fi
done  #end loop on flist

cd $datadir

flist=`ls -1 cmcc_sic_${yyyy}${st}_0??.nc`

for ff in $flist 
do
    pp=`echo $ff | cut -d '.' -f1 |cut -d '_' -f4`
    if [ -f cmcc_sic_${yyyy}${st}_${pp}_${seas}_daily.nc ]
    then
       continue
    fi

    ncks -O -F -d time,${tstep1},${tstep2} cmcc_sic_${yyyy}${st}_${pp}.nc cmcc_sic_${yyyy}${st}_${pp}_${seas}_daily.nc

done     

flist=`ls -1 cmcc_sic_${yyyy}${st}_0??_${seas}_daily.nc |head -$nrunC3Sfore`

for ff in $flist 
do
    pp=`echo $ff | cut -d '.' -f1 |cut -d '_' -f4`
    export outfile=$outdircon/cmcc_${pp}_${yyyy}${st}01_${yyyyp1}0228_concentration.nc
    if [ -f $outfile ]
    then
       continue
    fi
    export ifile="cmcc_sic_${yyyy}${st}_${pp}_${seas}_daily.nc"
    export smask="${REPOSITORY}/cmcc_CMCC-CM2-v${versionSPS}_hindcast_S1993050100_atmos_fix_surface_sftlf_r26i00p00.nc"
    export tunits="days since $yyyyp1-$stp1-01"
    export firstmonthdays=`$DIR_UTIL/days_in_month.sh $st $yyyy`

    ncl $launchdir/make_concentration.ncl

done
fi


cd $datadir

export diri=$datadir/
export dira=${datadir}/
cd $datadir
flist=`ls cmcc_sic_${yyyy}${st}_???_${seas}_daily.nc| head -$nrunC3Sfore`
#echo $flist
for  file in $flist
do
    pp=`ls $file|cut -d "_" -f4`
    export filename=$file
    export csv_filename=$outdir/cmcc_${pp}_total-area.txt
    export csv_filename_bin=$outdir/cmcc_${pp}_regional-area.txt
    if [ -f $csv_filename ]
    then
      rm $csv_filename
    fi
    if [ -f $csv_filename_bin ]
    then
      rm $csv_filename_bin
    fi

    export okfile=$datadir/cmcc_sic_${yyyy}${st}_${pp}_${seas}_conc_ok
    ncl $launchdir/sea_ice_area_pp.ncl
    if [ ! -f $okfile ]
    then
        echo " something wrong with $launchdir/sea_ice_area_pp.ncl"
        exit 1
    fi
done
