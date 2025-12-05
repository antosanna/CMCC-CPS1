#!/bin/sh  -l

. ~/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
if [[ $machine != "juno" ]]
then
   . ~/load_miniconda
else
   . ~/load_condasys
fi
conda activate $envcondacm3

set -euvx

yyyy=$1
st=$2
mymail=$3
type_fore=$4
debug_ls=$5           # if debug_ls=1 than send to cmcc bologna ftp for tests
log_script=$6
machine=$7
cmd_ftp_ecmwf="open -u cmcc_cerise,ZZ6e0O1B ftp://acq.ecmwf.int"

. ${DIR_UTIL}/descr_ensemble.sh $yyyy

REMOTE_DIR="/DATA/CMCC_CERISE/"

lftp_cmd=$DIR_LOG/${type_fore}/$yyyy$st/ls.lftp
log_lftp=$DIR_LOG/${type_fore}/$yyyy$st/$log_script
cat > $lftp_cmd << EOF
set ftp:list-options -a
$cmd_ftp_ecmwf
cd $REMOTE_DIR
ls *S${yyyy}${st}*
quit
EOF
lftp -f $lftp_cmd |tee $log_lftp
stat=$?
if [ $stat -eq 1 ]; then
      echo "error on  attempt send.lftp "|mail $mymail
      exit 1
fi
