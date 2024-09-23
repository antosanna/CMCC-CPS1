#!/bin/sh -l
#BSUB -q s_medium
#BSUB -J launch_maxmin_single_year
#BSUB -o /work/cmcc/cp1//CPS/CMCC-CPS1/logs/DIAGS/C3S_statistics/launch_compute_maxmin_single_year%J.out
#BSUB -e /work/cmcc/cp1//CPS/CMCC-CPS1/logs/DIAGS/C3S_statistics/launch_compute_maxmin_single_year%J.err
#BSUB -P 0490
#BSUB -M 10000

. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/descr_ensemble.sh $iniy_hind

# THIS SCRIPT IS MEANT TO BE LAUNCHED FROM CRONTAB AND cp2 USER

set -uexv
stnow=$1
maxjob=10       # max number of procs to be simultaneously submitted
do_only_test_var=0   # if you want to compute only myvar
myvar=tas
#
namescript=compute_maxmin
outdir=$OUTDIR_DIAG/C3S_statistics   #OUTDIR_DIAG
mkdir -p $outdir

# ONLY ONE AT A TIME because it requires a large amount of memory
np=`${DIR_UTIL}/findjobs.sh -m $machine -n $namescript -c yes`
if [[ $np -gt 0 ]] 
then
   echo "there are $np $namescript already running! Exiting now!"
   exit
fi

launchdir=$DIR_DIAG_C3S/statistics
mkdir -p ${DIR_LOG}/DIAGS/C3S_statistics

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

echo "going to process var_arrayC3S "
echo ${var_arrayC3S[@]}

for var in ${var_arrayC3S[@]}; do
    
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
    echo "Launch $var"
        
    for st in $stnow
    do
       if [[ -f $DIR_LOG/DIAGS/C3S_statistics/compute_maxmin_allyears_st${st}_${var}_done ]] 
       then
          echo "$var already computed! "
          continue
       fi
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
       if [[ ! -f $DIR_LOG/DIAGS/C3S_statistics/compute_maxmin_allyears_st${st}_${var}_done ]] 
       then
          body="all year from $iniy_hind $endy_hind and start-date $stnow done"
          title="C3S_statistics maxmin start-date $st all years $var completed"
          $DIR_UTIL/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
          touch     $DIR_LOG/DIAGS/C3S_statistics/compute_maxmin_allyears_st${st}_${var}_done    
       fi
   done    #loop on $st
done    #loop on $var
if [[ `ls $DIR_LOG/DIAGS/C3S_statistics/compute_maxmin_allyears_st${st}_*_done |wc -l` -eq ${#var_arrayC3S[@]} ]]
then
   $DIR_UTIL/sendmail.sh -m $machine -e $mymail -M "$st completed" -t "C3S statistics"
   
fi

exit 0
