#!/bin/sh -l
#BSUB -q s_long
#BSUB -J check_stats
#BSUB -o check_stats_%J.out
#BSUB -e check_stats_%J.err
#BSUB -P 0490

# Load descriptor
. ~/.bashrc
. $DIR_SPS35/descr_SPS3.5.sh

. ${DIR_SPS35}/descr_hindcast.sh
set -eu

# 
C3Stablecam=$DIR_POST/cam/C3S_table.txt
C3Stableclm=$DIR_POST/clm/C3S_table_clm.txt

{
read 
while IFS=, read -r flname C3S dim lname sname units freq type realm addfact coord cell varflg
do
   if [ $freq == "12hr" ]
   then
      var_array+=("$C3S")
   else
      var_array+=("$C3S")
   fi  
done } < $C3Stablecam
{
while IFS=, read -r flname C3S realm prec coord lname sname units freq level addfact coord2 cell
do
   var_array+=("$C3S")
done } < $C3Stableclm
echo ${var_array[@]}
outdir=/work/csp/sp2/${SPSSYS}/C3S_statistics
for mm in 01 03 04 05 07 08 09 10 11 
do
   echo $mm
   for var in ${var_array[@]}
   do
      if [ "$var" == "orog" ] || [ "$var" == "sftlf" ] || [ "$var" == "rsdt" ]
      then
         continue
      fi
      if [[ $var == "sithick" ]]
      then
         echo $var
         exit
      fi
      nn=`ls $outdir/$mm/$var/ALLDONE_* |wc -l`
      if [ $nn -eq 0 ]
      then
         echo "manca $var mese $mm"
         echo ""
      fi
   done
done
