#!/bin/sh -l

# THIS SCRIPT WORKS ONLY ON login3!!!
# YOU MUST LOGIN THERE BEFORE RUNNING IT
#
cls
if [[ $? -ne 0 ]]
then
  echo " THIS SCRIPT WORKS ONLY ON login3!!!"
  echo " YOU MUST LOGIN THERE BEFORE RUNNING IT"
  exit
fi
# load descriptor file
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

# Description: This script ...
# How to submit:
# cps; cd $DIR_UTIL; ./launch_iDas_case_tape_archive.sh st &

set -euvx
#
# ******************************************
# Definitions here 
st=$1 # da settare manualmente
FINALARCHIVECINECA=/data/csp/${operational_user}/archive/CESM/${SPSSYS}_cineca
# ******************************************
dbg=0   #if 1 only one case
maxprocess=3 # number of processes at runtime (1 is crontab + 1 launched script and + 1 subshell)
# ******************************************
# LOG FILE
# ******************************************
# mkdir -p $DIR_LOG/TAPEARCHIVE/$st
# LOG_FILE=$DIR_LOG/TAPEARCHIVE/$st/launch_${st}_tape_archive.`date +%Y%m%d%H%M`.out
# #exec &> >(tee -a "$LOG_FILE")
# exec 3>&1 1>>${LOG_FILE} 2>&1

# If already running exit (use full loop to have more control with it instead of grep)
# ps -u ${operational_user} -f | grep "launch_case_tape_archive.sh" | grep "/bin/sh -l"
# grep -v $$ serve a eliminare se stesso, altrimenti restituisce 2 invece che 1
#cntrun=$(ps -u${operational_user} -f |grep launch_case_tape_archive.sh | grep -v "grep --color=auto" | wc -l)

cnt=0
if [ $dbg -eq 1 ]; then
	# questo processo (con il pipe) crea una sottoshell
	# quindi le linee attese saranno 3 (una per il crontab, una per il processo che gira)
	# ed una per il processo normale
	# NB: essendo una sottoshell non aggiorna variabili esterne al ciclo,
	# es:
	# LINE:
	# ${operational_user}      396608      1  0 18:34 ?        00:00:00 /bin/sh -c cd /users_home/csp/${operational_user}/SPS/CMCC-SPS3.5/src/util && ./launch_case_tape_archive.sh &
	# LINE:
	# ${operational_user}      396609 396608  7 18:34 ?        00:00:00 /bin/sh -l ./launch_case_tape_archive.sh
	# LINE:
	# ${operational_user}      397664 396609  0 18:34 ?        00:00:00 /bin/sh -l ./launch_case_tape_archive.sh
	set +vx
	ps -u ${operational_user} -f | while read line; do
		# Se è in uso rsub, skip
		if [[ $line == *"rsub"* ]];then
			continue
		fi	

		# se la linea di ps contiene launch_case_tape_archive.sh contala
		if [[ $line == *"launch_iDas_case_tape_archive"* ]];then
			cnt=$(( $cnt +1 ))
			echo LINE:
	  		echo "$line"
	  		# condizione: sono 3 processi: 1 per lo script e 1 per la sottoshell + crontab
	  		if [ $cnt -gt $maxprocess ];then
	  			echo "I'm already running, exit"
	  			exit 1
	# EXIT CONDITION !!!!!		
	# LINE:
	# ${operational_user}      411692      1  0 18:40 ?        00:00:00 /bin/sh -c cd /users_home/csp/${operational_user}/SPS/CMCC-SPS3.5/src/util && ./launch_case_tape_archive.sh &
	# LINE:
	# ${operational_user}      411737 411692  0 18:40 ?        00:00:00 /bin/sh -l ./launch_case_tape_archive.sh
	## NEW PROCESSES 18:41
	# LINE:
	# ${operational_user}      417179      1  0 18:41 ?        00:00:00 /bin/sh -c cd /users_home/csp/${operational_user}/SPS/CMCC-SPS3.5/src/util && ./launch_case_tape_archive.sh &
	# LINE:
	# ${operational_user}      417180 417179 15 18:41 ?        00:00:00 /bin/sh -l ./launch_case_tape_archive.sh
	  		fi
		fi
	done
	set -vx
	echo "3 lines of ps output are normal (1 for script and 1 for subshell + 1 for crontab) - go ahead"
else
	cntrun=$(ps -u ${operational_user} -f |grep launch_iDas_case_tape_archive | grep -v $$ | wc -l)
# # sleep 1000
 if [ $cntrun -gt $maxprocess ]; then
  	echo "I'm already running, exit"
  	exit 0
 fi
fi

# ******************************************
# START HERE
# ******************************************
# launch only 20 cases 
icsubmitted=0
icsubmitmax=20
# Lancia il case_tape_archive.sh (Prendi solo i casi con il semaforo di archiviazione archive_$caso_DONE) 
casetoarchive=" "
casetoarchivecnt=$(ls -1 $FINALARCHIVE/${SPSsystem}_????${st}_0??/archive_*DONE | wc -l)
if [ $casetoarchivecnt -gt 0 ]; then
	casetoarchive+=" $(dirname $(ls -1 $FINALARCHIVE/${SPSsystem}_????${st}_0??/archive_*DONE | uniq))"
fi
casetoarchivecnt=$(ls -1 $FINALARCHIVECINECA/${SPSsystem}_????${st}_0??/archive_*DONE | wc -l)
if [ $casetoarchivecnt -gt 0 ]; then
	casetoarchive+=" $(dirname $(ls -1 $FINALARCHIVECINECA/${SPSsystem}_????${st}_0??/archive_*DONE  | uniq))"
fi
#casetoarchivecnt=$(ls -1 $ARCHIVE/sps3.5_????${st}_0??/archive_*DONE | wc -l)
#if [ $casetoarchivecnt -gt 0 ]; then
# casetoarchive+=" $(dirname $(ls -1 $ARCHIVE/sps3.5_????${st}_0??/archive_*DONE  | uniq))"
#fi
#DO NOT CHANGE THIS ORDER! if there is a double copy of the same case in $FINALARCHIVE and in $ARCHIVE we want to tranfer the one on $FINALARCHIVE

for dir in $casetoarchive; do

	caso=$(echo $dir | grep -Eo ${SPSsystem}_[0-9]{4}${st}_[0-9]{3} )

	yyyy=`echo $caso|cut -d '_' -f 2|cut -c 1-4`
	startdate=${yyyy}${st}
	ens=`echo $caso|cut -d '_' -f 3`

	# 0 ) If forecast skip
	if [ $yyyy -gt ${endy_hind} ]; then
		continue
	fi
	# 1 ) check if size is what we expect
	lowersize=101
	uppersize=107
	expectedsize=103
# first check if  there are hidden files (consequences of ncrcat)
 nc=`find $dir -name \.sp\* |wc -l`
 if [ $nc -ne 0 ]
 then
     hidfiles=`find $dir -name \.sp\*`
     chmod u+w -R $dir
     rm $hidfiles
     chmod u-w -R $dir
 fi
# now check if there are files like ${caso}_1m_grid_T.zip.nc 
 noce=`find $dir -name ${caso}_1m_grid_T.zip.nc |wc -l`
 if [ $noce -ne 0 ]
 then
     ocefiles=`find $dir -name ${caso}_1m_grid_T.zip.nc`
     chmod u+w -R $dir
     rm $ocefiles
     chmod u-w -R $dir
 fi
	size=$(du -shc $dir | tail -n 1 | awk '{print $1}' | grep -o -E '[0-9]+')
	if [ $size -lt $lowersize -o $size -gt $uppersize ]; then
   #check if hidden file present
   		body="Size for $dir is not near to expectedsize $expectedsize G, but is $size .SKIP. PLEASE CHECK IT MANUALLY! "
		   title="[TAPEARCHIVE] ${SPSSYS} WARNING"
		   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
		   continue
	fi

	## 2 ) check if qbo is already done
	## qbo_ok_${ens} ie. /work/csp/${operational_user}/qbo/01/1993
	# qbocnt=$(ls -1 $WORK/qbo/$st/$yyyy/qbo_ok_${ens} | wc -l )
	# if [ $qbocnt -ne 1 ]; then 
	#	continue
	# fi

	#ARCHIVEDIR=$FINALARCHIVE
	# 3) IF $dir contain cineca then check for /data/delivery/csp/c3s/cineca/${caso}.COPYOK
	if [[ $dir == *"cineca"* ]]; then 
	  	echo "Check if this cineca $caso is correctly archived and if /data/delivery/csp/c3s/cineca/${caso}.COPYOK it is present."
		  if [ ! -f /data/delivery/csp/c3s/cineca/${caso}.COPYOK ]; then
			    continue # will be processed next time when archiving proc is completed
		  fi
	#ARCHIVEDIR=$FINALARCHIVECINECA
	fi

	# 4) Check if qbo is present
	DIRQBO=/work/csp/sp2/${SPSSYS}/QBO/$st/$yyyy
	qbojobcnt=$(bj -w -u sp2 | grep extract_qbo_${startdate} | wc -l )
	# If qbo job is running for selected stardate, skip
	if [ $qbojobcnt -ne 0 ]; then
		continue
	fi	
	cntqbo=$(ls ${DIRQBO}/${caso}.Umonthly.nc | wc -l)
	cntqbozipped=$(ls ${DIRQBO}/${caso}.Umonthly.nc.gz | wc -l)
	# If both files are missing, then skip
	if [[ $cntqbo -eq 0 ]] && [[ $cntqbozipped -eq 0 ]]; then
		continue
	fi

	#Instead of defining explicitely $ARCHIVEDIR, we prefer to give in input the entire case path ($dir), in order to take into account also cases stored in $ARCHIVE (and not just in $FINALARCHIVE) 
	# 5) submit
	echo "Submitted process iDas_case_tape_archive.sh for $caso - $(date)" 

	# $ARCHIVEDIR is needed to manage CINECA different position
#	ssh ${operational_user}@zeus03 "$DIR_UTIL/case_tape_archive.sh $caso $dir 2>&1 &"
	$DIR_UTIL/iDas_case_tape_archive.sh $caso $dir 
	echo $?

	echo "End of iDas_case_tape_archive.sh for $caso $(date)" 
 icsubmitted=$(($icsubmitted + 1))
 if [ $icsubmitted -gt $icsubmitmax ]
 then
	   echo "you submitted $icsubmitted $DIR_UTIL/iDas_case_tape_archive.sh. Exiting now"
    exit 0
 fi
 if [ $dbg -eq 1 ]
 then
    exit 0
 fi

done

# remove traffic light file
#rm $DIR_LOG/TAPEARCHIVE/$st/${st}_trafficlight_stop

echo "DONE."
exit 0
