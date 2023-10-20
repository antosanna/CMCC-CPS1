#!/bin/sh -l
# load variables from descriptor
. $HOME/.bashrc
. $DIR_UTIL/descr_CPS.sh

set -exv

exitcode=15
#LOCKDIR=/users_home/csp/sp1/SPS/CMCC-${SPSSYS}/work/antonio
LOCKDIR=$DIR_CHECK
#*********************************************************************************************
# User defined function 
#*********************************************************************************************
#getmonth() {
#	local resubmit=$1
#	local continue=$2
	# Remove leading and trailing white spaces
#	resubmit=`echo $resubmit | awk '{$1=$1};1'`
#	continue=`echo $continue | awk '{$1=$1};1'`
	# Check if resubmit is 0
#	re='^[0-9]+$'
#	if ! [[ $resubmit =~ $re ]] ; then
#	   echo "checklist_run.sh: error: resubmit Not a number but is $resubmit"  ; exit $exitcode
#	fi
	# Convert continue to upper case (safer)
#	continueUC=`echo $continue | tr a-z A-Z`
#	if [ $continueUC == "FALSE" ]; then
#		if [ $resubmit == "4" ]; then
#			month=1
#		else
#			echo "checklist_run.sh: error: resubmit must be 0 in case of first run / continue $continueUC , but is $resubmit. Exit" ; exit $exitcode
#		fi

#	elif [ $continueUC == "TRUE" ]; then
		#statements
#		month=$(($nmonfore - $resubmit - 1))
#	else
#		echo "checklist_run.sh: error: continueUC must be TRUE or FALSE but is $continueUC. Exit" ; exit $exitcode
#	fi

#	}
#*********************************************************************************************
# Input and get data from case
#*********************************************************************************************
jobid=$1  # jobid 12345
ltarchdone=$2 # lt_archive flag (True or False)

# we are in Tools
#cd ..

# Just for test
#DIR_CHECK=$LOCKDIR
#cd /users_home/csp/sp1/SPS/CMCC-${SPSSYS}/cases/${SPSsystem}_199301_006

# get env_run.xml vars 
#caso=`./xmlquery CASE|cut -d '=' -f2`
#yy=`echo $caso|cut -d '_' -f2|cut -c 1-4`
#set +euvx
#if [ $yy -lt ${iniy_fore} ]
#then
#   . ${DIR_SPS35}/descr_hindcast.sh
#else
#   . ${DIR_SPS35}/descr_forecast.sh
#fi
set -euvx
#resubmit=`./xmlquery RESUBMIT|cut -d '=' -f2`
#continue=`./xmlquery CONTINUE_RUN|cut -d '=' -f2`

# remove white spaces for caso
#caso=`echo $caso | awk '{$1=$1};1'`

# get month
getmonth $resubmit $continue
echo "$month"
# calc position of the ith-month inside csv table 
table_month_id=$(($month + 2))

# TABLE FORMAT
#CASO,JOBID,mese1,mese2,mese3,mese4,mese5,mese6,mese7,archivio
#${SPSsystem}_199301_001,dummy,dummy,dummy,dummy,dummy,dummy,dummy,dummy,dummy
# Assign proper list file according to $typeofrun (hindcast/forecast)
listfiletocheck="${SPSSYS}_${typeofrun}_list.csv"
# find line number
LN="$(grep -n "$caso" ${DIR_CHECK}/$listfiletocheck | head -n 1 | cut -d: -f1)"
LNp1=$(($LN + 1))
LNm1=$(($LN - 1))

# just for LT_ARCHIVE
if [ $ltarchdone == "True" ] ; then
	table_month_id=10
fi 


#*********************************************************************************************
# Use lock (flock) and write (if unlocked)
#*********************************************************************************************
(
  # Wait for 160 sec lock on /var/lock/.myscript.exclusivelock (fd 200) for 60  seconds 
  flock -x -w 160 200 ||  exit 1
	# Do stuff

	#MONTH or LT_ARCHIVE (for latter see previous if condition)
 	checkrow=`grep $caso ${DIR_CHECK}/$listfiletocheck`
 	echo "BEFORE $checkrow"

	ts1=`date +%s%N | cut -b1-13`
	awk  -v c1="$LNm1" -v c2="$LNp1" -v mnth="$table_month_id" -F, 'NR>c1 && NR<c2{$mnth="DONE";}1' OFS=,  ${DIR_CHECK}/$listfiletocheck > ${DIR_CHECK}/temporary_file_${ts1}.csv
	sleep 1 # enough to ensure ts1 no ts2 

	#JOBID (second column position on the table)
	ts2=`date +%s%N | cut -b1-13`
 	awk  -v c1="$LNm1" -v c2="$LNp1" -v jid="$jobid" -F, 'NR>c1 && NR<c2{$2=jid;}1' OFS=,  ${DIR_CHECK}/temporary_file_${ts1}.csv > ${DIR_CHECK}/temporary_file_${ts2}.csv

 	# copy temporary file into new list, ONLY if all went ok
 	if [ $? -eq 0 ] ; then
 		echo "OK"
 		# place $listfiletocheck in scracth, since in DIR_CHECK there is a link
 		mv ${DIR_CHECK}/temporary_file_${ts2}.csv $DIR_ROOT/scratch/$listfiletocheck
 		rm -f ${DIR_CHECK}/temporary_file_${ts1}.csv
 	fi

	checkrow=`grep $caso ${DIR_CHECK}/$listfiletocheck`
 	echo "AFTER $checkrow"

) 200> $DIR_CHECK/.csp.sp1.checklist_run.exclusivelock


exit 0
