#!/bin/sh -l
#SBATCH  --job-name=send_mail_sp1
#SBATCH  --output=/leonardo_work/CMCC_2026/scratch/CMCC-CPS1/temporary/mails/send_mail_sp1.%J.out
#SBATCH  --error=/leonardo_work/CMCC_2026/scratch/CMCC-CPS1/temporary/mails/send_mail_sp1.%J.err

. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
set -euvx

message+="<br> `date`"
ARG_EMAIL_TO="$mymail"
ARG_EMAIL_FROM="sp1 <sp1@cmcc.it>"
ARG_EMAIL_SUBJECT="TITLE"

  #echo "Mime-Version: 1.0"
  #echo "Content-Type: text/html; charset='utf-8'"
  # echo -e "$message" is the key to keep new line

cc="CC"
message="MESSAGE"
if [[ $cc != "CC" ]]
then
    ARG_EMAIL_CC="$cc"
    (
    echo "To: ${ARG_EMAIL_TO}"
    echo "From: ${ARG_EMAIL_FROM}"
    echo "Cc:  ${ARG_EMAIL_CC}"
    echo "Subject: ${ARG_EMAIL_SUBJECT}"
    echo "MIME-Version: 1.0"
    echo 'Content-Type: multipart/mixed; boundary="-q1w2e3r4t5"'
    echo
    echo '---q1w2e3r4t5'
    echo 'Content-Type: text/html; charset=utf-8'
    echo 'Content-Transfer-Encoding: 8bit'
    echo
    echo "$message" 
    echo
    ) | sendmail -t


else
 
  (
    echo "To: ${ARG_EMAIL_TO}"
    echo "From: ${ARG_EMAIL_FROM}"
    echo "Subject: ${ARG_EMAIL_SUBJECT}"
    echo "MIME-Version: 1.0"
    echo 'Content-Type: multipart/mixed; boundary="-q1w2e3r4t5"'
    echo
    echo '---q1w2e3r4t5'
    echo 'Content-Type: text/html; charset=utf-8'
    echo 'Content-Transfer-Encoding: 8bit'
    echo
    echo "$message" 
    echo
  ) | sendmail -t 

fi
