#!/bin/sh -l


#source $HOME/.bashrc
#source ${DIR_SPS3}/descr_run_ICs.sh
. $HOME/.bashrc
. ${DIR_SPS3}/descr_run_ICs.sh

set -x

input=$1
scriptdir=$2

tfreq=1

filetype=`echo $input | cut -d '.' -f3`
caso=`echo $input | cut -d '/' -f6`
yyst=`echo $input | cut -d '_' -f2 | cut -c1-4`
st=`echo $input | cut -d '_' -f2 | cut -c5-6`
pp=`echo $input | cut -d '_' -f3 | cut -c1-3`
year=`echo $input | cut -d '.' -f4 | cut -d '-' -f1`
mm=`echo $input | cut -d '.' -f4 | cut -d '-' -f2`

# Controllo le dimensioni dei singoli files

if [ -f $DIR_ROOT/cases/$caso/logs/QC/ocn/check_oce_daily_${yyst}${st}_${pp}_${year}${mm}.txt ] ; then
    rm $DIR_ROOT/cases/$caso/logs/QC/ocn/check_oce_daily_${yyst}${st}_${pp}_${year}${mm}.txt
fi

tot=`cat $DIR_ROOT/scripts_oper/technical_quality_check.txt | grep oce.${filetype}.${mm} | awk {'print $1'}`
dimfil=`ls -l $input | awk {'print $5'}`
    
exit
if [ $dimfil -ne $tot ] ; then
   echo "$dimfil /= $tot (REF)" >> $DIR_ROOT/cases/$caso/logs/QC/ocn/check_oce_daily_${yyst}${st}_${pp}_${year}${mm}.txt
   echo "$input WRONG DIMENSION" >> $DIR_ROOT/cases/$caso/logs/QC/ocn/check_oce_daily_${yyst}${st}_${pp}_${year}${mm}.txt
   exit 90
fi
${scriptdir}/check_value_oce_daily.sh $input $scriptdir

dimcontrol="$input WRONG DIMENSION"
dimlogstat=`cat $DIR_ROOT/cases/$caso/logs/QC/ocn/check_oce_daily_${yyst}${st}_${pp}_${year}${mm}.txt | grep "DIMENSION"`
valcontrol="$input WRONG VALUES"
vallogstat=`cat $DIR_ROOT/cases/$caso/logs/QC/ocn/check_oce_daily_${yyst}${st}_${pp}_${year}${mm}.txt | grep "WRONG VALUES" | uniq -u`

if [ "${dimlogstat}" = "${dimcontrol}" ] ; then
   body="QC ERROR:"$caso" Dimension ERROR in ocn ${filetype}. Check in $DIR_ROOT/cases/$caso/logs/QC/ocn" 
   title="SPS3 forecast ERROR"
   ${DIR_SPS3}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r yes -s $yyst$st
fi

if [ "${vallogstat}" = "${valcontrol}" ] ; then
   body="QC ERROR in $caso WRONG Value in ocn ${filetype}. Check in $DIR_ROOT/cases/$caso/logs/QC/ocn"
   title="SPS3 forecast ERROR"
   ${DIR_SPS3}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r yes -s $yyst$st
fi


