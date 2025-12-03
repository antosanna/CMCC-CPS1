#!/bin/sh -l
#BSUB -P 0490
#BSUB -q s_short
#BSUB -J check_CAM_IC
#BSUB -e logs/check_CAM_IC_%J.err
#BSUB -o logs/check_CAM_IC_%J.out
#BSUB -M 2G

# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. ${DIR_UTIL}/load_cdo
. ${DIR_UTIL}/load_nco
. ${DIR_UTIL}/load_ncl
. ${DIR_UTIL}/load_convert

if [[ $machine == "juno" ]]
then
   . $HOME/load_miniconda
   conda activate /users_home/cmcc/sp1/utils/miniforge/envs/new_eccodes_env 
fi


set -euvx
#
yyyy=$1
st=$2
set +euvx   
. ${DIR_UTIL}/descr_ensemble.sh $yyyy
set -euvx
if [[ $typeofrun == "forecast" ]] ; then
   export obs="IFS"
fi
stm1=`date -d ' '$yyyy${st}01' - 1 month' +%m`
yyyym1=`date -d ' '$yyyy${st}01' - 1 month' +%Y`
dd=`$DIR_UTIL/days_in_month.sh $stm1 $yyyym1`
export stdate=$yyyy$st
inputECOPER=ECOPER_${yyyym1}${stm1}${dd}_00.grib
inp=`echo $inputECOPER|rev |cut -d '.' -f1 --complement|rev`

workdir=$SCRATCHDIR/$typeofrun/${yyyy}${st}/IC_CAM
mkdir -p $workdir
fileokU=$workdir/Uprof_${stdate}_DONE
#THE FIELDS RELATIVE TO YESTERDAY ARE NOT AVAILABLE!!
# we are forced to use IFS ones
#cdo --eccodes -f nc copy $DATA_ECACCESS/ERA5T/snapshot/00Z/${inputECOPER} $SCRATCHDIR/ICCAM2plot/${inp}.nc
cdo --eccodes -f nc copy $DATA_ECACCESS/IFS/snapshot/00Z/${inputECOPER} $workdir/${inp}.nc
export inputERA=$workdir/$inp.nc
mkdir -p $workdir/plots
export dirplots=$workdir/plots

for i in {01..10}
do
   if [ -f ${IC_CAM_CPS_DIR}/$st/${CPSSYS}.cam.i.${yyyy}-${st}-01-00000.$i.nc.gz ]
   then
       gunzip ${IC_CAM_CPS_DIR}/$st/${CPSSYS}.cam.i.${yyyy}-${st}-01-00000.$i.nc.gz 
   fi
   if [ -f ${IC_CAM_CPS_DIR}/$st/${CPSSYS}.cam.i.${yyyy}-${st}-01-00000.$i.nc ]
   then
      ln -sf ${IC_CAM_CPS_DIR}/$st/${CPSSYS}.cam.i.${yyyy}-${st}-01-00000.$i.nc $workdir
   fi
done
export diri=$workdir
export filename="${CPSSYS}.cam.i.${yyyy}-${st}-01-00000."

echo ''
export typeofplot="png"

cd $DIR_ATM_IC/ncl
for varera in q t u v
do
   case $varera in
      "q") export varcam="Q" ;;
      "t") export varcam="T" ;;
      "u") export varcam="US" ;;
      "v") export varcam="VS" ;;
   esac
   export varera=$varera
   echo $varcam
   value=10
   export value2check=$value
   export fileok2d=$workdir/${value}hPa_${varcam}_${stdate}_DONE
   echo $diri
   ncl multipanel_plot_ERA5-ICsCAM.ncl 
   if [ ! -f $fileok2d ]
   then
      body="$fileok2d not produced by $DIR_ATM_IC/multipanel_plot_ERA5-ICsCAM.ncl"
      title="[CAMIC] ${CPSSYS} forecast ERROR"
      $DIR_UTIL/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
      exit
   fi
   value=500
   export fileok2d=$workdir/${value}hPa_${varcam}_${stdate}_DONE
   export  value2check=$value
   ncl multipanel_plot_ERA5-ICsCAM.ncl 
   if [ ! -f $fileok2d ]
   then
      body="$fileok2d not produced by $DIR_ATM_IC/multipanel_plot_ERA5-ICsCAM.ncl"
      title="[CAMIC] ${CPSSYS} forecast ERROR"
      $DIR_UTIL/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
      exit
   fi
done
convert $dirplots/?500*${obs}*png $dirplots/500hPa_IC_vs_${obs}_${yyyy}$st.pdf
convert $dirplots/?10*${obs}*png $dirplots/10hPa_IC_vs_${obs}_${yyyy}$st.pdf

$DIR_ATM_IC/Uprofile.sh $st $yyyy $DIR_ATM_IC/ncl $fileokU $dirplots/Uprofile_${yyyy}${st}

if [ ! -f $fileokU ]
then
   body="$fileokU not produced by $DIR_ATM_IC/Uprofile.ncl"
   title="[CAMIC] ${CPSSYS} forecast ERROR"
   $DIR_UTIL/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
   exit
fi
listafile="$dirplots/Uprofile_${yyyy}${st}.png $dirplots/500hPa_IC_vs_${obs}_$yyyy$st.pdf"
. $DIR_UTIL/condaactivation.sh
condafunction activate $envcondarclone
rclone mkdir my_drive:${typeofrun}/${yyyy}${st}/IC_plots
for fplot in $listafile 
do
   rclone copy ${fplot} my_drive:${typeofrun}/${yyyy}${st}/IC_plots
done
conda deactivate $envcondarclone
title="[CAMIC] ${CPSSYS} forecast notification"
body="On google drive https://drive.google.com/drive/folders/18q9gTUlV5_OY5dlYOvBkzxWMWmLrdW4-?usp=sharing in the folder ${yyyy}${st}/IC_plots you may find the initialization fields for CAM.\n
Comparison between 500hPa $obs and CAM ICs for ${yyyy}${st} start-date.\n
The first plot is $obs, the following ones are the 10 CAM ICs. \n
The native levels of each model nearest to 500 hPa (without any vertical interpolation) are plotted.Morever there is also the zonal wind vertical profile of the 10 ICs from 0.01 to 20hPa." 
${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -c $ccmail -M "$body" -t "$title" 


#body="Dear all, \n
#attached you may find the initialization fields for CAM.\n
#Comparison between 500hPa $obs and CAM ICs for ${yyyy}${st} start-date.\n
#The first plot is $obs, the following ones are the 10 CAM ICs. \n
#The native levels of each model nearest to 500 hPa (without any vertical interpolation) are plotted.
#Morever we attach also the zonal wind vertical profile of the 10 ICs from 0.01 to 20hPa."
#title="[CAMIC] ${CPSSYS} forecast notification"
#$DIR_UTIL/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -a "$dirplots/500hPa_IC_vs_${obs}_$yyyy$st.pdf $dirplots/Uprofile_${yyyy}${st}.png"
