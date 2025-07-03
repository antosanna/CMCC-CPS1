#!/bin/sh -l

#this script can be run in dbg mode but always using submitcommand
# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. ${DIR_UTIL}/load_nco
. ${DIR_UTIL}/load_cdo

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
dbg=0
#
#
if [ $dbg -eq 1 ]
then
   ic="atm=5,lnd=1,ocn=02"
   caso="sps4_199307_001"
   OUTDIR=/work/csp/sps-dev/CESM2/archive/${caso}/lnd/hist
   mkdir -p $OUTDIR
   outdirCERISE=$SCRATCHDIR/test_clm
   mkdir -p $outdirCERISE
   DIR_LOG=/users_home/csp/mb16318/SPS/SPS4/postproc/CLM/logs
   ic="`cat $DIR_CASES/$caso/logs/ic_${caso}.txt`"
else

#"$ppp $startdate $outdirCERISE $ic $DIR_ARCHIVE/$caso/lnd/hist $caso 0"
   CLM_OUTPUT_FV=$1
   ppp=$2
   startdate=$3
   outdirCERISE=$4  # where python write finalstandardized  output 
   caso=$5
   check_postclm=$6
   wkdir=$7
   ic=${8}  
   ftype=${9} #h1 or h3 currently
fi

mkdir -p $SCRATCHDIR/regrid_CERISE/$caso/CLM
yyyy=`echo "${startdate}" | cut -c1-4`
st=`echo "${startdate}" | cut -c5-6`
pp=`echo $ppp | cut -c2-3` # two digits member ie 001 -> 01

#**********************************************************
# Load vars depending on hindcast/forecast
#**********************************************************
set +uexv
. $DIR_UTIL/descr_ensemble.sh $yyyy
set -uexv

#file name:$caso.clm2.$ft.$yyyy-$st.zip.nc

landcase="clm2.${ftype}"
rootname=${caso}.${landcase}.zip

#**********************************************************
# Start postprocessing operations only if not already done
#**********************************************************
if [ ! -f $check_postclm ]
then

#remap input *************************************************
   export weight_file="$REPOGRID/CAMFV05_2_reg1x1_conserve_C3S.nc"
   lsmfile="$REPOGRID/SPS4_C3S_LSM.nc"

# Define working directories
   DIROUT_REG1x1=${wkdir}/reg1x1
   mkdir -p ${DIROUT_REG1x1}

# Define all input and output files
   export CLM_OUTPUT_REG1x1=${DIROUT_REG1x1}/${rootname}.reg1x1.nc
    
   cd ${DIROUT_REG1x1}  
   if [[ $dbg -ne 0 ]] && [[ -f $CLM_OUTPUT_REG1x1 ]]
   then
      echo "file already regridded"
   else
      if [[ $ftype == "h2" ]] ; then
        # create interpolated file in ./reg1x1 dir
        inputf=`basename ${CLM_OUTPUT_FV}`
        rsync -av ${CLM_OUTPUT_FV} ${DIROUT_REG1x1}
        chmod u+rw $DIROUT_REG1x1/${inputf}
        cdo selvar,TSOI ${DIROUT_REG1x1}/$inputf TSOI.nc
# select first 20 levels to make it consistent with H2OSOI
        cdo sellevidx,1/20 TSOI.nc TSOI_cropped.nc
# rename its dimension accordingly to H2OSOI
        ncrename -O -d levgrnd,levsoi TSOI_cropped.nc TSOI_cropped_levsoi.nc
        cdo selvar,H2OSOI ${DIROUT_REG1x1}/$inputf h2osoi.nc
        cdo -O --reduce_dim -sellevidx,1 ${DIROUT_REG1x1}/h2osoi.nc ${DIROUT_REG1x1}/h2osoi_lev.nc
        lev=20
        cdo mulc,$lev ${DIROUT_REG1x1}/h2osoi_lev.nc ${DIROUT_REG1x1}/mrlsl1.nc
        #
        cdo -O --reduce_dim -sellevidx,2 ${DIROUT_REG1x1}/h2osoi.nc ${DIROUT_REG1x1}/h2osoi_lev.nc
        lev=40
        cdo mulc,$lev ${DIROUT_REG1x1}/h2osoi_lev.nc ${DIROUT_REG1x1}/mrlsl2.nc
        #
        cdo -O --reduce_dim -sellevidx,3 ${DIROUT_REG1x1}/h2osoi.nc ${DIROUT_REG1x1}/h2osoi_lev.nc
        lev=60
        cdo mulc,$lev ${DIROUT_REG1x1}/h2osoi_lev.nc ${DIROUT_REG1x1}/mrlsl3.nc
        #
        cdo -O --reduce_dim -sellevidx,4 ${DIROUT_REG1x1}/h2osoi.nc ${DIROUT_REG1x1}/h2osoi_lev.nc
        lev=80
        cdo mulc,$lev ${DIROUT_REG1x1}/h2osoi_lev.nc ${DIROUT_REG1x1}/mrlsl4.nc
        #
        cdo -O --reduce_dim -sellevidx,5 ${DIROUT_REG1x1}/h2osoi.nc ${DIROUT_REG1x1}/h2osoi_lev.nc
        lev=120
        cdo mulc,$lev ${DIROUT_REG1x1}/h2osoi_lev.nc ${DIROUT_REG1x1}/mrlsl5.nc
        #
        cdo -O --reduce_dim -sellevidx,6 ${DIROUT_REG1x1}/h2osoi.nc ${DIROUT_REG1x1}/h2osoi_lev.nc
        lev=160
        cdo mulc,$lev ${DIROUT_REG1x1}/h2osoi_lev.nc ${DIROUT_REG1x1}/mrlsl6.nc
        #
        cdo -O --reduce_dim -sellevidx,7 ${DIROUT_REG1x1}/h2osoi.nc ${DIROUT_REG1x1}/h2osoi_lev.nc
        lev=200
        cdo mulc,$lev ${DIROUT_REG1x1}/h2osoi_lev.nc ${DIROUT_REG1x1}/mrlsl7.nc
        #
        cdo -O --reduce_dim -sellevidx,8 ${DIROUT_REG1x1}/h2osoi.nc ${DIROUT_REG1x1}/h2osoi_lev.nc
        lev=240
        cdo mulc,$lev ${DIROUT_REG1x1}/h2osoi_lev.nc ${DIROUT_REG1x1}/mrlsl8.nc
        #
        cdo -O --reduce_dim -sellevidx,9 ${DIROUT_REG1x1}/h2osoi.nc ${DIROUT_REG1x1}/h2osoi_lev.nc
        lev=280
        cdo mulc,$lev ${DIROUT_REG1x1}/h2osoi_lev.nc ${DIROUT_REG1x1}/mrlsl9.nc
        #
        cdo -O --reduce_dim -sellevidx,10 ${DIROUT_REG1x1}/h2osoi.nc ${DIROUT_REG1x1}/h2osoi_lev.nc
        lev=320
        cdo mulc,$lev ${DIROUT_REG1x1}/h2osoi_lev.nc ${DIROUT_REG1x1}/mrlsl10.nc
        #
        cdo -O --reduce_dim -sellevidx,11 ${DIROUT_REG1x1}/h2osoi.nc ${DIROUT_REG1x1}/h2osoi_lev.nc
        lev=360
        cdo mulc,$lev ${DIROUT_REG1x1}/h2osoi_lev.nc ${DIROUT_REG1x1}/mrlsl11.nc
        #
        cdo -O --reduce_dim -sellevidx,12 ${DIROUT_REG1x1}/h2osoi.nc ${DIROUT_REG1x1}/h2osoi_lev.nc
        lev=400
        cdo mulc,$lev ${DIROUT_REG1x1}/h2osoi_lev.nc ${DIROUT_REG1x1}/mrlsl12.nc
        #
        cdo -O --reduce_dim -sellevidx,13 ${DIROUT_REG1x1}/h2osoi.nc ${DIROUT_REG1x1}/h2osoi_lev.nc
        lev=440
        cdo mulc,$lev ${DIROUT_REG1x1}/h2osoi_lev.nc ${DIROUT_REG1x1}/mrlsl13.nc
        #
        cdo -O --reduce_dim -sellevidx,14 ${DIROUT_REG1x1}/h2osoi.nc ${DIROUT_REG1x1}/h2osoi_lev.nc
        lev=540
        cdo mulc,$lev ${DIROUT_REG1x1}/h2osoi_lev.nc ${DIROUT_REG1x1}/mrlsl14.nc
        #
        cdo -O --reduce_dim -sellevidx,15 ${DIROUT_REG1x1}/h2osoi.nc ${DIROUT_REG1x1}/h2osoi_lev.nc
        lev=640
        cdo mulc,$lev ${DIROUT_REG1x1}/h2osoi_lev.nc ${DIROUT_REG1x1}/mrlsl15.nc
        #
        cdo -O --reduce_dim -sellevidx,16 ${DIROUT_REG1x1}/h2osoi.nc ${DIROUT_REG1x1}/h2osoi_lev.nc
        lev=740
        cdo mulc,$lev ${DIROUT_REG1x1}/h2osoi_lev.nc ${DIROUT_REG1x1}/mrlsl16.nc
        #
        cdo -O --reduce_dim -sellevidx,17 ${DIROUT_REG1x1}/h2osoi.nc ${DIROUT_REG1x1}/h2osoi_lev.nc
        lev=840
        cdo mulc,$lev ${DIROUT_REG1x1}/h2osoi_lev.nc ${DIROUT_REG1x1}/mrlsl17.nc
        #
        cdo -O --reduce_dim -sellevidx,18 ${DIROUT_REG1x1}/h2osoi.nc ${DIROUT_REG1x1}/h2osoi_lev.nc
        lev=940
        cdo mulc,$lev ${DIROUT_REG1x1}/h2osoi_lev.nc ${DIROUT_REG1x1}/mrlsl18.nc
        #
        cdo -O --reduce_dim -sellevidx,19 ${DIROUT_REG1x1}/h2osoi.nc ${DIROUT_REG1x1}/h2osoi_lev.nc
        lev=1040
        cdo mulc,$lev ${DIROUT_REG1x1}/h2osoi_lev.nc ${DIROUT_REG1x1}/mrlsl19.nc
        #
        cdo -O --reduce_dim -sellevidx,20 ${DIROUT_REG1x1}/h2osoi.nc ${DIROUT_REG1x1}/h2osoi_lev.nc
        lev=1140
        cdo mulc,$lev ${DIROUT_REG1x1}/h2osoi_lev.nc ${DIROUT_REG1x1}/mrlsl20.nc
        ncecat mrlsl?.nc mrlsl??.nc H2OSOI.nc
        ncrename -O -d record,levsoi H2OSOI.nc
        ncks --fix_rec_dmn levsoi H2OSOI.nc prova.nc
        ncks --mk_rec_dmn time  prova.nc prova2.nc
        ncpdq -O -a time,levsoi,lat,lon prova2.nc H2OSOI.nc
        cdo selvar,SNOTTOPL ${DIROUT_REG1x1}/$inputf SNOTTOPL.nc
# cat the three vars together
        interp_input=CERISE_${inputf}
        cdo -O merge TSOI_cropped_levsoi.nc H2OSOI.nc SNOTTOPL.nc $interp_input
      elif [[ $ftype == "h3" ]] ; then
        inputfname=`basename ${CLM_OUTPUT_FV}` 
        interp_input=cerise.$inputfname
        ncap2 -O -s "Z0M=Z0MV+Z0MG;Z0H=Z0HV+Z0HG+Z0QV+Z0QG" ${CLM_OUTPUT_FV} ${inputfname}
        cdo -selvar,Z0M,Z0H,TLAI ${inputfname} ${interp_input}
        ncrename -v Z0M,Z0MV -v Z0H,Z0HV ${interp_input}
      fi
      export REMAP_EXTRAP="on"
      cdo remapbil,$REPOGRID1/griddes_C3S.txt ${interp_input} $CLM_OUTPUT_REG1x1 
      if [[ $ftype == "h3" ]] ; then
        outfile=`basename $CLM_OUTPUT_REG1x1`
        mv $outfile tmp.$outfile
        cdo -O merge $SCRATCHDIR/CERISE/PCT_NATVEG_reg1x1_185days.nc tmp.$outfile $CLM_OUTPUT_REG1x1
      fi
   fi
   
# remove intermidiate output files
   ifexistdelete ${rootname}.nc_tmp_rm 
   ifexistdelete ${rootname}.tmp_*.nc 
   
#************************************************************************
# Standardize in C3S format
#************************************************************************
# C3S vars    prefix
   prefix="cmcc_CERISE-${GCM_name}-v${versionSPS}_${typeofrun}_S${startdate}0100"
   
# (I) FIRST FORMAT IN C3S STANDARD
   set +euvx
   
    . $DIR_UTIL/condaactivation.sh
    condafunction activate $envcondaclm
   set -euvx
   cd ${DIR_POST}/clm # where python script is
   python clm_standardize2c3s.py $startdate $ppp $ftype $typeofrun $CLM_OUTPUT_REG1x1 $SPSSystem $outdirCERISE $DIR_LOG $REPOGRID $ic $DIR_TEMPL/CERISE_globalatt.txt ${DIR_POST}/clm/CERISE_table_clm.txt $caso $lsmfile $prefix
   if [ $? -ne 0 ]
   then
# intermidiate product
#      rm ${DIROUT_REG1x1}/${rootname}.reg1x1.nc
#   else
# notificate error
      body="ERROR in postpc_clm.sh during CLM standardization for $caso case. "
      title="${SPSSYS} forecast ERROR "
      ${DIR_SPS35}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "$typeofrun" -s $yyyy$st
      exit 1
   fi  
   
   cd $outdirCERISE
   
   set +euvx
   condafunction deactivate $envcondaclm 
   set -euvx   

   echo "postpc_clm.sh DONE"
   touch ${check_postclm}
   rm -rf $DIROUT_REG1x1
else
   body="$startdate postprocessing CLM already completed. \n
         ${check_postclm} exists. If you want to recomputed first delete it"
   title="${CPSSYS} FORECAST warning"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "$typeofrun" -s $yyyy$st
   
fi

echo "$0 completed"
exit 0
