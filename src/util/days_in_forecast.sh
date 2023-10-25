#!/bin/sh -l
. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh

# function for leap year (useful here since don't print any loading modules)
isleap() { date -d $1-02-29 &>/dev/null &&  echo "TRUE" || echo "FALSE"; }

# usage of thisfunction
usage() { echo "Usage: $0 [-y <year> OPTIONAL] [-m <month> OPTIONALE] [-d <day> OPTIONAL] [-f <outputfrequency> OPTIONAL] [-l <noleap_cal> OPTIONAL]" 1>&2; exit 1; }
#set -evx
while getopts ":y:m:d:f:l:" o; do
    case "${o}" in
        m)
            mon=${OPTARG}
            ;;  
        y)      
            year=${OPTARG}
            ;;  
        d)      
            day=${OPTARG}
            ;;  
        f)      
            outxday=${OPTARG}
            ;;
        l)      
            noleap=${OPTARG}
            ;;            
    esac
done
if [ -z $year ]
then
   year=`date +%Y`
fi
if [ -z $mon ]
then
   month=`date +%m`
else
   month=`printf '%.2d' $((10#$mon))`
fi
if [ -z $day ]
then
   day='01'
fi
if [ -z $outxday ]
then
   outxday=1
fi
ic=0
days=0
while [ $ic -lt $nmonfore ]
do
   mm=`date -d "$year${month}$day + $ic month" +%m`
   yyyy=`date -d "$year${month}$day + $ic month" +%Y`
   days=$(($days + `cal $mm $yyyy | awk 'NF {DAYS = $NF}; END {print DAYS}'`))
   # if noleap option is defined february will be returned as a 28 days month 
   if [ ! -z $noleap ]
   then
      if [ $mm -eq 2 ]
      then
        # if year is a leap year
        isleap=$( isleap $yyyy )
        if [ $isleap == "TRUE" ]; then
          days=$(( $days - 1 ))
        fi
      fi  
   fi
   # echo results
   echo $days $mm  
   ic=$(($ic + 1))
done
echo $(($days * $outxday))
