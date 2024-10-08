#!/bin/sh -l

. ~/.bashrc
. $DIR_SPS35/descr_SPS3.5.sh
. $DIR_TEMPL/load_cdo
. $DIR_TEMPL/load_nco

set -euvx

yyyy=$1
st=$2 
export varm=$3  # var name in the model
dirlog=$4
filetype=$5
make_statistics=${6}
make_anom=${7}
make_plot=${8}
flag_done=${9}
dbg=${10}
#
climdir=$DIR_CLIM/daily/$varm 
refperiod=$iniy_hind-$endy_hind

if [ $yyyy -lt ${iniy_fore} ]
then
   . ${DIR_SPS35}/descr_hindcast.sh
else
   . ${DIR_SPS35}/descr_forecast.sh
fi


workdir=$SCRATCHDIR/diag_oce/$varm/${yyyy}${st}/
mkdir -p $workdir

set +e
ncapsuleyyyystDONE=`ls -1 $dirlog/capsule_${yyyy}${st}_oce_${varm}_DONE* | wc -l`
set -e

#ANTO AND ZHIQI 20220221+
###
#we have to keep the 50 DMOs that actually has been considered for C3S (i.e. before possible renumbering). If one member did not conclude the run (tagged 01-50), it could be possible that even in $DIR_ARCHIVE/$caso/ocn/hist the needed input files are not available 
###
# THIS IS NOT NEEDED ANYMORE because now there is the removal of extramembers in change_realization so that at this point we only have the correct members in the correct order from 1 to $nrunC3Sfore
#
#lista_ens=`ls -ltr $WORK_C3S/$yyyy$st/all_checkers_ok_0?? |head -n $nrunC3Sfore |rev |cut -d '_' -f1 |rev `
#lista_ens=`ls -1tr $WORK_C3S/$yyyy$st/all_checkers_ok_0?? |head -n $nrunC3Sfore |rev |cut -d '_' -f1 |rev `
lista_ens=`ls -1 $WORK_C3S1/$yyyy$st/all_checkers_ok_0?? |head -n $nrunC3Sfore |rev |cut -d '_' -f1 |rev `
#ANTO AND ZHIQI 20220221-

if [ $ncapsuleyyyystDONE -eq 0 ] ; then
   for ppp in $lista_ens ; do
	      workdir_ens=$SCRATCHDIR/diag_oce/$varm/${yyyy}${st}/${ppp}
       mkdir -p $workdir_ens
       if [[ ! -f $dirlog/capsule_${yyyy}${st}_${ppp}_oce_${varm}_DONE ]]
       then
		        input="$yyyy $st $ppp $workdir_ens $workdir $varm $dirlog $filetype"
          $DIR_SPS35/submitcommand.sh -S $qos -M 20000 -m $machine -q $serialq_m -j C3S_lead2Mmonth_capsule_oce_${yyyy}${st}_${ppp} -l $dirlog -d ${DIR_DIAG_C3S} -s C3S_lead2Mmonth_capsule_oce.sh -i "$input"
       fi
		     while `true` ; do
           ncapsjob=`$DIR_SPS35/findjobs.sh -m $machine -n capsule_oce -c yes`
           if [ $ncapsjob -lt $nrunC3Sfore ] ; then
				          break
			        fi
		         sleep 6
		      done
   done #end loop over members

   # Check if no other capsule jobs are still running
   while `true` ; do

      ncapsjob=`$DIR_SPS35/findjobs.sh -m $machine -n capsule_oce -c yes`
	     if [ $ncapsjob -eq 0 ] ; then
		       break
      fi
	     sleep 60
   done      
fi

      
echo "End loop over Members"
if [ ! -f ${dirlog}/capsule_${yyyy}${st}_oce_${varm}_DONE ] ; then
    set +e
    ncapsuleyyyystDONE=`ls -1 $dirlog/capsule_${yyyy}${st}_???_oce_${varm}_DONE* | wc -l`
    set -e
    if [ $ncapsuleyyyystDONE -eq $nrunC3Sfore ] ; then
       rm $dirlog/capsule_${yyyy}${st}_???_oce_${varm}_DONE*
       touch $dirlog/capsule_${yyyy}${st}_oce_${varm}_DONE
    else
      	ncapsyyyystDONEfound=`ls -1 $dirlog/capsule_${yyyy}${st}_???_oce_${varm}_DONE | wc -l`
 	     ###SENDMAIL
       title="[diags OCE] ${SPSSYS} ${typeofrun} capsule ERROR"
       body="$ncapsyyyystDONEfound file $varm found of the $nrunC3Sfore expected for $yyyy$st $typeofrun"
       ${DIR_SPS35}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r $typeofrun
       exit 1
    fi
fi 

if [ $make_anom -eq 1 ] ; then
	  $DIR_DIAG_C3S/anom_${SPSSYS}_oce.sh $yyyy $st $refperiod $nrunC3Sfore $climdir $varm $workdir $dbg
fi

if [ $make_plot -eq 1 ] ; then
   export yyyyfore=$yyyy
   export mmfore=$st
   export diroce="$DIR_FORE_ANOM"
   export maskoce="$REPOSITORY/mesh_mask_from2000.nc"
   export dirlogo="$DIR_DIAG_C3S/ncl/"
   export plname="$workdir/temperature_pac_trop_ensmean_${yyyyfore}_${mmfore}"

   ncl $DIR_DIAG_C3S/ncl/T_prof_forecast_movie.ncl
   if [ -f ${plname}.gif ] ; then
      touch ${flag_done}_OCE
      rm $diroce/${varm}_${SPSSYS}_sps_${yyyyfore}${mmfore}_spread_ano.$refperiod.nc
      rm $diroce/${varm}_${SPSSYS}_sps_${yyyyfore}${mmfore}_ens_ano.$refperiod.nc
      rm $diroce/${varm}_${SPSSYS}_sps_${yyyyfore}${mmfore}_all_ano.$refperiod.nc
   else
     title="[diags-oce] ${SPSSYS} ${typeofrun} ERROR"
     body=" Something goes wrong with ocean diagnostic plots ($DIR_DIAG_C3S/ncl/T_prof_forecast_movie.ncl). \n" 
     ${DIR_SPS35}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"-r $typeofrun
     exit 1   
   fi
fi
