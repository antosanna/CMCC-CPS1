#!/bin/sh -l
. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
set -euvx

reminder_type=$1			# for ois analysis reminder
																			# for forecast checklist reminder

recmail=$mymail
others=$mymail

# body depending on reminder_type
if [[ $reminder_type -eq 1 ]] ; then 
    title="REMINDER FOR GROUP"
    body="CHECK OIS WEEKLY ANALISYS MAILS IN SP1"
elif [[ $reminder_type -eq 2 ]] ; then 
    title="REMINDER FOR FORECASTER"
    body="CHECK FORECAST CHECKLIST"
    recmail=sp1@cmcc.it
elif [[ $reminder_type -eq 5 ]] ; then 
    title="REMINDER FOR MED-UPDATE"
    body="Check the automatic procedure on server73"
elif [[ $reminder_type -eq 6 ]] ; then 
    $DIR_UTIL/send_quota_sp1.sh
#elif [ $reminder_type -eq 7 ] ; then 
#    title="TODAY IS 18TH: LONG RUN NEMO ANALYSIS!"
#    body="Check the Long NEMO analysis"
elif [[ $reminder_type -eq 7 ]]
then
    title="URGENT: CMCC-SPS4 BACK-UP ACTIVATION on CASSANDRA"
    body="Dear HSM \n
\n
     This is to ask to prioritize the activation of SC_sps35 on Cassandra for forecast back-up operations as soon as possible \n
\n
As agreed, the configuration will consist of a minimum of 56 and a maximum of 112 nodes guaranteed, starting in up to 12hours and ending, according to email notification, as soon as the forecast is completed.
\n
Thank you for your prompt cooperation
\n
\n
CMCC-SPS-staff"

   others=$ccmail
   recmail=$hsmmail
elif [[ $reminder_type -eq 8 ]] ; then 
    title="TIME TO LAUNCH launch_end_forecast_${SPSSystem}.sh"
    body="You should submit the script $DIR_CPS/launch_end_forecast_${SPSSystem}.sh either from crontab or from prompt"
fi

# send mail
${DIR_UTIL}/sendmail.sh -m $machine -e $recmail -c $others -M "$body" -t "$title"

exit 0
