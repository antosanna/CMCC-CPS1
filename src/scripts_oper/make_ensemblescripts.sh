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

. $DIR_UTIL/descr_ensemble.sh $yyyy
mkdir -p ${DIR_SUBM_SCRIPTS}/$st/$yyyy${st}_scripts/
# per CINECA
if [[ $machine == "leonardo" ]]
then
   mkdir -p ${DIR_SUBM_SCRIPTS}/$st/$yyyy${st}_scripts/CINECA
fi

cd $DIR_CPS

#*******************************************
plnd=( $(awk '{print $1}' $TRIP_DIR/triplette.random.$yyyy$st.txt ) )
poce=( $(awk '{print $2}' $TRIP_DIR/triplette.random.$yyyy$st.txt ) )
patm=( $(awk '{print $3}' $TRIP_DIR/triplette.random.$yyyy$st.txt ) )

nrun=1
while [ $nrun -le $nrunmax ]
do
   nrun3=`printf '%.3d' $nrun`
set +e
   i=`expr $nrun - 1`
set -evx
   pp=${patm[$i]}
   ppland=${plnd[$i]}
   poce=${poce[$i]}

   caso=${SPSSystem}_${yyyy}${st}_${nrun3}
     
   if [[ $machine == "juno" ]]   #this will be used only in backup conditions because the forecast is to be run on Leonardo
   then
      echo "#!/bin/sh -l "                               > $DIR_SUBM_SCRIPTS/$st/$yyyy${st}_scripts/${header}_$yyyy${st}_${nrun3}.sh
      echo ". ~/.bashrc"                                 >> $DIR_SUBM_SCRIPTS/$st/$yyyy${st}_scripts/${header}_$yyyy${st}_${nrun3}.sh
      echo ". \${DIR_UTIL}/descr_CPS.sh"             >> $DIR_SUBM_SCRIPTS/$st/$yyyy${st}_scripts/${header}_$yyyy${st}_${nrun3}.sh
      echo "set -euvx"                                   >> $DIR_SUBM_SCRIPTS/$st/$yyyy${st}_scripts/${header}_$yyyy${st}_${nrun3}.sh
      echo "mkdir -p \$DIR_LOG/$typeofrun/$yyyy$st"           >> $DIR_SUBM_SCRIPTS/$st/$yyyy${st}_scripts/${header}_$yyyy${st}_${nrun3}.sh

      input="$yyyy $st $pp $ppland $poce $nrun"
      echo "\${DIR_UTIL}/submitcommand.sh -m \$machine -q \$serialq_m -j crea_${caso} -l \${DIR_LOG}/$typeofrun/$yyyy$st -d \$DIR_CPS -s create_caso.sh -i \"$input\" " >> $DIR_SUBM_SCRIPTS/$st/$yyyy${st}_scripts/${header}_$yyyy${st}_${nrun3}.sh

      chmod u+x $DIR_SUBM_SCRIPTS/$st/$yyyy${st}_scripts/${header}_$yyyy${st}_${nrun3}.sh

      #crea analogo per CINECA + (dopo il fcst di marzo aggiungere le code di MARCONI!!!)

   elif [[ $machine == "leonardo" ]]
   then
      cat > $DIR_SUBM_SCRIPTS/$st/$yyyy${st}_scripts/CINECA/${header}_${yyyy}${st}_${nrun3}.sh << EOF2
#!/bin/sh -l
. \$HOME/.bashrc
. \$DIR_UTIL/descr_CPS.sh
set -euvx
cd \$DIR_LOG
mkdir -p $typeofrun/$yyyy${st}
cd \$DIR_CASES
mkdir -p $caso/logs

mkdir -p $SCRATCHDIR/cases_${st}
sed -e "s/YYYY/${yyyy}/g;s/STDATE/$st/g;s/PATM/$pp/g;s/PLAND/$ppland/g;s/POCE/$poce/g;s/NRUN/$nrun/g;" $DIR_CPS/create_caso_leonardo.sh > $SCRATCHDIR/cases_$st/create_caso_leonardo_$caso.sh
chmod u+x $SCRATCHDIR/cases_$st/create_caso_leonardo_$caso.sh
srun -c16 -A ${account_name} --qos=qos_lowprio -p dcgp_usr_prod -t 0:30:00 $SCRATCHDIR/cases_$st/create_caso_leonardo_$caso.sh

EOF2
      chmod u+x $DIR_SUBM_SCRIPTS/$st/$yyyy${st}_scripts/CINECA/${header}_${yyyy}${st}_${nrun3}.sh
   fi
    nrun=`expr $nrun + 1`
    cd $DIR_CPS 
done  # loop over ensemble members

