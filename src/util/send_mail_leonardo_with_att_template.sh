#!/bin/sh -l
#SBATCH  --job-name=send_mail_sp1
#SBATCH  --output=/leonardo_work/CMCC_2026/scratch/CMCC-CPS1/temporary/mails/send_mail_sp1.%J.out
#SBATCH  --error=/leonardo_work/CMCC_2026/scratch/CMCC-CPS1/temporary/mails/send_mail_sp1.%J.err

. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
set -euvx

BOUNDARY="==BOUNDARY_$(date +%s)=="
message+="<br> `date`"
ARG_EMAIL_TO="$mymail"
ARG_EMAIL_FROM="CMCC-SPS <scc-noreply@cmcc.it>"
ARG_EMAIL_SUBJECT="TITLE"
cc="CCmail"

if [[ $cc != "" ]]
then
    ARG_EMAIL_CC="$cc"
{
echo "From: CMCC-SPS"
echo "To: ${ARG_EMAIL_TO}"
echo "Cc:  ${ARG_EMAIL_CC}"
echo "Subject: TITLE"
echo "MIME-Version: 1.0"
echo "Content-Type: multipart/mixed; boundary=\"$BOUNDARY\""
echo
echo "--$BOUNDARY"
echo "Content-Type: text/plain; charset=UTF-8"
echo
echo "MESSAGE"
echo
echo "--$BOUNDARY"
echo "Content-Type: application/pdf; name=\"FILE\""
echo "Content-Transfer-Encoding: base64"
echo "Content-Disposition: attachment; filename=\"FILE\""
echo
base64 "FILE"
echo "--$BOUNDARY--"
} | sendmail -t
else
{
echo "From: CMCC-SPS4"
echo "To: ${ARG_EMAIL_TO}"
echo "Subject: TITLE"
echo "MIME-Version: 1.0"
echo "Content-Type: multipart/mixed; boundary=\"$BOUNDARY\""
echo
echo "--$BOUNDARY"
echo "Content-Type: text/plain; charset=UTF-8"
echo
echo "MESSAGE"
echo
echo "--$BOUNDARY"
echo "Content-Type: application/pdf; name=\"FILE\""
echo "Content-Transfer-Encoding: base64"
echo "Content-Disposition: attachment; filename=\"FILE\""
echo
base64 "FILE"
echo "--$BOUNDARY--"
} | sendmail -t
fi
