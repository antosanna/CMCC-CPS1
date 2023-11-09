#!/bin/sh -l
#BSUB -q s_long
#BSUB -J launch_compute_stats_part2
#BSUB -o ../../../../logs/DIAGS/stats/launch_compute_stats_part2%J.out
#BSUB -e ../../../../logs/DIAGS/stats/launch_compute_stats_part2%J.err
#BSUB -P 0490

. ~/.bashrc
. $DIR_SPS35/descr_SPS3.5.sh
. $DIR_SPS35/descr_hindcast.sh

# THIS SCRIPT IS MEANT TO BE LAUNCHED FROM CRONTAB
# check is done in the inner script
set -uvxe
stlist="01 02 03 04 05 06 07 08 09 10 11 12"
debug=0   # IN debug=1 only uas is processed; debug=2 exit at the first cycle;debug=3 only vectorial fields
do_only_wind=1  # if 1 computes onyl for winds
#
# IN debug=1 MODE ONLY ONE VAR (instead of all 53)
namescript=stdev_on_line
outdir=$OUTDIR_DIAG/C3S_statistics/  
launchdir=$DIR_DIAG/C3S_statistics
endyear=2016
refperiod=1993-$endyear
nens=40
mkdir -p $outdir
mkdir -p ${DIR_LOG}/DIAGS

# read C3S variables
# Tackle separately 3d, 2d and 2dmon (the first require much more memory)
C3Stablecam=$DIR_POST/cam/C3S_table.txt
C3Stableclm=$DIR_POST/clm/C3S_table_clm.txt
C3Stableocean=$DIR_POST/nemo/C3S_table_ocean2d.txt
{
read 
while IFS=, read -r flname C3S dim lname sname units freq type realm addfact coord cell varflg
do
   if [ $freq == "12hr" ]
   then
      var_array3d+=("$C3S")
   else
      var_array2d+=("$C3S")
   fi
done } < $C3Stablecam
{
while IFS=, read -r flname C3S realm prec coord lname sname units freq level addfact coord2 cell
do
   var_array2d+=("$C3S")
done } < $C3Stableclm
{
read 
while IFS=, read -r flname C3S lname sname units realm level addfact coord cell varflg reflev model fillval
do
   var_array2dmon+=("$C3S")
done } < $C3Stableocean
var_array=( "${var_array2d[@]}" "${var_array3d[@]}" "${var_array2dmon[@]}")

institude_id="cmcc"
model_id="CMCC-CM2-v"$versionSPS
fileroot=${institude_id}_${model_id}_${typeofrun}
if [[ $debug -eq 3 ]]
then
   varlist="ua va vas uas tauu tauv"
else
   varlist=${var_array[@]}
fi
echo "you are going to process: ${varlist[@]}"

for st in $stlist
do
   inpdir=$outdir/$st  

   ic=0
   for var in ${varlist[@]}; do
       if [ $debug -eq 1 ] && [ $var != "uas" ]
       then
         continue
       fi
       if [ "$var" == "orog" ] || [ "$var" == "sftlf" ] || [ "$var" == "rsdt" ] || [ "$var" == "zos" ] || [ "$var" == "sos" ] || [ "$var" == "sot300" ] || [ "$var" == "thetaot300" ] || [ "$var" == "t14d" ] || [ "$var" == "t17d" ] || [ "$var" == "t20d" ] || [ "$var" == "t26d" ] || [ "$var" == "t28d" ] || [ "$var" == "mlotstheta001" ] || [ "$var" == "mlotstheta003" ] || [ "$var" == "sithick" ]
       then
          continue
       fi  
       if [[ "$var" == "ua" ]] || [[ "$var" == "va" ]] || [[ "$var" == "vas" ]] || [[ "$var" == "uas" ]] || [[ "$var" == "tauu" ]] || [[ "$var" == "tauv" ]]
       then
          wind=1
       else   
          wind=0
# already computed
          if [[ $do_only_wind -eq 1 ]]
          then
             continue
          fi     
       fi     

       echo "Launch $var"
       mkdir -p $outdir/$st/${var}/
       fileok=$outdir/$st/${var}/ALLDONE_${var}_$st
       if [ -f $fileok ]
       then
          continue
       fi
       input="$var ${refperiod} $st $inpdir $outdir/ $fileroot $fileok $endyear $nens $namescript"
       ${DIR_SPS35}/submitcommand.sh -m $machine -M 10000  -S qos_resv -t "1" -q $serialq_m -j compute_stats_refperiod_${var} -l $DIR_LOG/DIAGS/stats -d ${launchdir} -s compute_stats_refperiod.sh -i "$input"
       if [ $debug -eq 2 ]
       then
          exit 0
       fi
   done
done
