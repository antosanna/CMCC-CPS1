 #!/bin/sh -l
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

set -euvx
HERE=$PWD

cd $DIR_CASES
#yyyy=$1
#st=$2

#listacasi=`ls -d sps4_${yyyy}${st}_0??`
listacasi=`ls -d sps4_20260[3-6]_0?? sps4ext_????11_0??`
listalog=" "
for caso in $listacasi ; do
#   listalog+=` ls $DIR_CASES/$caso/timing/cesm_timing.${caso}.* `

   listalog+=$(find $DIR_CASES/$caso -path "*/timing/cesm_timing.*_??????_0??.*" -type f | tr '\n' ' ')
done

mkdir -p $SCRATCHDIR/SPS4_timing_statistics/
csvfile=$SCRATCHDIR/SPS4_timing_statistics/timing_summary_cmcc_2026.csv
$HERE/timing_statistics.sh $listalog $csvfile

set +euvx
. $DIR_UTIL/condaactivation.sh
condafunction activate $envcondarclone
set -eu
rclone mkdir my_drive:CMCC-SPS4_timining_statistics_Leonardo
rclone copy $csvfile my_drive:CMCC-SPS4_timining_statistics_Leonardo/


