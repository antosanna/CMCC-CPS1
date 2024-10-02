#!/bin/sh -l

. $HOME/.bashrc
. $DIR_UTIL/descr_CPS.sh
. $DIR_POST/APEC/descr_SPS4_APEC.sh

set -evx 

yyyy=$1
st="$2"
type_fore=$3
dbg_push=$4

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

if [ $dbg_push -eq 1 ] ; then
   user="c3s"
   hostname="ftp://downloads.cmcc.bo.it"
   password="cDx52!lst"
   REMOTE_DIR="DATA/CMCC_C3S/test/${yyseas}${sss}"
else
   user="ftp_cmcc"
   hostname="210.98.49.14"
   REMOTE_DIR="/apccdata01/CMCC/${yyseas}${sss}"
   option_connect='~/.ssh/apcc_14_ftp_cmcc.key -oKexAlgorithms=+diffie-hellman-group1-sha1 -oHostKeyAlgorithms=+ssh-dss -oport=21322'
fi
if [ $dbg_push -eq 1 ] ; then
   cat > ls.lftp.bologna << EOF
set ftp:list-options -a
open -u ${user},${password} ftp://downloads.cmcc.bo.it
mkdir ${REMOTE_DIR}
quit
EOF
   lftp -f ls.lftp.bologna
else
   ssh -i ${option_connect} ${user}@${hostname} "mkdir -p ${REMOTE_DIR};exit"
fi
excludevars="grep -v swe | grep -v u10 | grep -v v10"
LOCAL_DIR1="${pushdirapec}/${type_fore}/${yyyy}${st}/monthly"
listmonthly=`ls -1 ${LOCAL_DIR1}/CMCC_SPS_* | eval ${excludevars}`
if [ $isforecast -eq 1 ] 
then
   LOCAL_DIR2="${pushdirapec}/${type_fore}/${yyyy}${st}/daily"
   listdaily=`ls -1 ${LOCAL_DIR2}/CMCC_SPS_* | eval ${excludevars}`
fi
if [ $dbg_push -eq 1 ] ; then
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
else
   if [ $isforecast -eq 1 ] 
   then
      rsync -auv --progress -e "ssh -i ${option_connect}" ${listdaily} ${user}@${hostname}:${REMOTE_DIR} 
   fi
   rsync -auv --progress -e "ssh -i ${option_connect}" ${listmonthly} ${user}@${hostname}:${REMOTE_DIR} 
fi

if [ $? -ne 0 ] ; then
   body="send_to_APEC.sh in $DIR_POST/APEC rsync of $type_fore ${yyyy}${st} failed"
   echo $body | mail -s "[APEC] ${SPSSYS} $type_fore ERROR" ${mymail}
   exit 1
else
   echo "rsync of ${yyyy}${st} $type_fore DONE"
fi

touch $DIR_LOG/${type_fore}/${yyyy}${st}/push_${yyyy}${st}_APEC_DONE

exit 0
