#!/bin/sh -l
. $HOME/.bashrc
# load variables from descriptor
. $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/load_cdo
. $DIR_UTIL/load_nco

caso=$1
export ic=$2
export outdirC3S=$3
INPUT=$4
running=$5    # 0 if running; 1 if off-line

set -exuv
func_error_dims () {
local dir2examine=$1
# initialize associative arrays for storing conf interval values
declare -A std_d
declare -A mean_d
declare -A upper2s
declare -A lower2s
archive_size_stats_file=$DIR_TEMPL/archive_size_stats.csv
if [ ! -f  $archive_size_stats_file ]; then
   echo "File $archive_size_stats_file not exist. Exit"
   exit 1
fi

lines=0
echo "Reading from $archive_size_stats_file"
while IFS="," read -r dir mean std reminder
do
   lines=$(( $lines + 1 ))
   std_d["$dir"]=$std
   mean_d["$dir"]=$mean
   echo ""
   # python return 2 numbers, 1st is upper limit, 2nd lower limit
   INTERVALS=$(calcinterval ${mean_d[$dir]} ${std_d[$dir]} )
   upper2s["$dir"]=`echo $INTERVALS | awk '{print $1}'`
   lower2s["$dir"]=`echo $INTERVALS | awk '{print $2}'`
   echo "${dir},${mean_d[$dir]},${std_d[$dir]} LIMITS: ${lower2s[$dir]},${upper2s[$dir]}"
done < "${archive_size_stats_file}"

# count words of mandatory_dirs
# check that all mandatory dir are in the csvdir
arr1=`echo ${mandatory_dirs} ${csvdir} ${csvdir} | tr ' ' '\n' | sort | uniq -u `
if [[ ! -z $arr1 ]];then
   body="Stop $DIR_UTIL/mv_case2_archive.sh for case $caso mandatory_dirs in $DIR_ARCHIVE/$caso are more than csvdir defined in ${archive_size_stats_file}"
   echo $body
   title="${CPSSYS} ERROR - mv_case2archive.sh $caso "
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
   exit 1
fi
size_error=0
listdir=" "
for dir in $dir2examine
do
 # first check if mandatory dir exist
   if [ ! -d $DIR_ARCHIVE/$caso/${dir} ]; then
      echo "ERROR CHECK $DIR_ARCHIVE/$caso/${dir} ${dir} not exist!!!! "
      listdir+=" $dir NOT EXISTENT "
      size_error+=$(( $size_error + 1 ))
      continue
   fi

   size=0
   size=`du -h --block-size=1K --max-depth=0 $DIR_ARCHIVE/$caso/${dir}/ | awk '{ print $1}'`
   FLAGERROR=0
   FLAGERROR=$(checkifoutofintervals ${lower2s[$dir]}  ${upper2s[$dir]} $size)
done
}
checkifoutofintervals () {
# check if float number is in interval
local lower=$1
local upper=$2
local size=$3
PY_AR1=$lower PY_AR2=$upper PY_AR3=$size  python - << EOF
import os
lower = float(os.environ['PY_AR1'])
upper = float(os.environ['PY_AR2'])
size = float(os.environ['PY_AR3'])
error = 0
if ( size < lower or size > upper ): error = 1
print(error)
EOF
}
calcinterval () {
# calc 4sigmas flaot intervals for given mean and std
local mean=$1
local std=$2
PY_AR1=$mean PY_AR2=$std  python - << EOF
import os
mean = float(os.environ['PY_AR1'])
std = float(os.environ['PY_AR2'])
upper = mean + 3 * std
lower = mean - 3 * std
print("%.1f" % upper,"%.1f" % lower)
EOF
}


archive_oce_ok=$DIR_CASES/$caso/logs/archive_${caso}_oce_DONE
ens=`echo $caso|cut -d '_' -f3|cut -c 2,3`
export C3S_table_ocean2d="$DIR_POST/nemo/C3S_table_ocean2d.txt"
export real="r"${ens}"i00p00"
export st=`echo $caso|cut -d '_' -f 2|cut -c 5-6`
export yyyy=`echo $caso|cut -d '_' -f 2|cut -c 1-4`
. $DIR_UTIL/descr_ensemble.sh $yyyy
set -euvx

export lsmfile="$REPOGRID/lsm_${SPSSystem}_cam_h1_reg1x1_0.5_359.5.nc"
export meshmaskfile="$REPOSITORY/mesh_mask_from2000.nc"
export srcGridName="$REPOSITORY/ORCA_SCRIP_gridT.nc"
export dstGridName="$REPOSITORY/World1deg_SCRIP_gridT.nc"
export wgtFile="$REPOSITORY/ORCA_2_World_SCRIP_gridT.nc"
export C3Satts="$DIR_TEMPL/C3S_globalatt.txt"
export yyyytoday=`date +%Y`
export mmtoday=`date +%m`
export ddtoday=`date +%d`
export Htoday=`date +%H`
export Mtoday=`date +%M`
export Stoday=`date +%S`
cd $INPUT
#TAKES 3'
if [ $running -eq 0 ]
then
   inputlist=`ls ${caso}*_1m_*grid_T.nc`
else    # from archive
   inputlist=`ls ${caso}*_1m_*grid_T.zip.nc`
fi
input=${caso}_1m_grid_T.nc
#echo 'inizio ncrcat ' `date`
if [ ! -f $input ]
then
   ncrcat -O $inputlist $input
fi
#echo 'fine ncrcat ' `date`
scriptname=interp_ORCA2_1X1_gridT2C3S.ncl

#this one will be compressed via ncks at the end
prefix=`sed -n 4p $DIR_TEMPL/C3S_globalatt.txt |cut -d '=' -f2|cut -d ':' -f1|awk '{$1=$1};1'`
export fore_type=$typeofrun
export frq="mon"
export level="ocean2d"

export ini_term="cmcc_${prefix}_${typeofrun}_S${yyyy}${st}0100"

export inputfile=$INPUT/$input

#cp ${DIR_POST}/nemo/$scriptname $INPUT
echo "---------------------------------------------"
echo "launching $scriptname "`date`
echo "---------------------------------------------"
ncl ${DIR_POST}/nemo/$scriptname
echo "---------------------------------------------"
echo "executed $scriptname "`date`
echo "---------------------------------------------"
if [ ! -f $outdirC3S/interp_ORCA2_1X1_gridT2C3S.ncl_${real}_ok ]
then
    title="[C3S] ${CPSSYS} forecast ERROR"
    body="ERROR in standardization of ocean files for case $caso. 
            Script is ${DIR_POST}/nemo/$scriptname"
    exit 1
else
    rm $input
fi
# 
{
read 
while IFS=, read -r flname C3S lname sname units realm levelin addfact coord cell reflev model fillval
do
   model="$model"
   if [[ $model == "nemo" ]]
   then
      varout+=("$C3S")
   fi
done } < $C3S_table_ocean2d
for v in ${varout[@]}
do 
   C3Sfile=$outdirC3S/${ini_term}_ocean_${frq}_${level}_${v}_r${ens}i00p00.nc
   if [ ! -f $C3Sfile ]
   then
      title="${CPSSYS} forecast ERROR"
      body="C3S ocean file $C3Sfile for variable not produced for case $caso. 
            Script is ${DIR_POST}/nemo/$scriptname"
      ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
      exit 1
   fi
done  
if [ $running -eq  0 ]
then
   cd $INPUT
   inputlist=`ls *1[md]*grid_T.nc`
   for input in $inputlist
   do
      rootname=`basename $input |rev |cut -d '.' -f1 --complement|rev`
      $compress $input ${rootname}.zip.nc
      ncatted -O -a ic,global,a,c,"$ic" ${rootname}.zip.nc
# TEMPORARY
      rm -f $input 
   done
   inputlist=`ls *1[m]*grid_[UVW].nc`
   for input in $inputlist
   do
      rootname=`basename $input |rev |cut -d '.' -f1 --complement|rev`
      $compress $input ${rootname}.zip.nc
      ncatted -O -a ic,global,a,c,"$ic" ${rootname}.zip.nc
      rm -f $input 
   done
   inputlist=`ls *1d_*grid_Tglobal.nc`
   for input in $inputlist
   do
      rootname=`basename $input |rev |cut -d '.' -f1 --complement|rev`
      $compress $input ${rootname}.zip.nc
      ncatted -O -a ic,global,a,c,"$ic" ${rootname}.zip.nc
      rm -f $input 
   done
   
   if [ `ls $DIR_ARCHIVE/$caso/ocn/hist/${caso}*zip.nc|wc -l` -ne 0 ] 
   then
#      chmod -R u+rw $ARCHIVE/$caso
#      rsync -auv --remove-source-files $DIR_ARCHIVE/$caso/ocn/hist/${caso}*zip.nc $ARCHIVE/$caso/ocn/hist/
      chmod -R u+rw $FINALARCHIVE/$caso
      mkdir -p $FINALARCHIVE/$caso/ocn/hist
      func_error_dims "ocn"
      if [[ $FLAGERROR -ne 0 ]]
      then
         title="${CPSSYS} forecast ERROR"
         body="ERROR in archiving ocean files for case $caso. Dimensions are not the expected ones"
         exit 1
      fi     
      rsync -auv --remove-source-files $DIR_ARCHIVE/$caso/ocn/hist/${caso}*zip.nc $FINALARCHIVE/$caso/ocn/hist/
      touch  $archive_oce_ok
   fi  
elif [ $running -eq 1 ]  # 0 if running; 1 if off-line
then
   mkdir -p $FINALARCHIVE/$caso/ocn/hist/
   rsync -auv --remove-source-files $DIR_ARCHIVE/$caso/ocn/hist/${caso}*zip.nc $FINALARCHIVE/$caso/ocn/hist/
   touch  $archive_oce_ok
   rm -f $INPUT/${caso}_*grid_T*
fi
exit 0
