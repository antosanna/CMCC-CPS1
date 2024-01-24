#!/bin/sh -l

#THIS WORKS ONLY FROM LSF
#${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_l -j modify_triplette_sps4 -l ${DIR_LOG}/hindcast/ -d ${DIR_UTIL} -s modify_triplette.sh

# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

casefromoutside=$1

set -euxv

dateymdhms=`date +%Y%m%d%H%M%S`
subm_cnt=0
listacasisubmitted=() 

#listcases="${SPSSystem}_200311_016" 
#listcases="${SPSSystem}_200011_016" 
#listcases="${SPSSystem}_200611_004"
listcases="${SPSSystem}_200111_016 ${SPSSystem}_200311_017 ${SPSSystem}_200511_030"
if [ "$casefromoutside" != "" ]
then
  listcases=$casefromoutside
fi
for caso in $listcases
do
   yyyy=`echo $caso|cut -d '_' -f2|cut -c1-4`
   . $DIR_UTIL/descr_ensemble.sh $yyyy
   st=`echo $caso|cut -d '_' -f2|cut -c5-6`
   ens=`echo $caso|cut -d '_' -f3`
   n1=$((10#$ens))
   n2=$((${nmax4modify_trip} + 1))

   #the line used to modify the IC will be kept to 40($nmax4modify_trip) instead of $nrunmax in hindcast in order to avoid the risk
   #of running twice the same members for the startdates initially launched with 40 members, which have potentially run already 
   #some members between 31 and 40
   #in forecast $nmax4modify_trip will be equal to $nrunmax

   while `true`
   do
     np=`${DIR_UTIL}/findjobs.sh -m $machine -n modify_triplette_${SPSSystem} -c yes`
     if [ $np -eq 1 ]
     then
        break
     fi
     sleep 30
   done

   if [ ! -f $TRIP_DIR/triplette.random.${yyyy}${st}.txt.orig ]
   then
      cp $TRIP_DIR/triplette.random.${yyyy}${st}.txt $TRIP_DIR/triplette.random.${yyyy}${st}.txt.orig
   else
      cp $TRIP_DIR/triplette.random.${yyyy}${st}.txt $TRIP_DIR/triplette.random.${yyyy}${st}.txt.$dateymdhms
   fi

   cd $TRIP_DIR

  
   line1=`cat triplette.random.${yyyy}${st}.txt | head -n${n1} | tail -1`
   line1script=`echo $line1 | awk '{print $3" "$1" "$2}'`
   line2=`cat triplette.random.${yyyy}${st}.txt | head -n${n2} | tail -1`
   line2script=`echo $line2 | awk '{print $3" "$1" "$2}'`
 
   echo $n1" line1: "$line1" line1script: "$line1script 
   echo $n2" line2: "$line2" line2script: "$line2script 

   # Make substitutions in triplette.random
   # substitute triplette with the ones in 41st line
   sed -i "s/${line1}/${line2}/g" triplette.random.${yyyy}${st}.txt
   # remove 41st line to avoid repetition in next substitutions
   sed -i "${n2},${n2}d" triplette.random.${yyyy}${st}.txt

   # Make substitutions in ensemble scripts
   cd $DIR_SUBM_SCRIPTS/${st}/${yyyy}${st}_scripts/ 
   if [ ! -f ensemble4_${yyyy}${st}_${ens}.sh.orig ]
   then
      cp ensemble4_${yyyy}${st}_${ens}.sh ensemble4_${yyyy}${st}_${ens}.sh.orig
   else
      cp ensemble4_${yyyy}${st}_${ens}.sh ensemble4_${yyyy}${st}_${ens}.sh.$dateymdhms
   fi
   sed -i "s/${line1script}/${line2script}/g" ensemble4_${yyyy}${st}_${ens}.sh
   chmod 744 ensemble4_${yyyy}${st}_${ens}.sh
   ./ensemble4_${yyyy}${st}_${ens}.sh
   subm_cnt=$(( $subm_cnt + 1 ))
   listacasisubmitted+="$caso "

done

# ***************************************************
# Email and exit
# ***************************************************
if [ "$casefromoutside" == "" ]
then
   body="In ${dateymdhms} re-submitted ${subm_cnt} cases that aborted after changing tripletta: \n
   \n
   ${listacasisubmitted[@]} \n
   "
   title="RECOVER SPIKE JOBS RE-SUBMITTED"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r $typeofrun -s $yyyy$st

   echo "Done."
fi
exit 0
