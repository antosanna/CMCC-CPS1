#!/usr/bin/sh -l
. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
set -euvx
#
logdir=$DIR_LOG/hindcastext/rebuild_restart_nemo
mkdir -p $logdir

caso=$1
outdir=$2
# check if already done
if [[ `ls $outdir/${caso}_????????_restart.nc|wc -l` -ne 0 ]]
then
# if so, exit
   exit
fi

wkdir=$outdir/orig_multi_rest
mkdir -p $wkdir
n_rest=`ls $outdir/*_restart_*|wc -l`
if [[ $n_rest -ne 0 ]]
then
   mv $outdir/*_restart_* $wkdir
fi

set +euvx
if [[ $machine == "leonardo" ]]
then
   module purge
   module purge
fi
. $DIR_UTIL/condaactivation.sh 
condafunction deactivate $envcondacm3
condafunction activate $envcondanemo
set -euvx
# add your frequencies and grids. The script skip them if not present
nfile=`ls $wkdir/*_restart*|wc -l`
if [[ $nfile -eq 0 ]]
then
   body="no restart present in $wkdir"
   title="[CPSSYS] EXTENDED FORECAST ISSUE $caso"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r no
   exit
fi
#
data_now=`ls $wkdir/${caso}_????????_restart_0001.nc|rev|cut -d '_' -f3|rev`
# rebuild with python
N=1
$mpirun4py_nemo_rebuild -n $N python $DIR_NEMO_REBUILD/nemo_rebuild.py -i $wkdir/${caso}_${data_now}_restart
#mv to the expected diretory
mv $wkdir/${caso}_${data_now}_restart.nc $outdir
# if correctly merged remove single files
if [[ ! -f $outdir/${caso}_${data_now}_restart.nc ]]
then
   body="restart not correctly rebuilt in $outdir"
   title="[CPSSYS] EXTENDED FORECAST ISSUE $caso"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r no
else
    rm $wkdir/${caso}_${data_now}_restart_0???.nc
fi
