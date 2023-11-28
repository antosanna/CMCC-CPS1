#!/bin/sh -l
#-----------------------------------------------------------------------
# Determine necessary environment variables
#-----------------------------------------------------------------------
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. ${DIR_UTIL}/load_nco

set -euxv
check_pp_monthly=$1
echo "-----------STARTING EXPNAME.l_archive-------- "`date`
cd $DIR_CASES/EXPNAME
ic="DUMMYIC"
DOUT_S_ROOT=`./xmlquery DOUT_S_ROOT|cut -d '=' -f2|cut -d ' ' -f2||sed 's/ //'`
cd $DOUT_S_ROOT/logs
gunzip `ls -1tr atm.log.* |tail -1`
logCAM=`ls -1tr atm.log.* |tail -1`
mese=`grep 'Current date' $logCAM |awk '{print $8}'`
curryear=`grep 'Current date' $logCAM |awk '{print $7}'`
gzip $logCAM
currmon=`printf '%.2d' $mese`
cd $DIR_CASES/EXPNAME

#-----------------------------------------------------------------------
# check presence of TMAX spikes
# KEEP  BUT HOPEFULLY UNNECESSARY
#-----------------------------------------------------------------------
#yyyy=`echo EXPNAME |cut -d '_' -f2|cut -c 1-4`
#st=`echo EXPNAME |cut -d '_' -f2|cut -c 5-6`
#type=h3
#comp=atm
#ens=`echo EXPNAME |cut -d '_' -f3`
#if [ -f $DIR_CASES/EXPNAME/logs/findspikes_ok_${ens} ]
#then 
#   rm $DIR_CASES/EXPNAME/logs/findspikes_ok_${ens}
#fi
#file=EXPNAME.cam.${type}.${curryear}-${currmon}.spikes.nc
#ncrcat -O ${DOUT_S_ROOT}/$comp/hist/EXPNAME.cam.$type.$curryear-$currmon-??-00000.nc ${DOUT_S_ROOT}/$comp/hist/${file}

#set +euvx
#. $DIR_UTIL/condaactivation.sh 
#condafunction activate CHECK_ENV_DEV 
#set -euvx

#checkerversion=c3s_qa_checker.py
#var="TREFMXAV"
#python ${DIR_UTIL}/${checkerversion} ${file} -p ${DOUT_S_ROOT}/$comp/hist/ -v ${var} -l ${DIR_CASES}/EXPNAME/logs/ -exp ${yyyy}${st} -j ${DIR_UTIL}/qa_checker_table.json -real ${ens} --verbose >> ${DIR_CASES}/EXPNAME/logs/log_${var}_spikes_${curryear}-${currmon}
#stat=$?
#if [ $stat -ne 0 ]
#then
#  title="[${SPSSYS}] ${SPSSYS} ERROR"
#  body="In EXPNAME.l_archive ${DIR_UTIL}/${checkerversion} did not complete correctly for EXPNAME, ${curryear}-${currmon}."
#  ${DIR_SPS35}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "yes"
#  exit 6
#fi

#cnterror=`grep FIELDERR ${DIR_CASES}/EXPNAME/logs/log_${var}_spikes_${curryear}-${currmon} | wc -l`
#if [ -f ${DIR_CASES}/EXPNAME/logs/list_spikes_on_ice_${yyyy}${st}_${ens}.txt ] || [ $cnterror -ne 0 ]
#then
#   sed 's/CASO/EXPNAME/g' $DIR_TEMPL/killjobs_spike_and_resub.sh > ${DIR_CASES}/EXPNAME/killjobs_spike_and_resub.sh

#  chmod u+x ${DIR_CASES}/EXPNAME/killjobs_spike_and_resub.sh
#
#  title="[${SPSSYS} spike] ${SPSSYS} warning EXPNAME: RESUBMITTED"
#  body="Found a spike in case EXPNAME during EXPNAME.l_archive. killjobs_spike_and_resub.sh script created and submitted" 
#  ${DIR_SPS35}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "yes"
#  ${DIR_SPS35}/submitcommand.sh -m $machine -q $serialq_s -S qos_resv -r $sla_serialID -j killjob_spike_resub_${yyyy}${st}_${ens} -l $DIR_LOG/spikes/ -d ${DIR_CASES}/EXPNAME -s killjobs_spike_and_resub.sh
#  exit 5
#else
#  touch $DIR_CASES/EXPNAME/logs/findspikes_ok_${ens}
#fi
# now remove catted file
#rm ${DOUT_S_ROOT}/$comp/hist/${file}

#set +uevx
#condafunction deactivate CHECK_ENV_DEV
#set -uevx
#-----------------------------------------------------------------------
# add ic to global attributes of each output file
#-----------------------------------------------------------------------
type=h0
for comp in atm rof lnd
do
   file=$DOUT_S_ROOT/$comp/hist/EXPNAME.$comp.${type}.${curryear}-${currmon}.nc
   nfile=`ls $file|wc -l`
   if [[ $nfile -ne 0 ]]
   then
      pref=`ls $file |rev |cut -d '.' -f1 --complement|rev`
      $compress $file $pref.zip.nc
#   rm $pref.nc  useless because copied from restdir each month
      ncatted -O -a ic,global,a,c,"$ic" $pref.zip.nc
   fi
done
type=h
for comp in ice 
do
   file=$DOUT_S_ROOT/$comp/hist/EXPNAME.$comp.${type}.${curryear}-${currmon}.nc
   nfile=`ls $file|wc -l`
   if [[ $nfile -ne 0 ]]
   then
      pref=`ls $file |rev |cut -d '.' -f1 --complement|rev`
      if [[ ! -f $pref.zip.nc ]] ; then
         $compress $file $pref.zip.nc
         ncatted -O -a ic,global,a,c,"$ic" $pref.zip.nc
         rm $file
      fi
   fi
done

if [[ -d $DOUT_S_ROOT/rest/${curryear}-$currmon-01-00000 ]] ; then
   rm -rf $DOUT_S_ROOT/rest/${curryear}-$currmon-01-00000
fi
# now rebuild EquT from NEMO
yyyy=`./xmlquery RUN_STARTDATE|cut -d ':' -f2|sed 's/ //'|cut -d '-' -f1`
st=`./xmlquery RUN_STARTDATE|cut -d ':' -f2|sed 's/ //'|cut -d '-' -f2`
if [[ `ls $DOUT_S_ROOT/ocn/hist/EXPNAME_1d_${curryear}${currmon}01_${curryear}${currmon}??_grid_EquT_T.zip.nc|wc -l` -eq 0 ]]
then
   $DIR_POST/nemo/rebuild_EquT_1month.sh EXPNAME $yyyy $curryear $currmon "$ic" $DOUT_S_ROOT/ocn/hist
fi
echo "-----------postproc_monthly_EXPNAME.sh COMPLETED-------- "`date`
touch  $check_pp_monthly

exit 0
