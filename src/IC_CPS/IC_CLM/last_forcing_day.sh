#!/bin/sh -l
#-------------------------------------------------------------------------------
# Use: ./last_forcing_day.sh [file] [nday] [yyyy] [mm] [freq]
#   file   ECMWF data of month previous to start-date
#   nday   n dayys of month previous to start-date
#   yyyy   year of month previous to start-date
#   mm     month previous to start-date in 2 digits
#   freq   time frequency
#
# THIS SCRIPT IS CAUTIONARY TO "FILL" THE MONTH IN CASE ECMWF ANALYSES ARE NOT AVAILABLE UP TO THE END OF THE PREVIOUS MONTH
# In operational production, this script is launched in $DIR_LND_IC by create_ecmwfFORC.sh
#-------------------------------------------------------------------------------

set -exvu

#------------------------------------------------
#-------------------------------------------------------------
# read input
#-------------------------------------------------------------
#------------------------------------------------
inputfile=$1   #NCEP data of month previous to start-date
nday=$2   #n dayys of month previous to start-date
yr=$3     #year of month previous to start-date
mm2d=$4   #month previous to start-date in 2 digits
freq=$5

#------------------------------------------------
#-------------------------------------------------------------
# Persist N days if necessary
#-------------------------------------------------------------
#------------------------------------------------
# copy monthly file
# read last time step
tstepread=`cdo -ntime ${inputfile}`
tstep=`expr $nday \* $freq`
# if last time step is not the desired forecast day, then persist file to fill the month
date_lastday=999
if [ $tstepread -ne $tstep ]
then
    #lastdayp1=`cdo showdate $inputfile|rev|cut -d ' ' -f1|rev`
    #tail added to handle multiple line output of cdo showdate
    lastdayp1=`cdo showdate $inputfile|rev|cut -d ' ' -f1|rev |tail -n1`
    date_lastdayp1=${lastdayp1:0:4}${lastdayp1:5:2}${lastdayp1:8:2}
    date_lastday=`date -d "$date_lastdayp1 - 1day" +%d`
fi
echo $((10#$date_lastday))

exit 0
