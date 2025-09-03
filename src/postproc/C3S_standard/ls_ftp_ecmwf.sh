#!/bin/sh  -l

. ~/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

set -euvx

yyyy=$1
st=$2
mymail=$3
type_fore=$4
debug_ls=$5           # if debug_ls=1 than send to cmcc bologna ftp for tests
log_script=$6
machine=$7
#cmd_ftp_cmccbo="open -u c3s,cDx52!lst ftp://downloads.cmcc.bo.it"
cmd_ftp_cmccbo="open -u c3s,YhjDf733 ftp://ftp4.cmcc.it"
cmd_ftp_ecmwf="open -u cmcc_c3s,cmcc_c3s_2018 ftp://acq.ecmwf.int"

. ${DIR_UTIL}/descr_ensemble.sh $yyyy

REMOTE_DIR="/DATA/CMCC_C3S/"
# WARNING!! DO NOT PUT / AT THE END
if [[ $debug_ls -ge 1 ]]
then
# WARNING!! DO NOT PUT / AT THE END
   REMOTE_DIR="/DATA/CMCC_C3S/TEST"
fi

if [[ $debug_ls -eq 1 ]]
then
   if [[ "$machine" == "juno" ]]
   then
      lftp_cmd=$DIR_LOG/${type_fore}/$yyyy$st/ls.lftp.cmcc
      log_lftp=$DIR_LOG/${type_fore}/$yyyy$st/$log_script
   elif [[ "$machine" == "leonardo" ]]
   then
      lftp_cmd=$DIR_LOG/${type_fore}/$yyyy$st/ls.lftp.cmcc
      log_lftp=$DIR_LOG/${type_fore}/$yyyy$st/$log_script
   fi
   cat > $lftp_cmd << EOF
set ftp:list-options -a
$cmd_ftp_cmccbo
cd $REMOTE_DIR
ls *S${yyyy}${st}*
quit
EOF
   lftp -f $lftp_cmd |tee $log_lftp
   stat=$?
   if [[ $stat -eq 1 ]]; then
      echo "error on  attempt ls.lftp.cmcc "|mail $mymail
      exit 1
   fi        


elif [[ $debug_ls -eq 2 ]] || [[ $debug_ls -eq 0 ]]
then
   if [[ "$machine" == "juno" ]]
   then
      lftp_cmd=$DIR_LOG/${type_fore}/$yyyy$st/ls.lftp.ecmwf
      log_lftp=$DIR_LOG/${type_fore}/$yyyy$st/$log_script
   elif [[ "$machine" == "leonardo" ]]
   then
      lftp_cmd=$DIR_LOG/${type_fore}/$yyyy$st/ls.lftp.ecmwf
      log_lftp=$DIR_LOG/${type_fore}/$yyyy$st/$log_script
   fi
   cat > $lftp_cmd << EOF
set ftp:list-options -a
$cmd_ftp_ecmwf
cd $REMOTE_DIR
ls *S${yyyy}${st}*
quit
EOF
   lftp -f $lftp_cmd |tee $log_lftp
   stat=$?
   if [[ $stat -eq 1 ]]; then
      echo "error on  attempt send.lftp "|mail $mymail
      exit 1
   fi
fi         
