#!/bin/sh -l

. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
. ${DIR_UTIL}/load_cdo
set -euvx

yyyy=$1
st=$2 #2 figures
varm=$3  
all=$4
reglist="$5"
ensorgl="$6"
flag_done=${7}
dbg=${8}

set +euvx
. ${DIR_UTIL}/descr_ensemble.sh $yyyy
set -euvx

refperiod=$iniy_hind-$endy_hind
climdir=$WORK_SCORES/monthly/$varm/C3S/clim
pctldir=$WORK_SCORES/pctl
workdir=$SCRATCHDIR/diag_C3S/$varm/$yyyy$st
dirplots=$SCRATCHDIR/diag_C3S/forecast_plots/$yyyy$st
anomdir=$DIR_FORE_ANOM/$yyyy$st
mkdir -p $anomdir $dirplots

if [ $all -eq 3 ] ; then #case all=3 -> compute capsule, anomalies and plot
#       set +e
       ncapsuleyyyystDONE=`ls -1 ${DIR_LOG}/${typeofrun}/$yyyy$st/diagnostics/capsule_${yyyy}${st}_${varm}_DONE* | wc -l`
#       set -e

	      $DIR_DIAG_C3S/C3S_lead2Mmonth_capsule_notify.sh  $yyyy $st $workdir $anomdir $varm $dbg ${DIR_LOG}/${typeofrun}/$yyyy$st/diagnostics
       
       # if this flag is missing: you are running for the first time
       if [ ! -f ${DIR_LOG}/${typeofrun}/$yyyy$st/diagnostics/capsule_${yyyy}${st}_${varm}_DONE ] ; then
#         set +e
         ncapsuleyyyystDONE=`ls -1 ${DIR_LOG}/${typeofrun}/$yyyy$st/diagnostics/capsule_${yyyy}${st}_0??_${varm}_DONE* | wc -l`  
#	        set -e
         #if flags for single members are all present - remove them and put the one for entire startdate
         if [ $ncapsuleyyyystDONE -eq $nrunC3Sfore ] ; then
            rm ${DIR_LOG}/${typeofrun}/$yyyy$st/diagnostics/capsule_${yyyy}${st}_0??_${varm}_DONE*
            touch ${DIR_LOG}/${typeofrun}/$yyyy$st/diagnostics/capsule_${yyyy}${st}_${varm}_DONE

         else 
         #if flags for single members are not all present - something goes wrong! send mail and exit  
            ncapsyyyystDONEfound=`ls -1 ${DIR_LOG}/${typeofrun}/$yyyy$st/diagnostics/capsule_${yyyy}${st}_???_${varm}_DONE | wc -l`            
   	        title="[diags] ${CPSSYS} $typeofrun capsule ERROR"
            body="$ncapsyyyystDONEfound file $varm found of the $nrunC3Sfore expected for $yyyy$st $typeofrun"
            ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r $typeofrun
            exit 1
         fi     
       fi

       #now check if anomalies have been computed -same logic as before
#       set +e
       nanomyyyystDONE=`ls -1 ${DIR_LOG}/${typeofrun}/$yyyy$st/diagnostics/anom_${SPSSystem}_${yyyy}${st}_${varm}_DONE* | wc -l`
#       set -e
       #if this flag is missing - is the first time you run this routine
       $DIR_DIAG_C3S/anom_${CPSSYS}_C3S_notify.sh $yyyy $st $climdir $workdir $anomdir $varm $dbg ${DIR_LOG}/${typeofrun}/$yyyy$st/diagnostics

elif [ $all -eq 2 ] ; then #case all=2  -> compute anomalies +plot
#       set +e
       nanomyyyystDONE=`ls -1 ${DIR_LOG}/${typeofrun}/$yyyy$st/diagnostics/anom_${SPSSystem}_${yyyy}${st}_${varm}_DONE* | wc -l`
#       set -e
        $DIR_DIAG_C3S/anom_${CPSSYS}_C3S_notify.sh $yyyy $st $climdir $workdir $varm $dbg ${DIR_LOG}/${typeofrun}/$yyyy$st/diagnostics
fi 

###FROM HERE - plot routines !!!
 	
if [[ "$varm" == "sst" ]] ; then
   #define dir for ncep obs needed for plot
   ncep_dir=$SCRATCHDIR/ENSO/NCEP
   mkdir -p $ncep_dir

	  $DIR_DIAG_C3S/nino_plume_notify.sh $yyyy $st $workdir $varm $ncep_dir $dbg
	  for ensoreg in $ensorgl ; do
	      $DIR_DIAG_C3S/ENSO_plot_notify.sh $yyyy $st $ensoreg $dirplots $workdir $anomdir $ncep_dir
       $DIR_DIAG_C3S/ENSO_prob_seas_plot.sh $yyyy $st $ensoreg $dirplots $workdir $anomdir
   done
	  nENSOplotDONE=`ls -1 ${dirplots}/${varm}_*Nino*_mem_${yyyy}_${st}_DONE | wc -l`
	  if [[ $nENSOplotDONE -ne 4 ]] ; then 
         title="[diags] ${CPSSYS} $typeofrun ENSO plot ERROR"
	        body="Something in ${DIR_DIAG_C3S}/ncl/ENSO_plot.ncl went wrong"
         ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r $typeofrun
	        rm ${dirplots}/${varm}_*Nino*_mem_${yyyy}_${st}_DONE
	        exit 1
	  fi

   nENSOplotDONE_prob=`ls -1 ${dirplots}/${varm}_*Nino*_prob_${yyyy}_${st}_DONE | wc -l`
   if [[ $nENSOplotDONE_prob -ne 4 ]] ; then 
         title="[diags] ${CPSSYS} $typeofrun ENSO plot ERROR"
         body="Something in ${DIR_DIAG_C3S}/ncl/ENSO_prob_seas_plot.ncl went wrong"
         ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r $typeofrun
         rm ${dirplots}/${varm}_*Nino*_prob_${yyyy}_${st}_DONE
         exit 1
   fi
   if [[ $nENSOplotDONE -eq 4 ]] && [[ $nENSOplotDONE_prob -eq 4 ]] ; then
      list1_nino=$(ls -1 ${dirplots}/${varm}_*Nino*_mem_${yyyy}_${st}.png)     
      list2_nino=$(ls -1 ${dirplots}/${varm}_*Nino*_prob_${yyyy}_${st}.png)
   fi
   if [[ $machine == "zeus" ]] ; then
   #### Now IOD 
     regIOD="IOD"
     dir=$DIR_FORE_ANOM
     dirobs=$SCRATCHDIR/NOAA_SST
     mkdir -p $dirobs
     $DIR_DIAG_C3S/make_update_sst_series.sh $yyyy $st $dirobs
     $DIR_DIAG_C3S/IOD_plot_notify.sh $yyyy $st $regIOD $dir $dirplots $dirobs $anomdir $nrunC3Sfore
     nIODplotDONE=`ls -1 ${dirplots}/sst_IOD_mem_${yyyy}_${st}_DONE | wc -l`
     if [[ $nIODplotDONE -ne 1 ]] ; then 
         title="[diags] ${CPSSYS} $typeofrun IOD plot ERROR"
	        body="Something in $DIR_DIAG_C3S/ncl/IOD_plot.ncl went wrong"
         ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r $typeofrun
         rm ${dirplots}/sst_IOD_mem_${yyyy}_${st}_DONE
	        exit 1
     fi

     $DIR_DIAG_C3S/IOD_prob_seas_plot.sh $yyyy $st $regIOD $dirplots $varm $dir $anomdir $nrunC3Sfore  
     nIODplotDONE_prob=`ls -1 ${dirplots}/sst_IOD_prob_${yyyy}_${st}_DONE | wc -l`
     if [[ $nIODplotDONE_prob -ne 1 ]] ; then
         title="[diags] ${CPSSYS} $typeofrun IOD plot ERROR"
         body="Something in $DIR_DIAG_C3S/ncl/IOD_prob_seas_plot.ncl went wrong"
         ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r $typeofrun
         rm ${dirplots}/sst_IOD_prob_${yyyy}_${st}_DONE
         exit 1
     fi
     
     if [[ $nIODplotDONE -eq 1 ]] && [[ $nIODplotDONE_prob -eq 1 ]] ; then 
         list1_IOD=$(ls -1 ${dirplots}/${varm}_*IOD*_mem_${yyyy}_${st}.png)
         list2_IOD=$(ls -1 ${dirplots}/${varm}_*IOD*_prob_${yyyy}_${st}.png)
     fi
  fi #machine == zeus
fi
#if [ $varm = "mslp" ] ; then
#	./NAO_forecast.sh $yy $st $refperiod $datamm $workdir $mymail
#	./NAO_plot_auto.sh $yy $st 
#fi
mkdir -p $dirplots

for flgmnth in {0..1} ; do
   if [[ $flgmnth -eq 0 ]]  ; then
      leadlist="1 2 3 4"
      flgmnth_fname="seasonal"
   else
      leadlist="1 2 3 4 5 6"
      flgmnth_fname="monthly"
   fi

   $DIR_DIAG_C3S/single_var_forecast_C3S_auto_newproj_notify.sh $yyyy $st $varm "$reglist" $anomdir "$dirplots" $flgmnth ${flgmnth_fname} "$leadlist"
done


# must be loaded here to not raise conflicts among conda envs
. $DIR_UTIL/load_convert
for flgmnth in {0..1} ; do
   if [[ $flgmnth -eq 0 ]]  ; then
      leadlist="1 2 3 4"
      flgmnth_fname="seasonal"
   else
      leadlist="1 2 3 4 5 6"
      flgmnth_fname="monthly"
   fi
  #Controlla se per ciascuna variabile siano state create tutte le mappe
  nregion=`echo ${reglist[@]}|wc -w` # global Tropics NH SH Europe
  nlead=`echo ${leadlist[@]}|wc -w`   # 0 1 2 3  #true for seasonal
  nterc=4   # low_terc mid_terc up_terc terc_summ
  ndiag=2   # ensmean ensspread
  nplotprob=$(($nterc * $nlead * $nregion))   #80 for seasonal
  nplotdet=$(($ndiag * $nlead * $nregion))    #40 for seasonal
  nplotexpected=$(($nplotprob + $nplotdet))   #120 for seasonal 
  nfcplotDONE=`ls -1 ${dirplots}/${varm}_*_${yyyy}_${st}_${flgmnth_fname}_l?_DONE | wc -l`
  if [ $nfcplotDONE -ne $nplotexpected ] ; then
     title="[diags] ${CPSSYS} $typeofrun plot ERROR"
     body="Something in ${DIR_DIAG_C3S}/ncl/forecast_prob_season_lead_newproj.ncl \n or $DIR_DIAG_C3S/ncl/forecast_deterministic_season_lead_newproj.ncl went wrong"
     ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r $typeofrun
     rm ${dirplots}/${varm}_*_${yyyy}_${st}_*l?_DONE
     exit 1
  else
     ##the png files for the website are transfered just if running on zeus by launch_diagnostic_webpage.sh
     if [ $varm = "z500" ] ; then
        list1=$(ls -1 ${dirplots}/hgt500_global_*ens_anom*_${yyyy}_${st}_${flgmnth_fname}_l?.png )
        list2=$(ls -1 ${dirplots}/hgt500_global_*summary*_${yyyy}_${st}_${flgmnth_fname}_l?.png )
        list3=$(ls -1 ${dirplots}/hgt500_global_*prob*_${yyyy}_${st}_${flgmnth_fname}_l?.png )
        list4=$(ls -1 ${dirplots}/hgt500_global_*spread*_${yyyy}_${st}_${flgmnth_fname}_l?.png )
        magick convert $list1 $list2 $list3 $list4 $dirplots/${varm}_${yyyy}_${st}_${flgmnth_fname}.pdf
     else
        list1=$(ls -1 ${dirplots}/${varm}_global_*ens_anom*_${yyyy}_${st}_${flgmnth_fname}_l?.png )
        list2=$(ls -1 ${dirplots}/${varm}_global_*summary*_${yyyy}_${st}_${flgmnth_fname}_l?.png )
        list3=$(ls -1 ${dirplots}/${varm}_global_*prob*_${yyyy}_${st}_${flgmnth_fname}_l?.png )
        list4=$(ls -1 ${dirplots}/${varm}_global_*spread*_${yyyy}_${st}_${flgmnth_fname}_l?.png )

        magick convert $list1 $list2 $list3 $list4 $dirplots/${varm}_${yyyy}_${st}_${flgmnth_fname}.pdf
     fi


     title="[diags] ${CPSSYS} ${varm} $typeofrun notifications plot"
     body="Figures from $typeofrun ${yyyy}${st} and variable ${varm} produced and available here: $dirplots/${varm}_${yyyy}_${st}_${flgmnth_fname}.pdf"
     app="${dirplots}/${varm}_${yyyy}_${st}_${flgmnth_fname}.pdf"
     ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -a $app -r $typeofrun
     rm ${dirplots}/${varm}_*_${yyyy}_${st}_${flgmnth_fname}_l?_DONE
     touch ${flag_done}_${varm}_${flgmnth_fname}
  fi
# WARNING! Waiting for monthly pctls
# sst IOD
  if [[ $varm == "sst" ]]
  then
    if [[ $machine == "zeus" ]]
    then
       magick convert $list1_IOD $list2_IOD ${dirplots}/IOD_${yyyy}_${st}.pdf
       title="[diags] ${CPSSYS} $typeofrun notifications IOD plot"
       body="IOD plots for $typeofrun ${yyyy}${st} produced and avaialble here ${dirplots}/IOD_${yyyy}_${st}.pdf"
       app="${dirplots}/IOD_${yyyy}_${st}.pdf"
       ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -a $app -r $typeofrun
       rm ${dirplots}/sst_IOD_mem_${yyyy}_${st}_DONE
       rm ${dirplots}/sst_IOD_prob_${yyyy}_${st}_DONE
    fi
# sst Nino
     magick convert $list1_nino $list2_nino ${dirplots}/ElNino_${yyyy}_${st}.pdf
     title="[diags] ${CPSSYS} ${typeofrun} notifications ENSO plot"
     body="El Nino indices figures for ${typeofrun} ${yyyy}${st} produced and available here ${dirplots}/ElNino_${yyyy}_${st}.pdf"
     app="${dirplots}/ElNino_${yyyy}_${st}.pdf"
     ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -a $app -r $typeofrun
     rm ${dirplots}/${varm}_*Nino*_mem_${yyyy}_${st}_DONE
     rm ${dirplots}/${varm}_*Nino*_prob_${yyyy}_${st}_DONE
  fi
done
set +euvx
. $DIR_UTIL/condaactivation.sh
condafunction activate $envcondarclone
listafig=`ls ${dirplots}/*${yyyy}_${st}*pdf`
rclone mkdir my_drive:forecast/$yyyy$st/C3S_diags/$varm
for fig in $listafig
do
   rclone copy $fig my_drive:forecast/$yyyy$st/C3S_diags/$varm
   rm $fig
done
set -euvx
title="[diags] ${CPSSYS} ${typeofrun} notifications C3S plots"
body="All figures for ${typeofrun} ${yyyy}${st} produced and available on google drive, directory my_drive:forecast/$yyyy$st/C3S_diags/$varm"
${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r $typeofrun 
