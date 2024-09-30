#!/bin/sh  -l

. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
. $DIR_POST/APEC/descr_SPS4_APEC.sh

set -euvx

yyyy=$1
st=$2
mymail=$3
type_fore=$4
ntarandsha=$5      #number of total file expected (sha256+tar)
first=$6
dbg_push=$7           # if dbg_push=1 than send to bologna ftp for tests

user=`whoami`
#if [ $dbg_push -ne 1 ]
#then
#   exit
#fi
nstreams=18
REMOTE_DIR="/data/DATA/SEASON/gpc_bologna/${type_fore}"
title_debug=""

if [ $type_fore = "hindcast" ] ; then
   mymail=sp1@cmcc.it
fi
# WARNING!! DO NOT PUT / AT THE END
if [ $dbg_push -ge 1 ]
then
   mymail=sp1@cmcc.it
# WARNING!! DO NOT PUT / AT THE END
   REMOTE_DIR="/data/DATA/SEASON/gpc_bologna/sample_${type_fore}"
   title_debug="TEST "
fi

# WARNING!! DO NOT PUT / AT THE END
datestr=`date +%Y%m%d%H%M%S`
LOCAL_DIR="$pushdirapec/${type_fore}/${yyyy}${st}/monthly"

logfile="push_${type_fore}_S${yyyy}${st}.$datestr.log"

if [ ! -f $first ]
then
   touch $first
fi
if [ $dbg_push -eq 1 ]
then
      cat > $DIR_LOG/${type_fore}/$yyyy$st/send.lftp.bologna << EOF
set xfer:log true
set xfer:log-file "/home/${user}/${logfile}"
set ftp:list-options -a
open -p 21322 -u gpc_bologna,gpcbologna@! sftp://210.98.49.66
mirror -v --reverse --ignore-time --parallel=${nstreams} $LOCAL_DIR $REMOTE_DIR || exit 1
quit
EOF
      chmod 744 $DIR_LOG/${type_fore}/$yyyy$st/send.lftp.bologna
      lftp -f $DIR_LOG/${type_fore}/$yyyy$st/send.lftp.bologna
      stat=$?
      if [ $stat -eq 1 ]; then
         echo "error on  attempt send.lftp.bologna ${yyyy}$st"|mail -s "${title_debug}[WMO] ${SPSSYS} ${type_fore} notification" $mymail
         exit 1
      fi        
else
      cat > $DIR_LOG/${type_fore}/$yyyy$st/send.lftp << EOF
set xfer:log true
set xfer:log-file "$DIR_LOG/${type_fore}/$yyyy$st/${logfile}"
set ftp:list-options -a
open -p 21322 -u gpc_bologna,gpcbologna@! sftp://210.98.49.66
cd $REMOTE_DIR
mkdir ${yyyy}$st
mirror -v --reverse --ignore-time --parallel=${nstreams} $LOCAL_DIR $REMOTE_DIR/${yyyy}$st || exit 1
quit
EOF
      chmod 744 $DIR_LOG/${type_fore}/$yyyy$st/send.lftp
      lftp -f $DIR_LOG/${type_fore}/$yyyy$st/send.lftp
      stat=$?
      if [ $stat -eq 1 ]; then
         echo "error on  attempt send.lftp ${yyyy}$st"|mail -s "${title_debug}[WMO] ${SPSSYS} ${type_fore} notification" $mymail
         exit 1
      fi         
fi

if [ $dbg_push -eq 1 ]
then
      cat > $DIR_LOG/${type_fore}/$yyyy$st/ls.lftp.bologna << EOF
set ftp:list-options -a
open -p 21322 -u gpc_bologna,gpcbologna@! sftp://210.98.49.66
cd $REMOTE_DIR
ls -l |grep CMCC_SPS_${yyyy}${st}
quit
EOF
      lftp -f $DIR_LOG/${type_fore}/$yyyy$st/ls.lftp.bologna |tee $DIR_LOG/${type_fore}/$yyyy$st/ls_WMO_S${yyyy}$st.log
else
      cat > $DIR_LOG/${type_fore}/$yyyy$st/ls.lftp << EOF
set ftp:list-options -a
open -p 21322 -u gpc_bologna,gpcbologna@! sftp://210.98.49.66
cd $REMOTE_DIR/${yyyy}$st
ls -l |grep CMCC_SPS_${yyyy}${st}
quit
EOF
      lftp -f $DIR_LOG/${type_fore}/$yyyy$st/ls.lftp |tee $DIR_LOG/${type_fore}/$yyyy$st/ls_WMO_S${yyyy}$st.log
fi

if [ $ntarandsha -eq 1 ]
then 
   if [ $dbg_push -eq 1 ]
   then
      lftp -f $DIR_LOG/${type_fore}/$yyyy$st/send.lftp.bologna
      lftp -f $DIR_LOG/${type_fore}/$yyyy$st/ls.lftp.bologna |tee $DIR_LOG/${type_fore}/$yyyy$st/ls_WMO_S${yyyy}$st.log
   else
      lftp -f $DIR_LOG/${type_fore}/$yyyy$st/send.lftp
      lftp -f $DIR_LOG/${type_fore}/$yyyy$st/ls.lftp |tee $DIR_LOG/${type_fore}/$yyyy$st/ls_WMO_S${yyyy}$st.log
   fi
   echo "sending manifest ${yyyy}$st"|mail -s "[WMO] ${SPSSYS} ${type_fore} notification" $mymail
fi
