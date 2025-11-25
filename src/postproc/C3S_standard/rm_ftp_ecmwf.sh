#!/bin/sh  -l

. ~/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. ~/load_miniconda
conda activate $envcondacm3

set -euvx

yyyy=$1
st=$2
mymail=$3
list2rm=$4
debug_rm=$5           # if debug_rm=1 than send to bologna ftp for tests
machine=$6
type_fore=${7:-"forecast"}

. ${DIR_UTIL}/descr_ensemble.sh $yyyy

REMOTE_DIR="/DATA/CMCC_CERISE"
# WARNING!! DO NOT PUT / AT THE END
cmd_ftp_dataecmwf="open -u cmcc_cerise,ZZ6e0O1B ftp://acq.ecmwf.int"

datestr=`date +%Y%m%d%H%M%S`
script=$DIR_LOG/${type_fore}/$yyyy$st/rm.lftp
cat > $script << EOF
set ftp:list-options -a
$cmd_ftp_dataecmwf
cd $REMOTE_DIR
glob -a rm -r -f ${list2rm}
quit
EOF

lftp -f $script
stat=$?
if [ $stat -eq 1 ]; then
   echo "error on  attempt $script "|mail $mymail
   exit 1
fi        
touch ${script}_${datestr}_DONE
