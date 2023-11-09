#!/bin/sh -l
#BSUB -q s_medium
#BSUB -J launch_compute_stats_part1
#BSUB -o ../../../../logs/DIAGS/stats/launch_compute_stats_part1%J.out
#BSUB -e ../../../../logs/DIAGS/stats/launch_compute_stats_part1%J.err
#BSUB -P 0490

. ~/.bashrc
. $DIR_SPS35/descr_SPS3.5.sh
. $DIR_SPS35/descr_hindcast.sh

# THIS SCRIPT IS MEANT TO BE LAUNCHED FROM CRONTAB
set -uexv
debug=0          # just the first startdate and first year
do_only_wind=0   # if you want to compute only vector vars
do_only_test_var=1   # if you want to compute only myvar
myvar="clt"
#
# IN debug=1 MODE ONLY ONE YEAR (instead of all 24)
namescript=compute_stats_C3S_
outdir=$OUTDIR_DIAG/C3S_statistics   #OUTDIR_DIAG
mkdir -p $outdir

# ONLY ONE AT A TIME because it requires a large amount of memory
np=`${DIR_SPS35}/findjobs.sh -m $machine -n $namescript -c yes`
if [[ $np -ne 0 ]] 
then
   echo "there is one $namescript already running! Exiting now!"
   exit
fi

iniy=1993
lasty=2016
launchdir=$DIR_DIAG/C3S_statistics
mkdir -p ${DIR_LOG}/DIAGS/stats

# read C3S variables
# Tackle separately 3d, 2d and 2dmon (the first require much more memory)
C3Stablecam=$DIR_POST/cam/C3S_table.txt
C3Stableclm=$DIR_POST/clm/C3S_table_clm.txt
C3Stableocean=$DIR_POST/nemo/C3S_table_ocean2d.txt
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
done } < $C3Stableocean

echo "going to process var_arrayC3S "
echo ${var_arrayC3S[@]}

for var in ${var_arrayC3S[@]}; do
    
    if [[ "$var" == "orog" ]] || [[ "$var" == "sftlf" ]] || [[ "$var" == "rsdt" ]]
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
    if [[ $do_only_test_var -eq 1 ]]
    then
       if [[ "$var" != "$myvar" ]]
       then 
           continue
       fi
    fi
        
    echo "Launch $var"
    for st in {01..12}
    do
       for yyyy in `seq $iniy $lasty`
       do
          fileok=$outdir/$st/$yyyy/${var}/ALLDONE_${var}_${yyyy}$st
          if [[ -f $fileok ]]
          then
             continue
          fi
          odir=$outdir/$st/$yyyy/${var}
          mkdir -p $odir
          input="$var $yyyy $st $launchdir $odir $fileok $wind"
          ${DIR_SPS35}/submitcommand.sh -m $machine -M 8000 -t 1 -q $serialq_m -j compute_stats_C3S_nco_${var}_${yyyy}${st} -l $DIR_LOG/DIAGS/stats/ -d ${launchdir} -s compute_stats_nco.sh -i "$input"
          npint=`${DIR_SPS35}/findjobs.sh -m $machine -n compute_stats_C3S_nco_ -c yes`
          if [[ $npint -ge 10 ]]
          then
             exit 0
          fi
       done    #loop on $st
   done    #loop on $yyy
   if [[ ! -f $DIR_LOG/DIAGS/stats/C3S_stats_part1_${var}_done ]] 
   then
      body="all year from $iniy and $lasty and start-date {01..12} done"
      title="C3S_statistics part1 $var completed"
      $DIR_SPS35/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
      touch $DIR_LOG/DIAGS/stats/C3S_stats_part1_${var}_done
   fi
done    #loop on $var

exit 0
