#!/bin/sh  -l

. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
. ~/load_miniconda
conda activate $envcondacm3
##DO NOT UPLOAD the DESCRIPTOR HERE!! THIS SCRIPT IS USED ON dtn03 !!!

set -euvx
user_dtn03=`whoami`
yyyy=$1
st=$2
mymail=$3
type_fore=$4
ntarandsha=$5      #number of total file expected (sha256+tar)
first=$6
dbg_push=$7           # if dbg_push=1 than send to cmcc ftp for tests
log_script=$8
machine=$9
lpushdir=${10}

. ${DIR_UTIL}/descr_ensemble.sh $yyyy

#nstreams=9
nstreams=20
REMOTE_DIR="/DATA/CMCC_CERISE"
# WARNING!! DO NOT PUT / AT THE END

# WARNING!! DO NOT PUT / AT THE END
datestr=`date +%Y%m%d%H%M%S`
LOCAL_DIR=$lpushdir/${yyyy}${st}
logfile="push_CERISE_${type_fore}_S${yyyy}${st}.$datestr.log"

cmd_ftp_ecmwf="open -u cmcc_cerise,ZZ6e0O1B ftp://acq.ecmwf.int"


if [ ! -f $first ]
then
   touch $first
fi
if [[ $dbg_push -eq 1 ]]
then
   if [[ "$machine" == "juno" ]] || [[ "$machine" == "cassandra" ]]
   then
      script_send=$DIR_LOG/${type_fore}/$yyyy$st/send.lftp.cmcc
      cat > $script_send << EOF
set xfer:log true
set xfer:log-file "$DIR_LOG/${type_fore}/$yyyy$st/${logfile}"
set ftp:list-options -a
$cmd_ftp_cmccbo
mirror -v --reverse --ignore-time --parallel=${nstreams} $LOCAL_DIR $REMOTE_DIR || exit 1
quit
EOF
   elif [[ "$machine" == "leonardo" ]]
   then
      script_send=$DIR_LOG/${type_fore}/$yyyy$st/send.lftp.cmcc
      cat > $script_send << EOF
set xfer:log true
set xfer:log-file "$DIR_LOG/${type_fore}/$yyyy$st/${logfile}"
set ftp:list-options -a
$cmd_ftp_cmccbo
mirror -v --reverse --ignore-time --parallel=${nstreams} $LOCAL_DIR $REMOTE_DIR || exit 1
quit
EOF
   fi
   chmod 744 $script_send

elif [[ $dbg_push -eq 2 ]] || [[ $dbg_push -eq 0 ]] 
then
   if [[ "$machine" == "juno" ]] || [[ "$machine" == "cassandra" ]]
   then
      script_send=$DIR_LOG/${type_fore}/$yyyy$st/send.lftp
      cat > $script_send << EOF
set xfer:log true
set xfer:log-file "$DIR_LOG/${type_fore}/$yyyy$st/${logfile}"
set ftp:list-options -a
$cmd_ftp_ecmwf
mirror -v --reverse --ignore-time --parallel=${nstreams} $LOCAL_DIR $REMOTE_DIR || exit 1
quit
EOF
   fi
   chmod 744 $script_send

fi  #if dbg
lftp -f $script_send
stat=$?
if [ $stat -eq 1 ]; then
      echo "error on  attempt $script_send ${yyyy}$st"|mail -s "[CERISE] ${SPSSystem} forecast ERROR" $mymail
      exit 1
fi         

if [[ $dbg_push -eq 1 ]]
then
   if [[ "$machine" == "juno" ]] || [[ "$machine" == "cassandra" ]]
   then
      script_ls=$DIR_LOG/${type_fore}/$yyyy$st/ls.lftp.cmcc
      log_script=$DIR_LOG/${type_fore}/$yyyy$st/$log_script
      cat > $script_ls << EOF
set ftp:list-options -a
$cmd_ftp_cmccbo
cd $REMOTE_DIR
ls *S${yyyy}${st}*
quit
EOF
   elif [[ "$machine" == "leonardo" ]]
   then
      script_ls=$DIR_LOG/${type_fore}/$yyyy$st/ls.lftp.cmcc
      log_script=$DIR_LOG/${type_fore}/$yyyy$st/$log_script
      cat > $script_ls << EOF
set ftp:list-options -a
$cmd_ftp_cmccbo
cd $REMOTE_DIR
ls *S${yyyy}${st}*
quit
EOF
   fi

elif [[ $dbg_push -eq 2 ]] || [[ $dbg_push -eq 0 ]]
then
   if [[ "$machine" == "juno" ]] || "$machine" == "cassandra" ]]
   then
      script_ls=$DIR_LOG/${type_fore}/$yyyy$st/ls.lftp
      log_script=$DIR_LOG/${type_fore}/$yyyy$st/$log_script
      cat > $script_ls << EOF
set ftp:list-options -a
$cmd_ftp_ecmwf
cd $REMOTE_DIR
ls *S${yyyy}${st}*
quit
EOF
   elif [[ "$machine" == "leonardo" ]]
   then
      script_ls=$DIR_LOG/${type_fore}/$yyyy$st/ls.lftp
      log_script=$DIR_LOG/${type_fore}/$yyyy$st/$log_script
      cat > $script_ls << EOF
set ftp:list-options -a
$cmd_ftp_ecmwf
cd $REMOTE_DIR
ls *S${yyyy}${st}*
quit
EOF
   fi  
fi

lftp -f $script_ls |tee $log_script

if [ $ntarandsha -eq 1 ]
then 
   lftp -f $script_send
   lftp -f $script_ls |tee $log_script
   echo "sending manifest ${yyyy}$st"|mail -s "[CERISE] ${SPSSystem} forecast notification" $mymail
fi
