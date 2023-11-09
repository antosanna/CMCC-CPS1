#!/bin/sh -l

. ~/.bashrc
. $DIR_SPS35/descr_SPS3.5.sh
. ${DIR_TEMPL}/load_cdo
set -euvx

yyyy=$1
st=$2 #2 figures
refperiod=$3
varm=$4  
nrun=$5
all=$6
typefore=$7
export reglist="$8"
ensorgl="$9"
flag_done=${10}
debug=${11}

if [ $yyyy -lt ${iniy_fore} ]
then
   . ${DIR_SPS35}/descr_hindcast.sh
else
   . ${DIR_SPS35}/descr_forecast.sh
fi
climdir=$DIR_CLIM/monthly/$varm/C3S/clim
anomdir=$DIR_CLIM/monthly/$varm/C3S/anom
pctldir=$DIR_CLIM/pctl
workdir=$SCRATCHDIR/diag_C3S/$varm/$yyyy$st
mkdir -p $workdir

if [ $all -eq 3 ] ; then #case all=3 -> compute capsule, anomalies and plot
       set +e
       ncapsuleyyyystDONE=`ls -1 ${DIR_LOG}/${typeofrun}/$yyyy$st/diagnostics/capsule_${yyyy}${st}_${varm}_DONE* | wc -l`
       set -e
       if [ $ncapsuleyyyystDONE -eq 0 ] ; then

	          $DIR_DIAG_C3S/C3S_lead2Mmonth_capsule_notify.sh  $yyyy $st $nrun $workdir $varm $debug ${DIR_LOG}/${typeofrun}/$yyyy$st/diagnostics
       fi
       
       # if this flag is missing: you are running for the first time
       if [ ! -f ${DIR_LOG}/${typeofrun}/$yyyy$st/diagnostics/capsule_${yyyy}${st}_${varm}_DONE ] ; then
         set +e
         ncapsuleyyyystDONE=`ls -1 ${DIR_LOG}/${typeofrun}/$yyyy$st/diagnostics/capsule_${yyyy}${st}_0??_${varm}_DONE* | wc -l`  
	        set -e
         #if flags for single members are all present - remove them and put the one for entire startdate
         if [ $ncapsuleyyyystDONE -eq $nrun ] ; then
            rm ${DIR_LOG}/${typeofrun}/$yyyy$st/diagnostics/capsule_${yyyy}${st}_0??_${varm}_DONE*
            touch ${DIR_LOG}/${typeofrun}/$yyyy$st/diagnostics/capsule_${yyyy}${st}_${varm}_DONE

         else 
         #if flags for single members are not all present - something goes wrong! send mail and exit  
            ncapsyyyystDONEfound=`ls -1 ${DIR_LOG}/${typeofrun}/$yyyy$st/diagnostics/capsule_${yyyy}${st}_???_${varm}_DONE | wc -l`            
   	        title="[diags] ${SPSSYS} $typeofrun capsule ERROR"
            body="$ncapsyyyystDONEfound file $varm found of the $nrun expected for $yyyy$st $typefore"
            ${DIR_SPS35}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" 
            exit 1
         fi     
       fi

       #now check if anomalies have been computed -same logic as before
       set +e
       nanomyyyystDONE=`ls -1 ${DIR_LOG}/${typeofrun}/$yyyy$st/diagnostics/anom_sps_${yyyy}${st}_${varm}_DONE* | wc -l`
       set -e
       #if this flag is missing - is the first time you run this routine
       if [ $nanomyyyystDONE -eq 0 ] ; then
           
	            $DIR_DIAG_C3S/anom_${SPSSYS}_C3S_notify.sh $yyyy $st $refperiod $nrun $climdir $workdir $varm $debug ${DIR_LOG}/${typeofrun}/$yyyy$st/diagnostics
       fi

elif [ $all -eq 2 ] ; then #case all=2  -> compute anomalies +plot
       set +e
       nanomyyyystDONE=`ls -1 ${DIR_LOG}/${typeofrun}/$yyyy$st/diagnostics/anom_sps_${yyyy}${st}_${varm}_DONE* | wc -l`
       set -e
       if [ $nanomyyyystDONE -eq 0 ] ; then
	         $DIR_DIAG_C3S/anom_${SPSSYS}_C3S_notify.sh $yyyy $st $refperiod $nrun $climdir $workdir $varm $debug
       fi	
fi 


###FROM HERE - plot routines !!!
 	
if [[ "$varm" == "sst" ]] ; then
  	export dirplots=$workdir
   #define dir for ncep obs needed for plot
   ncep_dir=$SCRATCHDIR/ENSO/NCEP
   mkdir -p $ncep_dir

	  $DIR_DIAG_C3S/nino_plume_notify.sh $yyyy $st $refperiod $nrun $workdir $varm $ncep_dir $debug
	  for ensoreg in $ensorgl ; do
	      $DIR_DIAG_C3S/ENSO_plot_notify.sh $yyyy $st $ensoreg $dirplots $workdir $ncep_dir
       $DIR_DIAG_C3S/ENSO_prob_seas_plot.sh $yyyy $st $ensoreg $dirplots $workdir
   done
	  nENSOplotDONE=`ls -1 ${dirplots}/${varm}_*Nino*_mem_${yyyy}_${st}_DONE | wc -l`
	  if [[ $nENSOplotDONE -ne 4 ]] ; then 
         title="[diags] ${SPSSYS} $typefore ENSO plot ERROR"
	        body="Something in ${DIR_DIAG_C3S}/ncl/ENSO_plot.ncl went wrong"
         ${DIR_SPS35}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
	        rm ${dirplots}/${varm}_*Nino*_mem_${yyyy}_${st}_DONE
	        exit 1
	  fi

   nENSOplotDONE_prob=`ls -1 ${dirplots}/${varm}_*Nino*_prob_${yyyy}_${st}_DONE | wc -l`
   if [[ $nENSOplotDONE_prob -ne 4 ]] ; then 
         title="[diags] ${SPSSYS} $typefore ENSO plot ERROR"
         body="Something in ${DIR_DIAG_C3S}/ncl/ENSO_prob_seas_plot.ncl went wrong"
         ${DIR_SPS35}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
         rm ${dirplots}/${varm}_*Nino*_prob_${yyyy}_${st}_DONE
         exit 1
   fi
   if [[ $nENSOplotDONE -eq 4 ]] && [[ $nENSOplotDONE_prob -eq 4 ]] ; then
      list1=$(ls -1 ${dirplots}/${varm}_*Nino*_mem_${yyyy}_${st}.png)     
      list2=$(ls -1 ${dirplots}/${varm}_*Nino*_prob_${yyyy}_${st}.png)
      convert $list1 $list2 ${dirplots}/ElNino_${yyyy}_${st}.pdf
      title="[diags] ${SPSSYS} ${typeofrun} notifications ENSO plot"
      body="In allegato le figure per il ${typeofrun} ${yyyy}${st} di El Nino index."
      app="${dirplots}/ElNino_${yyyy}_${st}.pdf"
      ${DIR_SPS35}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -a $app
      rm ${dirplots}/ElNino_${yyyy}_${st}.pdf
      rm ${dirplots}/${varm}_*Nino*_mem_${yyyy}_${st}_DONE
      rm ${dirplots}/${varm}_*Nino*_prob_${yyyy}_${st}_DONE
   fi
   if [[ $machine == "zeus" ]] ; then
   #### Now IOD 
     regIOD="IOD"
     dir=$workdir/anom
     dirobs=$SCRATCHDIR/NOAA_SST
     mkdir -p $dirobs
     $DIR_DIAG_C3S/make_update_sst_series.sh $yyyy $st $dirobs
     $DIR_DIAG_C3S/IOD_plot_notify.sh $yyyy $st $regIOD $dir $dirplots $dirobs $anomdir $nrun
     nIODplotDONE=`ls -1 ${dirplots}/sst_IOD_mem_${yyyy}_${st}_DONE | wc -l`
     if [[ $nIODplotDONE -ne 1 ]] ; then 
         title="[diags] ${SPSSYS} $typefore IOD plot ERROR"
	        body="Something in $DIR_DIAG_C3S/ncl/IOD_plot.ncl went wrong"
         ${DIR_SPS35}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
         rm ${dirplots}/sst_IOD_mem_${yyyy}_${st}_DONE
	        exit 1
     fi

     $DIR_DIAG_C3S/IOD_prob_seas_plot.sh $yyyy $st $regIOD $dirplots $varm $dir $anomdir $nrun  
     nIODplotDONE_prob=`ls -1 ${dirplots}/sst_IOD_prob_${yyyy}_${st}_DONE | wc -l`
     if [[ $nIODplotDONE_prob -ne 1 ]] ; then
         title="[diags] ${SPSSYS} $typefore IOD plot ERROR"
         body="Something in $DIR_DIAG_C3S/ncl/IOD_prob_seas_plot.ncl went wrong"
         ${DIR_SPS35}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
         rm ${dirplots}/sst_IOD_prob_${yyyy}_${st}_DONE
         exit 1
     fi
     
     if [[ $nIODplotDONE -eq 1 ]] && [[ $nIODplotDONE_prob -eq 1 ]] ; then 
         list1=$(ls -1 ${dirplots}/${varm}_*IOD*_mem_${yyyy}_${st}.png)
         list2=$(ls -1 ${dirplots}/${varm}_*IOD*_prob_${yyyy}_${st}.png)
         convert $list1 $list2 ${dirplots}/IOD_${yyyy}_${st}.pdf
         title="[diags] ${SPSSYS} forecast notifications IOD plot"
         body="In allegato le figure per il forecast ${yyyy}${st} di IOD index. \n \n SPS staff"
         app="${dirplots}/IOD_${yyyy}_${st}.pdf"
         ${DIR_SPS35}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -a $app
         rm ${dirplots}/sst_IOD_mem_${yyyy}_${st}_DONE
         rm ${dirplots}/sst_IOD_prob_${yyyy}_${st}_DONE
     fi
  fi #machine == zeus
fi

#if [ $varm = "mslp" ] ; then
#	./NAO_forecast.sh $yy $st $refperiod $datamm $workdir $mymail
#	./NAO_plot_auto.sh $yy $st 
#fi
export dirplots=$workdir
mkdir -p $dirplots

for flgmnth in {0..1} ; do
   if [[ $flgmnth -eq 0 ]]  ; then
      leadlist="1 2 3 4"
      flgmnth_fname="seasonal"
   else
      leadlist="1 2 3 4 5 6"
      flgmnth_fname="monthly"
   fi

   $DIR_DIAG_C3S/single_var_forecast_C3S_auto_newproj_notify.sh $yyyy $st $varm "$reglist" "$dirplots" $flgmnth ${flgmnth_fname} "$leadlist"


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
     title="[diags] ${SPSSYS} $typeofrun plot ERROR"
     body="Something in ${DIR_DIAG_C3S}/ncl/forecast_prob_season_lead_newproj.ncl \n or $DIR_DIAG_C3S/ncl/forecast_deterministic_season_lead_newproj.ncl went wrong"
     ${DIR_SPS35}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
     rm ${dirplots}/${varm}_*_${yyyy}_${st}_*l?_DONE
     exit 1
  else
     ##the png files for the website are transfered just if running on zeus by launch_diagnostic_webpage.sh
     if [ $varm = "z500" ] ; then
        list1=$(ls -1 ${dirplots}/hgt500_global_*ens_anom*_${yyyy}_${st}_${flgmnth_fname}_l?.png )
        list2=$(ls -1 ${dirplots}/hgt500_global_*summary*_${yyyy}_${st}_${flgmnth_fname}_l?.png )
        list3=$(ls -1 ${dirplots}/hgt500_global_*prob*_${yyyy}_${st}_${flgmnth_fname}_l?.png )
        list4=$(ls -1 ${dirplots}/hgt500_global_*spread*_${yyyy}_${st}_${flgmnth_fname}_l?.png )
        convert $list1 $list2 $list3 $list4 $dirplots/${varm}_${yyyy}_${st}_${flgmnth_fname}.pdf
     else
        list1=$(ls -1 ${dirplots}/${varm}_global_*ens_anom*_${yyyy}_${st}_${flgmnth_fname}_l?.png )
        list2=$(ls -1 ${dirplots}/${varm}_global_*summary*_${yyyy}_${st}_${flgmnth_fname}_l?.png )
        list3=$(ls -1 ${dirplots}/${varm}_global_*prob*_${yyyy}_${st}_${flgmnth_fname}_l?.png )
        list4=$(ls -1 ${dirplots}/${varm}_global_*spread*_${yyyy}_${st}_${flgmnth_fname}_l?.png )

        convert $list1 $list2 $list3 $list4 $dirplots/${varm}_${yyyy}_${st}_${flgmnth_fname}.pdf
     fi
     title="[diags] ${SPSSYS} ${varm} $typeofrun notifications plot"
     body="In allegato le figure del $typeofrun ${yyyy}${st} per la variabile ${varm} (solo sul dominio globale)."
     app="${dirplots}/${varm}_${yyyy}_${st}_${flgmnth_fname}.pdf"
     ${DIR_SPS35}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -a $app
     rm $dirplots/${varm}_${yyyy}_${st}_${flgmnth_fname}.pdf
     rm ${dirplots}/${varm}_*_${yyyy}_${st}_${flgmnth_fname}_l?_DONE
     touch ${flag_done}_${varm}_${flgmnth_fname}
  fi
done
