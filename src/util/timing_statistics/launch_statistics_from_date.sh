 #!/bin/sh -l
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

set -euvx
HERE=$PWD
cd $DIR_CASES

listacasi=`ls -d sps4_20260[3-6]_0?? sps4ext_????11_0??`

listalog=""
for caso in $listacasi; do
    listalog="$listalog $(find $DIR_CASES/$caso -path "*/timing/cesm_timing.${caso}.*" -type f | tr '\n' ' ')"
done

loglist1=""
loglist2=""
for log in $listalog; do
    lid=$(basename "$log" | sed -E 's/.*\.([0-9]+\.[0-9]{6}-[0-9]{6})$/\1/')
    datepart=$(echo "$lid" | cut -d. -f2 | cut -d- -f1)
    log_date="20${datepart:0:2}-${datepart:2:2}-${datepart:4:2}"

    if [ "$log_date" \> "2026-02-11" ] && [ "$log_date" \< "2026-05-01" ]; then
        loglist1="$loglist1 $log"
    elif [ "$log_date" \> "2026-04-30" ]; then
        loglist2="$loglist2 $log"
    fi
done

echo "loglist1 (N=$(echo $loglist1 | wc -w)): $loglist1"
echo "loglist2 (N=$(echo $loglist2 | wc -w)): $loglist2"
mkdir -p $SCRATCHDIR/SPS4_timing_statistics/
csvfile1=$SCRATCHDIR/SPS4_timing_statistics/timing_summary_202602-202604.csv
csvfile2=$SCRATCHDIR/SPS4_timing_statistics/timing_summary_202605-202606.csv
if [[ -f  $csvfile1 ]]
then
  rm  $csvfile1
fi

if [[ -f $csvfile2 ]]
then
   rm $csvfile2
fi

$HERE/timing_statistics.sh $loglist1 $csvfile1 
$HERE/timing_statistics.sh $loglist2 $csvfile2


set +euvx
. $DIR_UTIL/condaactivation.sh
condafunction activate $envcondarclone
set -eu
rclone mkdir my_drive:CMCC-SPS4_timining_statistics_Leonardo
rclone copy $csvfile1 my_drive:CMCC-SPS4_timining_statistics_Leonardo/
rclone copy $csvfile2 my_drive:CMCC-SPS4_timining_statistics_Leonardo/
