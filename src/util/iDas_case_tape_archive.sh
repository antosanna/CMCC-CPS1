#!/bin/sh -l
#
# THIS HAS NEVER BEEN TESTED FOR SPS4

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

# Description:
# This script transfer ${CPSSYS} DMO from archive ($dir_caso) to tape library. This is done through different phases:
# 1. Preliminary check: Check if tape quota is ok
# 2. Creation of tar files. For each domain a single tar file is created (except for lnd+rof that are joined together). 
#    Each tar file will be transferred (one by one) to the tape library, for this reason the variable $listoftarfiles is populated.
#    Before completing the tar phase, a check on tar dimension is done.
# 3. Transfer to tape library: the single tar files are transferred to tape library. 
#    In order to avoid a file recall for already migrated files, the following procedure is used:
#    For each tar file:
#    a) check if file exist not and in case sync it
#    b) check if file is resident or not. If is on iDAS just sync it
#    c) if was migrated, first remove it and then sync it again
#
# How to submit:
#  "$DIR_UTIL/iDas_case_tape_archive.sh $caso $FINALARCHIVE 2>&1 &"
#		
#  test: "/users_home/csp/sp1/SPS/CMCC-${CPSSYS}/work/iDas_case_tape_archive.sh sps3.5_201606_001 $FINALARCHIVE 2>&1" &
set -euvx

caso=$1
dir_caso=$2 #it was $dir in the launcher

st=`echo $caso|cut -d '_' -f 2|cut -c 5-6`
yyyy=`echo $caso|cut -d '_' -f 2|cut -c 1-4`
startdate=${yyyy}${st}
ens=`echo $caso|cut -d '_' -f 3`
# ******************************************
# LOG FILE
mkdir -p $DIR_LOG/TAPEARCHIVE/$st/$yyyy
LOG_FILE=$DIR_LOG/TAPEARCHIVE/$st/$yyyy/${caso}_tape_archive.`date +%Y%m%d%H%M`.out
#exec &> >(tee -a "$LOG_FILE")
exec 3>&1 1>>${LOG_FILE} 2>&1

# ******************************************
# CHECK IF TAPE QUOTA IS OK
# ******************************************
echo "TIMESTAMP $(date)" 
cls
if [ $? -ne 0 ];then
  	body="Error on login03 - access test - command cls ,means that you did not access correctly to iDAS \n
        Script is $DIR_UTIL/iDas_case_tape_archive.sh. Logfile $LOG_FILE."
  	title="[TAPEARCHIVE] ${CPSSYS} ERROR"
  	${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
  	exit 1
fi

cntquotaok=$(cqu | grep -i "quota ok" | wc -l)
if [ $cntquotaok -lt 1 ]; then
  	body="Quota warning during $dir_caso archiving procedure. Quota on TAPE is NOT ok and the probably max limit has been reached, since the quota_ok_counter is $cntquotaok , but should be GE 1. SKIP this case, until quota will come back to reasonable levels. "
	  title="[TAPEARCHIVE] ${CPSSYS} QUOTA WARNING"
  	${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
	  exit 1	
fi
# *************************************************************
# SECTION 1 - INTRO program start here
# *************************************************************
echo "TIMESTAMP $(date)" 
# ******************************************
# Definitions here 
idaspath=/idas/home/sp1/CMCC-${CPSSYS}
#idaspath=/idas/home/sp1/test
# retention time
rettime=60
# DEBUG flag 
# debug=0 - enables  the removing procedure of DMO (!!!) from $dir_caso and the ocean rsync to $OCNARCHIVE, performed starting from line 568
# debug=1 - disables the removing procedure of DMO from $dir_caso and the ocean rsync to $OCNARCHIVE, performed starting from line 568
debug=0
sizethreshold=50 # MB differences allowed in size check
# ******************************************
set +euvx
. ${DIR_UTIL}/descr_ensemble.sh $yyyy
set -euvx

# workdir creation
workdir=$SCRATCHDIR/work_tape_archive/$caso
mkdir -p $SCRATCHDIR/work_tape_archive
cd $SCRATCHDIR/work_tape_archive
if [ -d $caso ];then
	  rm -rf $caso
fi
mkdir -p $workdir
# *************************************************************
# SECTION 2 - TAR creation and checks (>1GB - < 30 GB) 
# *************************************************************
#intialize a list of tar files for tape syncing
listoftarfiles=""
# atm **************************
cd $dir_caso/atm/hist
taratmok=0
listofall=" "
for cnt in $( seq 1 $nmonfore );do

  	year=$(date +%Y -d "${startdate}01 + $(( $cnt - 1 ))  month")
	  mon=$(date +%m -d "${startdate}01 + $(( $cnt - 1 ))  month")
  	filelist=$(ls -1 ${caso}.cam.h?.${year}-${mon}* )

	  if [ $cnt -eq $nmonfore ]; then	
		    yearmd=$(date +%Y -d "${startdate}01  + $cnt month")
    		monmd=$(date +%m -d "${startdate}01 + $cnt month")
		    filelistmd=$(ls -1 ${caso}.cam.h?.${yearmd}-${monmd}* )		
    		filelist+=" ${filelistmd}"
  	fi

	  listofall+=" $filelist"
  	filename=${caso}.cam.h.${year}-${mon}.tar
	# copy README in $dir_caso/atm/hist
	  chmod -R u+wx $dir_caso/atm/hist
	  cd $dir_caso/atm/hist
  	cp $CESMDATAROOT/CMCC-${CPSSYS}/files4${CPSSYS}/README_atm .
	# tar all
	  tar -cvf $workdir/$filename $filelist README_atm
	  if [ $? -eq 0 ]; then
		    taratmok=$(( $taratmok + 1 ))
    		listoftarfiles+=" $filename "
  	fi
	# remove $dir_caso/atm/hist/README_atm to avoid false warning
	  cd $dir_caso/atm/hist
  	rm README_atm	
done


# confronto tra i file presenti nella dir e quelli archiviati (tar)
dom=atm
cd $dir_caso/$dom/hist
line1="$(ls -1 *.nc)"
line2="$(ls -1 $listofall)"
read -a Array1 <<< $line1 
read -a Array2 <<< $line2 
echo "cosa manca ad array 2"
res=$(echo ${Array1[@]} ${Array2[@]} ${Array2[@]}| tr ' ' '\n' | sort | uniq -u )
rescnt=$(echo ${Array1[@]} ${Array2[@]} ${Array2[@]}| tr ' ' '\n' | sort | uniq -u | wc -l )
if [ $rescnt -ne 0 ]; then
  	body="Script is $DIR_UTIL/iDas_case_tape_archive.sh. Logfile $LOG_FILE. File on $dir_caso/$dom/hist and not in tar \n
	  	$res"
  	title="[TAPEARCHIVE] ${CPSSYS} ERROR"
	  ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
  	exit 1
fi	

# lnd rof  **************************
domain=lndrof
mkdir -p $workdir/$domain

for dom in lnd rof;do 
	  listofall=" "
  	case $dom in
	    	lnd) suff=clm2 ;;
    		rof) suff=rtm;;
		    ocn) suff="_*_????????_????????_grid" ;; 
    		ice) suff=".cice.h." ;; 
  	esac

	  chmod -R u+wx $dir_caso/$dom/hist
  	rsync -auv $dir_caso/$dom/hist/${caso}.${suff}.h* $workdir/$domain/
	  if [ $? -ne 0 ];then   
		    body="Script is $DIR_UTIL/iDas_case_tape_archive.sh. Logfile $LOG_FILE. Error on rsync for $dir_caso/$dom/hist/${caso}.${suff}.h"
    		title="[TAPEARCHIVE] ${CPSSYS} ERROR"
		    ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
    		exit 1
	  fi

	# confronto tra i file presenti nella dir e quelli archiviati (tar)
	  cd $dir_caso/$dom/hist
  	listofall=$(ls -1 ${caso}.${suff}.h*)
	  line1="$(ls *.nc)"
  	line2="$(ls $listofall)"
	  read -a Array1 <<< $line1 
  	read -a Array2 <<< $line2 
	  echo "cosa manca ad array 2"
  	res=$(echo ${Array1[@]} ${Array2[@]} ${Array2[@]}| tr ' ' '\n' | sort | uniq -u )
	  rescnt=$(echo ${Array1[@]} ${Array2[@]} ${Array2[@]}| tr ' ' '\n' | sort | uniq -u | wc -l )
  	if [ $rescnt -ne 0 ]; then
	    	body="Script is $DIR_UTIL/iDas_case_tape_archive.sh. Logfile $LOG_FILE. File on $dir_caso/$dom/hist and not in tar \n
    			$res"
		    title="[TAPEARCHIVE] ${CPSSYS} ERROR"
    		${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
		    exit 1
  	fi	

done

tarlndrofok=0
cd $workdir/$domain
filename=${caso}.$domain.h.tar
# copy README in workdir/$domain
cp $CESMDATAROOT/CMCC-${CPSSYS}/files4${CPSSYS}/README_lndrof $workdir/$domain/
# tar all
tar -cvf $workdir/$filename ${caso}.*.h* README_lndrof
if [ $? -eq 0 ]; then
	  tarlndrofok=1
  	listoftarfiles+=" $filename "
else
	  body="Script is $DIR_UTIL/iDas_case_tape_archive.sh. Logfile $LOG_FILE. Error on $dir_caso/$domain "
  	title="[TAPEARCHIVE] ${CPSSYS} ERROR"
	  ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
  	exit 1
fi

# ocn ice  **************************
domain=ocnice
mkdir -p $workdir/$domain

for dom in ocn ice;do 

	  case $dom in
		    lnd) suff=clm2 ;; 
    		rof) suff=rtm;;
    		ocn) suff="_*_????????_????????_grid" ;; 
		    ice) suff=".cice.h." ;; 
  	esac

	  chmod -R u+wx $dir_caso/$dom/hist
  	rsync -auv $dir_caso/$dom/hist/${caso}${suff}* $workdir/$domain/
	  if [ $? -ne 0 ];then
		    body="Script is $DIR_UTIL/iDas_case_tape_archive.sh. Logfile $LOG_FILE. Error on rsync for $dir_caso/$dom/hist/${caso}${suff}"
    		title="[TAPEARCHIVE] ${CPSSYS} ERROR"
		    ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
    		exit 1
  	fi

	# confronto tra i file presenti nella dir e quelli archiviati (tar)
	  cd $dir_caso/$dom/hist
  	listofall=$(ls -1 ${caso}${suff}*)
	  line1="$(ls -1 *.nc)"
  	line2="$(ls -1 $listofall)"
	  read -a Array1 <<< $line1 
  	read -a Array2 <<< $line2 
	  echo "cosa manca ad array 2"
  	res=$(echo ${Array1[@]} ${Array2[@]} ${Array2[@]}   | tr ' ' '\n' | sort | uniq -u )
	  rescnt=$(echo ${Array1[@]} ${Array2[@]} ${Array2[@]}| tr ' ' '\n' | sort | uniq -u | wc -l )
  	if [ $rescnt -ne 0 ]; then
	    	echo "File on $dir_caso/$dom/hist and not in tar"
    		echo $res
		    listares="$(echo $res)"
    		filerestobenotified=" "
		    notifyres=0
    		for res in $listares; do
			# *****************************************
			# Manage ocn excecption - ADD case here
			# *****************************************
			# first exception - 1m_grid_T.zip.nc file
		      	if [ "$(echo $res)" == "${caso}_1m_grid_T.zip.nc" ]; then
        				notifyres=$(( $notifyres + 1 ))
				        filerestobenotified+=" $res "
			# 2nd exception - scalar files
      			elif [[ "$(echo $res)" == *"_scalar.nc"* ]]; then
			        	notifyres=$(( $notifyres + 1 ))
        				filerestobenotified+=" $res "
      			else
			        	body="Script is $DIR_UTIL/iDas_case_tape_archive.sh. Logfile $LOG_FILE. File on $dir_caso/$dom/hist and not included in tar file \n
      					$res"
			        	title="[TAPEARCHIVE] ${CPSSYS} ERROR"
        				${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
				        exit 1
      			fi		
  	  	done
		# if false alarm files are present, notify by email
  	  	if [ $notifyres -gt 0 ]; then
	  	    	body="False alarm, files: $(echo $filerestobenotified) are not required for permanent TAPE archive. \n 
		  		     They will be not included in tar and removed by ${dir_caso} after cleaning."
      			title="[TAPEARCHIVE] ${CPSSYS} WARNING"
			#${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
		    fi	
  	fi

done

tarocniceok=0
cd $workdir/$domain
filename=${caso}.$domain.h.tar
# copy README in workdir/$domain
cp $CESMDATAROOT/CMCC-${CPSSYS}/files4${CPSSYS}/README_ocnice $workdir/$domain/
# tar all
tar -cvf $workdir/$filename ${caso}* README_ocnice
if [ $? -eq 0 ]; then
  	tarocniceok=1
	  listoftarfiles+=" $filename "
else
  	body="Script is $DIR_UTIL/iDas_case_tape_archive.sh. Logfile $LOG_FILE. Error on $dir_caso/$domain "
	  title="[TAPEARCHIVE] ${CPSSYS} ERROR"
  	${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
	  exit 1
fi

# rest  **************************
domain=rest

tarresok=0
filename=${caso}.$domain.tar

cd $dir_caso/$domain
tar -cvf $workdir/$filename ????-??-01-00000
if [ $? -eq 0 ]; then
  	tarresok=1
	  listoftarfiles+=" $filename "
else
  	body="Script is $DIR_UTIL/iDas_case_tape_archive.sh. Logfile $LOG_FILE. Error on $dir_caso/$domain "
	  title="[TAPEARCHIVE] ${CPSSYS} ERROR"
  	${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
	  exit 1
fi
cd $workdir

# Posizionarle su work
if [ $taratmok -eq 1 -a $tarlndrofok -eq 1 -a $tarocniceok -eq 1 -a $tarresok -eq 1 ];then
  	echo "Go ahead"
	  rm -rf  $workdir/lndrof
  	rm -rf  $workdir/ocnice
fi
# ****************************************** 
# Controllo size 
# ******************************************
# ATM and REST
dom=atm
# for atm domain we have $nmonfore tar files
sizeoftar=0
sizeofdir=$(du -sb $dir_caso/$dom/hist | awk '{print $1}' | grep -o -E '[0-9]+')
sizeofdir=$(( $sizeofdir / 1000000))
for file in $(ls -1 $workdir/${caso}.cam.h*tar ); do
	  sizeofsingletar=$(du -csb $file | tail -1 | awk '{print $1}' | grep -o -E '[0-9]+')
  	sizeofsingletar=$(( $sizeofsingletar / 1000000))
	  if [ $sizeofsingletar -lt 1000 -o $sizeofsingletar -gt 30000 ]; then
		    body="Error in $caso. Script is $DIR_UTIL/iDas_case_tape_archive.sh. Logfile $LOG_FILE. For domain $dom sizeofsingletar must be ge 1GB and le 30GB but is $sizeofsingletar in MB. Exit"
    		title="[TAPEARCHIVE] ${CPSSYS} ERROR"
		    ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
    		exit 1
  	fi
	  sizeoftar=$(( $sizeoftar + $sizeofsingletar ))
done
sizediff=$(( $sizeofdir - $sizeoftar )) 
sizediff=${sizediff#-} # remove minus to get ABS()
if [ $sizediff -gt $sizethreshold ]; then
  	body="Error in $caso. Script is $DIR_UTIL/iDas_case_tape_archive.sh. Logfile $LOG_FILE. For domain $dom sizeofdir ($sizeofdir) $dir_caso/$dom/hist differs from sizeoftar ($sizeoftar). Exit"
	  title="[TAPEARCHIVE] ${CPSSYS} ERROR"
  	${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
	  exit 1
fi

dom=rest
# get size in GB
sizeofdir=$(du -sb $dir_caso/$dom | awk '{print $1}' | grep -o -E '[0-9]+')
sizeoftar=$(du -sb $workdir/${caso}.$dom.tar | awk '{print $1}' | grep -o -E '[0-9]+')
sizeofdir=$(( $sizeofdir / 1000000))
sizeoftar=$(( $sizeoftar / 1000000))
if [ $sizeoftar -lt 1000 -o $sizeoftar -gt 30000 ]; then
  	body="Error in $caso. Script is $DIR_UTIL/iDas_case_tape_archive.sh. Logfile $LOG_FILE. For domain $dom sizeoftar must be ge 1GB and le 30GB but is $sizeoftar in MB. Exit"
	  title="[TAPEARCHIVE] ${CPSSYS} ERROR"
  	${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
	  exit 1
fi
sizediff=$(( $sizeofdir - $sizeoftar )) 
sizediff=${sizediff#-} # remove minus to get ABS()
if [ $sizediff -gt $sizethreshold ]; then
  	body="Error in $caso. Script is $DIR_UTIL/iDas_case_tape_archive.sh. Logfile $LOG_FILE. For domain $dom sizeofdir ($sizeofdir) $dir_caso/$dom differs from sizeoftar ($sizeoftar). Exit"
	  title="[TAPEARCHIVE] ${CPSSYS} ERROR"
  	${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
	  exit 1
fi

# OCN and ICE
sizeofdir=0
for dom in ocn ice; do
	# get size in GB
	  tmpsize=$(du -sb $dir_caso/$dom/hist | awk '{print $1}' | grep -o -E '[0-9]+')
	  sizeofdir=$(( $sizeofdir + $tmpsize  ))
done
sizeofdir=$(( $sizeofdir / 1000000))

dom=ocnice
sizeoftar=$(du -sb $workdir/${caso}.$dom.h.tar | awk '{print $1}' | grep -o -E '[0-9]+')
sizeoftar=$(( $sizeoftar / 1000000))
if [ $sizeoftar -lt 1000 -o $sizeoftar -gt 30000 ]; then
  	body="Error in $caso. Script is $DIR_UTIL/iDas_case_tape_archive.sh. Logfile $LOG_FILE. For domain $dom sizeoftar must be ge 1GB and le 30GB but is $sizeoftar in MB. Exit"
	  title="[TAPEARCHIVE] ${CPSSYS} ERROR"
  	${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
	  exit 1
fi
sizediff=$(( $sizeofdir - $sizeoftar )) 
sizediff=${sizediff#-} # remove minus to get ABS()
if [ $sizediff -gt $sizethreshold ]; then
  	body="Error in $caso. Script is $DIR_UTIL/iDas_case_tape_archive.sh. Logfile $LOG_FILE. For domain $dom sizeofdir ($sizeofdir) $dir_caso/ocn/hist plus $dir_caso/ice/hist differs from sizeoftar ($sizeoftar). Exit"
	  title="[TAPEARCHIVE] ${CPSSYS} ERROR"
  	${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
	  exit 1
fi

# LND and ROF
sizeofdir=0
for dom in lnd rof; do
	# get size in GB
	  tmpsize=$(du -sb $dir_caso/$dom/hist | awk '{print $1}' | grep -o -E '[0-9]+')
	  sizeofdir=$(( $sizeofdir + $tmpsize  ))
done
sizeofdir=$(( $sizeofdir / 1000000))
dom=lndrof
sizeoftar=$(du -sb $workdir/${caso}.$dom.h.tar | awk '{print $1}' | grep -o -E '[0-9]+')
sizeoftar=$(( $sizeoftar / 1000000))
if [ $sizeoftar -lt 1000 -o $sizeoftar -gt 30000 ]; then
  	body="Error in $caso. Script is $DIR_UTIL/iDas_case_tape_archive.sh. Logfile $LOG_FILE. For domain $dom sizeoftar must be ge 1GB and le 30GB but is $sizeoftar in MB. Exit"
	  title="[TAPEARCHIVE] ${CPSSYS} ERROR"
  	${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
	  exit 1
fi
sizediff=$(( $sizeofdir - $sizeoftar )) 
sizediff=${sizediff#-} # remove minus to get ABS()
if [ $sizediff -gt $sizethreshold ]; then
  	body="Error in $caso. Script is $DIR_UTIL/iDas_case_tape_archive.sh. Logfile $LOG_FILE. For domain $dom sizeofdir ($sizeofdir) $dir_caso/rof/hist + $dir_caso/lnd/hist differs from sizeoftar ($sizeoftar). Exit"
	  title="[TAPEARCHIVE] ${CPSSYS} ERROR"
  	${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
	  exit 1
fi

# *************************************************************
# SECTION 3 - TRANSFER TO TAPELIBRARY
# *************************************************************

# ****************************************** 
# Verifica accesso login03
# ******************************************
echo "TIMESTAMP $(date)" 
cls
if [ $? -ne 0 ];then
  	body="Error on login03 - access test - command cls ,means that you did not access correctly to iDAS \n
      Script is $DIR_UTIL/iDas_case_tape_archive.sh. Logfile $LOG_FILE."
	  title="[TAPEARCHIVE] ${CPSSYS} ERROR"
  	${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
	  exit 1
fi
# ******************************************
# Creare cartella caso
# ******************************************
echo "TIMESTAMP $(date)" 
dirtocreate=$idaspath/$st/$yyyy/$ens #$startdate
cmkdir -p $dirtocreate
if [ $? -ne 0 ];then
  	body="Error on login03 - cmkdir $dirtocreate \n
       Script is $DIR_UTIL/iDas_case_tape_archive.sh. Logfile $LOG_FILE."
	  title="[TAPEARCHIVE] ${CPSSYS} ERROR"
  	${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
	  exit 1
fi
# ******************************************
# crsync di ciascun tar
# ******************************************
echo "TIMESTAMP $(date)" 

## OLD PROCEDURE
#crsync -v $workdir/*tar $dirtocreate rtime=$rettime
#if [ $? -ne 0 ];then
#	body="Error on login03 - crsync -rv $workdir/*tar $dirtocreate rtime=$rettime \n
#       Script is $DIR_UTIL/iDas_case_tape_archive.sh. Logfile $LOG_FILE."
#	title="[TAPEARCHIVE] ${CPSSYS} ERROR"
#	${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
#	exit 1
#fi

# For each tar file:
# 1) check if file exist not and in case sync it
# 2) check if file is resident or not. If is on iDAS just sync it
# 3) if was migrated, first remove it and then sync it again
echo "TAR FILES TO BE TRANSFERRED onto $dirtocreate"
echo "$listoftarfiles"

for file in $listoftarfiles; do
	# cls need +e otherwise script exit
  	set +e
	  cls $dirtocreate/$file
  	res=$(echo $?)
	  set -e
	# 1) check if file exist
  	if [ $res -ne 0 ]; then
		# file is not existent, crsync directly
	    	echo "file is not existent, crsync directly"
    		crsync -v $workdir/$file $dirtocreate rtime=$rettime
		    if [ $? -ne 0 ];then
      			body="Error on login03 - crsync -rv $workdir/$file $dirtocreate rtime=$rettime \n
		       Script is $DIR_UTIL/iDas_case_tape_archive.sh. Logfile $LOG_FILE."
			      title="[TAPEARCHIVE] ${CPSSYS} ERROR"
      			${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
			      exit 1
    		fi		
	  else
		# 2) file exist, check is status first
	  	  echo "first check $file status:"
    		cstate $dirtocreate/$file # return 0=still on idas ;1=migrated on Tape
	    	if [ $? -eq 0 ]; then
			# file is still on idas crsync it normally
		      	echo "  file is still on idas crsync it normally"
    	  		crsync -v $workdir/$file $dirtocreate rtime=$rettime
  		    	if [ $? -ne 0 ];then
        				body="Error on login03 - crsync -rv $workdir/$file $dirtocreate rtime=$rettime \n
		  	       Script is $DIR_UTIL/iDas_case_tape_archive.sh. Logfile $LOG_FILE."
			        	title="[TAPEARCHIVE] ${CPSSYS} ERROR"
        				${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
			        	exit 1
    		  	fi				
  		  else	
			# 3) file is probably migrated
	  		    echo "  file is probably migrated"

			# NOW SEND WARNING if trafficlight file is not present in /users_home/csp/sp1/SPS/CMCC-${CPSSYS}/logs/TAPEARCHIVE/$st/$year
      			trafficlight=${caso}_removefromtape_and_syncagain
		      	if [ ! -f $DIR_LOG/TAPEARCHIVE/$st/$yyyy/${trafficlight} ]; then
				        body="Warning on login03 - You are trying to remove a pre-existing file from TAPE, before crsync it, with: crm $dirtocreate/$file \n
        					 This procedure is not allowed by default, unless you are completely sure about it. \n
			        		 To let the program remove file from tape and sync it again for $caso you must create a trafficlight file by: \n
					         touch $DIR_LOG/TAPEARCHIVE/$st/$yyyy/${trafficlight} \n
      		  			 and wait the crontab laucher restart automatically the iDas_case_tape_archive.sh for caso $caso . \n
			           Script is $DIR_UTIL/iDas_case_tape_archive.sh. Logfile $LOG_FILE."
			      	  title="[TAPEARCHIVE] ${CPSSYS} WARNING"
        				${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
	  		      	exit 1
      			else
		        		echo "second remove it from tape"
        				crm $dirtocreate/$file
			        	if [ $? -ne 0 ];then
          					body="Error on login03 - Removing pre-existing file before crsync it, with: crm $dirtocreate/$file \n
				             Script is $DIR_UTIL/iDas_case_tape_archive.sh. Logfile $LOG_FILE."
          					title="[TAPEARCHIVE] ${CPSSYS} ERROR"
				          	${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
        		  			exit 1
  				      fi
        				echo "third crsync as usual"
		  	      	crsync -v $workdir/$file $dirtocreate rtime=$rettime
        				if [ $? -ne 0 ];then
			          		body="Error on login03 - Syncing $file after (removing it from tape) with: crsync -rv $workdir/$file $dirtocreate rtime=$rettime \n
				         Script is $DIR_UTIL/iDas_case_tape_archive.sh. Logfile $LOG_FILE."
          					title="[TAPEARCHIVE] ${CPSSYS} ERROR"
				          	${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
          					exit 1
			        	fi
      			fi # endif trafficlight exist			
	  	  fi # endif file is resident
  	fi # endif file exist
done

echo "TIMESTAMP $(date)" 
# COMMENTED: not the safest way to catch a success code
# # grep Success and Data transfer completed .
# cntmsg1=$(grep -i "Data transfer completed" ${LOG_FILE} | wc -l )
# cntmsg2=$(grep -i "success" ${LOG_FILE} | wc -l )
# if [ $cntmsg1 -gt 0 -a $cntmsg2 -gt 0 ]; then
# 	continue
# else
# 	body="Error during crsync -v $workdir/*tar $dirtocreate"
# 	title="[TAPEARCHIVE] ${CPSSYS} ERROR"
# 	${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
# 	exit 1
# fi

# ******************************************
# Rimozione della work temporanea
# ******************************************
echo "Going to remove $workdir"
echo "TIMESTAMP $(date)" 
rm -r $workdir
# ******************************************
# save ocn into OCNARCHIVE dir
# ******************************************
mkdir -p $OCNARCHIVE/$caso/ # redundant but safe to cath quota exceptions
if [ $debug -eq 0 ]; then
	  cd $dir_caso 
  	rsync -auv ocn $OCNARCHIVE/$caso/
	  if [ $? -ne 0 ]; then
		    body="Error, $dir_caso/ocn copy procedure onto $OCNARCHIVE/$caso failed \n
        Script is $DIR_UTIL/iDas_case_tape_archive.sh. Logfile $LOG_FILE."
    		title="[TAPEARCHIVE] ${CPSSYS} ERROR"
		    ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
    		exit 1
  	fi
fi
# ******************************************
# Rimozione del DMO
# ******************************************
echo "Going to remove ${dir_caso}"

archivedir="$(dirname "${dir_caso}")"
cd $archivedir

if [ $debug -eq 0 ]; then
	  chmod -R u+wx $caso
  	rm -r $caso
	  if [ $? -ne 0 ]; then
    		body="Error, ${dir_caso} removing procedure failed \n
		    Script is $DIR_UTIL/iDas_case_tape_archive.sh. Logfile $LOG_FILE."
    		title="[TAPEARCHIVE] ${CPSSYS} ERROR"
		    ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
    		exit 1
	  fi
fi
# ******************************************
# Exit and notificate successfull termination
# ******************************************
title="[TAPEARCHIVE] ${CPSSYS} notification"
body="$caso - successfull archive on tape library ($dirtocreate) and removal from ${dir_caso}"
${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"

echo "Done."
echo "TIMESTAMP $(date)" 
exit 0

