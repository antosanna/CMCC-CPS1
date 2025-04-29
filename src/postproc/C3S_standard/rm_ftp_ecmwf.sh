#!/bin/sh  -l

. ~/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

set -euvx

yyyy=$1
st=$2
mymail=$3
list2rm=$4
debug_rm=$5           # if debug_rm=1 than send to bologna ftp for tests
machine=$6
type_fore=${7:-"forecast"}

. ${DIR_UTIL}/descr_ensemble.sh $yyyy

REMOTE_DIR="/DATA/CMCC_C3S/"
# WARNING!! DO NOT PUT / AT THE END
if [[ $debug_rm -ge 1 ]]
then
# WARNING!! DO NOT PUT / AT THE END
   REMOTE_DIR="/DATA/CMCC_C3S/test"
fi
#cmd_ftp_cmccbo="open -u c3s,cDx52!lst ftp://downloads.cmcc.bo.it"
cmd_ftp_cmccbo="open -u c3s,YhjDf733 ftp://ftp4.cmcc.it"
cmd_ftp_dataecmwf="open -u cmcc_c3s,cmcc_c3s_2018 ftp://acq.ecmwf.int"

datestr=`date +%Y%m%d%H%M%S`
if [[ $debug_rm -eq 1 ]]
then
   if [[ "$machine" == "juno" ]]
   then
      script=$DIR_LOG/${type_fore}/$yyyy$st/rm.lftp.cmcc
   elif [[ "$machine" == "leonardo" ]]
   then
      script=$DIR_LOG/${type_fore}/$yyyy$st/rm.lftp.cmcc
   fi
   cat > $script << EOF
set ftp:list-options -a
$cmd_ftp_cmccbo
cd $REMOTE_DIR
glob -a rm -r -f ${list2rm}
quit
EOF
elif [[ $debug_rm -eq 0 ]] || [[ $debug_rm -eq 2 ]]
then
   if [[ "$machine" == "juno" ]]
   then
      script=$DIR_LOG/${type_fore}/$yyyy$st/rm.lftp.ecmwf
   elif [[ "$machine" == "leonardo" ]]
   then
      script=$DIR_LOG/${type_fore}/$yyyy$st/rm.lftp.ecmwf
   fi
   cat > $script << EOF
set ftp:list-options -a
$cmd_ftp_dataecmwf
cd $REMOTE_DIR
glob -a rm -r -f ${list2rm}
quit
EOF
fi         
lftp -f $script
stat=$?
if [ $stat -eq 1 ]; then
   echo "error on  attempt $script "|mail $mymail
   exit 1
fi        
touch ${script}_${datestr}_DONE
