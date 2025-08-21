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
# per CINECA
if [[ $machine == "leonardo" ]]
then
   echo "This script must be run on Juno!!! Exit now!!"
   exit 1
fi

#-- RANDOMIZATION --------------------------------

# numero totale di perturbazioni totale superiore al numero totale da fare per prevedere che alcuni membri esplodano
ntot=$nrunmax
#SELECT RANDOMLY AMONG ? PERTURBATIONS
mkdir -p $DIR_LOG/$typeofrun/$yyyy$st
cd $DIR_LOG/$typeofrun/$yyyy$st

# RANDOM is an instrinsic unix proc that generates a random number
# to each $i a random number is associated and then sorted in ascendong order
for i in `seq -w 01 $n_ic_nemo` ; do echo $RANDOM $i ; done|sort -k1|cut -d" " -f2 > $DIR_LOG/$typeofrun/$yyyy$st/oce.ics.$yyyy$st
   
for i in `seq -w 01 $n_ic_clm` ; do echo $RANDOM $i ; done|sort -k1|cut -d" " -f2 > $DIR_LOG/$typeofrun/$yyyy$st/lnd.ics.$yyyy$st

for i in `seq 1 $n_ic_cam` ; do echo $RANDOM $i ; done|sort -k1|cut -d" " -f2 > $DIR_LOG/forecast/$yyyy$st/atm.ics.$yyyy$st

cd $DIR_CPS
# if triplette.random.$yyyy$st.txt  does not exist yet into $TRIP_DIR, create it
if [ ! -f $TRIP_DIR/triplette.CERISE.random.$yyyy$st.txt ]
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
   mkdir -p $TRIP_DIR
   cat triplette.txt |shuf >$TRIP_DIR/triplette.CERISE.random.$yyyy$st.txt
   rm triplette.txt
fi

set +euvx
. $dictionary
set -euvx
touch $checkfile_trip
