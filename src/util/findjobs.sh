#!/bin/sh -l
. ~/.bashrc
. ${DIR_UTIL}/descr_SPS4.sh

set -eu
usage() { echo "Usage: $0 [-m <machine string >] [-W <format string(yes)>] [-Y <year-date integer(jobID)>] [-q <queue string>] [-n <name_to_grep string >] [-N <name_to_grep2 string >] [-a <status_run string>] [-i <id_job string>] [-c <wc string>] [-r <reservation string>] [-J <name_complete string output>] [-p <id_job string>]" 1>&2; exit 1; }

machine="None"
queue="None"
scriptname="None"
scriptname2="None"
printjobname="None"
stat="None"
jobID="None"
id="None"
dependency="None"
sla="None"
count="None"
format="None"
duration="None"
while getopts ":m:q:n:N:a:c:r:i:d:H:M:W:Y:J:p:" o; do
    case "${o}" in
        m)
            machine=${OPTARG}
            ;;
        q)
            queue=${OPTARG}
            ;;
        n)
            scriptname=${OPTARG}
            ;;
        N)
            scriptname2=${OPTARG}
            ;;
        J)
            printjobname=${OPTARG}
            ;;
        a)
            stat=${OPTARG}
            ;;
        i)
            id=${OPTARG}
            ;;
        Y)
            jobID=${OPTARG}
            ;;
        W)
            format=${OPTARG}
            ;;
        c)
            count=${OPTARG}
            ;;
        r)
            sla=${OPTARG}
            ;;
        p)  
            dependency=${OPTARG}
            ;;  
        d)  
            duration=${OPTARG}
            ;;  
        *)
            usage
            ;;
    esac
done

if [[ "$machine" == "None" ]]
then
   usage
fi
# Condizione troppo stringente per lt_archive e postrun.tpl

if [  "$machine" == "zeus" ]
then

   command="bjobs -w "

   if [ "$format" != "None" ]
   then
      command="bjobs -W "
   fi
   if [[ "$queue" != "None" ]]
   then
      command+=" | grep $queue "
   fi
   if [[ "$scriptname" != "None" ]]
   then
      command+=" | grep $scriptname "
   fi
   if [[ "$scriptname2" != "None" ]]
   then
      command+=" | grep $scriptname2 "
   fi
   if [[ "$printjobname" != "None" ]]
   then
      command+=" |awk '{print \$2}'"
   fi
   if [[ "$stat" != "None" ]]
   then
#      command+=" | awk '{print \$3}' "
      command+=" | grep $stat "
   fi
   if [[ "$id" != "None" ]]
   then
      command+=" | awk '{print \$1}' "
   fi
   if [[ "$count" != "None" ]]
   then
      command+=" | wc -l "
   fi
   if [[ "$jobID" != "None" ]]
   then
      export LSB_DISPLAY_YEAR="Y" 
      command="bjobs -l $jobID "
      command+=" |grep Start|awk '{print \$5}'|cut -c 1-4"
   fi
   if [[ "$dependency" != "None" ]] ; then
      #check if for job_id=$dependency there is a dependency never satisfied
      command="bjobs -p $dependency | grep 'Dependency condition invalid or never satisfied'"
   fi  

   if [[ "$duration" != "None" ]]
   then
      start_date_proc=`bjobs -l $duration |grep Started|awk '{print $2, $3, $4}'|rev|cut -d ':' -f2-|rev`
      start_date_proc_unix=`date "-d $start_date_proc" +%s`
      now=$(date +%s)
#in this case command gives back just duration in hours
      delta=$((($now - $start_date_proc_unix)/3600))
      command="echo $delta"
   fi
#   set -evx
   eval $command  
#   set +evx
fi

if [  "$machine" = "marconi" ]
then
   # option -h remove header
   command="squeue -u `whoami` -h -o \"%P %j  %T %i\" "

   if [[ "$sla" != "None" ]]
   then
      command+=" -R $sla "
   fi
   if [[ "$queue" != "None" ]]
   then
      command+=" | grep $queue "
   fi
   if [[ "$scriptname" != "None" ]]
   then
      command+=" | grep $scriptname "
   fi
   if [[ "$scriptname2" != "None" ]]
   then
      command+=" | grep $scriptname2 "
   fi
   if [[ "$printjobname" != "None" ]]
   then
      command+=" |awk '{print \$7}'"
   fi
   if [[ "$duration" != "None" ]]
   then
      command+=" |awk '{print \$8}'|cut -d '-' -f2|cut -c 1,2"
   fi
   if [[ "$stat" != "None" ]]
   then
#      command+=" | awk {'print \$3'} | cut -c1-3 "
      command+=" | grep $stat "
   fi
   if [[ "$id" != "None" ]]
   then
      command+=" | awk {'print \$4'} "
   fi
   if [[ "$count" != "None" ]]
   then
      command+=" | wc -l "
   fi

   if [[ "$dependency" != "None" ]]
   then
      command="squeue --job $dependency | grep 'DependencyNeverSatisfied'"
   fi
   if [[ "$duration" != "None" ]]
   then
#this is the duration in hours 
      command="squeue |grep $duration | awk {'print \$6'} |cut -d ':' -f1"
   fi

#   set -evx
   eval $command
fi
