#!/bin/sh -l
#BSUB -J IRI_csv
#BSUB -e /work/cmcc/cp1/CPS/CMCC-CPS1/logs/forecast/IRI/IRI_csv_%J.err
#BSUB -o /work/cmcc/cp1/CPS/CMCC-CPS1/logs/forecast/IRI/IRI_csv_%J.out
#BSUB -M 1000
#BSUB -P 0784

. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh

set -euvx

export yyyy=`date +%Y`
set +evx
. $DIR_UTIL/descr_ensemble.sh $yyyy
set -evx
export st=`date +%m`
export refperiod=1993-2020

ok_flag=DIR_LOG/forecast/$yyyy$st/diagnostics/sst_anomalies_${yyyy}${st}_${refperiod}_DONE
if [[ ! -f $ok_flag ]]
then
   ./launch_compute_anomalies_C3S_sst_to_IRI.sh $yyyy $st $refperiod
fi

export csvdir=$WORK/CPS/CMCC-CPS1/IRI_csv_files/${yyyy}${st}
mkdir -p $csvdir

export mm_string=`date +%B`
export mmp1_string=`date -d "${yyyy}${st}01 +1month" +%B`
export mmp2_string=`date -d "${yyyy}${st}01 +2months" +%B`
export mmp3_string=`date -d "${yyyy}${st}01 +3months" +%B`
export mmp4_string=`date -d "${yyyy}${st}01 +4months" +%B`
export mmp5_string=`date -d "${yyyy}${st}01 +5months" +%B`

export H0 H1 H2 H3 
case $st
 in
 01) SS0="JFM" ; SS1="FMA" ; SS2="MAM" ; SS3="AMJ";;
 02) SS0="FMA" ; SS1="MAM" ; SS2="AMJ";SS3="MJJ" ;;
 03) SS0="MAM" ; SS1="AMJ" ; SS2="MJJ" ; SS3="JJA" ;;
 04) SS0="AMJ" ; SS1="MJJ" ; SS2="JJA" ; SS3="JAS" ;;
 05) SS0="MJJ" ; SS1="JJA" ; SS2="JAS" ; SS3="ASO" ;;
 06) SS0="JJA" ; SS1="JAS" ; SS2="ASO" ; SS3="SON" ;;
 07) SS0="JAS" ; SS1="ASO" ; SS2="SON" ; SS3="OND" ;;
 08) SS0="ASO" ; SS1="SON" ; SS2="OND" ; SS3="NDJ" ;;
 09) SS0="SON" ; SS1="OND" ; SS2="NDJ" ; SS3="DJF" ;;
 10) SS0="OND" ; SS1="NDJ" ; SS2="DJF" ; SS3="JFM" ;;
 11) SS0="NDJ" ; SS1="DJF" ; SS2="JFM" ; SS3="FMA" ;;
 12) SS0="DJF" ; SS1="JFM" ; SS2="FMA" ; SS3="MAM" ;;
esac
diags="Nino3.4 "
H0=$diags$SS0
H1=$diags$SS1
H2=$diags$SS2
H3=$diags$SS3

###NINO3.4 box
export lat1n=-5
export lat2n=5
export lon1n=190
export lon2n=240
ncl NINO3.4_csv_sea.ncl
diags="IOD "
H0=$diags$SS0
H1=$diags$SS1
H2=$diags$SS2
H3=$diags$SS3
ncl IOD_csv_monthly.ncl

export stdfile=$WORK/CPS/CMCC-CPS1/rel_nino3.4/std4RONI_tropic_nino_sst.${st}.sea.${refperiod}.nc

###Tropical band
export lat1t=-20
export lat2t=20
export lon1t=0
export lon2t=360
diags="Rel. Nino3.4 "
H0=$diags$SS0
H1=$diags$SS1
H2=$diags$SS2
H3=$diags$SS3

export anomdir=${DIR_FORE_ANOM}/$yyyy$st
ncl RONI_csv_sea.ncl

#load the rclone environment
set +euvx
. ~/load_miniconda
conda activate rclone_gdrive
set -euvx
# create the specific dir
rclone mkdir my_drive:IRI/$yyyy$st

cd $csvdir
listaf=`ls *csv`
for ff in $listaf
do
   rclone copy $ff my_drive:IRI/$yyyy$st
done

title="CMCC-${SPSSystem} ${typeofrun} ${yyyy}${st} data available"
body="Dear Muhammad and all, \n
\n
This is to notify that the csv files for Nino3.4, realtive Nino3.4 and IOD, issued this month $yyyy$st, have been computed and are available at https://drive.google.com/drive/u/1/folders/1C7XlBqVeOQeChcC02CHFzraNFEqPesYy (directory ${yyyy}${st}). \n
\n
Many thanks for your cooperation \n
CMCC-SPS staff\n"

${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -c $IRImail -b $mymail -r $typeofrun -s $yyyy$st
exit 0
