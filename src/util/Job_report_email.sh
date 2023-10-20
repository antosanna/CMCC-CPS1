#!/bin/sh -l
. $HOME/.bashrc
. ${DIR_UTIL}/descr_SPS4.sh
mymail=$1

if [ $LSB_JOBEXIT_STAT -ne 0  ] ; then
  
    message=" Jobname : $LSB_JOBNAME \n
           Job's exit status : $LSB_JOBEXIT_STAT \n
           Submission directory : $LS_SUBCWD \n
           Signal that caused a job to exit : $LSB_JOBEXIT_INFO \n
           Job_ID : $LSB_JOBID \n
            \n
           Output file : $LSB_OUTPUTFILE \n
           Error file : $LSB_ERRORFILE"  
    ag=`echo $LSB_JOBNAME |grep ag_12h`
    sps_CAM_IC=`echo $LSB_JOBNAME |grep ${SPSsystem}_CAM_IC`
    log_check=`echo $LSB_JOBNAME |grep log_checker`
    title="${SPSSYS} forecast ERROR" 
    if [ ! -z $ag ]
    then
       title="[CAMIC] ${SPSSYS} atmospheric guess ERROR"
    elif [ ! -z $sps_CAM_IC ]
    then
       title="[CAMIC] ${SPSSYS} SPS guess ERROR"
    elif [ ! -z $log_check ]
    then
       title="${SPSSYS} log_checker ERROR" 
    fi
    $DIR_UTIL/sendmail.sh -m $machine -e $mymail -M "$message" -t "$title" 
fi
