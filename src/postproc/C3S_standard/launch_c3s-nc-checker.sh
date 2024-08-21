#!/bin/sh -l
# Load environment
. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/load_nco
set +euvx
  . $DIR_UTIL/condaactivation.sh
  condafunction activate $envcondac3schecker
set -euvx

export C3Stable_cam="$DIR_POST/cam/C3S_table.txt"
export C3Stable_clm="$DIR_POST/clm/C3S_table_clm.txt"
export C3Stable_oce="$DIR_POST/nemo/C3S_table_ocean2d.txt"

# Load input vars
startdate=$1
real=$2
outdirC3S=$3
dir_log_checker=$4
##############################
filedir=$outdirC3S


# real in 2 digits
real=$(printf "%.2d" $((10#${real})))

set +euvx
. $DIR_UTIL/descr_ensemble.sh ${startdate:0:4}
. $dictionary
set -euvx

n_error=0
list_error=""

#Read vars from table
{
read
while IFS=, read -r flname C3S dim lname sname units freq type realm addfact coord cell varflg
do
   varC3S+=" $C3S"
done } < $C3Stable_cam
{
while IFS=, read -r flname C3S vtype dim lname sname units freq type realm coord cell
do
   varC3S+=" $C3S"
done } < $C3Stable_clm
{
read
while IFS=, read -r flname C3S lname sname units realm level expr coord cell rlev model
do
   varC3S+=" $C3S"
done } < $C3Stable_oce


cd ${filedir}
for var in ${varC3S[@]};
do

    filename=`ls -1 cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${startdate}0100_*_${var}_r${real}i00p00.nc`
    

    #$c3s_checker_cmd -p $filename >& $dir_log_checker/${c3s_checker_cmd}_${var}_${startdate}_0${real}.log
    set +e
    $c3s_checker_cmd $filename >& $dir_log_checker/${c3s_checker_cmd}_${var}_${startdate}_0${real}.log
    if [[ $? -eq 1 ]] ; then
      echo "error for $var"
    fi
    set -e
    # python writes an error or ok file
    #ERROR string present 2 times anyway - even if test is passed
    #one option is evaluate ERROR -gt 2
    #n_error=`grep ERROR $dir_log_checker/${c3s_checker_cmd}_${var}_${startdate}_0${real}.log|wc -l`
    #alternative approach:
    n_error=`grep 'Failed tests:' $dir_log_checker/${c3s_checker_cmd}_${var}_${startdate}_0${real}.log|rev|cut -d ':' -f1|rev` 
    tracepy_error=`grep 'Traceback' $dir_log_checker/${c3s_checker_cmd}_${var}_${startdate}_0${real}.log |wc -l`
    syspy_error=`grep 'sys.exit' $dir_log_checker/${c3s_checker_cmd}_${var}_${startdate}_0${real}.log |wc -l`
 
    #evaluate following string" ERROR    |     Failed tests: 0" - if 0 ok, otherwise problems
    echo "$n_error found for var ${var}"
    if [[ $n_error -gt 0 ]] || [[ ${tracepy_error} -gt 0 ]] || [[ ${syspy_error} -gt 0 ]]  
    then
        list_error+=" ${c3s_checker_cmd}_${var}_${startdate}_0${real}.log"
    fi

done
set +evxu
  condafunction deactivate $envcondac3schecker
set -euvx

# If ERRORs encountered, then send a mail
if [[ $list_error != "" ]];then
    body="C3S standardization of member ${SPSSystem}_${startdate}_0${real} has reported `echo $list_error|wc -w` errors in ${c3s_checker_cmd} checker. Logs are: $dir_log_checker: $list_error 
"
    title="${CPSSYS} ${typeofrun} ERROR - ${c3s_checker_cmd} CHECK"
    ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r yes -s $startdate
    touch $check_c3s_meta_err
    exit 0
else
    touch $check_c3s_meta_ok
fi

exit 0
