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


$HERE/timing_statistics.sh $listalog $HERE/timing_summary_cmcc_2026.csv
