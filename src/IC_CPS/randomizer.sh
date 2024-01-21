#!/bin/sh -l

#***************************************
# TEMPORARY COMMENTED send2CINECA
#***************************************
# load variables from descriptor
. $HOME/.bashrc
. $DIR_UTIL/descr_CPS.sh

set -evxu
#-------------------------------------------------
# THIS RANDOMIZER USES ONLY NCEP datasets FOR CLM IC
#-------------------------------------------------

yyyy=$1
st=$2 
it=$3
checkfileok=$4    # to be defined in dictionary

. $DIR_UTIL/descr_ensemble.sh $yyyy
#-- USEFUL FUNCTIONS -----------------------------
ifExistRemove() {
   local fname=$1
   if [ -f $fname ]; then
      rm $fname
   fi
}
#-- DIRS CREATION --------------------------------
mkdir -p ${DIR_SUBM_SCRIPTS}/$st/$yyyy${st}_scripts
# per CINECA
mkdir -p ${DIR_SUBM_SCRIPTS}/$st/$yyyy${st}_scripts/CINECA

#-- RANDOMIZATION --------------------------------

# numero totale di perturbazioni totale superiore al numero totale da fare per prevedere che alcuni membri esplodano
ntot=$nrunmax
#SELECT RANDOMLY AMONG ? PERTURBATIONS
mkdir -p $DIR_LOG/$typeofrun/$yyyy$st
cd $DIR_LOG/$typeofrun/$yyyy$st

#listaicoce=`ls $IC_NEMO_SPS_DIR/$st/$yyyy${st}*modified.nc`
#for file in $listaicoce 
#do
#   icsoce+=" `basename $file|cut -d '_' -f3`"
#done
#for i in $icsoce ; do echo $RANDOM $i ; done|sort -k1|cut -d" " -f2 > $DIR_LOG/forecast/$yyyy$st/oce.ics.$yyyy$st
#cd $IC_NEMO_SPS_DIR/$st/
for poce in `seq -w 01 $n_ic_nemo`
do
   oceic=$IC_NEMO_SPS_DIR/$st/${CPSSYS}.nemo.${yyyy}-${st}-01-00000.${poce}.nc
   iceic=$IC_CICE_SPS_DIR/$st/${CPSSYS}.cice.r.$yyyy-$st-01-00000.$poce.nc
# DA MODIFICARE +
   bk_oceic=da_definire.nc
#         bk_oceic=$IC_SPS_guess/NEMO/$st/${yyyy}${st}0100_R025_${poce}_restart_oce_modified.bkup.nc
   bk_iceic=da_definire.nc
#            bk_iceic=$IC_SPS_guess/NEMO/$st/ice_ic${yyyy}${st}_${poce}.bkup.nc ice_ic${yyyy}${st}_${poce}.nc
# DA MODIFICARE -
   if [[ $typeofrun == "forecast" ]]
   then
      if [[ ! -f $oceic ]]
      then
         if [[ -f $bk_oceic ]]
         then
            ln -sf $bk_oceic $oceic
            if [[ -f $iceic ]]
            then
               rm  $iceic
            fi
            ln -sf $bk_iceic $iceic
            icsoce+=" $poce"
   
            body="Using bkup as IC for perturbation $poce" 
            title="[NEMOIC] ${CPSSYS} forecast notification"
            $DIR_UTIL/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "yes" -s $yyyy$st
         else
            body="Nemo IC for perturbation $poce not available" 
            title="[NEMOIC] ${CPSSYS} forecast warning"
            $DIR_UTIL/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "yes" -s $yyyy$st
         fi 
      elif [[ ! -f $iceic ]]
      then
         if [[ -f $bk_iceic ]]
         then
            ln -sf $bk_iceic $iceic
            if [[ -f $oceic ]]
            then
               rm ${oceic}
            fi
            ln -sf $bk_oceic $oceic
            body="Using bkup as IC for perturbation $poce" 
            title="[NEMOIC] ${CPSSYS} forecast notification"
            $DIR_UTIL/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "yes" -s $yyyy$st
            icsoce+=" $poce"
         else
            body="Nemo IC for perturbation $poce not available" 
            title="[NEMOIC] ${CPSSYS} forecast warning"
            $DIR_UTIL/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "yes" -s $yyyy$st
         fi 
      else
         if [[ `whoami` == $operational_user ]] ; then 
            if [[ -f $bk_oceic ]]
            then
               rm $bk_oceic
            fi
            if [[ -f $bk_iceic ]]
            then
               rm $bk_iceic
            fi
         fi
         icsoce+=" $poce"
      fi
   else
#HINDCAST
      if [[ ! -f $oceic ]]
      then
         poce1=$((10#$(($poce - 1))))
#TEMPORARY: is this path final?
         if [[ `ls $DIR_REST_OIS/MB$poce1/RESTARTS/$yyyy${st}0100/*_restart_0???.nc|wc -l` -eq 0 ]]
         then
            mkdir -p $DIR_LOG/$typeofrun/$yyyy$st/IC_NEMO
#           get  check_IC_NEMO_miss from dictionary

            set +euvx
            . $dictionary
            set -euvx
            touch $check_IC_Nemo_miss
            continue
         else
            $DIR_OCE_IC/nemo_rebuild_restart.sh $yyyy $st $poce
         fi
      fi
      if [[ ! -f $iceic ]]
      then
         if [[ `ls $DIR_REST_OIS/MB$poce1/RESTARTS/$yyyy${st}0100/*cice.r.*nc |wc -l` -ne 0 ]]
         then
            rsync -auv $DIR_REST_OIS/MB$poce1/RESTARTS/$yyyy${st}0100/*cice.r.*nc $IC_CICE_CSP_DIR/$st/$iceic
         else
            mkdir -p $DIR_LOG/$typeofrun/$yyyy$st/IC_CICE
#           get  check_IC_CICE_miss from dictionary
            set +euvx
            . $dictionary
            set -euvx
            touch $check_IC_CICE_miss
         fi
      fi 
      icsoce+=" $poce"
   fi
done
# RANDOM is an instrinsic unix proc that generates a random number
# to each $i a random number is associated and then sorted in ascendong order
for i in $icsoce ; do echo $RANDOM $i ; done|sort -k1|cut -d" " -f2 > $DIR_LOG/$typeofrun/$yyyy$st/oce.ics.$yyyy$st
   
#listaicland=`ls $IC_CLM_SPS_DIR/$st/*clm2.r.${yyyy}-${st}-01-00000.nc`
#for file in $listaicland 
#do
#   icslnd+=" `basename $file|cut -d '_' -f4|cut -d '.' -f1`"
#done
#for i in $icslnd ; do echo $RANDOM $i ; done|sort -k1|cut -d" " -f2 > $DIR_LOG/forecast/$yyyy$st/lnd.ics.$yyyy$st
cd $IC_CLM_CPS_DIR/$st/
for clmic in `seq -w 01 $n_ic_clm`
do
   lndic=$IC_CLM_CPS_DIR/$st/${CPSSYS}.clm2.r.$yyyy-$st-01-00000.$clmic.nc
   rtmic=$IC_CLM_CPS_DIR/$st/${CPSSYS}.hydros.r.$yyyy-$st-01-00000.$clmic.nc
   bk_rtmic=da_definire.nc
   bk_lndic=da_definire.nc
   if [[ $typeofrun == "hindcast" ]]
   then
      icslnd+=" $clmic"
   fi
   if [[ ! -f $lndic ]]
   then
      if [[ -f $bk_lndic ]]
      then
         ln -sf $bk_lndic $lndic
         ln -sf $bk_rtmic $rtmic
         body="Using $bk_lndic and $bk_rtmic as IC for perturbation $clmic" 
         title="[CLMIC] ${CPSSYS} forecast notification"
         $DIR_UTIL/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"-r "yes" -s $yyyy$st
         if [[ $typeofrun == "forecast" ]]
         then
            icslnd+=" $clmic"
         fi
      else
         body="Not available IC for perturbation $clmic" 
         title="[CLMIC] ${CPSSYS} forecast warning"
         $DIR_UTIL/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "yes" -s $yyyy$st
      fi
   else
      if [[ `whoami` == $operational_user ]] ; then 
         if [[ -f $bk_lndic ]]
         then
            rm $bk_lndic
         fi
         if [[ -f $bk_rtmic ]]
         then
            rm $bk_rtmic
         fi
      fi
      if [[ $typeofrun == "forecast" ]]
      then
         icslnd+=" $clmic"
      fi
   fi
done
for i in $icslnd ; do echo $RANDOM $i ; done|sort -k1|cut -d" " -f2 > $DIR_LOG/$typeofrun/$yyyy$st/lnd.ics.$yyyy$st

#wait until all make_atm_ic_l46_ processes are done so that you are sure that no CAM ICs are in production
while `true`
do  
   np=`${DIR_UTIL}/findjobs.sh -m $machine -n make_atm_ic_l46_ -c yes`
   if [[ $np -eq 0 ]]
   then
      break
   fi 
   sleep 60
done
cd $IC_CAM_SPS_DIR/$st/
for atmic in `seq 1 $n_ic_cam`
do
   if [ ! -f ${CPSSYS}.cam.i.${yyyy}${st}.$atmic.nc ]
   then
      if [[ -f $IC_CAM_SPS_DIR/$st/${CPSSYS}.cam.i.${yyyy}${st}.$atmic.bkup.nc ]]
      then
         ln -sf $IC_CAM_SPS_DIR/$st/${CPSSYS}.cam.i.${yyyy}${st}.$atmic.bkup.nc ${CPSSYS}.cam.i.${yyyy}${st}.$atmic.nc
         body="Using ${CPSSYS}.cam.i.${yyyy}${st}.$atmic.bkup.nc as IC for perturbation $atmic" 
         ln -sf $IC_CAM_SPS_DIR/$st/${CPSSYS}.cam.i.${yyyy}${st}.$atmic.bkup.nc ${CPSSYS}.cam.i.${yyyy}${st}.$atmic.nc
         body="Using ${CPSSYS}.cam.i.${yyyy}${st}.$atmic.bkup.nc as IC for perturbation $atmic" 
         title="[CAMIC] ${CPSSYS} forecast notification"
         $DIR_UTIL/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "yes" -s $yyyy$st
         icsatm+=" $atmic" 
      else
         body="Not available IC for perturbation $atmic" 
         title="[CAMIC] ${CPSSYS} forecast warning"
         $DIR_UTIL/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"-r "yes" -s $yyyy$st
      fi
   else
      if [[ `whoami` == $operational_user ]] ; then 
         if [[ -f $IC_CAM_SPS_DIR/$st/${CPSSYS}.cam.i.${yyyy}${st}.$atmic.bkup.nc ]]
         then
            rm $IC_CAM_SPS_DIR/$st/${CPSSYS}.cam.i.${yyyy}${st}.$atmic.bkup.nc 
         fi
      fi
      icsatm+=" $atmic"
   fi
done
for i in $icsatm ; do echo $RANDOM $i ; done|sort -k1|cut -d" " -f2 > $DIR_LOG/forecast/$yyyy$st/atm.ics.$yyyy$st

#---------------------------------------------
# CHECK THAT YOU HAVE ENOUGH ICs TO RUN THE ENSEMBLE WITH $nrunmax MEMBERS
#---------------------------------------------
nicsatm=`echo $icsatm | wc -w`
nicslnd=`echo $icslnd | wc -w`
nicsoce=`echo $icsoce | wc -w`
totpert=$(($nicsatm * $nicsoce * $nicslnd))
if [ $totpert -lt $(( $nrunmax + 5)) ]  # 5 more ensemble for possibile spikes
then
   if [ $it -gt 5 ]   # meaning more than 2 hours passed from run_ICs_production.sh launched: 
                      #START SENDING WARNING
   then
      body="Available ICs for ${CPSSYS} start-date $yyyy$st NOT SUFFICIENT \n
         CAM: $icsatm \n
         NEMO: $icsoce \n
         CLM: $icslnd
         total number $totpert.\n
         EXITING $IC_SPS35/randomizer.sh"
      title="[${CPSSYS}IC] ${CPSSYS} forecast warning"
      $DIR_UTIL/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "yes" -s $yyyy$st
      exit 1
   fi
   exit 0
else
   body="Available ICs for ${CPSSYS} start-date $yyyy$st \n
      CAM: $icsatm \n
      NEMO: $icsoce \n
      CLM: $icslnd"
   title="[${CPSSYS}IC] ${CPSSYS} forecast notification"
   $DIR_UTIL/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "yes" -s $yyyy$st
# if enough IC to generate triplette_done.txt create $checkfileok
   touch $checkfileok
fi

cd $DIR_CPS
# if triplette.txt exist remove it
if [ -f triplette.txt ] 
then
   rm triplette.txt
fi
# if triplette.random.$yyyy$st.txt  does not exist yet into $TRIP_DIR, create it
if [ ! -f $TRIP_DIR/triplette.random.$yyyy$st.txt ]
then
   # generate arrays from files with bash builtin function mapfile
   mapfile -t lndAR < $DIR_LOG/forecast/$yyyy$st/lnd.ics.$yyyy$st
   mapfile -t oceAR < $DIR_LOG/forecast/$yyyy$st/oce.ics.$yyyy$st
   mapfile -t atmAR < $DIR_LOG/forecast/$yyyy$st/atm.ics.$yyyy$st
   # invoke python passing it, by environment vars LNDAR etc, the arrays with IC number
   # python in turn get them from os.environ and split from ' 3 2 1 ' format to list [3,2,1]
   # finally itertools make permutations and write all (note the mode w+) on triplette.txt
   # (Now ocean is 1S,2U etc. therefore map function force to be a string) 
   LNDAR=${lndAR[@]} OCEAR=${oceAR[@]} ATMAR=${atmAR[@]} python - << EOF
import os, itertools 
lnd=list(map(int, os.environ['LNDAR'].split())) 
oce=list(map(int, os.environ['OCEAR'].split()))
atm=list(map(int, os.environ['ATMAR'].split()))
triplette = ["           {x}           {y}           {z}".format(x=x,y=y,z=z) for x,y,z in itertools.product(lnd, oce, atm)]
with open("triplette.txt", 'w+') as file_handler:
    for item in triplette:
        file_handler.write("{}\n".format(item))
EOF
   # create triplette.random.$yyyy$st.txt by shuffle operation
   cat triplette.txt |shuf >triplette.random.$yyyy$st.txt
   rm triplette.txt
else
   mv $TRIP_DIR/triplette.random.$yyyy$st.txt .
fi
# At this point triplette.random.$yyyy$st.txt is in $DIR_CPS

# now ensure to have TRIP_DIR and move the triplette.random.$yyyy$st.txt to $TRIP_DIR
mkdir -p $TRIP_DIR
mv triplette.random.$yyyy$st.txt $TRIP_DIR

#*******************************************
plnd=( $(awk '{print $1}' $TRIP_DIR/triplette.random.$yyyy$st.txt ) )
poce=( $(awk '{print $2}' $TRIP_DIR/triplette.random.$yyyy$st.txt ) )
patm=( $(awk '{print $3}' $TRIP_DIR/triplette.random.$yyyy$st.txt ) )

nrun=1
while [ $nrun -le $ntot ]
do
      nrun3=`printf '%.3d' $nrun`
set +e
      i=`expr $nrun - 1`
set -evx
      pp=${patm[$i]}
      ppland=${plnd[$i]}
      poce=${poce[$i]}

      caso=${SPSSystem}_${yyyy}${st}_${nrun3}
      echo "#!/bin/sh -l "                               > $DIR_SUBM_SCRIPTS/$st/$yyyy${st}_scripts/${header}_$yyyy${st}_${nrun3}.sh
      echo ". ~/.bashrc"                                 >> $DIR_SUBM_SCRIPTS/$st/$yyyy${st}_scripts/${header}_$yyyy${st}_${nrun3}.sh
      echo ". \${DIR_UTIL}/descr_CPS.sh"             >> $DIR_SUBM_SCRIPTS/$st/$yyyy${st}_scripts/${header}_$yyyy${st}_${nrun3}.sh
      echo "set -euvx"                                   >> $DIR_SUBM_SCRIPTS/$st/$yyyy${st}_scripts/${header}_$yyyy${st}_${nrun3}.sh
      echo "mkdir -p \$DIR_LOG/$typeofrun/$yyyy$st"           >> $DIR_SUBM_SCRIPTS/$st/$yyyy${st}_scripts/${header}_$yyyy${st}_${nrun3}.sh

      input="$yyyy $st $pp $ppland $poce $nrun"
      echo "\${DIR_UTIL}/submitcommand.sh -m \$machine -q \$serialq_m -j crea_${SPSSYS}_$yyyy${st}_${nrun3} -l \${DIR_LOG}/$typeofrun/$yyyy$st -d \$DIR_CPS -s create_caso.sh -i \"$input\" " >> $DIR_SUBM_SCRIPTS/$st/$yyyy${st}_scripts/${header}_$yyyy${st}_${nrun3}.sh

      chmod u+x $DIR_SUBM_SCRIPTS/$st/$yyyy${st}_scripts/${header}_$yyyy${st}_${nrun3}.sh

      #crea analogo per CINECA + (dopo il fcst di marzo aggiungere le code di MARCONI!!!)

      echo "#!/bin/sh -l"                      > $DIR_SUBM_SCRIPTS/$st/$yyyy${st}_scripts/CINECA/${header}_${yyyy}${st}_${nrun3}.sh
      echo ". \$HOME/.bashrc"              >> $DIR_SUBM_SCRIPTS/$st/$yyyy${st}_scripts/CINECA/${header}_${yyyy}${st}_${nrun3}.sh
      echo ". \$DIR_UTIL/descr_CPS.sh" >> $DIR_SUBM_SCRIPTS/$st/$yyyy${st}_scripts/CINECA/${header}_${yyyy}${st}_${nrun3}.sh
      # ATTENZIONE! I LOG SU CINECA VENGONO PRODOTTI RUN_TIME QUINDI NON POSSONO ESSERE SCRITTI SU UNA DIRECTORY NON ANCORA ESISTENTE, LA DIR LOGS DEL CASO VA CREATA prima
      echo "set -euvx "                >> $DIR_SUBM_SCRIPTS/$st/$yyyy${st}_scripts/CINECA/${header}_${yyyy}${st}_${nrun3}.sh
      echo "cd \$DIR_LOG"                >> $DIR_SUBM_SCRIPTS/$st/$yyyy${st}_scripts/CINECA/${header}_${yyyy}${st}_${nrun3}.sh
      echo "mkdir -p $typeofrun/$yyyy${st}"             >> $DIR_SUBM_SCRIPTS/$st/$yyyy${st}_scripts/CINECA/${header}_${yyyy}${st}_${nrun3}.sh
      echo "cd \$DIR_CASES"                   >> $DIR_SUBM_SCRIPTS/$st/$yyyy${st}_scripts/CINECA/${header}_${yyyy}${st}_${nrun3}.sh
      echo "mkdir -p $caso/logs"           >> $DIR_SUBM_SCRIPTS/$st/$yyyy${st}_scripts/CINECA/${header}_${yyyy}${st}_${nrun3}.sh
      
      # +ANTONIO 31/03/21 - added reservation and qos for MARCONI
      echo "\${DIR_UTIL}/submitcommand.sh -m \$machine -S qos_resv -q \$serialq_l -r \$sla_serialID -j crea_${SPSSystem}_$yyyy${st}_${nrun3} -l \$DIR_LOG/forecast/$yyyy${st} -d \$DIR_CPS -s create_caso.sh -i \"$input\" " >> $DIR_SUBM_SCRIPTS/$st/$yyyy${st}_scripts/CINECA/${header}_${yyyy}${st}_${nrun3}.sh
      chmod u+x $DIR_SUBM_SCRIPTS/$st/$yyyy${st}_scripts/CINECA/${header}_${yyyy}${st}_${nrun3}.sh
#crea analogo per CINECA -
      nrun=`expr $nrun + 1`
      cd $DIR_CPS 
done  # loop over ensemble members

cd $DIR_CPS

# COPY SCRIPTS, triplette_random AND ICs TO CINECA
cd ${DIR_SUBM_SCRIPTS}/$st/$yyyy${st}_scripts/CINECA/
if [ -f $TRIP_DIR/triplette.random.$yyyy$st.txt ]; then
tar -cvf $yyyy${st}_scripts_CINECA.tar *
body="Starting scripts dispach to CINECA" 
title="${CPSSYS} forecast notification"
$DIR_UTIL/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "yes" -s $yyyy$st
 
# FILE SYSTEM DEPENDENT
# create backup_machine directory (not necessary (since installer should had created it) but safer) 
mkdir -p $DIR_SCRA/backup_machine
mv $yyyy${st}_scripts_CINECA.tar $DIR_SCRA/backup_machine/

# SEND IC AND SUBMISSION SCRIPTS TO BACK-UP MACHINE
date_sendIC=`date +%Y%m%d`
njob=`${DIR_UTIL}/findjobs.sh -m $machine -n sendIC2CINECA_${date_sendIC} -c yes`
if [ $njob -eq 0 ]
then
   input="$date_sendIC 0"
   ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_l -j sendIC2CINECA_${date_sendIC} -l ${DIR_LOG}/sendIC2CINECA -d ${DIR_UTIL} -s sendIC2CINECA.sh -i "$input"
#   # adding new line for Marconi - antonio 01/03/2021 - 18:00
#   # manage marconi downtime
#   y2notify=`date +%Y`;
#   m2notify=`date +%m`;
#   d2notify=`date +%d`;
#   H2notify=18;
#   M2notify=`date +%M`;
#   data2notify=$y2notify":"$m2notify":"$d2notify":"$H2notify":"$M2notify
#   ${DIR_UTIL}/submitcommand.sh -m $machine -B $data2notify -q $serialq_l -j sendIC2MARCONI_${date_sendIC} -l ${DIR_LOG}/sendIC2CINECA -d ${DIR_UTIL} -s sendIC2BACKUP.sh -i "$input"

fi
