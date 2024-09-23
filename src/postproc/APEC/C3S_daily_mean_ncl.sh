#!/bin/sh -l
#BSUB -q s_long
#BSUB -J C3S_daily_mean
#BSUB -e logs/C3S_daily_mean_%J.err
#BSUB -o logs/C3S_daily_mean_%J.out

. ~/.bashrc
. $DIR_SPS35/descr_SPS3.5.sh
. $DIR_TEMPL/load_cdo
if [[ $machine == "juno" ]]
then
   . $DIR_TEMPL/load_ncl
fi
set -euxv
export member=$1
ens=$member
wkdir=$2
stdate=$3
outdir=$4  
#NEW 202103 !!! position of checkfile
checkfile=$5 
daylist="$6"

#NEW 202103 !!! 
# descr_hindcast.sh o descr_forecast.sh
yyyy=`echo $stdate |cut -c 1-4`
st=`echo $stdate |cut -c 5-6`
set +euvx
if [ $yyyy -lt ${iniy_fore} ]
then
   . ${DIR_SPS35}/descr_hindcast.sh
else
   . ${DIR_SPS35}/descr_forecast.sh
fi
set -euvx
if [ ! -d $wkdir ]
then
   echo "something wrong $wkdir does not exist"
fi
#NEW 202103 !!! +
# condiziona ncl al checkfile
checkncl=$wkdir/C3S_daily_mean_2d.ncl_${member}_ok
varlist="tso tas psl ta zg ua va"
if [ -f $checkncl ] 
then
#se i file C3S ad alta frequenza sono piu' recenti rifai
   cd $WORK_C3S/$stdate/
   for var in $varlist
   do
      file=`ls *${var}_r${member}i00p00.nc`
#      ret=`find -name $file -newer ${checkncl}`
#      if [ "$ret" ==  "./$file" ]
      if [[ $file -nt ${checkncl} ]]
      then
         rm $checkncl
         break 
      fi
   done
fi
if [ ! -f $checkncl ]
then
   cd $wkdir
   ncl 'key_path="C3S_daily_mean.txt"' C3S_daily_mean_2d.ncl
fi


if [ -f $checkncl ]
then
#NEW 202103 !!! +
# condiziona il qa_checker al suo checkfile e spostato il log in $DIR_LOG/$typeofrun
# if $checkfile for quality check exist check if older than corresponding files 
   if [ -f $checkfile ]
   then
      cd $outdir
      for var in $varlist
      do
         file=`ls *${var}_r${member}i00p00.nc`
         if [[ $file -nt ${checkfile} ]]
         then
            rm $checkfile
            break 
         fi
      done
   fi
   if [ ! -f $checkfile ]
   then
#NEW 202103 !!!  -
      $DIR_POST/APEC/launch_c3s_qa_checker_keep_in_archive.sh ${stdate} $member $wkdir $outdir $checkfile "$daylist"
   fi
else # checkncl does not exist
   title="[C3Sdaily 4APEC] SPS3.5 forecast ERROR"
   body="$stdate $member ${DIR_POST}/APEC/C3S_daily_mean_2d.ncl did not complete correctly, launched by ${DIR_POST}/APEC/C3S_daily_mean_ncl.sh. Check ${DIR_LOG}/$typeofrun/${stdate}/launch_C3S_daily_ncl4APEC_${stdate}_0${member}*.err/out"
   ${DIR_SPS35}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
   exit 11
fi
if [ ! -f $checkfile ]
then
   body="Some problem occurred during ${DIR_POST}/APEC/launch_c3s_qa_checker_keep_in_archive.sh for ${SPSsystem}_${stdate}_0${member}. Launched by ${DIR_POST}/APEC/C3S_daily_mean_ncl.sh. Check ${DIR_LOG}/$typeofrun/${stdate}/launch_C3S_daily_ncl4APEC_${stdate}_0${member}*.err/out"
   title="[C3Sdaily 4APEC] SPS3.5 forecast ERROR"
   ${DIR_SPS35}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
   exit 1
fi

echo "That's all Folks"
