#!/bin/sh -l
# this script must be run only once at the beginning of the extended hindcast operations
. $HOME/.bashrc
. $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/descr_ensemble.sh 1993
#***************************************
#***************************************
# load variables from descriptor

set -evxu
ntot=$nrunmax
mkdir -p $TRIP_DIR
for yyyy in `seq $iniy_hindext $endy_hind`
do
   for st in 11
   do
      mkdir -p $DIR_LOG/$typeofrun/$yyyy$st
      mkdir -p $DIR_SUBM_SCRIPTS/$st/$yyyy${st}_scripts

#---------------------------------------------
# CHECK THAT YOU HAVE ENOUGH ICs TO RUN THE ENSEMBLE WITH $nrunmax MEMBERS
#---------------------------------------------
      totpert=$(($n_ic_cam * $n_ic_nemo * $n_ic_clm))

# if triplette.random.$yyyy$st.txt  does not exist yet into $TRIP_DIR, create it
      if [[ ! -f $TRIP_DIR/triplette.random.$yyyy$st.txt ]]
      then
         echo "the file $TRIP_DIR/triplette.random.$yyyy$st.txt must exist"
         exit
      fi

#*******************************************
      plnd=( $(awk '{print $1}' $TRIP_DIR/triplette.random.$yyyy$st.txt ) )
      poce=( $(awk '{print $2}' $TRIP_DIR/triplette.random.$yyyy$st.txt ) )
      patm=( $(awk '{print $3}' $TRIP_DIR/triplette.random.$yyyy$st.txt ) )

#      nrun=1
#      while [ $nrun -le $ntot ]
      for nrun in `seq 1 $ntot`
      do
         nrun3=`printf '%.3d' $nrun`
         if [[ -f $DIR_SUBM_SCRIPTS/$st/$yyyy${st}_scripts/${headerext}_$yyyy${st}_${nrun3}.sh ]]
         then
            continue
         fi
      set +e
         i=`expr $nrun - 1`
      set -evx
         pp=${patm[$i]}
         ppland=${plnd[$i]}
         poce=${poce[$i]}

         caso=${SPSSystem}ext_${yyyy}${st}_${nrun3}
         input="$yyyy $st $pp $ppland $poce $nrun"
         cat > $DIR_SUBM_SCRIPTS/$st/$yyyy${st}_scripts/${headerext}_$yyyy${st}_${nrun3}.sh << EOF1
#!/bin/sh -l
. \$HOME/.bashrc
. \${DIR_UTIL}/descr_CPS.sh
set -euvx
mkdir -p \$DIR_LOG/$typeofrun/$yyyy$st

\${DIR_UTIL}/submitcommand.sh -m \$machine -q \$serialq_m -j crea_${caso} -l \${DIR_LOG}/$typeofrun/$yyyy$st -d \$DIR_CPS -s create_branch_extended.sh -i "$input"
EOF1

         chmod u+x $DIR_SUBM_SCRIPTS/$st/$yyyy${st}_scripts/${headerext}_$yyyy${st}_${nrun3}.sh
         chmod u+x $DIR_SUBM_SCRIPTS/$st/$yyyy${st}_scripts/${headerext}_$yyyy${st}_${nrun3}.sh

      #now the script for CINECA where the syntax with submitcommand.sh does not work
         cat > $DIR_SUBM_SCRIPTS/$st/$yyyy${st}_scripts/CINECA/${headerext}_$yyyy${st}_${nrun3}.sh << EOF2
#!/bin/sh -l
. \$HOME/.bashrc
. \${DIR_UTIL}/descr_CPS.sh
set -euvx
mkdir -p \$DIR_LOG/$typeofrun/$yyyy$st

\$DIR_CPS/create_branch_extended.sh $yyyy $st $pp $ppland $poce $nrun >& ${DIR_LOG}/$typeofrun/$yyyy$st/crea_${caso}.log
EOF2

         chmod u+x $DIR_SUBM_SCRIPTS/$st/$yyyy${st}_scripts/CINECA/${headerext}_$yyyy${st}_${nrun3}.sh

#         nrun=`expr $nrun + 1`
         cd $DIR_CPS 
      done  # loop over ensemble members

   done   #loop on start-date months
done   #loop on hindcast years
