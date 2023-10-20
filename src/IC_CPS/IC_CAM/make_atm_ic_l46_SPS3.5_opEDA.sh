#!/bin/sh -l
#BSUB -J test_EDA2CAM
#BSUB -e /users_home/csp/sps-dev/SPS/CMCC-SPS3.5/work/ANTO/developSPS3.5/IC_CAM/logs/test_EDA2CAM_%J.err
#BSUB -o /users_home/csp/sps-dev/SPS/CMCC-SPS3.5/work/ANTO/developSPS3.5/IC_CAM/logs/test_EDA2CAM_%J.out
#BSUB -P 0490

# load variables from descriptor
set +euvx
. $HOME/.bashrc
. ${DIR_SPS35}/descr_SPS3.5.sh
. $DIR_TEMPL/load_cdo
. $DIR_TEMPL/load_nco
set -euvx

debug=0
if [[ `whoami` == "$operational_user" ]]
then
   debug=0
fi

if [[ $debug -eq 1 ]]
then
   yyin=2022    # IC year
   mmin=04    # IC month; this is not a number (2 digits)
   dd=09
   tstamp=00 
   st=05
   yyyy=2022
   ppland=4 
   bk=1 
   iniICfile=$IC_CAM_SPS_DIR/$st/${SPSSYS}.EDAcam.i.$yyyy$st
   bkoce=${IC_SPS_guess}/NEMO/$st/${yyyy}${st}0100_R025_09_restart_oce_modified.bkup.nc
   bkice=${IC_SPS_guess}/NEMO/$st/ice_ic${yyyy}${st}_09.bkup.nc
   bkclm=${IC_SPS_guess}/CLM/$st/land_clm45_forced_${ppland}_analisi_1993_2015.clm2.r.$yyyy-$st-01-00000.bkup.nc 
   bkrtm=${IC_SPS_guess}/CLM/$st/land_clm45_forced_${ppland}_analisi_1993_2015.rtm.r.$yyyy-$st-01-00000.bkup.nc 
else
   yyin=$1   # IC year
   mmin=$2   # IC month; this is not a number (2 digits)
   dd=$3     # IC day
   tstamp=$4
   yyyy=$5
   st=$6
   ppland=$7  
   bk=${8}
   iniICfile=${9}
   bkoce=${10}
   bkice=${11}
   bkclm=${12}
   bkrtm=${13}
fi

mkdir -p $IC_CAM_SPS_DIR/$st/
startdate=$yyyy${st}01
#
export year=$yyin   # IC year
export mon=$mmin
export day=$dd

set +euvx
if [ $yyyy -lt ${iniy_fore} ]
then
   . ${DIR_SPS35}/descr_hindcast.sh
else
   . ${DIR_SPS35}/descr_forecast.sh
fi
set -euvx

data=$DATA_ECACCESS/EDA/snapshot/${tstamp}Z/
echo 'starting preprocessing for raw date '$yyin $mmin $dd $tstamp `date`
echo ''

#INPUT FILES DOWNLOADED FROM ECMWF
#lev_ml=ECEDA_${yyin}${mmin}${dd}_${tstamp}lev.grib  #level fields
# now contains also specific humidity previously in lev_gg files
# surf file are not downloaded anymore because not used
# lev now inputECEDA
for ppeda in {0..9}
do
   pp=$(($ppeda + 1))
   
   
   ICfile=$iniICfile.$pp.nc
   if [[ $bk -eq 1 ]]
   then
      ICfile=$iniICfile.$pp.bkup.nc
   fi

   inputECEDA=ECEDA${ppeda}_$yyin$mmin${dd}_${tstamp}.grib
   inp=`echo $inputECEDA|rev |cut -d '.' -f1 --complement|rev`
   
   
   export output=${SPSSYS}.EDAcam.i.${pp}.${yyin}-${mmin}-${dd}_${tstamp}.nc
   # this to check output after vertical interpolation
   output_checkZIP="${SPSSYS}.EDAcam.i.$pp.3dfields_${yyin}-${mmin}-${dd}_${tstamp}_ECEDAgrid46lev.zip.nc"
   
   # create output dir if not existing already
   mkdir -p $WORK_IC4CAM
   
   workdir="${WORK_IC4CAM}/WORK_${tstamp}_${yyin}${mmin}_${dd}"
   if [ -d $workdir ] 
   then
      cd ${WORK_IC4CAM}
      rm -rf WORK_${tstamp}_${yyin}${mmin}_${dd}
   fi
   mkdir -p $workdir
   cd $workdir
   
   #TEMPLATE FILE 2 CAM
   export templateL46=${CESMDATAROOT}/inputdata/atm/cam/inic/homme/cami-from-SPS3-ne60np4_L46_c190621.nc
   
   #NOW LEVEL FIELDS U, V, Q, T and lnPS (used to vertical interp)
   # 20210429 +
   if [ ! -f ${data}/${inputECEDA} ]
   then
      title="[CAMIC] ${SPSSYS} ERROR"
      body="$DIR_ATM_IC/make_atm_ic_l46_${SPSSYS}_op.sh: ${data}/${inputECEDA} missing!"
      ${DIR_SPS35}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "yes" 
      exit 1
   fi
   # 20210429 -
   cdo --eccodes -f nc copy ${data}/${inputECEDA} ${WORK_IC4CAM}/${inp}.tmp.nc
   cdo smooth9 ${WORK_IC4CAM}/${inp}.tmp.nc ${WORK_IC4CAM}/${inp}.tmp.smooth.nc
   cdo smooth9 ${WORK_IC4CAM}/${inp}.tmp.smooth.nc ${WORK_IC4CAM}/${inp}.nc
   rm ${WORK_IC4CAM}/${inp}.tmp.nc ${WORK_IC4CAM}/${inp}.tmp.smooth.nc
   export input3d=${WORK_IC4CAM}/${inp}.nc
   export output_check=$WORK_IC4CAM/${inp}.tmp2.nc
   # WEIGHTS AND SCRIPTS ARE THE SAME AS FOR ERA5 BECAUSE FIELDS ARE RETRIEVED
   # AT THE SAME RESOLUTION
   export wgt_file=$REPOGRID/ERA5_to_CAMSE05.nc
   cd $DIR_ATM_IC/ncl
   echo 'invoke regrid_ERA5_to_ne60np4.ncl '`date`
   echo ''
   export fileok=${WORK_IC4CAM}/${inp}_ok
   ncl regrid_ERA5_to_ne60np4.ncl
   if [ -f $fileok ]
   then
      echo 'ended regrid_ERA5_to_ne60np4.ncl and begin compression check level fileds'`date`
      echo ''
      rm $input3d
   else
      title="[CAMIC] ${SPSSYS} warning"
      body="$IC_SPS35/IC_CAM/ncl/regrid_ERA5_to_ne60np4.ncl did not complete correctly for $input3d"
      ${DIR_SPS35}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "yes"
   fi
   # the script produces check files for vertical interpolation $output_check
   # put them in $WORK_IC4CAM
   if [ -f $WORK_IC4CAM/$output_checkZIP ]
   then
       rm $WORK_IC4CAM/$output_checkZIP
   fi
   $compress ${output_check} $WORK_IC4CAM/$output_checkZIP
   rm ${output_check}
   
   echo 'ended compression check level fields and begin compression IC CAM ' `date`echo ''
   # put results in $IC_SPS_guess/CAM ready for SPS3_guess
   mkdir -p $IC_SPS_guess/CAM/$st
   ncdataSPS=$IC_SPS_guess/CAM/$st/$output
   mv ${output} $ncdataSPS
   echo 'ended compression IC CAM 00 '`date`
   echo ''
   caso=${SPSsystem}_EDACAM_IC${pp}.${yyin}${mmin}${dd}.$tstamp
   ncpl=192
   stopdate="dummy"
   input="$yyin $mmin $dd $startdate ${tstamp} $pp $ppland $caso $ncpl $stopdate $bk $ncdataSPS $ICfile $bkoce $bkice $bkclm $bkrtm"
   mkdir -p ${DIR_LOG}/forecast/$yyyy$st/IC_CAM
   ${DIR_SPS35}/submitcommand.sh -m $machine -S qos_resv -t "1" -q $serialq_s -j ${caso}_launch -l ${DIR_LOG}/forecast/$yyyy$st/IC_CAM -d ${IC_SPS35}/IC_CAM -s ${SPSSYS}_IC4CAM_op.sh -i "$input"
done
if [ -d $workdir ]
then
   cd ${WORK_IC4CAM}
   rm -rf WORK_${tstamp}_${yyin}${mmin}_${dd}
fi
