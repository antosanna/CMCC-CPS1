#!/bin/sh -l
#BSUB -q s_long
#BSUB -J check_all_stats_done
#BSUB -o ../../../../logs/DIAGS/stats/check_all_stats_done%J.out
#BSUB -e ../../../../logs/DIAGS/stats/check_all_stats_done%J.err
#BSUB -P 0490

. ~/.bashrc
. $DIR_SPS35/descr_SPS3.5.sh
. $DIR_SPS35/descr_hindcast.sh

# final check on the presence of all the required stats
set -uvxe
stlist="01 02 03 04 05 06 07 08 09 10 11 12"
#
outdir=$OUTDIR_DIAG/C3S_statistics/  
launchdir=$DIR_DIAG/C3S_statistics
endyear=2016
refperiod=1993-$endyear

# read C3S variables
# Tackle separately 3d, 2d and 2dmon (the first require much more memory)
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
   if [ $freq == "12hr" ]
   then
      var_array3d+=("$C3S")
   else
      var_array2d+=("$C3S")
   fi
done } < $C3Stable_cam
{
while IFS=, read -r flname C3S realm prec coord lname sname units freq level addfact coord2 cell
do
   var_array2d+=("$C3S")
done } < $C3Stable_clm
{
read 
while IFS=, read -r flname C3S lname sname units realm level addfact coord cell varflg reflev model fillval
do
   var_array2dmon+=("$C3S")
done } < $C3Stable_oce1
{
read 
while IFS=, read -r flname C3S lname sname units realm level addfact coord cell varflg reflev model fillval
do
   var_array2dmon+=("$C3S")
done } < $C3Stable_oce2
{
read 
while IFS=, read -r flname C3S lname sname units realm level addfact coord cell varflg reflev model fillval
do
   var_array2dmon+=("$C3S")
done } < $C3Stable_oce3
{
read 
while IFS=, read -r flname C3S lname sname units realm level addfact coord cell varflg reflev model fillval
do
   var_array2dmon+=("$C3S")
done } < $C3Stable_oce4
{
read 
while IFS=, read -r flname C3S lname sname units realm level addfact coord cell varflg reflev model fillval
do
   var_array2dmon+=("$C3S")
done } < $C3Stable_oce5
{
read 
while IFS=, read -r flname C3S lname sname units realm level addfact coord cell varflg reflev model fillval
do
   var_array2dmon+=("$C3S")
done } < $C3Stable_oce6
{
read 
while IFS=, read -r flname C3S lname sname units realm level addfact coord cell varflg reflev model fillval
do
   var_array2dmon+=("$C3S")
done } < $C3Stable_oce1
var_array=( "${var_array2d[@]}" "${var_array3d[@]}" "${var_array2dmon[@]}")

institude_id="cmcc"
model_id="CMCC-CM2-v"$versionSPS
fileroot=${institude_id}_${model_id}_${typeofrun}
echo "you are going to process: ${var_array[@]}"

for st in $stlist
do
   inpdir=$OUTDIR_DIAG/C3S_statistics/$st  

   ic=0
   for var in ${var_array[@]}; do
       if [ "$var" == "orog" ] || [ "$var" == "sftlf" ] || [ "$var" == "rsdt" ] || [ "$var" == "zos" ] || [ "$var" == "sos" ] || [ "$var" == "sot300" ] || [ "$var" == "thetaot300" ] || [ "$var" == "t14d" ] || [ "$var" == "t17d" ] || [ "$var" == "t20d" ] || [ "$var" == "t26d" ] || [ "$var" == "t28d" ] || [ "$var" == "mlotstheta001" ] || [ "$var" == "mlotstheta003" ] || [ "$var" == "sithick" ]
       then
          continue
       fi  
       fileok=$outdir/$st/${var}/ALLDONE_${var}_$st
       if [ -f $fileok ]
       then
          echo "ALLDONE_${var}_$st"
          continue
       fi
   done
   echo ""
   echo "completed check for startdate $st (should be 38)"
   echo "ALLDONE files in number "
   ndone=`ls $outdir/$st/[a-z]*|grep ALLDONE|wc -l`
   if [[ $ndone -ne 38 ]]
   then
      title="ERROR IN C3S_statistics"
      body="C3S_statistics incomplete for $st. ALLDONE file $ndone instead of expected 38"
      $DIR_SPS35/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
      exit
   fi
   echo $ndone
   echo ""
   echo ""
done
