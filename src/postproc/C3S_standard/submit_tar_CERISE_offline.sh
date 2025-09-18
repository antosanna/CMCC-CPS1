#!/bin/sh -l 
#BSUB -q s_medium
#BSUB -J submit_tar_CERISE_offline
#BSUB -e /work/cmcc/cp2/CPS/CMCC-CPS1/logs/hindcast/submit_tar_CERISE%J.err
#BSUB -o /work/cmcc/cp2/CPS/CMCC-CPS1/logs/hindcast/submit_tar_CERISE%J.out
#BSUB -P 0490
#BSUB -M 1000

. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

set -evxu
set -eu
# ----------------------------------------------------------
# Start here
# ----------------------------------------------------------
st=02 # startdate
onlycheckfileok=0  #if 0 does tar_CERISE
                   #if 1 only check that everything is ready
# ----------------------------------------------------------
C3Stable_cam=$DIR_POST/cam/C3S_table.txt
CERISEtable_cam=$DIR_POST/cam/CERISE_table.txt
C3Stable_clm=~cp1/CPS/CMCC-CPS1/src/postproc/clm/C3S_table_clm.txt
CERISEtable_clm=$DIR_POST/clm/CERISE_table_clm.txt
#
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
read
while IFS=, read -r flname C3S dim lname sname units freq type realm addfact coord cell varflg
do
   if [ $freq == "12hr" ]
   then
      var_array3d+=("$C3S")
   else
      var_array2d+=("$C3S")
   fi  
done } < $CERISEtable_cam
{
while IFS=, read -r flname C3S realm prec coord lname sname units freq level addfact coord2 cell
do
   var_array2d+=("$C3S")
done } < $C3Stable_clm
{
while IFS=, read -r flname C3S realm prec coord lname sname units freq level addfact coord2 cell
do
   var_array2d+=("$C3S")
done } < $CERISEtable_clm
#var_array3d=(hus ta ua va zg wp)
var_array=("${var_array2d[@]} ${var_array3d[@]}")
echo ${var_array[@]}
# - MAIN LOOP ------------------------------------------------------
submit_list=" "
for yyyy in  `seq $iniy_hind $endy_hind`
do
  
  startdate=$yyyy$st
  outdirC3S=${WORK_CERISE}/$startdate
  #load other parameters depending on forecast_type
  set +uevx
  . $DIR_UTIL/descr_ensemble.sh $yyyy
  . $dictionary
  set -uexv

  cd ${outdirC3S}
  allC3Sfiles=`ls ${outdirC3S}/cmcc*.nc|wc -l`
  if [ $allC3Sfiles -ge $(($nfieldsC3S * $nrunC3Sfore)) ]
  then
  # check that no job are running for the startdate
        input="$yyyy $st"
        echo "ready to send $startdate"
        submit_list+=" $startdate"
        if [ $onlycheckfileok -eq 0 ]
        then 
           echo "Submitting tar_CERISE for $startdate"     
           $DIR_UTIL/submitcommand.sh -m $machine -q $serialq_l -M 5000 -j tar_CERISE_${startdate} -l $DIR_LOG/$typeofrun/$startdate/ -d ${DIR_C3S} -s tar_CERISE.sh -i "$input"
        fi    
  else
     body="MISSING FILES FOR STARTDATE $startdate"
     title="${CPSSYS} tar_CERISE for $startdate not submitted by submit_tar_CERISE"
     ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" 
  
  # checker files
  # all C3S files
     if [ $allC3Sfiles -ne $(($nfieldsC3S * $nrunC3Sfore)) ]
     then
       echo "files $allC3Sfiles expected $(($nfieldsC3S * $nrunC3Sfore)) "
       for i in `seq -w 01 $nrunC3Sfore`
       do
           missing=" "
           for var in ${var_array[@]}
           do
              nf=0
              nf=`ls $WORK_CERISE/$startdate/cmcc*${var}_*r${i}i00p00.nc|wc -l`
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

printtext="The following startdates are ready to be submitted:"
if [ $onlycheckfileok -eq 0 ]; then
 printtext="The following startdates were submitted:"
fi
echo $printtext
echo $submit_list
echo " "
echo "Done."

exit 0
