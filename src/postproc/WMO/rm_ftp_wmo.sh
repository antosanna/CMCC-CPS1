#!/bin/sh  -l

. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh

set -euvx

yyyy=$1
st=$2
mymail=$3
list2rm=$4
dbg_push=$5           # if dbg_push=1 than send to bologna ftp for tests
type_fore=$6

#if [ $dbg_push -ne 1 ]
#then
#   exit
#fi
REMOTE_DIR="/data/DATA/SEASON/gpc_bologna/${type_fore}"
# WARNING!! DO NOT PUT / AT THE END
if [ $dbg_push -ge 1 ]
then
   mymail=sp1@cmcc.it
# WARNING!! DO NOT PUT / AT THE END
   REMOTE_DIR="/data/DATA/SEASON/gpc_bologna/${type_fore}/test"
fi

datestr=`date +%Y%m%d%H%M%S`
if [ $dbg_push -gt 1 ]
then
      cat > rm.lftp.bologna << EOF
set ftp:list-options -a
open -p 21322 -u gpc_bologna,gpcbologna@! sftp://210.98.49.66
cd $REMOTE_DIR
glob -a rm -r -f ${list2rm}
quit
EOF
      lftp -f rm.lftp.bologna 
      stat=$?
      if [ $stat -eq 1 ]; then
         echo "[WMO] error on  attempt rm.lftp.bologna "|mail $mymail
         exit 1
      fi        
      touch rm.lftp.bologna_${datestr}_DONE
else
      cat > rm.lftp << EOF
set ftp:list-options -a
open -p 21322 -u gpc_bologna,gpcbologna@! sftp://210.98.49.66
cd $REMOTE_DIR
glob -a rm -r -f ${list2rm}
quit
EOF
      lftp -f rm.lftp 
      stat=$?
      if [ $stat -eq 1 ]; then
         echo "[WMO] error on  attempt rm.lftp "|mail $mymail
         exit 1
      fi
      touch rm.lftp_${datestr}_DONE
fi         
