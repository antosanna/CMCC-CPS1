#!/bin/sh  -l

. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh

set -euvx

yyyy=$1
st=$2
mymail=$3
type_fore=$4
dbg=$5           # if dbg=1 than send to bologna ftp for tests

REMOTE_DIR="/data/DATA/SEASON/gpc_bologna/${type_fore}"
# WARNING!! DO NOT PUT / AT THE END
if [ $dbg -ge 1 ]
then
   mymail=andrea.borrelli@cmcc.it
# WARNING!! DO NOT PUT / AT THE END
   REMOTE_DIR="/data/DATA/SEASON/gpc_bologna/${type_fore}/sample_hindcast"
fi

if [ $dbg -gt 1 ]
then
      cat > $DIR_LOG/${type_fore}/$yyyy$st/ls.lftp << EOF
set xfer:log true
set xfer:log-file "$DIR_LOG/${type_fore}/$yyyy$st/lista_WMO_S${yyyy}$st.log"
set ftp:list-options -a
open -p 21322 -u gpc_bologna,gpcbologna@! sftp://210.98.49.66
cd $REMOTE_DIR
ls -l |grep CMCC_SPS_${yyyy}${st}
quit
EOF
     lftp -f $DIR_LOG/${type_fore}/$yyyy$st/ls.lftp |tee ls_S${yyyy}$st.log
     stat=$?
     if [ $stat -eq 1 ]; then
        echo "TEST [WMO] error on attempt ls.lftp "|mail $mymail
        exit 1
     fi        
else
      cat > $DIR_LOG/${type_fore}/$yyyy$st/ls.lftp << EOF
set xfer:log true
set xfer:log-file "$DIR_LOG/${type_fore}/$yyyy$st/lista_WMO_S${yyyy}$st.log"
set ftp:list-options -a
open -p 21322 -u gpc_bologna,gpcbologna@! sftp://210.98.49.66
cd $REMOTE_DIR
ls -l |grep CMCC_SPS_${yyyy}${st}
quit
EOF
      lftp -f $DIR_LOG/${type_fore}/$yyyy$st/ls.lftp |tee ls_S${yyyy}$st.log
      stat=$?
      if [ $stat -eq 1 ]; then
         echo "[WMO] error on  attempt send.lftp "|mail $mymail
         exit 1
      fi
fi         
