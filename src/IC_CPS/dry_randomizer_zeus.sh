#!/bin/sh -l
#BSUB -J dry_randomizer_zeus
#BSUB -e /work/csp/sps-dev/CPS/CMCC-CPS1/logs/hindcast/dry_randomizer_%J.err
#BSUB -o /work/csp/sps-dev/CPS/CMCC-CPS1/logs/hindcast/dry_randomizer_%J.out
#BSUB -P 0574
#BSUB -q s_short

#***************************************
#***************************************
# load variables from descriptor
. $HOME/.bashrc
. $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/descr_ensemble.sh 1993

if [[ $machine != "zeus" ]]
then
   echo "this script is meant to run only in Zeus"
   exit
fi
set -evxu
ntot=$nrunmax
mkdir -p $TRIP_DIR
for yyyy in `seq $iniy_hind $endy_hind`
do 
   for st in {01..12}
   do
      mkdir -p $DIR_LOG/$typeofrun/$yyyy$st
      mkdir -p $DIR_SUBM_SCRIPTS1/$st/$yyyy${st}_scripts
      mkdir -p $DIR_SUBM_SCRIPTS1/$st/$yyyy${st}_scripts/CINECA

      for i in `seq -w 01 $n_ic_nemo` ; do echo $RANDOM $i ; done|sort -k1|cut -d" " -f2 > $DIR_LOG/$typeofrun/$yyyy$st/oce.ics.$yyyy$st
   
      for i in `seq -w 01 $n_ic_clm` ; do echo $RANDOM $i ; done|sort -k1|cut -d" " -f2 > $DIR_LOG/$typeofrun/$yyyy$st/lnd.ics.$yyyy$st

      for i in `seq -w 01 $n_ic_cam` ; do echo $RANDOM $i ; done|sort -k1|cut -d" " -f2 > $DIR_LOG/$typeofrun/$yyyy$st/atm.ics.$yyyy$st

#---------------------------------------------
# CHECK THAT YOU HAVE ENOUGH ICs TO RUN THE ENSEMBLE WITH $nrunmax MEMBERS
#---------------------------------------------
      totpert=$(($n_ic_cam * $n_ic_nemo * $n_ic_clm))

# if triplette.random.$yyyy$st.txt  does not exist yet into $TRIP_DIR, create it
      if [ ! -f $TRIP_DIR/triplette.random.$yyyy$st.txt ]
      then
   # generate arrays from files with bash builtin function mapfile
         mapfile -t lndAR < $DIR_LOG/$typeofrun/$yyyy$st/lnd.ics.$yyyy$st
         mapfile -t oceAR < $DIR_LOG/$typeofrun/$yyyy$st/oce.ics.$yyyy$st
         mapfile -t atmAR < $DIR_LOG/$typeofrun/$yyyy$st/atm.ics.$yyyy$st
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
         cat triplette.txt |shuf >$TRIP_DIR/triplette.random.$yyyy$st.txt
         rm triplette.txt
      fi

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
         input="$yyyy $st $pp $ppland $poce $nrun"
         cat > $DIR_SUBM_SCRIPTS1/$st/$yyyy${st}_scripts/${header}_$yyyy${st}_${nrun3}.sh << EOF1
#!/bin/sh -l
. \$HOME/.bashrc
. \${DIR_UTIL}/descr_CPS.sh
set -euvx
mkdir -p \$DIR_LOG/$typeofrun/$yyyy$st

\${DIR_UTIL}/submitcommand.sh -m \$machine -q \$serialq_m -j crea_${CPSSYS}_$yyyy${st}_${nrun3} -l \${DIR_LOG}/$typeofrun/$yyyy$st -d \$DIR_CPS -s create_caso.sh -i "$input"
EOF1

         chmod u+x $DIR_SUBM_SCRIPTS1/$st/$yyyy${st}_scripts/${header}_$yyyy${st}_${nrun3}.sh

      #crea analogo per CINECA + (dopo il fcst di marzo aggiungere le code di MARCONI!!!)
      # ATTENZIONE! I LOG SU CINECA VENGONO PRODOTTI RUN_TIME QUINDI NON POSSONO ESSERE SCRITTI SU UNA DIRECTORY NON ANCORA ESISTENTE, LA DIR LOGS DEL CASO VA CREATA prima

         cat > $DIR_SUBM_SCRIPTS1/$st/$yyyy${st}_scripts/CINECA/${header}_${yyyy}${st}_${nrun3}.sh << EOF2
#!/bin/sh -l
. \$HOME/.bashrc
. \$DIR_UTIL/descr_CPS.sh
set -euvx
cd \$DIR_LOG
mkdir -p $typeofrun/$yyyy${st}
cd \$DIR_CASES
mkdir -p $caso/logs
      
\${DIR_UTIL}/submitcommand.sh -m \$machine -S qos_resv -q \$serialq_l -r \$sla_serialID -j crea_${SPSSystem}_$yyyy${st}_${nrun3} -l \$DIR_LOG/$typeofrun/$yyyy${st} -d \$DIR_CPS -s create_caso.sh -i "$input"

EOF2
         chmod u+x $DIR_SUBM_SCRIPTS1/$st/$yyyy${st}_scripts/CINECA/${header}_${yyyy}${st}_${nrun3}.sh
#crea analogo per CINECA -
         nrun=`expr $nrun + 1`
         cd $DIR_CPS 
      done  # loop over ensemble members


# COPY SCRIPTS, triplette_random AND ICs TO CINECA
      cd ${DIR_SUBM_SCRIPTS1}/$st/$yyyy${st}_scripts/CINECA/
      if [ -f $TRIP_DIR/triplette.random.$yyyy$st.txt ]; then
         cp $TRIP_DIR/triplette.random.$yyyy$st.txt .
      fi
      tar -cvf $yyyy${st}_scripts_CINECA.tar *
      mkdir -p $DIR_SUBM_SCRIPTS1/backup_machine
      mv $yyyy${st}_scripts_CINECA.tar $DIR_SUBM_SCRIPTS/backup_machine/
   done   #loop on start-date months
done   #loop on hindcast years
