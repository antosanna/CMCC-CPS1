#!/bin/sh -l 
#BSUB -q s_medium
#BSUB -J submit_tar_CERISE_phase2offline_mrlsl
#BSUB -e /work/cmcc/cp2/CPS/CMCC-CPS1/logs/hindcast/submit_tar_CERISEphase2_mrlsl_%J.err
#BSUB -o /work/cmcc/cp2/CPS/CMCC-CPS1/logs/hindcast/submit_tar_CERISEphase2_mrlsl_%J.out
#BSUB -P 0575
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
# - MAIN LOOP ------------------------------------------------------
submit_list=" "
#for yyyy in  `seq $iniy_hind $endy_hind`
for yyyy in  2003
do
  
  startdate=$yyyy$st
  FINALDIR=$WORK_CERISE_final/$startdate
  flag_metadata=$WORK_CERISE/$yyyy$st/phase1_2cerise_phase2_${yyyy}${st}_DONE
  if [[ ! -f $flag_metadata ]]
  then
     for ens in {001..025}
     do
# change metadata according to Harris email 20251124
        caso=sps4_${startdate}_${ens}
        $DIR_C3S/phase1_2cerise_phase2.sh $caso $FINALDIR
     done
     touch $flag_metadata
  fi
  outdirC3S=$FINALDIR
  #load other parameters depending on forecast_type
  set +uevx
  . $DIR_UTIL/descr_ensemble.sh $yyyy
  . $dictionary
  set -uexv

  cd ${outdirC3S}
  allC3Sfiles=`ls ${outdirC3S}/cmcc*6hr*mrlsl*.nc|wc -l`
  if [ $allC3Sfiles -ge $nrunC3Sfore ]
  then
  # check that no job are running for the startdate
        input="$yyyy $st"
        echo "ready to send $startdate"
        submit_list+=" $startdate"
        if [ $onlycheckfileok -eq 0 ]
        then 
           echo "Submitting tar_CERISE_phase2 for $startdate"     
           $DIR_UTIL/submitcommand.sh -m $machine -q $serialq_l -M 5000 -j tar_CERISE_phase2_mrlsl_${startdate} -l $DIR_LOG/$typeofrun/$startdate/ -d ${DIR_C3S} -s tar_CERISE_phase2_mrlsl.sh -i "$input"
        fi    
  else
     body="MISSING FILES FOR STARTDATE $startdate"
     title="${CPSSYS} tar_CERISE_phase2 for $startdate not submitted by submit_tar_CERISE_phase2"
     ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" 
  
  # checker files
  # all C3S files
     if [ $allC3Sfiles -ne $nrunC3Sfore ]
     then
       echo "files $allC3Sfiles expected $nrunC3Sfore "
       for i in `seq -w 01 $nrunC3Sfore`
       do
           missing=" "
           for var in mrlsl
           do
              nf=0
              nf=`ls $WORK_CERISE/$startdate/cmcc*6hr*${var}_*r${i}i00p00.nc|wc -l`
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
