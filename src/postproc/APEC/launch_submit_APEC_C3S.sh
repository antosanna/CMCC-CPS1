#!/bin/sh -l
#BSUB -P 0490
#BSUB -J postprocAPEC
#BSUB -q s_long
#BSUB -o logs/postprocAPEC_%J.out
#BSUB -e logs/postprocAPEC_%J.err
#BSUB -N
#BSUB -u sp1@cmcc.it
#--------------------------------

# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. ${DIR_POST}/APEC/descr_SPS4_APEC.sh

set -ex

here="${DIR_POST}/APEC"
#-----------------------------------
#get start-date from system
#-----------------------------------
yyyyi=1993 #`date +%Y`
yyyyf=2022 #`date +%Y`
st=10     #`date +%m`    #2 figures

for yyyy in `seq $yyyyi $yyyyf`
do

   . $DIR_UTIL/descr_ensemble.sh $yyyy

# APEC SUBMISSION --------------------------------------------------------------------------------
   
   start_date=${yyyy}${st}
   mkdir -p ${DIR_LOG}/${typeofrun}/${start_date}
   input="${yyyy} ${st} $here"
   ${DIR_UTIL}/submitcommand.sh -M 1000 -m $machine -q $serialq_m -j submit_APEC_C3S_${typeofrun}_${start_date} -l ${DIR_LOG}/${typeofrun}/${start_date} -d ${here} -s submit_APEC_C3S.sh -i "$input"

   body="APEC C3S post-processing STARTED"
   title="[APEC] ${SPSSYS} ${typeofrun} ${yyyy}${st} postproc STARTED"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r yes -s $yyyy$st


   while `true` ; do
       njobsubmit=`${DIR_UTIL}/findjobs.sh -m $machine -q $serialq_m -n "submit_APEC_C3S_${typeofrun}_${start_date}"  -c yes`
    			sleep 60
    			if [ $njobsubmit -eq 0 ] ; then
       			break
    			fi 
   done
   while `true` ; do
       njobapec=`${DIR_UTIL}/findjobs.sh -m $machine -q $serialq_m -n "APEC_${start_date}_"  -c yes`
    			sleep 60
    			if [ $njobapec -eq 0 ] ; then
       			break
    			fi 
   done
done
echo "That's all Folks"
exit 0
