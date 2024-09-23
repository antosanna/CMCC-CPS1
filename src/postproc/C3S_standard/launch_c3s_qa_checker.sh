#!/bin/sh -l
#-------------------------------------------------------------------------------
# Script to check 1 member of produced forecast 
#  launched by CMCC-SPS3/src/postproc/C3S_standard/tar_and_push.sh
#  input arguments: 
#	$1 startdate:	YYYYMM
#	$2 memberlist:	i
# usage:
#	./launch_c3s_qa_checker_random.sh 200005 10 (i.e., check member 10th)
#-------------------------------------------------------------------------------
. $HOME/.bashrc
# load variables from descriptor
. $DIR_UTIL/descr_CPS.sh

set -evxu

# ***************************************************************************
# Input
# ***************************************************************************
startdate=$1 # 202001
memberlist=$2 # define member to check explicitly
outdirC3S=$3
#
st=${startdate:4:6}
yyyy=${startdate:0:4}
set +evxu
. $DIR_UTIL/descr_ensemble.sh $yyyy
set -evxu
#
memberstocheck=1 # only 1 member DO NOT CHANGE

#touch $checkfile     # check file qa started in $DIR_CASES/$caso  unlikely needed anymore

tmembers=$nrunC3Sfore # from descriptor, change between hindcast and forecast
expected_files=$nfieldsC3S # from descriptor, number of variables (distinct files)

member=$(printf "%.2d" $((10#$memberlist))) #member with 2 digits
set +euvx
. $dictionary
set -euvx
ens=$(printf "%.3d" $((10#$memberlist))) #member with 3 digits

ACTDIR=$SCRATCHDIR/qa_checker/$startdate/CHECKER_${ens}
wdir=$ACTDIR/CHECK/
#DL=$DIR_CASES/${SPSSystem}_${startdate}_${ens}/logs # case dir 

DL=${DIR_LOG}/$typeofrun/$yyyy$st/qa_checker/${ens}
mkdir -p $DL
if [ -d $ACTDIR ]
then
   rm -rf $ACTDIR
fi
mkdir -p $wdir

# the following filetobechecked number number is given by 53 netcdf files = number of variables by member
filetobechecked=$(( ( $expected_files ) * $memberstocheck   )) #2120 for hindcat

# ***************************************************************************
# Define a namespace of vars - parallelization
# ***************************************************************************
# each namespace is a process submitted on serial_24h and have a specific memory need
namespace=()
# atmos
namespace+="atmos_6hr_surface_psl "
namespace+="atmos_6hr_surface_prw "
namespace+="atmos_6hr_surface_clt "
namespace+="atmos_6hr_surface_tas "
namespace+="atmos_6hr_surface_tdps "
namespace+="atmos_6hr_surface_uas "
namespace+="atmos_6hr_surface_vas "
namespace+="atmos_6hr_surface_ua100m "
namespace+="atmos_6hr_surface_va100m "
namespace+="atmos_12hr_pressure_zg "
namespace+="atmos_12hr_pressure_ta "
namespace+="atmos_12hr_pressure_hus "
namespace+="atmos_12hr_pressure_ua "
namespace+="atmos_12hr_pressure_va "
namespace+="atmos_day "
namespace+="atmos_fix "
# land
namespace+="land_6hr "
namespace+="land_day "
# seaIce
namespace+="seaIce_6hr "
namespace+="seaIce_day "
# ocean (only tso)
namespace+="ocean_6hr "
namespace+="ocean_mon " #uncomment when adding gli ocean_mon

# Define memory needs for each namespace (attention:keep order)
# atmos
memory[0]="5000M" #"2500M " #"atmos_6hr_surface_psl "
memory[1]="5000M" #"2500M " #"atmos_6hr_surface_prw "
memory[2]="5000M" #"2500M " #"atmos_6hr_surface_clt "
memory[3]="5000M" #"2500M " #"atmos_6hr_surface_tas "
memory[4]="5000M" #"2500M " #"atmos_6hr_surface_tdps "
memory[5]="7500M" #"2500M " #"atmos_6hr_surface_uas "
memory[6]="7500M" #"2500M " #"atmos_6hr_surface_vas "
memory[7]="7500M" #"2500M " #"atmos_6hr_surface_ua100m "
memory[8]="7500M" #"2500M " #"atmos_6hr_surface_va100m "
memory[9]="20000M" #"3500M " #"atmos_12hr_pressure_zg "
memory[10]="20000M" #"4000M " #"atmos_12hr_pressure_ta "
memory[11]="20000M" #"5000M " #"atmos_12hr_pressure_hus "
memory[12]="20000M" #"3500M " #"atmos_12hr_pressure_ua "
memory[13]="20000M" #"3500M " #"atmos_12hr_pressure_va "
memory[14]="7500M" #"5000M "  #"atmos_day "
memory[15]="2000M " #"atmos_fix "
# land
memory[16]="5000M" #"2500M " #"land_6hr "
memory[17]="5000M" #"2750M " #"land_day "
# seaIce
memory[18]="5000M" #"3500M " #"seaIce_6hr "
memory[19]="5000M" #"2000M " #"seaIce_day "
# ocean (only tso)
memory[20]="12000M" #"2500M " #"ocean_6hr "
memory[21]="2000M " #"ocean_mon " #uncomment when adding gli ocean_mon
    
# Link or copy temporarily all files to working dir
cd $wdir

# clean old files if they exist
if [ -n "$(ls -A $wdir/*nc)" ];then
    echo "Must clean old files in $wdir"
    rm $wdir/*nc
fi

# Copy netcdf files 
rsync -auv $outdirC3S/*r${member}*.nc $wdir/

# Count all netcdf files
ncnumber=`ls -1 *.nc | wc -l `
if [ $ncnumber -ne $filetobechecked ]; then
    echo "Uncorrect number of netcdf files, ncnumber should be $filetobechecked but is $ncnumber "
    		
    title="SPS4 FORECAST ERROR - QA CHECKER"   
    body="Something probably went wrong with check of member ${SPSSystem}_${startdate}_${ens}. Uncorrect number of netcdf files, ncnumber should be $filetobechecked but is $ncnumber."
    ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r yes -s $startdate
    exit 1
fi

# link python checker from util to here
cd $ACTDIR

# ***************************************************************************
# ***************************************************************************
# Main submission loop
# ***************************************************************************
# *********************************************§******************************
output=$wdir/output

mkdir -p $wdir/output

# json file
json=${DIR_C3S}/qa_checker_table.json

if [ -f $wdir/c3s_qa_checker.py ]; then
   rm -f $wdir/c3s_qa_checker.py
fi
cp $DIR_C3S/c3s_qa_checker.py $wdir/
cp -r $DIR_C3S/qa_checker_lib $wdir/ 

submit_cnt=0
mem_idx=0
for ns in ${namespace}; do
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
  . $DIR_UTIL/condaactivation.sh 
  condafunction activate qachecker 
set -euvx


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
    varname=\`echo \$logname  | cut -d _ -f4\`

    if [  -f \$output/\$logname.txt ] ; then 
        rm \$output/\$logname.txt
    fi

    # copy to tempdir
    cp \$ncfile tempdir_\$namespace
    
    scratch4outl=$SCRATCHDIR/checker_\$startdate/\$member/\$namespace/
    if [[ -d \$scratch4outl ]] ; then
        rm -r \$scratch4outl
    fi
    mkdir -p \$scratch4outl
    # launch python (checking files in tempdir_\$namespace)
    # adding -pclim input activates the climatological check on monthly min/max, while -pqval activates the interquantile one 
    #python c3s_qa_checker.py \$ncfile -p tempdir_\$namespace -pqval 0.01 -mf 1. -pclim \$OUTDIR_DIAG/C3S_statistics -j \$jsonf -exp \$startdate -real \$member --logdir \$output/ --verbose >> \$output/\$logname.txt
# WILL BE THE ABOVE ONCE THE HINDCAST CLIMATOLOGIES WILL BE COMPUTED
    #python c3s_qa_checker.py \$ncfile -p tempdir_\$namespace -pclim \$OUTDIR_DIAG/C3S_statistics -u -scd \$scratch4outl -j \$jsonf -exp \$startdate -real \$member --logdir \$output/ --verbose >> \$output/\$logname.txt
    python c3s_qa_checker.py \$ncfile -p tempdir_\$namespace -j \$jsonf -exp \$startdate -real \$member --logdir \$output/ --verbose >> \$output/\$logname.txt

    # remove files
    if [ \$? -eq 0 ] ; then
        echo Once finished, clean file...
        rm $wdir/\$ncfile   
    else
        exit 1
    fi

done

cd $ACTDIR

#set +evxu
#  condafunction deactivate qachecker  
#set -euvx


# remove and touch done file
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
# modified 20201021 from serialq_s to serialq_l for priority reasons
    input="$ns ${startdate} ${ens} ${json}"

#
${DIR_UTIL}/submitcommand.sh -m $machine -q $parallelq_s -S $qos -t "2" -M $memlimit -s launch_c3s_qa_checker.${ns}.sh -j chk_err_${startdate}_${ens}_${ns} -d $ACTDIR -l $DL -i "$input"



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
    if [ $jobdone -eq $submit_cnt ] ; then
        break
    fi
    elapsed_time=$(( $elapsed_time + $sleeptime  ))

    # avoid infinite waiting
    number_of_chk_proc=0
    number_of_chk_proc=`${DIR_UTIL}/findjobs.sh -m $machine -n chk_err_${startdate}_${ens} -c yes`

    if [ $elapsed_time -gt 7200 -a $number_of_chk_proc -eq 0 ]; then 
        echo "Something probably went wrong with checker. Check in logs for missing NSDONE_ files production."
        title="SPS4 FORECAST ERROR - QA CHECKER"	
        body="Something probably went wrong with checker of member ${SPSSystem}_${startdate}_${ens}. Check in logs for NSDONE_ files production."
        ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r yes -s $startdate
        exit 1
    fi

done
# ***************************************************************************
# Now send mail
cd $wdir
cd output
cnt_files=`ls -1 *.txt | wc -l`
endtime=`date +%Y%m%d%H%M`

# if all files have been checked
filetobechecked=1
if [ $cnt_files -ge $filetobechecked ]; then

    # look for warnings
    mkdir -p ${DIR_LOG}/REPORTS/${startdate}
    warningreport="${DIR_LOG}/REPORTS/${startdate}/${SPSSystem}_${startdate}_${ens}_checker_warnings.txt"
    if [ -f $warningreport ] 
    then
        rm -f $warningreport
    fi

    cntwarning=`grep -Ril FIELDWARNING *.txt | wc -l`
    if [ $cntwarning -ne 0 ]; then
        echo "WARNING REPORT `date`" >> $warningreport
        
        warninmsg=`grep -Rh FIELDWARNING *.txt`
        warninlist=`grep -Ril FIELDWARNING *.txt`
  

        title="${CPSSYS} FORECAST WARNING - QA CHECKER" 
     
        #since $warninmsg and $warninlist are arrays, the body message is created by parts
        body="For member ${SPSSystem}_${startdate}_${ens} $cntwarning warnings files have been found over the $cnt_files C3S standardized files checked."
        body+="\n\n Here the warning list"
        for w in ${warninmsg}; do
            if [ "$w" == "[FIELDWARNING]" ];then
                body+=" \n${w}"
            else
                body+=" ${w}"
            fi
        done
  
        body+="\n\n Please check in $wdir/output or ${DL}/output_${startdate}_${endtime} the output log of \n"

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
        body+="\n This piece of information may be found on the WARNING REPORT $warningreport."
        body+="\n For further information, use the checker with the option --verbose." 
        ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r yes -s $startdate

    fi

    # look for errors
    # remove ok file if present
    if [ -f $check_c3s_qa_ok ]; then
        rm -f $check_c3s_qa_ok
    fi
    if [ -f $check_c3s_qa_err ]; then
        rm -f $check_c3s_qa_err
    fi

    cnterror=`grep -Ril ERROR\] *.txt | wc -l`
    if [ $cnterror -eq 0 ]; then
        touch $check_c3s_qa_ok
    else
        errormsg=`grep -Ril ERROR\] *.txt`
        
        title="${CPSSYS} FORECAST ERROR - QA CHECKER"         	
        body="For member  ${SPSSystem}_${startdate}_${ens} errors on $cnterror files have been found on the $cnt_files C3S standardized files checked. \n Please check the output log in $wdir/output. \n Here you may found the list of error: \n  ${errormsg} \n For further information, use the checker with the --verbose option active."
        ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r yes -s $startdate
        touch $check_c3s_qa_err
        exit
    fi

    filenamerr_num=`ls $wdir/output/clim_error_list_*_${startdate}_${ens}.outlier | wc -l` 
    if [[ $filenamerr_num -ne 0 ]] ; then
         set +euvx
         . $DIR_UTIL/condaactivation.sh 
         condafunction activate checker_plot_env
         set -euvx
         filenamerr_list=`ls $wdir/output/clim_error_list_*_${startdate}_${ens}.outlier` 
         for outlier_ff in $filenamerr_list ; do
               var=`basename ${outlier_ff} |cut -d '_' -f4`
               nmb_out_tol=`grep -r 'outside' ${outlier_ff} |wc -l`
               nmb_ins_tol=`grep -r 'inside' ${outlier_ff} |wc -l`
               if [[ $nmb_out_tol -ne 0 ]] ; then
                  outlierf=$wdir/output/outside_tol_error_list_${var}_${startdate}_${ens}.txt
                  grep 'Error' ${outlier_ff} >  ${outlierf}
                  grep 'outside' ${outlier_ff} >>  ${outlierf}
                  C3Sfile=`ls -1 $outdirC3S/*_${var}_*r${member}*.nc`
                  echo "Checking $outlierf"
                  python3 ${DIR_UTIL}/plt_outlier_inchain_4d.py ${outlierf} -v ${var} -p ${outdirC3S} -f $C3Sfile -l $wdir/output -sd ${startdate} -real ${member} -j $json -pl "outside_outliers-${startdate}_${member}_${var}"
                  if [[ `ls $wdir/output/outside_outliers-${startdate}_${member}_${var}_*.pdf |wc -l` -ne 0 ]] ; then
                       plotfile=`ls $wdir/output/outside_outliers-${startdate}_${member}_${var}_*.pdf`
                       echo "sendmail with $plotfile"
                       mkdir -p $SCRATCHDIR/$startdate/checker
                       plot4mail=$SCRATCHDIR/$startdate/checker/outside_outliers_${var}_${startdate}_${member}.pdf
                       convert $plotfile $plot4mail
                       attachment="$plot4mail $outlierf"
                       title="${CPSSYS} FORECAST ALERT - QA CHECKER"    
                       body="For case ${SPSSystem}_${startdate}_${ens}, c3s_qa_checker has found ${nmb_out_tol} out of the climatological interval for variable ${var} exceeding the accepted tolerance interval. Please check the list and the plots attached, and decide wethere to update the climatological files once the forecast is over."
                       ${DIR_UTIL}/sendmail.sh -m $machine  -a "$attachment" -e $mymail -M "$body" -t "$title" -r yes -s $startdate
                  fi
               fi
               if [[ $nmb_ins_tol -ne 0 ]] ; then
                  outlierf=$wdir/output/inside_tol_error_list_${var}_${startdate}_${ens}.txt
                  #table header needed for plot
                  grep 'Error' ${outlier_ff} >  ${outlierf}
                  grep 'inside' ${outlier_ff} >>  ${outlierf}
                  C3Sfile=`ls -1 $outdirC3S/*_${var}_*r${member}*.nc`
                  echo "Checking $outlierf"
                  python3 ${DIR_UTIL}/plt_outlier_inchain_4d.py ${outlierf} -v ${var} -p ${outdirC3S} -f $C3Sfile -l $wdir/output -sd ${startdate} -real ${member} -j $json -pl "inside_outliers-${startdate}_${member}_${var}"
                  if [[ `ls $wdir/output/inside_outliers-${startdate}_${member}_${var}_*.pdf |wc -l` -ne 0 ]] ; then
                       plotfile=`ls $wdir/output/inside_outliers-${startdate}_${member}_${var}_*.pdf`
                       echo "sendmail with $plotfile"
                       mkdir -p $SCRATCHDIR/$startdate/checker
                       plot4mail=$SCRATCHDIR/$startdate/checker/inside_outlier_${var}_${startdate}_${member}.pdf
                       convert $plotfile $plot4mail
                       attachment="$plot4mail $outlierf"
                       title="${CPSSYS} FORECAST WARNING - QA CHECKER"     
                       body="For case ${SPSSystem}_${startdate}_${ens}, c3s_qa_checker has found ${nmb_ins_tol} out of the climatological interval for variable ${var}, but inside the accepted tolerance interval. Please check the list and the plots attached."
                       ${DIR_UTIL}/sendmail.sh -m $machine -a "$attachment" -e $mymail -M "$body" -t "$title" -r yes -s $startdate
                   fi
               fi
         done
      fi #if outlier
fi


# ***************************************************************************
# save results
cd $wdir
mv $ACTDIR/NSDONE_* output/
cp -r output ${DL}/output_${startdate}_${endtime}

# ***************************************************************************
# Now clean all
if [[ ! -f $check_c3s_qa_err ]] ; then
   cd $wdir
   rm -rf tempdir*
fi
# ***************************************************************************
# Exit

echo "$0 Done."
exit 0
