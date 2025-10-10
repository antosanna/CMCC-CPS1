#!/bin/sh -l
#-------------------------------------------------------------------------------
# Script to check 1 member of produced forecast 
#  input arguments: 
#	$1 startdate:	YYYYMM
#	$2 memberlist:	i
# usage:
#	./launch_c3s_qa_checker_random.sh 200005 10 (check member 10th)
#-------------------------------------------------------------------------------
. $HOME/.bashrc
# load variables from descriptor
. $DIR_SPS35/descr_SPS3.5.sh

#NEW 202103: migliorato testo mail
set -evxu

# ***************************************************************************
# Input
# ***************************************************************************
startdate=$1 # 202001
memberlist=$2 # define member to check explicitly
DL=$3
outdir=$4
checkfile=$5
daylist="$6"
memberstocheck=1 # only 1 member DO NOT CHANGE
expected_files=7

# load  variables from forecast/hindcast descriptors
if [ $startdate -ge ${iniy_fore}01 ]
then
   . $DIR_SPS35/descr_forecast.sh
else
   . $DIR_SPS35/descr_hindcast.sh 
fi

tmembers=$nrunC3Sfore # from descriptor, change between hindcast and forecast

mb=$(printf "%.2d" $((10#$memberlist))) #member with 2 digits
mb3=$(printf "%.3d" $((10#$memberlist))) #member with 3 digits

ACTDIR=$DL/CHECKER_${mb3}
wdir=$ACTDIR/CHECK/
mkdir -p $wdir

# the following filetobechecked number number is given by 53 netcdf files = number of variables by member
filetobechecked=$(( ( $expected_files ) * $memberstocheck   )) #2120 for hindcat

# ***************************************************************************
# Define a namespace of vars - parallelization
# ***************************************************************************
# each namespace is a process submitted on serial_24h and have a specific memory need
namespace=()
# atmos
namespace+="pressure "
# ocean (only tso)
namespace+="surface " #uncomment when adding gli ocean_mon
# Define memory needs for each namespace (attention:keep order)
# atmos
memory[0]="1500M "  #"pressure "
# ocean (only tso)
memory[1]="1500M " #"surface "
# Link or copy temporarily all files to working dir
cd $wdir

# clean old files if they exist
if [ -n "$(ls -A $wdir/*r${mb}*.nc)" ];then
	echo "Must clean old files in $wdir"
	rm $wdir/*r${mb}*.nc
fi

# Copy netcdf files 

lista_file=`ls $outdir/*r${mb}*.nc`
for file in $lista_file ; do
  var_file=`echo $file |rev|cut -d '_' -f2 |rev`
  nosync=0
  for dayvar in $daylist ; do
     if [[ $dayvar == $var_file ]] ; then
         nosync=1
         break
     fi
  done
  if [[ $nosync -eq 0 ]] ; then
       rsync -auv $file $wdir/
  fi
done
# Count all netcdf files
ncnumber=`ls -1 *day*.nc | wc -l `
if [ $ncnumber -ne $filetobechecked ]; then
  	echo "Uncorrect number of netcdf files, ncnumber should be $filetobechecked but is $ncnumber "
	  title="[C3Sdaily] ${SPSSYS} $typeofrun daily postprocessing ERROR - QA CHECKER"		
	  body="Something probably went wrong with $DIR_C3S/launch_c3s_qa_checker_keep_in_archive.sh daily ${SPSsystem}_${startdate}_${mb3}. Uncorrect number of netcdf files, ncnumber should be $filetobechecked but is $ncnumber. Logfile in $DIR_CASES/${SPSsystem}_${startdate}_${mb3}/logs/qa_checker_daily_${startdate}"
	${DIR_SPS35}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r yes -s $startdate
	  exit 1
fi

# link python checker from util to here
cd $ACTDIR
if [ -L c3s_qa_checker.py ]; then
   unlink c3s_qa_checker.py
elif [ -f c3s_qa_checker.py ]; then
   rm -f c3s_qa_checker.py
fi
if [ ! -L c3s_qa_checker.py  ]; then
	ln -sf $DIR_UTIL/c3s_qa_checker.py .
fi
# ***************************************************************************
# ***************************************************************************
# Main submission loop
# ***************************************************************************
# ***************************************************************************
output=$wdir/output
if [ -d $output ] ; then
   rm -r $output
fi
mkdir -p $output

# json file
json=${DIR_UTIL}/qa_checker_table.json

if [ -L $wdir/c3s_qa_checker.py ]; then
   unlink $wdir/c3s_qa_checker.py
elif [ -f $wdir/c3s_qa_checker.py ]; then
   rm -f $wdir/c3s_qa_checker.py
fi
if [ ! -f $wdir/c3s_qa_checker.py ] ; then
	cp $ACTDIR/c3s_qa_checker.py $wdir/
fi

submit_cnt=0
mem_idx=0
for ns in $namespace ; do
	
	# clean old scripts if exists
	if [ -f launch_c3s_qa_checker.$ns.sh ] ; then
		rm -f launch_c3s_qa_checker.$ns.sh
	fi

	memlimit=${memory[$mem_idx]}

cat > launch_c3s_qa_checker.${ns}.sh << EOF3
#!/bin/sh -l
#-------------------------------------------------------------------------------
# Script to check produced forecast
#-------------------------------------------------------------------------------
#--------------------------------
. \$HOME/.bashrc

set -evx

namespace=\$1
startdate=\$2
member=\$3
jsonf=\$4

echo "activate env *********************"
set +euvx
if [[ $machine == "juno" ]] ; then
 . $HOME/load_miniconda
fi
 . $DIR_UTIL/condaactivation.sh 
  condafunction activate CHECK_ENV_DEV
set -evxu

echo "retrieve fields ******************"
output=$wdir/output

cd $wdir
if [ -d tempdir_\$namespace ] ; then
	rm -rf tempdir_\$namespace 
fi 

mkdir -p tempdir_\$namespace

netcdf2check=\`ls -1 *\$namespace*.nc\`

for ncfile in \$netcdf2check ; do

	# get variable name
	logname=\`echo \$ncfile  | cut -d _ -f5-15 | cut -d . -f1\`

	if [  -f \$output/\$logname.txt ] ; then 
		rm \$output/\$logname.txt
	fi

	# copy to tempdir
    cp \$ncfile tempdir_\$namespace

    python c3s_qa_checker.py \$ncfile -p tempdir_\$namespace -j \$jsonf -exp \$startdate -real \$member --logdir \$output/ --verbose >> \$output/\$logname.txt

	if [ \$? -eq 0 ] ; then
		echo Once finished, clean file...
		rm $wdir/\$ncfile
	else
		exit 1
	fi
done

cd $ACTDIR

#set +evxu
#condafunction deactivate CHECK_ENV_DEV
#set -evxu

if [ -f NSDONE_\$namespace ] ; then
	rm -r NSDONE_\$namespace
fi 
touch NSDONE_\$namespace

# remove temporary dir
if [ -f NSDONE_\$namespace ] ; then
    rm -rf $wdir/tempdir_\$namespace
fi

exit 0

EOF3

	chmod u+x launch_c3s_qa_checker.${ns}.sh
        input="$ns ${startdate} ${mb3} ${json}"
        ${DIR_SPS35}/submitcommand.sh -m $machine -q $serialq_l -t "2" -r $sla_serialID -S \$qos -M $memlimit -s launch_c3s_qa_checker.${ns}.sh -j chk_err_${startdate}_${mb3}_${ns} -d $ACTDIR -l $DL -i "$input"
	# update submitted counter
	if [ $? -eq 0 ]; then
		submit_cnt=$(( $submit_cnt + 1 ))
	fi
	mem_idx=$(( $mem_idx + 1 ))

done # end of submission loop

# ***************************************************************************
# Now wait for all jobs completion

elapsed_time=0
sleeptime=60
while `true` ; do
   sleep $sleeptime
   jobdone=`ls -1 ${ACTDIR}/NSDONE_* | wc -l`
   if [[ $jobdone -eq $submit_cnt ]] ; then
      break
   fi
   elapsed_time=$(( $elapsed_time + $sleeptime  ))

   # avoid infinite waiting
   number_of_chk_proc=0
   number_of_chk_proc=`${DIR_SPS35}/findjobs.sh -m $machine -n chk_err_${startdate}_${mb3} -c yes`
   if [[ $elapsed_time -gt 7200 ]] && [[ $number_of_chk_proc -eq 0 ]]; then 
		echo "Something probably went wrong with checker. Check in logs for NSDONE_ files production."
	        title="[C3Sdaily-QA] ${SPSSYS} forecast ERROR"		
		body="Something probably went wrong with checker of member ${SPSsystem}_${startdate}_${mb3}. Check in logs for NSDONE_ files production."
		${DIR_SPS35}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r yes -s $startdate
		exit 1
   fi

done


# ***************************************************************************
# Now send mail
cd $wdir
cd output
cnt_files=`ls -1 *.txt | wc -l`
endtime=`date +%Y%m%d%H%M`

if [ $cnt_files -eq $filetobechecked ]; then

    # look for warnings
    mkdir -p ${DIR_LOG}/REPORTS/${startdate}
    warningreport="${DIR_LOG}/REPORTS/${startdate}/${SPSsystem}_${startdate}_${mb3}_checker_daily_warnings.txt"
    if [ -f $warningreport ] 
    then
        rm -f $warningreport
    fi
    cntwarning=`grep -Ril FIELDWARNING *.txt | wc -l`
    if [ $cntwarning -ne 0 ]; then
        echo "WARNING REPORT `date`" >> $warningreport
        
        warninmsg=`grep -Rh FIELDWARNING *.txt`
        warninlist=`grep -Ril FIELDWARNING *.txt`

        title="[C3Sdaily-QA] ${SPSSYS} forecast warning"       
        #since $warninmsg and $warninlist are arrays, the body message is created by parts
        body="Il membro ${SPSsystem}_${startdate}_${mb3} ha riscontrato WARNINGS del checker su $cntwarning files rispetto ai $cnt_files files standardizzati controllati."
        body+="\n\n Ecco la lista di warnings"
        for w in ${warninmsg}; do
            if [ "$w" == "[FIELDWARNING]" ];then
                body+=" \n${w}"
            else
                body+=" ${w}"
            fi
        done
  
        body+="\n\n Per favore controlla in $wdir/output or ${DL}/output_${startdate}_${endtime} gli output log di \n"

        for w in $warninlist;do 
            body+="${w}\n";
        done
        
        # save to report
        printf "\n ${body}">> $warningreport
        printf "\n Full logs are attached below:">> $warningreport
        for w in $warninlist;do 
            printf "\n"  >> $warningreport
            printf "=%.0s"  $(seq 1 63) >> $warningreport
            printf "\n${w}\n" >> $warningreport
            printf "=%.0s"  $(seq 1 63) >> $warningreport
            printf "\n"  >> $warningreport
            cat ${w} >> $warningreport
        done
        
        # send mail
        body+="\n Questa informazione si trova sul WARNING REPORT $warningreport."
        body+="\n Per ulteriori informazioni, girare il checker con la opzione --verbose."  
        ${DIR_SPS35}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r yes -s $startdate

    fi

    # look for errors
    # remove ok file if present
    if [ -f $checkfile ]; then
        rm -f $checkfile
    fi

   	cnterror=`grep -Ril ERR *.txt | wc -l`
   	if [ $cnterror -eq 0 ]; then
		      touch $checkfile  #$DL/qa_checker_daily_ok_${mb3}
   	else
		      errormsg=`grep -Ril ERR *.txt`
      		title="[C3Sdaily-QA] ${SPSSYS} forecast ERROR"		
	      	body="Il membro ${SPSsystem}_${startdate}_${mb3} ha riscontrato errori del checker su $cnterror files rispetto ai $cnt_files files standardizzati controllati.\n Per favore controlla il log in $wdir/output. \n Ecco la lista di errori:\n ${errormsg} \n Per ulteriori informazioni, girare il checker con la opzione --verbose."
   		${DIR_SPS35}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r yes -s $startdate
		      exit 1
   	fi
else
    echo "number of *txt not the expected $filetobechecked"
    echo "check here $wdir/output and $ACTDIR/NSDONE_*"
    exit 1
fi


# ***************************************************************************
# save results
cd $wdir
mv $ACTDIR/NSDONE_* output/
outdir=${DL}/output_${startdate}_${endtime}
mkdir -p $outdir
mv output/* $outdir/

# ***************************************************************************
# Now clean all
cd $wdir
rm -rf tempdir*
# ***************************************************************************
# Exit

echo "$0 Done."
exit 0
