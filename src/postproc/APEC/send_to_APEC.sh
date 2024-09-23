#!/bin/sh -l

set -evx 

yyyy=$1
st="$2"
typeforecast=$3
debug=$4

  case $st 
   in  
   01) yyseas=$yyyy ; sss=FMA ;;
   02) yyseas=$yyyy ; sss=MAM ;;
   03) yyseas=$yyyy ; sss=AMJ ;;
   04) yyseas=$yyyy ; sss=MJJ ;;
   05) yyseas=$yyyy ; sss=JJA ;;
   06) yyseas=$yyyy ; sss=JAS ;;
   07) yyseas=$yyyy ; sss=ASO ;;
   08) yyseas=$yyyy ; sss=SON ;;
   09) yyseas=$yyyy ; sss=OND ;;
   10) yyseas=$yyyy ; sss=NDJ ;;
   11) yyseas=$yyyy ; sss=DJF ;;
   12) yyseas=$(($yyyy + 1)) ; sss=JFM ;;
esac

if [ $debug -eq 0 ] ; then
   user="ftp_cmcc"
   hostname="210.98.49.14"
   REMOTE_DIR="/apccdata01/CMCC/${yyseas}${sss}"
   option_connect='~/.ssh/apcc_14_ftp_cmcc.key -oKexAlgorithms=+diffie-hellman-group1-sha1 -oHostKeyAlgorithms=+ssh-dss -oport=21322'
else
   user="c3s"
   hostname="ftp://downloads.cmcc.bo.it"
   password="cDx52!lst"
   REMOTE_DIR="DATA/CMCC_C3S/test/${yyseas}${sss}"
fi
if [ $debug -eq 0 ] ; then
   ssh -i ${option_connect} ${user}@${hostname} "mkdir -p ${REMOTE_DIR};exit"
else
   cat > ls.lftp.bologna << EOF
set ftp:list-options -a
open -u ${user},${password} ftp://downloads.cmcc.bo.it
mkdir ${REMOTE_DIR}
quit
EOF
   lftp -f ls.lftp.bologna
fi
LOCAL_DIR1="${pushdir}/${typeforecast}/${yyyy}${st}/monthly"
LOCAL_DIR2="${pushdir}/${typeforecast}/${yyyy}${st}/daily"

if [ $debug -eq 0 ] ; then
   rsync -auv --progress -e "ssh -i ${option_connect}" ${LOCAL_DIR1}/CMCC_SPS_* ${user}@${hostname}:${REMOTE_DIR} 
   rsync -auv --progress -e "ssh -i ${option_connect}" ${LOCAL_DIR2}/CMCC_SPS_* ${user}@${hostname}:${REMOTE_DIR} 
else
   cat > send.lftp.bologna << EOF
set xfer:log true
set xfer:log-file "/home/sp1/${logfile}"
set ftp:list-options -a
open -u ${user},${password} ${hostname}
mirror -v --reverse --ignore-time --parallel=${nstreams} $LOCAL_DIR1 $REMOTE_DIR || exit 1
mirror -v --reverse --ignore-time --parallel=${nstreams} $LOCAL_DIR2 $REMOTE_DIR || exit 1
quit
EOF
      chmod 744 send.lftp.bologna
      lftp -f send.lftp.bologna
      stat=$?
      if [ $stat -eq 1 ]; then
         echo "error on  attempt send.lftp.bologna ${yyyy}$st"|mail -s "[C3S] ${SPSSYS} forecast notification" $mymail 
         exit 1
      fi    
fi

if [ $? -ne 0 ] ; then
   body="send_to_APEC.sh in dtn02.cmcc.scc: rsync of $typeforecast ${yyyy}${st} failed"
   echo $body | mail -s "[APEC] ${SPSSYS} $typeforecast ERROR" ${mymail}
   exit 1
else
   echo "rsync of ${yyyy}${st} $typeforecast DONE"
fi

touch push_${yyyy}${st}_APEC_DONE

exit 0
