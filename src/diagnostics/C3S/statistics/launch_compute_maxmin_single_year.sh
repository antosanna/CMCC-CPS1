#!/bin/sh -l
#BSUB -q s_medium
#BSUB -J launch_compute_maxmin_single_year
#BSUB -o /work/cmcc/cp1//CPS/CMCC-CPS1/logs/DIAGS/C3S_statistics/launch_compute_maxmin_single_year%J.out
#BSUB -e /work/cmcc/cp1//CPS/CMCC-CPS1/logs/DIAGS/C3S_statistics/launch_compute_maxmin_single_year%J.err
#BSUB -P 0490
#BSUB -M 10000

. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/descr_ensemble.sh $iniy_hind

# THIS SCRIPT IS MEANT TO BE LAUNCHED FROM CRONTAB AND cp2 USER

set -uexv
dbg=0          # just the first startdate and first year
do_only_test_var=1   # if you want to compute only myvar
myvar=tas
#
# IN dbg=1 MODE ONLY ONE YEAR (instead of all 24)
namescript=compute_maxmin
outdir=$OUTDIR_DIAG/C3S_statistics   #OUTDIR_DIAG
mkdir -p $outdir

# ONLY ONE AT A TIME because it requires a large amount of memory
maxjob=1
np=`${DIR_UTIL}/findjobs.sh -m $machine -n $namescript -c yes`
if [[ $np -gt $maxjob ]] 
then
   echo "there are $maxjob $namescript already running! Exiting now!"
   exit
fi

launchdir=$DIR_DIAG/C3S_statistics
launchdir=$PWD
mkdir -p ${DIR_LOG}/DIAGS/C3S_statistics

# read C3S variables
# Tackle separately 3d, 2d and 2dmon (the first require much more memory)
C3Stablecam=$DIR_POST/cam/C3S_table.txt
C3Stableclm=$DIR_POST/clm/C3S_table_clm.txt
C3Stableocean1=$DIR_POST/nemo/C3S_table_ocean2d_others.txt
C3Stableocean2=$DIR_POST/nemo/C3S_table_ocean2d_t14d.txt
C3Stableocean3=$DIR_POST/nemo/C3S_table_ocean2d_t17d.txt
C3Stableocean4=$DIR_POST/nemo/C3S_table_ocean2d_t20d.txt
C3Stableocean5=$DIR_POST/nemo/C3S_table_ocean2d_t26d.txt
C3Stableocean6=$DIR_POST/nemo/C3S_table_ocean2d_t28d.txt
{
read 
while IFS=, read -r flname C3S dim lname sname units freq type realm addfact coord cell varflg
do
      var_arrayC3S+=("$C3S")
done } < $C3Stablecam
{
while IFS=, read -r flname C3S realm prec coord lname sname units freq level addfact coord2 cell
do
   var_arrayC3S+=("$C3S")
done } < $C3Stableclm
{
read 
while IFS=, read -r flname C3S lname sname units realm level addfact coord cell varflg reflev model fillval
do
   var_arrayC3S+=("$C3S")
done } < $C3Stableocean1
{
read 
while IFS=, read -r flname C3S lname sname units realm level addfact coord cell varflg reflev model fillval
do
   var_arrayC3S+=("$C3S")
done } < $C3Stableocean2
{
read 
while IFS=, read -r flname C3S lname sname units realm level addfact coord cell varflg reflev model fillval
do
   var_arrayC3S+=("$C3S")
done } < $C3Stableocean3
{
read 
while IFS=, read -r flname C3S lname sname units realm level addfact coord cell varflg reflev model fillval
do
   var_arrayC3S+=("$C3S")
done } < $C3Stableocean4
{
read 
while IFS=, read -r flname C3S lname sname units realm level addfact coord cell varflg reflev model fillval
do
   var_arrayC3S+=("$C3S")
done } < $C3Stableocean5
{
read 
while IFS=, read -r flname C3S lname sname units realm level addfact coord cell varflg reflev model fillval
do
   var_arrayC3S+=("$C3S")
done } < $C3Stableocean6

echo "going to process var_arrayC3S "
echo ${var_arrayC3S[@]}

for var in ${var_arrayC3S[@]}; do
    
    echo "Launch $var"
   if [[ -f $DIR_LOG/DIAGS/C3S_statistics/compute_maxmin_${var}_allyears_allst_done ]] 
   then
      echo "$var already computed! "
      continue
   fi
    if [[ "$var" == "orog" ]] || [[ "$var" == "sftlf" ]] || [[ "$var" == "rsdt" ]]
    then
       continue
    fi  
    if [[ $do_only_test_var -eq 1 ]]
    then
       if [[ "$var" != "$myvar" ]]
       then 
           continue
       fi
    fi
        
#    for st in {01..12}
    for st in 10
    do
       for yyyy in `seq $iniy_hind $endy_hind`
       do
          fileok=$outdir/$st/$yyyy/${var}/maxminDONE_${var}_${yyyy}$st
          if [[ -f $fileok ]]
          then
             continue
          fi
          odir=$outdir/$st/$yyyy/${var}
          mkdir -p $odir
          input="$var $yyyy $st $odir $fileok"
          ${DIR_UTIL}/submitcommand.sh -m $machine -M 8000 -t 1 -q $serialq_m -j ${namescript}_${var}_${yyyy}${st} -l $DIR_LOG/DIAGS/C3S_statistics/ -d ${launchdir} -s ${namescript}.sh -i "$input"
          npint=`${DIR_UTIL}/findjobs.sh -m $machine -n ${namescript} -c yes`
#          if [[ $npint -ge 10 ]]
          if [[ $npint -ge $maxjob ]]
          then
             exit 0
          fi
       done    #loop on $yyyy
   done    #loop on $st
   if [[ ! -f $DIR_LOG/DIAGS/C3S_statistics/compute_maxmin_${var}_allyears_allst_done ]] 
   then
      body="all year from $iniy and $lasty and start-date {01..12} done"
      title="C3S_statistics maxmin single year $var completed"
      $DIR_UTIL/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
      touch $DIR_LOG/DIAGS/C3S_statistics/compute_maxmin_allyears_allst_${var}_done
   fi
done    #loop on $var

exit 0
