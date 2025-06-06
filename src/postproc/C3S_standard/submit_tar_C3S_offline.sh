#!/bin/sh -l 
#BSUB -q s_long
#BSUB -J submit_tar_C3S_offline
#BSUB -e /work/cmcc/cp1//CPS/CMCC-CPS1/logs/hindcast/submit_tar_C3S%J.err
#BSUB -o /work/cmcc/cp1//CPS/CMCC-CPS1/logs/hindcast/submit_tar_C3S%J.out
#BSUB -P 0490
#BSUB -M 1000

. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

set -evxu
set -eu
# ----------------------------------------------------------
# Start here
# ----------------------------------------------------------
st=07 # startdate
onlycheckfileok=1  #if 0 does tar_C3S
                   #if 1 only check that everything is ready
# ----------------------------------------------------------
C3Stable_cam=$DIR_POST/cam/C3S_table.txt
C3Stable_clm=$DIR_POST/clm/C3S_table_clm.txt
C3Stable_oce1=$DIR_POST/nemo/C3S_table_ocean2d_others.txt
C3Stable_oce2=$DIR_POST/nemo/C3S_table_ocean2d_t14d.txt
C3Stable_oce3=$DIR_POST/nemo/C3S_table_ocean2d_t17d.txt
C3Stable_oce4=$DIR_POST/nemo/C3S_table_ocean2d_t20d.txt
C3Stable_oce5=$DIR_POST/nemo/C3S_table_ocean2d_t26d.txt
C3Stable_oce6=$DIR_POST/nemo/C3S_table_ocean2d_t28d.txt
#
{
read 
while IFS=, read -r flname C3S dim lname sname units freq type realm addfact coord cell varflg
do
   if [ $freq == "12hr" ]
   then
      var_array3d+=(" $C3S")
   else
      var_array2d+=(" $C3S")
   fi  
done } < $C3Stable_cam
{
while IFS=, read -r flname C3S realm prec coord lname sname units freq level addfact coord2 cell
do
   var_array2d+=(" $C3S")
done } < $C3Stable_clm
{
read
while IFS=, read -r flname C3S lname sname units realm level addfact coord cell varflg reflev model fillval
do
   var_array2d+=(" $C3S")
done } < $C3Stable_oce1
{
read
while IFS=, read -r flname C3S lname sname units realm level addfact coord cell varflg reflev model fillval
do
   var_array2d+=(" $C3S")
done } < $C3Stable_oce2
{
read
while IFS=, read -r flname C3S lname sname units realm level addfact coord cell varflg reflev model fillval
do
   var_array2d+=(" $C3S")
done } < $C3Stable_oce3
{
read
while IFS=, read -r flname C3S lname sname units realm level addfact coord cell varflg reflev model fillval
do
   var_array2d+=(" $C3S")
done } < $C3Stable_oce4
{
read
while IFS=, read -r flname C3S lname sname units realm level addfact coord cell varflg reflev model fillval
do
   var_array2d+=(" $C3S")
done } < $C3Stable_oce5
{
read
while IFS=, read -r flname C3S lname sname units realm level addfact coord cell varflg reflev model fillval
do
   var_array2d+=(" $C3S")
done } < $C3Stable_oce6
#var_array3d=(hus ta ua va zg)
var_array=("${var_array2d[@]} ${var_array3d[@]}")
echo ${var_array[@]}
# - MAIN LOOP ------------------------------------------------------
submit_list=" "
#for yyyy in  `seq $iniy_hind $endy_hind`
for yyyy in `seq 1993 2022` 
do
  
  startdate=$yyyy$st
  outdirC3S=${WORK_C3S}/$startdate
  #load other parameters depending on forecast_type
  set +uevx
  . $DIR_UTIL/descr_ensemble.sh $yyyy
  . $dictionary
  set -uexv

  cd ${outdirC3S}
  allC3Schecks=`ls ${check_allchecksC3S}?? |wc -l` 
  set +vx
  allC3Sfiles=`ls ${outdirC3S}/cmcc*.nc|wc -l`
  set -vx
  #allC3S=`ls *i00p00.nc|wc -l`
  # IF ALL VARS HAVE BEEN COMPUTED FOR ALL MEMBERS tar_C3S
  if [ $allC3Schecks -ge $nrunC3Sfore ]  && [ $allC3Sfiles -ge $(($nfieldsC3S * $nrunC3Sfore)) ]
  then
  # check that no job are running for the startdate
     nacjob=`${DIR_UTIL}/findjobs.sh -m $machine -n ${startdate} -c yes`
     if [ $nacjob -eq 0 ]
     then
#        $DIR_UTIL/check_production_time.sh $st $yyyy 
# ANTO 20201113 testato su /users_home/csp/sp1/SPS/CMCC-${SPSSYS}/work/ANTO/develop${SPSSYS}
# MA MAI TESTATO QUI!!!! +
        $DIR_UTIL/check_production_time.sh -m $machine -s $st -y $yyyy
# MA MAI TESTATO QUI!!!! -
        input="$yyyy $st"
        echo "ready to send $startdate"
        submit_list+=" $startdate"
        if [ $onlycheckfileok -eq 0 ]
        then 
           echo "Submitting tar_C3S for $startdate"     
           $DIR_UTIL/submitcommand.sh -m $machine -q $serialq_l -M 5000 -j tar_C3S_${startdate} -l $DIR_LOG/$typeofrun/$startdate/ -d ${DIR_C3S} -s tar_C3S.sh -i "$input"
        fi    
     else
       body="something is still running. Retry"
       title="${CPSSYS} tar_C3S for $startdate not submitted by submit_tar_C3S"
       ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" 

     fi
  else
     body="MISSING FILES FOR STARTDATE $startdate"
     title="${CPSSYS} tar_C3S for $startdate not submitted by submit_tar_C3S"
     ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" 
  
  # checker files
     if [ $allC3Schecks -lt $nrunC3Sfore ]
     then
       echo "found $allC3Schecks and expected $nrunC3Sfore "
       checkmissing=" "
       for i in `seq -w 01 $nrunC3Sfore`
       do
          nm=0
          nm=`ls ${check_allchecksC3S}${i}|wc -l`
          if [ $nm -ne 1 ]
          then
             checkmissing+=" $i"
          fi
       done
       echo "for start-date $startdate check missing for member $checkmissing"
     fi 
  # all C3S files
     if [ $allC3Sfiles -lt $(($nfieldsC3S * $nrunC3Sfore)) ]
     then
       echo "files $allC3Sfiles expected $(($nfieldsC3S * $nrunC3Sfore)) "
       for i in `seq -w 01 $nrunC3Sfore`
       do
           missing=" "
           for var in ${var_array[@]}
           do
              nf=0
              nf=`ls $WORK_C3S/$startdate/cmcc*${var}_*r${i}i00p00.nc|wc -l`
              if [ $nf -ne 1 ]
              then
                missing+=" $var"
              fi
           done
           if [ "$missing" == " " ]
           then
             :
           else
              echo "for member $i missing $missing"
           fi
       done
     fi
  fi
done

set +vx
printtext="The following startdates are ready to be submitted:"
if [ $onlycheckfileok -eq 0 ]; then
 printtext="The following startdates were submitted:"
fi
echo $printtext
echo $submit_list
set -vx
echo " "
echo "Done."

exit 0
