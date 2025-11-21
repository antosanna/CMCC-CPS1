#!/bin/sh -l

. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
set -euvx

caso=CASO
yyyy=`echo $caso|cut -d '_' -f2 |cut -c1-4`
set +euvx
. $DIR_UTIL/descr_ensemble.sh $yyyy
set -euvx
# dir_cases must be defined for it can be a case run on Leonardo, for which the standard $DIR_CASE/$caso
# was not defined: it will be created inside the following script
dir_cases=dummy_DIR_CASES
mkdir -p $DIR_LOG/$typeofrun/CERISE_phase2_postproc
flag=1
${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_l -M 18000 -d ${DIR_C3S} -j postproc_CERISE_phase2_offline_resume_${caso} -s postproc_CERISE_phase2_offline_resume.sh -l $DIR_LOG/$typeofrun/CERISE_phase2_postproc -i "$caso ${dir_cases} $flag"
