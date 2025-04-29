#!/bin/sh -l
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
set -euvx

yy=$1
mm2d=$2
refcase=$3
icclm=$4
ichydros=$5
member=$6
check_mv=$7
lastday=$8
errorflag=$9
caso=$refcase

st=`date -d ' '$yy${mm2d}01' + 1 month' +%m`
yyyy=`date -d ' '$yy${mm2d}01' + 1 month' +%Y`

#------------------------------------------------
#-------------------------------------------------------------
# Run CLM standalone simulation
#-------------------------------------------------------------
#------------------------------------------------


set +euvx
    . $DIR_UTIL/condaactivation.sh
    condafunction activate $envcondacm3
set -euvx



###############################################################
# go to working dir
# clean the run directory and cp the correct restart files
cd ${WORK_CPS}/$caso/run

#to deal with the first month of land only simulations
if [[ -d $DIR_ARCHIVE/$caso/rest ]] ;  then
   set +e
#   rm -f ${WORK_CPS}/$caso/run/*  #???
   startclm_1=${yy}-${mm2d}-01
   chmod u+w  $DIR_ARCHIVE/$caso/rest/${startclm_1}-00000/
   rsync -av $DIR_ARCHIVE/$caso/rest/${startclm_1}-00000/* .
   gunzip -f $caso*.gz
   gunzip -f rpointer*.gz 
   chmod u-w $DIR_ARCHIVE/$caso/rest/${startclm_1}-00000/
   set -e
   cd $DIR_CASES/$caso
   ./xmlchange CONTINUE_RUN=TRUE
else
   cd $DIR_CASES/$caso
   ./xmlchange CONTINUE_RUN=FALSE
fi

#now got to the case directory to submit the run
cd $DIR_CASES/$caso
mkdir -p $DIR_CASES/$caso/logs
#scripterr=$DIR_LND_IC/clm_run_error_touch_${provider}.sh

#CHECK_THE_PATH!!!!
sed -e "s@CASO@$caso@g;s@YY@$yy@g;s@MM@${mm2d}@g;s@ICCLM@${icclm}@g;s@ICHYD@${ichydros}@g;s@MEMBER@${member}@g;s@CHECKMV@${check_mv}@g;s@LASTDAY@${lastday}@g" ${DIR_LND_IC}/mv_IC_2ICDIR.sh > $DIR_CASES/$caso/mv_IC_2ICDIR_${caso}.sh
chmod 755 $DIR_CASES/$caso/mv_IC_2ICDIR_${caso}.sh

sed -e "s@ERRFLAG@${errorflag}@g" $DIR_LND_IC/clm_run_error_touch.sh > $DIR_CASES/$caso/clm_run_error_touch.sh
chmod 755 $DIR_CASES/$caso/clm_run_error_touch.sh

#SED ERROR
rsync -av ${DIR_TEMPL}/env_workflow_land_only.xml $DIR_CASES/$caso/env_workflow.xml
rsync -av ${DIR_TEMPL}/env_batch.xml_${env_workflow_tag} $DIR_CASES/$caso/env_batch.xml

./case.setup --reset
./case.setup
./xmlchange BUILD_COMPLETE=TRUE

# if the IC have already been produced and you are running the script just to complete the CLM analysis run you MUST NOT overwrite the IC
if [[ -f ${check_mv} ]]
then
    ./xmlchange --subgroup case.launch_mvIC prereq=0
    #change prereq to switch off the mv_ic in env_workflow
fi


./case.submit

checktime0=`date`
body="CLM ICs: CLM run forced with EDA${member} data submitted at $checktime0 " 
title="[CLMIC] ${CPSSYS} forecast notification"
${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r yes -s ${yyyy}${st}

