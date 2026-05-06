#!/bin/sh -l
#-------------------------------------------------------------------------------
# Script to check 1 member of produced forecast 
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
dir_cases=$4
#
st=${startdate:4:6}
yyyy=${startdate:0:4}
set +evxu
. $DIR_UTIL/descr_ensemble.sh $yyyy
set -evxu
#
reduced=1    #reduced=1 json version of the checker
memberstocheck=1 # only 1 member DO NOT CHANGE

#touch $checkfile     # check file qa started in $DIR_CASES/$caso  unlikely needed anymore

tmembers=$nrunC3Sfore # from descriptor, change between hindcast and forecast
expected_files=$nfieldsC3S # from descriptor, number of variables (distinct files)

member=$(printf "%.2d" $((10#$memberlist))) #member with 2 digits
set +euvx
. $dictionary
set -euvx
ens=$(printf "%.3d" $((10#$memberlist))) #member with 3 digits

caso=${SPSSystem}_${startdate}_${ens}

ACTDIR=$SCRATCHDIR/qa_checker/$startdate/CHECKER_${ens}

mkdir -p ${DIR_LOG}/$typeofrun/$yyyy$st/qa_checker/${ens}
if [[ -d $ACTDIR ]]
then
   rm -rf $ACTDIR
fi

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
namespace+="ocean_mon " 

if [[ ${reduced} -eq 1 ]] 
then
# Define memory needs for each namespace (attention:keep order)
# atmos
   memory[0]="700M"  #"atmos_6hr_surface_psl "
   memory[1]="700M" #"atmos_6hr_surface_prw "
   memory[2]="700M" #"atmos_6hr_surface_clt "
   memory[3]="700M" #"atmos_6hr_surface_tas "
   memory[4]="700M" #"atmos_6hr_surface_tdps "
   memory[5]="700M" #"atmos_6hr_surface_uas "
   memory[6]="700M" #"atmos_6hr_surface_vas "
   memory[7]="700M" #"atmos_6hr_surface_ua100m "
   memory[8]="700M" #"atmos_6hr_surface_va100m "
   memory[9]="4000M" #"atmos_12hr_pressure_zg "
   memory[10]="4000M" #"atmos_12hr_pressure_ta "
   memory[11]="4000M" #"atmos_12hr_pressure_hus "
   memory[12]="4000M" #"atmos_12hr_pressure_ua "
   memory[13]="4000M" #"atmos_12hr_pressure_va "
   memory[14]="1000M"  #"atmos_day "
   memory[15]="100M " #"atmos_fix "
# land
   memory[16]="700M"  #"land_6hr "
   memory[17]="2000M" #"land_day "
# seaIce
   memory[18]="700M"  #"seaIce_6hr "
   memory[19]="500M"  #"seaIce_day "
# ocean 
   memory[20]="1000M"  #"ocean_6hr "  # previously seto to 700 yet on Leonoardo not enough
   memory[21]="100M " #"ocean_mon " 
else
# Define memory needs for each namespace (attention:keep order)
# atmos
   memory[0]="5000M" #"atmos_6hr_surface_psl "
   memory[1]="5000M" #"atmos_6hr_surface_prw "
   memory[2]="5000M" #"atmos_6hr_surface_clt "
   memory[3]="5000M" #"atmos_6hr_surface_tas "
   memory[4]="5000M" #"atmos_6hr_surface_tdps "
   memory[5]="7500M" #"atmos_6hr_surface_uas "
   memory[6]="7500M" #"atmos_6hr_surface_vas "
   memory[7]="7500M" #"atmos_6hr_surface_ua100m "
   memory[8]="7500M" #"atmos_6hr_surface_va100m "
   memory[9]="20000M" #"atmos_12hr_pressure_zg "
   memory[10]="20000M" #"atmos_12hr_pressure_ta "
   memory[11]="20000M" #"atmos_12hr_pressure_hus "
   memory[12]="20000M" #"atmos_12hr_pressure_ua "
   memory[13]="20000M" #"atmos_12hr_pressure_va "
   memory[14]="10000M"  #"atmos_day "
   memory[15]="2000M " #"atmos_fix "
# land
   memory[16]="5000M" #"land_6hr "
   memory[17]="5000M" #"land_day "
# seaIce
   memory[18]="5000M"  #"seaIce_6hr "
   memory[19]="5000M"  #"seaIce_day "
# ocean (only tso)
   memory[20]="12000M" #"ocean_6hr "
   memory[21]="2000M " #"ocean_mon " 
fi

# Link or copy temporarily all files to working dir
cd $wdir

# clean old files if they exist
if [[ -n "$(ls -A $wdir/*nc)" ]];then
    echo "Must clean old files in $wdir"
    rm $wdir/*nc
fi

# Copy netcdf files 
rsync -auv $outdirC3S/*r${member}*.nc $wdir/

# Count all netcdf files
ncnumber=`ls -1 *.nc | wc -l `
if [[ $ncnumber -ne $filetobechecked ]]; then
    echo "Uncorrect number of netcdf files, ncnumber should be $filetobechecked but is $ncnumber "
    		
    title="SPS4 FORECAST ERROR - QA CHECKER"   
    body="Something probably went wrong with check of member ${SPSSystem}_${startdate}_${ens}. Uncorrect number of netcdf files, ncnumber should be $filetobechecked but is $ncnumber."
    ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r $typeofrun -s $startdate -E $ens
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
spike_list=$output/list_spikes.txt
spike_list_dmo=${HEALED_DIR_ROOT}/${caso}/list_spikes_DMO.txt
if [[ -f $spike_list_dmo ]] ; then
   mv $spike_list_dmo ${spike_list_dmo}_`date +%Y%m%d%H%M`
fi
mkdir -p $wdir/output

# json file
json=${DIR_C3S}/qa_checker_table.json

if [[ -f $wdir/c3s_qa_checker.py ]]; then
   rm -f $wdir/c3s_qa_checker.py
fi
cp $DIR_C3S/c3s_qa_checker.py $wdir/
cp -r $DIR_C3S/qa_checker_lib $wdir/ 

submit_cnt=0
mem_idx=0
for ns in ${namespace}; do
    # clean old scripts if exists
    if [[ -f launch_c3s_qa_checker.$ns.sh ]] ; then
        rm -f launch_c3s_qa_checker.$ns.sh
    fi
    memlimit=${memory[$mem_idx]}

    rsync -auv $DIR_TEMPL/launch_c3s_qa_checker.template.sh  $wdir/launch_c3s_qa_checker.${ns}.sh

    chmod u+x launch_c3s_qa_checker.${ns}.sh
# modified 20201021 from serialq_s to serialq_l for priority reasons
    input="$ns ${startdate} ${ens} ${json} ${reduced} $wdir"

#
    ${DIR_UTIL}/submitcommand.sh -m $machine -q $parallelq_s -S $qos -t "2" -M $memlimit -s launch_c3s_qa_checker.${ns}.sh -j chk_err_${startdate}_${ens}_${ns} -d $ACTDIR -l ${DIR_LOG}/$typeofrun/$yyyy$st/qa_checker/${ens} -i "$input"



	# update submitted counter
    if [[ $? -eq 0 ]]; then
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
    number_of_chk_proc=`${DIR_UTIL}/findjobs.sh -m $machine -n chk_err_${startdate}_${ens} -c yes`

    if [[ $elapsed_time -gt 7200 ]] && [[ $number_of_chk_proc -eq 0 ]]; then 
        echo "Something probably went wrong with checker. Check in logs for missing NSDONE_ files production."
        title="SPS4 FORECAST ERROR - QA CHECKER"	
        body="Something probably went wrong with checker of member ${SPSSystem}_${startdate}_${ens}. Check in logs for NSDONE_ files production."
        ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r $typeofrun -s $startdate -E $ens
        exit 1
    fi

done
# ***************************************************************************
# Now send mail
cd $wdir/output

cnt_files=`ls -1 *.txt | wc -l`
endtime=`date +%Y%m%d%H%M`

# if all files have been checked
filetobechecked=1
if [[ $cnt_files -ge $filetobechecked ]]; then

    # look for warnings
    mkdir -p ${DIR_REP}/${startdate}
    warningreport="${DIR_REP}/${startdate}/${SPSSystem}_${startdate}_${ens}_checker_warnings.txt"
    if [[ -f $warningreport ]] 
    then
        rm -f $warningreport
    fi

    cntwarning=`grep -Ril FIELDWARNING *.txt | wc -l`
    if [[ $cntwarning -ne 0 ]]; then
        echo "WARNING REPORT `date`" >> $warningreport
        
        warninmsg=`grep -Rh FIELDWARNING *.txt`
        warninlist=`grep -Ril FIELDWARNING *.txt`
  

        title="${CPSSYS} FORECAST WARNING - QA CHECKER" 
     
        #since $warninmsg and $warninlist are arrays, the body message is created by parts
        body="For member ${SPSSystem}_${startdate}_${ens} $cntwarning warnings files have been found over the $cnt_files C3S standardized files checked. \n\n Here the warning list"
        if [[ "${warninmsg}" =~ "Air Temperature" ]] ; then
            touch $spike_from_cmor
        fi         
        for f in ${warninlist}; do
            w=`grep -Rh FIELDWARNING $f`
            w_pos=`grep -Rhn FIELDWARNING $f|cut -d ":" -f1`
            line_pos=$(($w_pos - 2))
            w_pos=`sed -n "${line_pos}p" $f`
            if [[ "$w" == "[fieldwarning]" ]];then
                body+=" \n ${w} "
                body+=" \n ${w_pos} "
            else
                body+=" ${w}"
                body+=" \n ${w_pos} "
            fi
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
        ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r $typeofrun -s $startdate -E $ens

    fi

    # look for errors
    # remove ok file if present
    if [[ -f $check_c3s_qa_ok ]]; then
        rm -f $check_c3s_qa_ok
    fi
    if [[ -f $check_c3s_qa_err ]]; then
        rm -f $check_c3s_qa_err
    fi

   
    cnterror=`grep -Ril ERROR\] *.txt | wc -l`
    if [[ $cnterror -eq 0 ]] && [[ ! -f $spike_list ]] ; then
        touch $check_c3s_qa_ok
    else
       if [[ $cnterror -ne 0 ]] ; then 
            errormsg=`grep -Ril ERROR\] *.txt`
            title="${CPSSYS} FORECAST ERROR - QA CHECKER"         	
            body="For member  ${SPSSystem}_${startdate}_${ens} errors on $cnterror files have been found on the $cnt_files C3S standardized files checked. \n Please check the output log in $wdir/output. \n Here you may found the list of error: \n  ${errormsg} \n For further information, use the checker with the --verbose option active."
            ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r $typeofrun -s $startdate -E $ens
       fi
       if [[ -f ${spike_list} ]] ; then

            ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_m -M 4000 -d ${DIR_POST}/cam -j plot_timeseries_spike_C3S_${caso} -s plot_timeseries_spike.sh -l ${DIR_LOG}/$typeofrun/$yyyy$st/qa_checker/${ens} -i "$caso 1 ${spike_list}"            
           #counting repetition by looking at number of DMO list produced, if more than 5 interrupt automatic resubmission
           nlist_dmo=`ls ${spike_list_dmo}* |wc -l` 
           title="${CPSSYS} FORECAST ERROR - QA CHECKER SPIKES on C3S  MANUAL INTERVENTION REQUIRED!!"          
           body="For member  ${SPSSystem}_${startdate}_${ens} a spike has been found on C3S standardized files. Healing attempt number ${nlist_dmo}/5." 
           ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r only -s $startdate -E $ens
           if [[ $nlist_dmo -ge 5 ]]  
           then
                 mkdir -p ${HEALED_DIR_ROOT}/${caso}
                 sed -e "s:CASO:$caso:g" $DIR_TEMPL/launch_recover_false_spike_onC3S.sh > ${HEALED_DIR_ROOT}/${caso}/launch_recover_false_spike_onC3S.sh 
                 chmod u+x  ${HEALED_DIR_ROOT}/${caso}/launch_recover_false_spike_onC3S.sh
                 title="MANUAL INTERVENTION REQUIRED C3S ${caso} spike infinite loop!!"
                 body="For member ${caso} a spike has been found on C3S standardized files, and there have been 5 attempts of healing. \n Please check the output log in $wdir/output/${spike_list} and the plots on google drive. \n In case of false spike, recover it launching ${HEALED_DIR_ROOT}/${caso}/launch_recover_false_spike_onC3S.sh from prompt."             
                 ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r $typeofrun -s $startdate -E $ens
           else
             while `true`
             do
                nt=`$DIR_UTIL/findjobs.sh -n postproc_C3S_offline_${caso} -c yes`
                if [[ $nt -eq 0 ]]
                then
                   break
                fi
                sleep 300
             done
             ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_l -M 18000 -d ${DIR_C3S} -j postproc_C3S_offline_resume_${caso} -s postproc_C3S_offline_resume.sh -l $DIR_LOG/$typeofrun/C3S_postproc -i "$caso ${dir_cases} 2" 
# in this case we do not want the checkfile with error $check_c3s_qa_err
             exit
          fi
       fi 
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
                       ${DIR_UTIL}/sendmail.sh -m $machine  -a "$attachment" -e $mymail -M "$body" -t "$title" -r $typeofrun -s $startdate
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
                       ${DIR_UTIL}/sendmail.sh -m $machine -a "$attachment" -e $mymail -M "$body" -t "$title" -r $typeofrun -s $startdate
                   fi
               fi
         done
      fi #if outlier
fi


# ***************************************************************************
# save results
mv $ACTDIR/NSDONE_* $wdir/output/
rsync -auv $wdir/output ${DIR_LOG}/$typeofrun/$yyyy$st/qa_checker/${ens}/output_${startdate}_${endtime}

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
