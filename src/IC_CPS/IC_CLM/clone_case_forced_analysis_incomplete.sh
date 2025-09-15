#!/bin/sh -l

#This script creates a new CLM forced run from a previous when you have to stop the simulation before the month reaches its end

# EXMAPLE
# starting from 202111 ending 20211127
# RESTART FILE WILL BEAR THE DATE OF THE DAY STILL TO RUN
# (in this case 20211128)

# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

set -exvu

ycurr=$1
mcurr=$2            
lastday=$3         
caso=$4           
refcase=$5
check_mv=$6
icclm=$7
ichydros=$8
member=${9}
errorflag=${10}
backup=${11:-0}

starting_date=$ycurr-$mcurr-01    #2021-11-01
set +euvx
. $DIR_UTIL/condaactivation.sh
condafunction activate $envcondacm3
set -euvx


# Create the new case

# Clone cases
# fix refer to the spectral snow issue fixed by replacing NCEP precip with ECNWF

#WARNING: you cannot clone the same experiment even if from different users.
#Here we use the trick to define a different refcase: at the end we copy as restart files in the run directory those we want actually to use

#THIS WILL CHANGE
	
        #=====================================================#
        #== FIRST PART - create a case =======================#
        #=====================================================#

	#Remove working dir just as a precaution
if [[ -d $WORK_CPS/$caso  ]]
then
   rm -rf $WORK_CPS/$caso
fi
if [[ -d $DIR_CASES/$caso ]] 
then
   rm -rf $DIR_CASES/$caso
fi

#prepare restart to be staged by cesm
chmod u+w $DIR_ARCHIVE/$refcase/rest/${starting_date}-00000
iszip=`ls $DIR_ARCHIVE/$refcase/rest/${starting_date}-00000/*.gz |wc -l`
if [[ $iszip -ne 0 ]]
then
   listarestf=`ls $DIR_ARCHIVE/$refcase/rest/${starting_date}-00000/*.gz`
   for ff in $listarestf
   do
      gunzip $ff
   done
fi


# clone case
 $DIR_CESM/cime/scripts/create_clone --case $DIR_CASES/$caso --clone $DIR_CASES/$refcase
  
cd $DIR_CASES/$caso
mkdir -p $DIR_CASES/$caso/logs

./xmlchange RUN_TYPE=hybrid
./xmlchange RUN_STARTDATE=$starting_date
./xmlchange RUN_REFCASE=${refcase}
./xmlchange RUN_REFDIR="/work/$HEAD/$USER/CMCC-CM/archive/${refcase}/rest/${starting_date}-00000"
./xmlchange RUN_REFDATE=$starting_date
./xmlchange STOP_OPTION=ndays
./xmlchange STOP_DATE=-999
./xmlchange REST_OPTION=ndays
./xmlchange REST_DATE=-999
./xmlchange STOP_N=$lastday
./xmlchange REST_N=$lastday
./xmlchange RESUBMIT=0
#./xmlchange -file env_run.xml -id DIN_LOC_ROOT_CLMFORC -val $DIR_FORC

#rsync -av ${DIR_TEMPL}/env_batch.xml_${env_workflow_tag} $DIR_CASES/$caso/env_batch.xml
rsync -av ${DIR_TEMPL}/env_workflow_land_only.xml $DIR_CASES/$caso/env_workflow.xml

#mv_IC_2ICDIR must be a template to avoid inputs: submission managed by env_workflow 
sed -e "s@CASO@$caso@g;s@YY@${ycurr}@g;s@MM@${mcurr}@g;s@ICCLM@${icclm}@g;s@ICHYD@${ichydros}@g;s@MEMBER@${member}@g;s@CHECKMV@${check_mv}@g;s@LASTDAY@${lastday}@g" $DIR_LND_IC/mv_IC_2ICDIR.sh > $DIR_CASES/$caso/mv_IC_2ICDIR_${caso}.sh
chmod 755 $DIR_CASES/$caso/mv_IC_2ICDIR_${caso}.sh

sed -e "s@ERRFLAG@${errorflag}@g" $DIR_LND_IC/clm_run_error_touch.sh > $DIR_CASES/$caso/clm_run_error_touch.sh
chmod 755 $DIR_CASES/$caso/clm_run_error_touch.sh

# make setup
./case.setup
 
if [[ $backup -eq 1 ]] ; then
   path2change="EDA_n${member}_backup"
   namefile2change="EDA${member}.backup"
   cat $DIR_CASES/$refcase/user_nl_datm_streams | sed -e "s@EDA_n${member}@${path2change}@g;s@EDA${member}@${namefile2change}@g" > $DIR_CASES/$caso/user_nl_datm_streams 

 else
   cp $DIR_CASES/$refcase/user_nl_datm_streams $DIR_CASES/$caso/user_nl_datm_streams
fi  


./xmlchange BUILD_COMPLETE=TRUE  
cp $DIR_EXE/cesm.exe.clm $WORK_CPS/$caso/bld/cesm.exe
#./case.build


./case.submit
exit 0
