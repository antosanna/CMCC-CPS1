#!/bin/sh -l
# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

usage() { echo "Usage: $0 [-m <machine string >] [-e <email string >] [-M <bodymessage string>] [-t <title string>] [-a <append file OPTIONAL>] [-c <cc string OPTIONAL>] [-b <bcc string OPTIONAL>] [-r <report string OPTIONAL>] [-s <startdate string OPTIONAL>] [-E <member number OPTIONAL] [ -g <input for gdrive path>]" 1>&2; exit 1; }

while getopts ":m:e:M:t:c:a:b:r:s:E:g:" o; do
    case "${o}" in
        m)
            machine=${OPTARG}
            ;;
        M)
            message=${OPTARG}
            ;;
        e)
            email=${OPTARG}
            ;;
        t)
            title=${OPTARG}
            ;;
        s)
            startdate=${OPTARG}
            ;;
        E)
            ensemble=${OPTARG}
            ;;
        c)
            cc=${OPTARG}
            ;;
        a)
            applist=${OPTARG}
            ;;
        b)
            bcc=${OPTARG}
            ;;
        r)
            report=${OPTARG}
            ;;
        g)  #to handle backup tag in gdrive send of report of IC production
            gdrive=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done

# check if message exists
# ok, now check for special characters in message and remove them (retain only . _ - () \n \r)
# "\\\" means that we save character \ in order to retain \n
#set -vx
message=`echo $message | tr -dc "'[:alnum:](-:. /_)=?\\\\\\\\"`
# After new method with  echo -e "$message \n `date`", there is no need for ()substitution
# substitute () with \( \)
#message=`echo $message |  sed 's/(/\\\(/g' `
#message=`echo $message |  sed 's/)/\\\)/g' `
#message+=" `date`"

# check if machine exists
if [[ -z $machine ]]
then
   usage
fi

# check if email exists
if [[ -z $email ]]
then
   usage
fi

if [[ ! -z $report ]]
then
   if [[ ! -z $startdate ]]
   then
      outlog=${DIR_REP}/$startdate/REPORT_${machine}.${SPSSystem}_${startdate}
      if [[ ! -z $ensemble ]]
      then
         outlog=${DIR_REP}/$startdate/report_${machine}.${SPSSystem}_${startdate}_${ensemble}
      fi
      mkdir -p ${DIR_REP}/$startdate
#      message=${message//'\n'/<br>}
      logfile=${outlog}.txt
      echo "`date` $message" >> ${logfile}
      echo " " >> $logfile
      . $DIR_UTIL/descr_ensemble.sh `echo ${startdate:0:4}`
      rclone_tag=${startdate}
      if [[ $typeofrun == "forecast" ]] && [[ ${is_backup} -eq 1 ]]
      then
              rclone_tag=${startdate}_backup
      fi
      if [[ ! -z $gdrive ]]
      then
            rclone_tag=${startdate}
      fi
      DIR_RCLONE=${typeofrun}/${rclone_tag}
  
      listaf=$logfile
      ${DIR_UTIL}/submitcommand.sh -m $machine -M 1000 -t 4 -q $serialq_rclone -j rclone_wrapper_report -l $DIR_LOG/$typeofrun/$startdate -d ${DIR_UTIL} -s rclone_wrapper.sh -i "$DIR_RCLONE/REPORTS '${listaf}'"
      if [ "$report" = "only" ]
      then
         exit
      fi
   fi
fi

if [[ "$machine" == "zeus" ]] || [[ $machine == "juno" ]] || [[ $machine == "cassandra" ]]
then
   if [[ ! -z $bcc ]]
   then
      b=" -b $bcc"
   else
      b=""
   fi
   if [[ `ls $applist|wc -w` -ne 0 ]]
   then
      for app in $applist
      do
         a+=" -a $app"
      done
   else
      a=""
   fi
   if [[ ! -z $cc ]]
   then
      c=" -c $cc"
   else
      c=""
   fi
   #set -evx 
   echo -e "$message \n `date`" | mail $a $b $c  -s "$title" $email  
    
   set +evx  
   exit 0
fi

if [[  "$machine" = "leonardo" ]]
then
  # MODIFY TITLE TO INCLUDE BACKUP INTO IT
# THIS DOES NOT HOLD ANYMORE BEING LEONARDO THE OPERATIONAL MACHINE
#  if [[ $title == *"CPS1"* ]]; then
#    oldString="CPS1"
#    newString="CPS1 - $machine BACKUP"
#    title=$(echo "${title/$oldString/$newString}")
#  else
#    title+=" - $machine BACKUP"
#  fi  

  #https://stackoverflow.com/questions/63319313/sendmail-sending-corrupted-unreadable-pdf-over-mail-sending-with-base64-encodin  - working sendmail example for single attachment
  sed -e "s#CCmail#${cc}#g;s@MESSAGE@$message@g;s@TITLE@$title@g" $DIR_UTIL/send_mail_leonardo_template.sh > $DIR_TEMP/mails/send_mail_leonardo_`date +%s`.sh

  sbatch $DIR_TEMP/mails/send_mail_leonardo_`date +%s`.sh
  exit 0 
fi
