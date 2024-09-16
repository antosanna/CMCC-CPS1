#!/bin/sh -l

#TO BE MODIFIED!!!
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
. ${DIR_SPS35}/descr_SPS3.5.sh

# Descriptio: This script ...
# How to submit:
# amb; cd $DIR_UTIL; ./launch_forecast_case_tape_archive.sh yyyy &

#
# ******************************************
# Definitions here 
yyyy=$1 # da settare manualmente

if [ $yyyy -le 2016 ] 
then
  . ${DIR_SPS35}/descr_hindcast.sh
else
  . ${DIR_SPS35}/descr_forecast.sh
fi
set -euvx
FINALARCHIVECINECA=/data/csp/sp1/archive/CESM/${SPSSYS}_cineca
# ******************************************
dbg=1  #if 1 only one case
maxprocess=3 # number of processes at runtime (1 is crontab + 1 launched script and + 1 subshell)
# ******************************************
# LOG FILE
# ******************************************
# mkdir -p $DIR_LOG/TAPEARCHIVE/$st
# LOG_FILE=$DIR_LOG/TAPEARCHIVE/$st/launch_${st}_tape_archive.`date +%Y%m%d%H%M`.out
# #exec &> >(tee -a "$LOG_FILE")
# exec 3>&1 1>>${LOG_FILE} 2>&1

# If already running exit (use full loop to have more control with it instead of grep)
# ps -u sp1 -f | grep "launch_forecast_case_tape_archive.sh" | grep "/bin/sh -l"
# grep -v $$ serve a eliminare se stesso, altrimenti restituisce 2 invece che 1
#cntrun=$(ps -usp1 -f |grep launch_forecast_case_tape_archive.sh | grep -v "grep --color=auto" | wc -l)

cnt=0
if [ $dbg -eq 1 ]; then
	# questo processo (con il pipe) crea una sottoshell
	# quindi le linee attese saranno 3 (una per il crontab, una per il processo che gira)
	# ed una per il processo normale
	# NB: essendo una sottoshell non aggiorna variabili esterne al ciclo,
	# es:
	# LINE:
	# sp1      396608      1  0 18:34 ?        00:00:00 /bin/sh -c cd /users_home/csp/sp1/SPS/CMCC-SPS3.5/src/util && ./launch_forecast_case_tape_archive.sh &
	# LINE:
	# sp1      396609 396608  7 18:34 ?        00:00:00 /bin/sh -l ./launch_forecast_case_tape_archive.sh
	# LINE:
	# sp1      397664 396609  0 18:34 ?        00:00:00 /bin/sh -l ./launch_forecast_case_tape_archive.sh
	set +vx
	ps -u sp1 -f | while read line; do
		# Se è in uso rsub, skip
		if [[ $line == *"rsub"* ]];then
			continue
		fi	

		# se la linea di ps contiene launch_forercast_case_tape_archive.sh contala
		if [[ $line == *"launch_forecast_case_tape_archive"* ]];then
			cnt=$(( $cnt +1 ))
			echo LINE:
	  		echo "$line"
	  		# condizione: sono 3 processi: 1 per lo script e 1 per la sottoshell + crontab
	  		if [ $cnt -gt $maxprocess ];then
	  			echo "I'm already running, exit"
	  			exit 1
	# EXIT CONDITION !!!!!		
	# LINE:
	# sp1      411692      1  0 18:40 ?        00:00:00 /bin/sh -c cd /users_home/csp/sp1/SPS/CMCC-SPS3.5/src/util && ./launch_forecast_case_tape_archive.sh &
	# LINE:
	# sp1      411737 411692  0 18:40 ?        00:00:00 /bin/sh -l ./launch_forecast_case_tape_archive.sh
	## NEW PROCESSES 18:41
	# LINE:
	# sp1      417179      1  0 18:41 ?        00:00:00 /bin/sh -c cd /users_home/csp/sp1/SPS/CMCC-SPS3.5/src/util && ./launch_forecast_case_tape_archive.sh &
	# LINE:
	# sp1      417180 417179 15 18:41 ?        00:00:00 /bin/sh -l ./launch_forecast_case_tape_archive.sh
	  		fi
		fi
	done
	set -vx
	echo "3 lines of ps output are normal (1 for script and 1 for subshell + 1 for crontab) - go ahead"
else
	cntrun=$(ps -u sp1 -f |grep launch_forecast_case_tape_archive | grep -v $$ | wc -l)
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
#casetoarchivecnt=$(ls -1 $FINALARCHIVE/sps3.5_${yyyy}??_0??/archive_*DONE | wc -l)
casetoarchivecnt=$(ls -1 /work/csp/sp1/logs/${typeofrun}/${yyyy}??/*DMO*ok* | wc -l)
if [ $casetoarchivecnt -gt 0 ]; then
	  #casetoarchive+=" $(dirname $(ls -1 $FINALARCHIVE/sps3.5_${yyyy}??_0??/archive_*DONE | uniq))"
   
  	casetoarchive+=" $(basename -a $(echo $(ls -1 /work/csp/sp1/logs/${typeofrun}/${yyyy}??/*DMO*ok* | uniq) ) | cut -d '_' -f1-3)"
fi
#casetoarchivecnt=$(ls -1 $FINALARCHIVECINECA/sps3.5_${yyyy}??_0??/archive_*DONE | wc -l)
#if [ $casetoarchivecnt -gt 0 ]; then
#	casetoarchive+=" $(dirname $(ls -1 $FINALARCHIVECINECA/sps3.5_${yyyy}??_0??/archive_*DONE  | uniq))"
#fi
casetoarchivecnt=$(ls -1 $DIR_LOG/${typeofrun}/${yyyy}??/*DMO*ok* | wc -l)
if [ $casetoarchivecnt -gt 0 ]; then
 casetoarchive+=" $(basename -a $(echo $(ls -1 $DIR_LOG/${typeofrun}/${yyyy}??/*DMO*ok* | uniq) ) | cut -d '_' -f1-3)" 
fi
#casetoarchivecnt=$(ls -1 $ARCHIVE/sps3.5_${yyyy}??_0??/archive_*DONE | wc -l)
#if [ $casetoarchivecnt -gt 0 ]; then
# casetoarchive+=" $(ls -1 $ARCHIVE/sps3.5_{yyyy}??_0??/archive_*DONE | uniq))"
#fi
#DO NOT CHANGE THIS ORDER! if there is a double copy of the same case in $FINALARCHIVE and in $ARCHIVE we want to tranfer the one on $FINALARCHIVE

for dirtmp in $casetoarchive; do

 dir="$FINALARCHIVE/$dirtmp"
 if [ ! -d $dir ] 
 then
    continue
 fi
	caso=$(echo $dir | grep -Eo ${SPSsystem}_${yyyy}[0-9]{2}_[0-9]{3} )
	st=`echo $caso|cut -d '_' -f 2|cut -c 5-6`
	startdate=${yyyy}${st}
	ens=`echo $caso|cut -d '_' -f 3`

 # SKIP forecast  for the current and the previous month
 mo_current=`date +%m`
 yy_current=`date +%Y`
 mo_prev=`date -d "-1month" +%m`
 yy_prev=`date -d "-1month" +%Y`
 if [[ $startdate == ${yy_prev}${mo_prev} ]] || [[ $startdate == ${yy_current}${mo_current} ]]
 then
   echo "skip this case - forecast for current/previous month"
   continue  
 fi
 
# 0) check if all expected files are present
 domains="atm lnd ocn ice rof rest"
 frequency_cam="h1 h2 h3 h0" 
 frequency_clm="h1 h0"
 # DAYS IN FORECAST  (-l true is in noleap calendar, since our cesm is runned with noleap option)
 dif=`${DIR_SPS35}/days_in_forecast.sh -y $yyyy -m $st -l true | tail -1`
 nmoredays=0 # init
 nmoredays=$(( $fixsimdays - $dif + 1))
 checkfile=0
 frc_date="${yyyy}${st}01"
 date_rest=`date -d "$frc_date +${nmonfore}month" +%Y-%m-%d`
 echo $date_rest
 for dom in $domains ; do
    if [[ "$dom" == "atm" ]] ; then
       for hh in $frequency_cam ; do
          nmb_file=`ls ${dir}/${dom}/hist/${caso}.*.${hh}.????-??.zip.nc  | wc -l`
          if [[ $nmb_file -ne $nmonfore ]] ; then
             echo "Case $caso - some ${hh} file in  ${dir}/${dom}/hist is missing"
             #sendmail
   		        body="Case $caso - some ${hh} file in  ${dir}/${dom}/hist is missing. SKIP. PLEASE CHECK IT MANUALLY! "
		           title="[TAPEARCHIVE] ${SPSSYS} WARNING"
		           ${DIR_SPS35}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
             checkfile=$(( $checkfile + 1))
          fi

          if [[ ${hh} != "h0" ]] ; then
             echo "checking moredays"
             nmb_file_md=`ls ${dir}/${dom}/hist/${caso}.*.${hh}.????-??-??-?????.zip.nc  | wc -l`
             if [[ $nmb_file_md -ne $nmoredays ]] ; then
                echo "Case $caso - some ${hh} file in ${dir}/${dom}/hist is missing"
   		           body="Case $caso - some ${hh} file in  ${dir}/${dom}/hist is missing. SKIP. PLEASE CHECK IT MANUALLY! "
		              title="[TAPEARCHIVE] ${SPSSYS} WARNING"
		              ${DIR_SPS35}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
                checkfile=$(( $checkfile + 1))
             fi
          fi
       done
    elif [[ "$dom" == "lnd" ]] ; then
       for hh in $frequency_clm ; do
          nmb_file=`ls ${dir}/${dom}/hist/${caso}.*.${hh}.????-??.zip.nc  | wc -l`
          if [[ $nmb_file -ne $nmonfore ]] ; then
             echo "Case $caso - some ${hh} file in  ${dir}/${dom}/hist is missing"
             #sendmail
             body="Case $caso - some ${hh} file in  ${dir}/${dom}/hist is missing. SKIP. PLEASE CHECK IT MANUALLY! "
             title="[TAPEARCHIVE] ${SPSSYS} WARNING"
             ${DIR_SPS35}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
             checkfile=$(( $checkfile + 1))
          fi  
          if [[ ${hh} != "h0" ]] ; then
             echo "checking moredays"
             nmb_file_md=`ls ${dir}/${dom}/hist/${caso}.*.${hh}.????-??-??-?????.zip.nc  | wc -l`
             if [[ $nmb_file_md -ne $nmoredays ]] ; then
                echo "Case $caso - some ${hh} file in ${dir}/${dom}/hist is missing"
                body="Case $caso - some ${hh} file in  ${dir}/${dom}/hist is missing. SKIP. PLEASE CHECK IT MANUALLY! "
                title="[TAPEARCHIVE] ${SPSSYS} WARNING"
                ${DIR_SPS35}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
                checkfile=$(( $checkfile + 1))
             fi
          fi
       done

    elif [[ "$dom" == "rof" ]] ; then
         hh="h0"
         nmb_file=`ls ${dir}/${dom}/hist/${caso}.*.${hh}.????-??.zip.nc  | wc -l`
         if [[ $nmb_file -ne $nmonfore ]] ; then
            echo "Case $caso - some ${hh} file in ${dir}/${dom}/hist is missing"
   		       body="Case $caso - some ${hh} file in  ${dir}/${dom}/hist is missing. SKIP. PLEASE CHECK IT MANUALLY! "
		          title="[TAPEARCHIVE] ${SPSSYS} WARNING"
		          ${DIR_SPS35}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
            checkfile=$(( $checkfile + 1))
         fi
    elif [[ "$dom" == "ice" ]] ; then
         hh="h"
         nmb_file=`ls ${dir}/${dom}/hist/${caso}.*.${hh}.????-??.zip.nc  | wc -l`
         if [[ $nmb_file -ne $nmonfore ]] ; then
            echo "Case $caso - some ${hh} file in ${dir}/${dom}/hist is missing"
   		       body="Case $caso - some ${hh} file in  ${dir}/${dom}/hist is missing. SKIP. PLEASE CHECK IT MANUALLY! "
		          title="[TAPEARCHIVE] ${SPSSYS} WARNING"
		          ${DIR_SPS35}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
            checkfile=$(( $checkfile + 1))
         fi
    elif [[ "$dom" == "ocn" ]] ; then
         vartype="grid_T grid_U grid_V grid_W grid_T_EquT grid_Tglobal"
         for var in $vartype ; do
            nmb_file=`ls ${dir}/${dom}/hist/${caso}_*_${var}.zip.nc  | wc -l`
            if [[ $nmb_file -ne $nmonfore ]] ; then
               echo "Case $caso - some ${vartype} file in ${dir}/${dom}/hist is missing"
   		          body="Case $caso - some ${vartype} file in  ${dir}/${dom}/hist is missing. SKIP. PLEASE CHECK IT MANUALLY! "
		             title="[TAPEARCHIVE] ${SPSSYS} WARNING"
		             ${DIR_SPS35}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
               checkfile=$(( $checkfile + 1))
            fi
         done
    elif [[ "$dom" == "rest" ]] ; then
        filetype="cam cice clm2 cpl rtm restart" 
        for ff in $filetype ; do
            case $ff in 
               "cam") nmb_rest=7 ;;
               "cice") nmb_rest=1 ;;
               "rtm") nmb_rest=3 ;;
               "cpl") nmb_rest=1 ;;
               "clm2") nmb_rest=5 ;;
               "restart") nmb_rest=$nmb_nemo_domains ;;
            esac 
      
            nmb_file=`ls ${dir}/${dom}/${date_rest}-00000/${caso}*${ff}*.nc  | wc -l`
            if [[ $nmb_file -ne $nmb_rest ]] ; then
                echo "Case $caso - some ${caso}*${ff}*.nc file in ${dir}/${dom}/${date_rest} is missing"
                body="Case $caso - some ${vartype} file in  ${dir}/${dom}/${date_rest} is missing. SKIP. PLEASE CHECK IT MANUALLY! "
                title="[TAPEARCHIVE] ${SPSSYS} WARNING"
                ${DIR_SPS35}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
                checkfile=$(( $checkfile + 1))
            fi

            nmb_file=`ls ${dir}/${dom}/${date_rest}-00000/rpointer.*  | wc -l`
            if [[ $nmb_file -ne 5 ]] ; then
                echo "Some rpointer file in ${dir}/${dom}/${date_rest} is missing"
                body="Case $caso - some rpointer file in  ${dir}/${dom}/${date_rest} is missing. SKIP. PLEASE CHECK IT MANUALLY! "
                title="[TAPEARCHIVE] ${SPSSYS} WARNING"
                ${DIR_SPS35}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
                checkfile=$(( $checkfile + 1))

            fi
        done  
        
    fi

 done
 if [[ $checkfile  -ne 0 ]] ;  then
    #checkfile -ne 0: at least one file is missing
    continue
 fi
 echo "checkfile value"
 echo $checkfile
	# 1 ) check if size is what we expect
	lowersize=102
	uppersize=108
# starting from December 2021 the size for each case increase from 103 to 104 GB (Were 129 GB because of the restart moredays)
	expectedsize=104   #103
# first check if there are hidden files (consequences of ncrcat)
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
		   ${DIR_SPS35}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
		   continue
	fi

	## 2 ) check if qbo is already done
	## qbo_ok_${ens} ie. /work/csp/sp1/qbo/01/1993
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
	if [ $cntqbo -eq 0 -a $cntqbozipped -eq 0 ]; then
		continue
	fi

	#Instead of defining explicitely $ARCHIVEDIR, we prefer to give in input the entire case path ($dir), in order to take into account also cases stored in $ARCHIVE (and not just in $FINALARCHIVE) 
	# 5) submit
	echo "Submitted process case_tape_archive.sh for $caso - $(date)" 

	# $ARCHIVEDIR is needed to manage CINECA different position
#	ssh sp1@zeus03 "$DIR_UTIL/case_tape_archive.sh $caso $dir 2>&1 &" #to run this from login1
	$DIR_UTIL/case_tape_archive.sh $caso $dir           #to run this from login3 (peferred option!)        
	echo $?

	echo "End of case_tape_archive.sh for $caso $(date)" 
 icsubmitted=$(($icsubmitted + 1))
 if [ $icsubmitted -ge $icsubmitmax ]
 then
	   echo "you submitted $icsubmitted $DIR_UTIL/case_tape_archive.sh. Exiting now"
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
