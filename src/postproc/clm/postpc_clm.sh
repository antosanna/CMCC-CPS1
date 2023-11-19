#!/bin/sh -l

#this script can be run in debug mode but always using submitcommand
# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
# load specific libreries for CLM
. ${DIR_TEMPL}/load_nco

set -evxu

ifexistdelete() {
	local filetodelete=$1
	if [ -f $filetodelete ] ; then
   		rm -f $filetodelete
	fi
}


#*************************************************************************
# Input 
#*************************************************************************
debug=${1:-0}
#
#
if [ $debug -eq 1 ]
then
   ic="atm=5,lnd=1,ocn=02"
   caso="sps4_199307_001"
   OUTDIR=/work/csp/sps-dev/CESM2/archive/${caso}/lnd/hist
   mkdir -p $OUTDIR
   outdirC3S=$SCRATCHDIR/test_clm
   mkdir -p $outdirC3S
   running=1
   DIR_LOG=/users_home/csp/mb16318/SPS/SPS4/postproc/CLM/logs
else

#"$ppp $startdate $outdirC3S $ic $DIR_ARCHIVE/$caso/lnd/hist $caso 0"
 
   ppp=$1
   startdate=$2
   outdirC3S=$3  # where python write finalstandardized  output 
   OUTDIR=$4     # output dir of clm DMO
   caso=$5
   check_postpcclm=$6
   checkfile=$7 #$DIR_CASES/$caso/logs/qa_started_${startdate}_0${member}_ok
   running=${8-:0}  # 0 in operational mode
fi
yyyy=`echo "${startdate}" | cut -c1-4`
st=`echo "${startdate}" | cut -c5-6`
pp=`echo $ppp | cut -c2-3` # two digits member ie 001 -> 01
ic="`cat $DIR_CASES/$caso/logs/ic_${caso}.txt`"

#**********************************************************
# Load vars depending on hindcast/forecast
#**********************************************************
set +uexv
$DIR_UTIL/descr_ensemble.sh $yyyy
set -uexv

#file name:$caso.clm2.$ft.$yyyy-$st.zip.nc

type=h1
landcase="clm2.${type}"
rootname=${caso}.${landcase}.zip

#**********************************************************
# Start postprocessing operations only if not already done
#**********************************************************
if [ ! -f $check_postpcclm ]
then

#remap input *************************************************
   export weight_file=$REPOGRID/CAMFV05_2_reg1x1_conserve_C3S.nc"
   CLM_OUTPUT_FV="${OUTDIR}/${rootname}.nc"

# ${caso}.clm2.${filetyp}.nc $caso.clm2.$ft.nc
   clm2_files_number=`ls -1 ${OUTDIR}/${rootname}.nc|wc -l`
   if [ $clm2_files_number -ne 1 ] ; then
      echo "Number of land clm file  ${rootname}.nc "${clm2_files_number}" not equal to expected: 1 "
      echo "Something went wrong in l_archive maybe."
      exit 1
   fi

# C script to compute snow density
   rhosnow_ncap2_script=$DIR_POST/clm/calc_rhosnow4clm.c 

# Define working directories
   DIROUT_REG1x1=${OUTDIR}/reg1x1
   mkdir -p ${DIROUT_REG1x1}

# Define all input and output files
   export CLM_OUTPUT_REG1x1=${DIROUT_REG1x1}/${rootname}.reg1x1.nc
   
   if [[ $debug -ne 0 ]] && [[ -f $CLM_OUTPUT_REG1x1 ]]
   then
      echo "file already regridded"
   else
      # NCO phase - Create new variables - 4 steps
      # (I) H2OSOI
      # for H2OSOI since we need according to C3S Kg/m2 - we use derived H2OSOI = SOILLIQ + SOILICE = [ kg/m2] instead of native H2OSOI  
      cd ${DIROUT_REG1x1}  
      ncap2 -O -s "H2OSOI2=SOILLIQ+SOILICE " ${CLM_OUTPUT_FV} ${CLM_OUTPUT_FV}_tmp_H2OSOI
      mv ${CLM_OUTPUT_FV}_tmp_H2OSOI ${rootname}.tmp_H2OSOI.nc
   
      # (II) SNOW
      ncap2 -O -S ${rhosnow_ncap2_script} ${rootname}.tmp_H2OSOI.nc ${CLM_OUTPUT_FV}_tmp_RHOSNO
      mv ${CLM_OUTPUT_FV}_tmp_RHOSNO ${rootname}.tmp_RHOSNO.nc
   
      # (III) Remove extra vars
      ncks -O -x -v RHOSNO_fresh,RHOSNO_BULK,H2OSNO_fresh,H2OSNO_diff ${rootname}.tmp_RHOSNO.nc ${CLM_OUTPUT_FV}_tmp_rm
      rm ${rootname}.tmp_RHOSNO.nc
   	
      # (IV) Change variable attributes
      ncatted -O -a long_name,H2OSOI,o,c,"Soil water (vegetated landunits only)" ${CLM_OUTPUT_FV}_tmp_rm	
      ncatted -O -a units,H2OSOI,o,c,"kg m-2" ${CLM_OUTPUT_FV}_tmp_rm	
   
      ncatted -O -a long_name,RHOSNO,o,c,"Snow Density" ${CLM_OUTPUT_FV}_tmp_rm	
      ncatted -O -a units,RHOSNO,o,c,"kg m-3" ${CLM_OUTPUT_FV}_tmp_rm	
      export interp_input=${CLM_OUTPUT_FV}_tmp_rm

      # Interpolation phase
      # create interpolated file in ./reg1x1 dir
#     ncl /users_home/csp/mb16318/SPS/SPS4/postproc/CLM/regridFV_1x1_CLM.ncl
      vars=H2OSNO,H2OSOI2,QDRAI,QOVER,RHOSNO
      ncremap -v $vars -m ${weight_file} -i ${interp_input} -o $CLM_OUTPUT_REG1x1 --sgs_frc=${interp_input}/landfrac
      stat=$?      
      if [[ $stat -ne 0 ]]
      then 
          echo "problem in ncremap"
          exit 2
      fi
   

   fi
   
# remove intermidiate output files
   ifexistdelete ${CLM_OUTPUT_FV}_tmp_rm 
   ifexistdelete ${rootname}.tmp_*.nc 
   
#************************************************************************
# Standardize in C3S format
#************************************************************************
# C3S vars    prefix
   prefix="${GCM_name}-v${versionSPS}_${typeofrun}_S${startdate}0100_land_day_"
   suffix="i00p00.nc"
   
# (I) FIRST FORMAT IN C3S STANDARD
   conda activate /work/csp/sp1/anaconda3/envs/CMOR_5
   cd ${DIR_POST}/clm # where python script is
   
   python clm_standardize2c3s.py $startdate $ppp $type $typeofrun $DIROUT_REG1x1 $SPSsystem $outdirC3S $DIR_LOG $REPOGRID $ic $DIR_TEMPL/C3S_globalatt.txt $versionSPS ${DIR_POST}/clm/C3S_table_clm.txt $caso
#   if [ $? -eq 0 ]
#   then
# remove catted product
#      rm $CLM_OUTPUT_FV 
# intermidiate product
#      rm ${DIROUT_REG1x1}/${rootname}.reg1x1.nc
   else
# notificate error
      body="ERROR in postpc_clm.sh during CLM standardization for $caso case. "
      title="${SPSSYS} forecast ERROR "
      ${DIR_SPS35}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" 
      exit 1
   fi  
   
   cd $outdirC3S
   
   set +euvx
   condafunction deactivate CMOR_5 
   set -euvx   

   echo "postpc_clm.sh DONE"
   touch $check_postpcclm
   if [ $running -eq 1 ]  # 0 if running; 1 if off-line
   then
      rm $OUTDIR/$caso.clm2.*
   fi  
else
   body="$startdate postprocessing CLM already completed. \n
         $OUTDIR/${caso}_clm_C3SDONE exists. If you want to recomputed first delete it"
   title="${SPSSYS} FORECAST warning"
   ${DIR_SPS35}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" 
   
fi


cd $outdirC3S   #can be redundant
allC3S=`ls *${pp}i00p00.nc|wc -l`
member=$pp
mkdir -p $DIR_CASES/$caso/logs
# IF ALL VARS HAVE BEEN COMPUTED QUALITY-CHECK
if [ $allC3S -eq $nfieldsC3S ]  && [ ! -f $checkfile ]
then
   ${DIR_SPS35}/submitcommand.sh -m $machine -q $serialq_l -M 3000 -t "24" -r $sla_serialID -S qos_resv -j checker_and_archive_${caso} -l ${DIR_LOG}/$typeofrun/${startdate} -d ${DIR_POST}/C3S_standard -s checker_and_archive.sh -i "$member $outdirC3S $startdate $caso"
fi
echo "$0 completed"
exit 0
