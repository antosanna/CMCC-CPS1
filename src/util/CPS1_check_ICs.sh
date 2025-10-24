#!/bin/sh -l

# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. ${DIR_UTIL}/descr_ensemble.sh 2025
set -euvx

echo "Starting checks on ICs "
# Input **********************
yyyy=$1
st=$2

# CREATE OCEAN ICs anomalies to check state of the ocean
#$DIR_OCE_IC/check_cice_restarts.sh $yyyy $st
$DIR_OCE_IC/check_nemo_restarts.sh $yyyy $st      #~15 '
$DIR_OCE_IC/calc_daily_anom_obs.sh $yyyy $st

mkdir -p $SCRATCHDIR/${typeofrun}/${yyyy}${st}/IC_OCE/
nmb_oce_plot=`ls $SCRATCHDIR/${typeofrun}/${yyyy}${st}/IC_OCE/*png |wc -l`
if [[ ${nmb_oce_plot} -eq 2 ]] ; then
   listafile=`ls $SCRATCHDIR/${typeofrun}/${yyyy}${st}/IC_OCE/*png`
#   body="Dear all, \n
 #  attached you may find the SST anomalies of the ${n_ic_nemo} Nemo IC perturbations together with the observed ones (start-date snapshot, last week, last month).\n\n
  # Thanks \n
  # SPS staff"
  # title="[NEMOIC] ${CPSSYS} forecast notification"
  # $DIR_UTIL/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -a "$listafile"
   . ${DIR_UTIL}/condaactivation.sh
   condafunction activate $envcondarclone
   rclone mkdir my_drive:${typeofrun}/${yyyy}${st}/IC_plots
   for fplot in $listafile 
   do
       rclone copy ${fplot} my_drive:${typeofrun}/${yyyy}${st}/IC_plots
   done
   conda deactivate $envcondarclone
   title="[NEMOIC] ${CPSSYS} forecast notification"
   body="On google drive in the folder ${typeofrun}/${yyyy}${st}/IC_plots you may find the SST anomalies of the ${n_ic_nemo} Nemo IC perturbations together with the observed ones (start-date snapshot, last week, last month)"
   $DIR_UTIL/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
else
   body="Plots to check NEMO ICs not completed. Check log of SPS4_step1_ICs.sh in ${DIR_LOG}/forecast/${yyyy}${st}. \n\n"
   title="[NEMOIC] ${CPSSYS} forecast warning"
   $DIR_UTIL/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
   exit 1
fi
#CHECK SIC IC compared to obs
$DIR_OCE_IC/check_cice_restarts.sh $yyyy $st 
mkdir -p $SCRATCHDIR/${typeofrun}/${yyyy}${st}/IC_CICE/
nmb_ice_plot=`ls $SCRATCHDIR/${typeofrun}/${yyyy}${st}/IC_CICE/*png |wc -l`
if [[ ${nmb_ice_plot} -ge 1 ]] ; then
   listafile=`ls $SCRATCHDIR/${typeofrun}/${yyyy}${st}/IC_CICE/*png`
   . ${DIR_UTIL}/condaactivation.sh
   condafunction activate $envcondarclone
   rclone mkdir my_drive:${typeofrun}/${yyyy}${st}/IC_plots
   for fplot in $listafile 
   do  
       rclone copy ${fplot} my_drive:${typeofrun}/${yyyy}${st}/IC_plots
   done
   conda deactivate $envcondarclone
   title="[CICEIC] ${CPSSYS} forecast notification"
   body="On google drive in the folder ${typeofrun}/${yyyy}${st}/IC_plots you may find the SIC anomalies of the ${n_ic_nemo} CICE IC perturbations with respect to the observed OSISAF estimate (full observed value on top; difference model vs obs on bottom)"
   $DIR_UTIL/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
else
   body="Plots to check CICE ICs not completed. Check log of SPS4_step1_ICs.sh in ${DIR_LOG}/forecast/${yyyy}${st}. \n\n"
   title="[NEMOIC] ${CPSSYS} forecast warning"
   $DIR_UTIL/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
   exit 1
fi


# Andrea - 30/9/2020
#*******graphical check of CLM forcings********
#MB - 19/10/2021

#input="$yyyy $st"
#${DIR_SPS35}/submitcommand.sh -m $machine -q $serialq_m -j launch_plot_clm_forcing_${yyyy}${st} -l $DIR_LOG/forecast/$yyyy$st -d ${DIR_LND_IC} -s launch_plot_clm_forcing_op.sh  -i "$input" 

#*******graphical check of CLM ICs********
#MB - 26/10/2022

#input="$yyyy $st"
#${DIR_SPS35}/submitcommand.sh -m $machine -q $serialq_m -j launch_panplot_clm_op_${yyyy}${st} -l $DIR_LOG/forecast/$yyyy$st -d ${DIR_LND_IC} -s launch_panplot_clm_op.sh  -i "$input" 

#*************************************
# Graphical check of Nemo and CAM ICs
#*************************************
# WORKS ONLY IF ALL PRESENT
input="$yyyy $st"
mkdir -p $DIR_LOG/${typeofrun}/$yyyy$st/IC_CAM 
${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_m -M 3000 -j multipanel_plot_ERA5_ICsCAM_${yyyy}${st} -l $DIR_LOG/${typeofrun}/$yyyy$st/IC_CAM -d $DIR_ATM_IC -s multipanel_plot_ERA5_ICsCAM.sh -i "$input"


exit 0
