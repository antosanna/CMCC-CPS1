#!/bin/sh -l

#this script can be run in debug mode but always using submitcommand
# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. ${DIR_UTIL}/load_nco

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
debug=0
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
   CLM_OUTPUT_FV=$1 
   ppp=$2
   startdate=$3
   outdirC3S=$4  # where python write finalstandardized  output 
   caso=$5
   check_postclm=$6
   check_qa_start=$7 #$DIR_CASES/$caso/logs/qa_started_${startdate}_0${member}_ok
   wkdir=$8
   running=${9-:0}  # 0 in operational mode
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
if [ ! -f $check_postclm ]
then

#remap input *************************************************
   export weight_file="$REPOGRID/CAMFV05_2_reg1x1_conserve_C3S.nc"
   lsmfile="$REPOGRID/SPS4_C3S_LSM.nc"

# C script to compute snow density
   rhosnow_ncap2_script=$DIR_POST/clm/calc_rhosnow4clm.c 

# Define working directories
   DIROUT_REG1x1=${wkdir}/reg1x1
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
      ncap2 -O -s "H2OSOI2=SOILLIQ+SOILICE " ${CLM_OUTPUT_FV} ${rootname}.nc_tmp_H2OSOI
      mv ${rootname}.nc_tmp_H2OSOI ${rootname}.tmp_H2OSOI.nc
   
      # (II) SNOW
      ncap2 -O -S ${rhosnow_ncap2_script} ${rootname}.tmp_H2OSOI.nc ${rootname}.nc_tmp_RHOSNO
      mv ${rootname}.nc_tmp_RHOSNO ${rootname}.tmp_RHOSNO.nc
   
      # (III) Remove extra vars
      ncks -O -x -v RHOSNO_fresh,RHOSNO_BULK,H2OSNO_fresh,H2OSNO_diff ${rootname}.tmp_RHOSNO.nc ${rootname}.nc_tmp_rm
      rm ${rootname}.tmp_RHOSNO.nc
   	
      # (IV) Change variable attributes
      ncatted -O -a long_name,H2OSOI,o,c,"Soil water (vegetated landunits only)" ${rootname}.nc_tmp_rm	
      ncatted -O -a units,H2OSOI,o,c,"kg m-2" ${rootname}.nc_tmp_rm	
   
      ncatted -O -a long_name,RHOSNO,o,c,"Snow Density" ${rootname}.nc_tmp_rm	
      ncatted -O -a units,RHOSNO,o,c,"kg m-3" ${rootname}.nc_tmp_rm	
      export interp_input=${rootname}.nc_tmp_rm

      # Interpolation phase
      # create interpolated file in ./reg1x1 dir
      vars=H2OSNO,H2OSOI2,QDRAI,QOVER,RHOSNO
      ncremap -v $vars -m ${weight_file} -i ${interp_input} -o $CLM_OUTPUT_REG1x1 --sgs_frc=${interp_input}/landfrac
   

   fi
   
# remove intermidiate output files
   ifexistdelete ${rootname}.nc_tmp_rm 
   ifexistdelete ${rootname}.tmp_*.nc 
   
#************************************************************************
# Standardize in C3S format
#************************************************************************
# C3S vars    prefix
   prefix="cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${startdate}0100"
   
# (I) FIRST FORMAT IN C3S STANDARD
   set +euvx
   
    . $DIR_UTIL/condaactivation.sh
    condafunction activate $envcondaclm
   set -euvx
   cd ${DIR_POST}/clm # where python script is
   
   python clm_standardize2c3s.py $startdate $ppp $type $typeofrun $CLM_OUTPUT_REG1x1 $SPSSystem $outdirC3S $DIR_LOG $REPOGRID $ic $DIR_TEMPL/C3S_globalatt.txt ${DIR_POST}/clm/C3S_table_clm.txt $caso $lsmfile $prefix
   if [ $? -ne 0 ]
   then
# intermidiate product
#      rm ${DIROUT_REG1x1}/${rootname}.reg1x1.nc
#   else
# notificate error
      body="ERROR in postpc_clm.sh during CLM standardization for $caso case. "
      title="${SPSSYS} forecast ERROR "
      ${DIR_SPS35}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" 
      exit 1
   fi  
   
   cd $outdirC3S
   
   set +euvx
   condafunction deactivate $envcondaclm 
   set -euvx   

   echo "postpc_clm.sh DONE"
   touch ${check_postclm}
   #if [ $running -eq 1 ]  # 0 if running; 1 if off-line
   #then
   #   rm $OUTDIR/$caso.clm2.*
   #fi  
else
   body="$startdate postprocessing CLM already completed. \n
         ${check_postpcclm} exists. If you want to recomputed first delete it"
   title="${CPSSYS} FORECAST warning"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" 
   
fi


cd $outdirC3S   #can be redundant
allC3S=`ls *${pp}i00p00.nc|wc -l`
member=$pp
mkdir -p $DIR_CASES/$caso/logs
# IF ALL VARS HAVE BEEN COMPUTED QUALITY-CHECK
#check_qa_start=$DIR_CASES/$caso/logs/qa_started_${startdate}_0${member}_ok
# get from $dictionary
set +euvx
. $dictionary
set -euvx
if [ $allC3S -eq $nfieldsC3S ]  && [ ! -f $check_qa_start ]
then
# TEMPORARY UNTIL IMPLEMENTATION OF CHECKER
   body="Temporary exit in $DIR_POST/clm/postpc_clm.sh before $DIR_C3S/checker_and_archive.sh until the implementation of the checker has been done"
   title="[CPS1] warning! $caso exiting before $DIR_C3S/checker_and_archive.s"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "yes"
   exit
   ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_l -M 3000 -t "24" -S qos_resv -j checker_and_archive_${caso} -l ${DIR_LOG}/$typeofrun/${startdate} -d ${DIR_POST}/C3S_standard -s checker_and_archive.sh -i "$member $outdirC3S $startdate $caso"
fi
echo "$0 completed"
exit 0
