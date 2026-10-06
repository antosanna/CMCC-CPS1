#!/bin/sh -l 
# to be modified according to specifications to be received from ECMWF
#--------------------------------
# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. ${DIR_UTIL}/load_cdo

set -evxu

#----------------------------
#  INPUT SECTION
#----------------------------
yyyy=$1 #2000
st=$2   #10

set +euvx
. ${DIR_UTIL}/descr_ensemble.sh $yyyy
. ${dictionary}
set -euvx

start_date=${yyyy}${st}
if [[ -f ${check_tar_done} ]]
then
   body="C3Sext: tar_C3Sext already done for ${start_date}. Exiting from $DIR_C3S/tar_C3Sext.sh now"
   title="[C3Sext] ${CPSSYS} $typeofrun notification"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" 
   exit
fi
C3Stable_cam=$DIR_POST/cam/C3S_table.txt
C3Stable_clm=$DIR_POST/clm/C3S_table_clm.txt
C3Stable_oce1=$DIR_POST/nemo/C3S_table_ocean2d_others_ext.txt
C3Stable_oce2=$DIR_POST/nemo/C3S_table_ocean2d_t14d.txt
C3Stable_oce3=$DIR_POST/nemo/C3S_table_ocean2d_t17d.txt
C3Stable_oce4=$DIR_POST/nemo/C3S_table_ocean2d_t20d.txt
C3Stable_oce5=$DIR_POST/nemo/C3S_table_ocean2d_t26d.txt
C3Stable_oce6=$DIR_POST/nemo/C3S_table_ocean2d_t28d.txt
#
{
read 
while IFS=, read -r flname C3S dim lname sname units freq type realm addfact coord cell varflg
do
   if [[ $freq == "12hr" ]]
   then
      var_array3d+=("$C3S")
   else
      if [[ $flname == "PHIS" ]] || [[ $flname == "LANDFRAC" ]]
      then
         continue
      fi
      var_array2d+=("$C3S")
   fi
done } < $C3Stable_cam
{
while IFS=, read -r flname C3S realm prec coord lname sname units freq level addfact coord2 cell
do
   var_array2d+=("$C3S")
done } < $C3Stable_clm
{
read 
while IFS=, read -r flname C3S lname sname units realm level addfact coord cell varflg reflev model fillval
do
   var_array2d+=("$C3S")
done } < $C3Stable_oce1
{
read 
while IFS=, read -r flname C3S lname sname units realm level addfact coord cell varflg reflev model fillval
do
   var_array2d+=("$C3S")
done } < $C3Stable_oce2
{
read 
while IFS=, read -r flname C3S lname sname units realm level addfact coord cell varflg reflev model fillval
do
   var_array2d+=("$C3S")
done } < $C3Stable_oce3
{
read 
while IFS=, read -r flname C3S lname sname units realm level addfact coord cell varflg reflev model fillval
do
   var_array2d+=("$C3S")
done } < $C3Stable_oce4
{
read 
while IFS=, read -r flname C3S lname sname units realm level addfact coord cell varflg reflev model fillval
do
   var_array2d+=("$C3S")
done } < $C3Stable_oce5
{
read 
while IFS=, read -r flname C3S lname sname units realm level addfact coord cell varflg reflev model fillval
do
   var_array2d+=("$C3S")
done } < $C3Stable_oce6
#var_array3d=(hus ta ua va zg)
# AA +
#var_array=("${var_array2d[@]} ${var_array3d[@]}" "rsdt")
# rdst e' un duplicato perche' compreso nel var_array2d
# gli array vanno separati con questa sintassi 
var_array=("${var_array2d[@]}" "${var_array3d[@]}")
# AA -
echo ${var_array[@]}

dim=${#var_array[@]}
if [[ $dim -ne $nfieldsC3SEXT ]]
then
   echo "!!!!!!!!!!!!!!!!!!!!!"
   echo "you are postprocessing only $dim variables instead of the $nfieldsC3SEXT ones"
   echo "check it beforegoing on and comment these lines"
   echo "!!!!!!!!!!!!!!!!!!!!!"
   exit
fi
cd $WORK_C3Sext/${start_date}

listatocheck=""
for var in ${var_array[@]}
do
   listafiles=""
   echo $var
  if [[ -d $pushdir/${start_date}/ ]] ; then
      cd $pushdir/${start_date}
# 
       nmb_tar_pushdir=`ls $pushdir/${start_date}/cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${start_date}0100_*_${var}_*n*-n*.tar |wc -l`
       if [[ ${nmb_tar_pushdir} -ne 0 ]]
       then
            rm $pushdir/${start_date}/cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${start_date}0100_*_${var}_*n*-n*.tar
       fi
   fi
   echo "cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${start_date}0100_*_${var}_*n*-n*"
   cd $WORK_C3SEXT/${start_date}
   nmb_tar_wkdir=`ls $WORK_C3SEXT/${start_date}/cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${start_date}0100_*_${var}_*n*-n*.tar |wc -l`
   if [[ ${nmb_tar_wkdir} -ne 0 ]]
   then
        rm $WORK_C3SEXT/${start_date}/cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${start_date}0100_*_${var}_*n*-n*.tar
   fi  

   listatocheck+="`ls cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${start_date}0100_*_${var}_*.nc | head -n $nrunhindext` "

done
echo $listatocheck


cd $WORK_C3SEXT/${start_date}
if [[ `ls $listatocheck|wc -l` -eq 0 ]]
then
   echo "$listatocheck is empty! Please check if this is really what you want"
   exit
fi
#----------------------------
#  CHEKC THAT ALL NEEDED MEMBERS ARE THERE
#----------------------------

if [[ `ls $listatocheck |wc -l` -ne $(($nrunhindext * $nfieldsC3SEXT)) ]]
then
    body="C3Sext: $DIR_C3S/tar_C3Sext.sh found `ls $listatocheck |wc -l`files instead of $(($nrunhindext * $nfieldsC3SEXT)) in $WORK_C3SEXT/${start_date}"
    title="[C3Sext] ${CPSSYS} $typeofrun ERROR"
    ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r $typeofrun -s $start_date 
    exit 2
fi
#
# change_realization if needed
#----------------------------
## not allowed in extended
#${DIR_C3S}/change_realization.sh $yyyy $st

# nel caso in cui change_realization.sh e' ridondante
listatocheck=" "
for var in "${var_array[@]}"
do
  listatocheck+=" `ls cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${start_date}0100_*_${var}_*.nc |head -n $nrunhindext`"
done
#
# clean pushdir
#-----------------------
$DIR_C3S/clean_pushdir.sh $yyyy $st
pushdir_hc=${pushdir}/${start_date}
mkdir -p ${pushdir_hc}

#----------------------------------------------
# CHECK THE TIME LENGTH OF EACH FILE
#----------------------------------------------

isdaily=`ls $listatocheck|grep day |wc -l`
if [[ $isdaily -ne 0 ]]  
then
   daily=`ls $listatocheck|grep day`

   for file in $daily
   do
      echo $file
      nstep=`cdo -ntime $file`
      if [[ $nstep -ne $fixsimextdays ]]
      then
          body="C3Sext: $DIR_C3S/tar_C3Sext.sh found number of days in file $nstep different from expected $fixsimextdays for file $file in $WORK_C3SEXT/${start_date}. See log $DIR_LOG/$start_date/tar_C3Sext..."
          title="[C3Sext] ${CPSSYS} forecast ERROR"
          ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r $typeofrun -s $start_date
          exit 1
      else
         echo "number of days in file $nstep correct"
      fi
   done
fi

islista6hrly=`ls $listatocheck|grep 6hr |wc -l`
if [[ $islista6hrly -ne 0 ]]
then

  lista6hrly=`ls $listatocheck|grep 6hr`
  n6hr=`expr $fixsimextdays \* 4`
  for file in ${lista6hrly}
  do
     nstep=`cdo -ntime $file`
     if [[ $n6hr -ne $nstep ]]
     then
        body="C3Sext: $DIR_C3S/tar_C3Sext.sh found number of timesteps in file $nstep different from expected ${n6hr}  for file $file in $WORK_C3SEXT/${start_date}. See log $DIR_LOG/$start_date/tar_C3Sext..."
        title="[C3Sext] ${CPSSYS} forecast ERROR"
        ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r $typeofrun -s $start_date
        exit 1
     else
        echo "number of timesteps in file $nstep correct"
     fi
  done
fi

islista12hrly=`ls $listatocheck|grep 12hr |wc -l`
if [[ $islista12hrly -ne 0 ]] ; then
   lista12hrly=`ls $listatocheck|grep 12hr`
   n12hr=`expr $fixsimextdays \* 2`
   for file in ${lista12hrly}
   do
      nstep=`cdo -ntime $file`
      if [[ $n12hr -ne $nstep ]]
      then
         body="C3Sext: $DIR_C3S/tar_C3Sext.sh found number of timesteps in file $nstep different from expected ${n12hr}  for file $file in $WORK_C3SEXT/${start_date}. See log $DIR_LOG/$start_date/tar_C3Sext..."
         title="[C3Sext] ${CPSSYS} forecast ERROR"
         ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r $typeofrun -s $start_date
         exit 1
      else
         echo "number of timesteps in file $nstep correct"
      fi
   done
fi
#
#----------------------------------------------
# PRODUCE SHA256
#----------------------------------------------
echo "NOW PRODUCE sha256 FILES"
for file in ${listatocheck}
do
   file="${file%.*}"
   if [[ -f $file.sha256 ]]
   then
     rm $file.sha256
   fi
   sha256sum ${file}.nc > $file.sha256
done

donotsend=0
NUMB_CHECK=`expr $nrunhindext + $nrunhindext` # for each field we have the .nc file and .sha


#----------------------------------------------
# CHECK THROUGH ALL THE C3S VARIABLES IF NUMBER OF FILES IS CORRECT
# THE PRODUCE TAR AND SHA256
#----------------------------------------------
echo "NOW PRODUCE  CHECK NUMBER OF FILES AND sha256 AND DO .tar"
# cmcc_${GCM_name}-v${versionSPS}_forecast_S2018050100_ocean_6hr_surface_tso_n1-n${nrunmax}.tar
for var in "${var_array2d[@]}"
do
#controllare! non e' precisissima...
   NUMB_FOUND=`ls -1 cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}*_${var}_*sha256 | wc -l`
   if [[ $((${NUMB_FOUND} * 2)) -eq ${NUMB_CHECK} ]] ; then
     
     # need to extract model,freq and type
     f=`ls -1 cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_*_${var}_r* | head -1`
     mft=`echo $f | cut -d '_' -f5-7`
     listafile2tar=" "
     for ens in `seq -w 01 $nrunhindext`
     do
        listafile2tar+=" `ls cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_*_${var}_r${ens}*`"
     done
     if [[ `echo $listafile2tar|wc -w` -ne $(($nrunhindext * 2)) ]]
     then
         body="C3Sext: standardisation error in script $DIR_C3S/tar_C3Sext.sh: start date ${yyyy}${st} incorrect number of files to tar for variable: ${var} Expected $(($nrunhindext * 2)) found `echo $listafile2tar|wc -w` in $WORK_C3SEXT/${start_date}. See log $DIR_LOG/$start_date/tar_C3Sext..."
         title="[C3Sext] ${CPSSYS} $typeofrun ERROR"
         ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -s $yyyy$st -r $typeofrun
         exit 3
     fi
     tar -cf cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_${mft}_${var}_n1-n${nrunhindext}.tar $listafile2tar
     
     if [[ $? -eq 0 ]] ; then
        sha256sum cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_${mft}_${var}_n1-n${nrunhindext}.tar > cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_${mft}_${var}_n1-n${nrunhindext}.sha256 
     
     #copy in dtn01 to push
        rsync -auv --remove-source-files cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_${mft}_${var}_n1-n${nrunhindext}.* $pushdir_hc
     else
        echo "something wrong in shasum ${yyyy}${st} $var"
     fi

   else
#mail MACHINE DEPENDENT chek if present
      body="C3Sext: standardisation error in script $DIR_C3S/tar_C3Sext.sh: start date ${yyyy}${st} incorrect number of files to tar for variable : ${var} Expected ${NUMB_CHECK} found ${NUMB_FOUND} in $WORK_C3SEXT/${start_date}. See log $DIR_LOG/$start_date/tar_C3Sext..."
      title="[C3Sext] ${CPSSYS} $typeofrun ERROR"
      ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r $typeofrun -s ${yyyy}${st}
      donotsend=1
      exit
   fi
done

# var in levels must be packed in 5 file tar each
for var in "${var_array3d[@]}"
do
   NUMB_FOUND=`ls -1 cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}*_${var}_*sha256 | wc -l`
   if [[ $((${NUMB_FOUND} * 2)) -eq ${NUMB_CHECK} ]] ; then
# IN THE FOLLOWING CASES VARS ARE DOUBLE WE SPLIT
    
# need to extract model,freq and type
      f=`ls -1 cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_*_${var}_r* | head -1`
      mft=`echo $f | cut -d '_' -f5-7`
      numb_nc=$nrunhindext
      list_0=`ls cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_*_${var}_r0[1-5]*`
      tar -cf cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_${mft}_${var}_n1-n5.tar ${list_0}
      sha256sum cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_${mft}_${var}_n1-n5.tar > cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_${mft}_${var}_n1-n5.sha256
      rsync -auv --remove-source-files cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_${mft}_${var}_n1-n5.* $pushdir_hc
      #second 5
      list_1=`ls cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_*_${var}_r0[6-9]* cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_*_${var}_r10*`
      tar -cf cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_${mft}_${var}_n6-n10.tar ${list_1}
      sha256sum cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_${mft}_${var}_n6-n10.tar > cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_${mft}_${var}_n6-n10.sha256
      rsync -auv --remove-source-files cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_${mft}_${var}_n6-n10.* $pushdir_hc
      #third 5
      list_2=`ls cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_*_${var}_r1[1-5]*`
      tar -cf cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_${mft}_${var}_n11-n15.tar ${list_2}
      sha256sum cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_${mft}_${var}_n11-n15.tar > cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_${mft}_${var}_n11-n15.sha256
      rsync -auv --remove-source-files cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_${mft}_${var}_n11-n15.* $pushdir_hc
      # fourth 5
      list_3=`ls cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_*_${var}_r1[6-9]* cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_*_${var}_r20*`
      tar -cf cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_${mft}_${var}_n16-n20.tar ${list_3}
      sha256sum cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_${mft}_${var}_n16-n20.tar > cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_${mft}_${var}_n16-n20.sha256
      rsync -auv --remove-source-files cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_${mft}_${var}_n16-n20.* $pushdir_hc

#      body="C3Sext: standardisation error in script $DIR_C3S/tar_C3Sext.sh: start date ${yyyy}${st} incorrect number of files to tar for variable: ${var} Expected ${NUMB_CHECK} found ${NUMB_FOUND} in $WORK_C3SEXT/${start_date}. See log $DIR_LOG/$start_date/tar_C3Sext..."
#      title="[C3Sext] ${CPSSYS} $typeofrun ERROR"
#      ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -s $yyyy$st -r $typeofrun
#      donotsend=1
#      exit
   fi #if on number of var
done  #end loop on var_array3d

#check if everything is ok inside the tarfiles
$DIR_C3S/check_tarC3Sext.sh $yyyy $st
body="C3Sext: $DIR_LOG/tar_C3Sext.sh completed for ${start_date}."
title="[C3Sext] ${CPSSYS} $typeofrun notification"
${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r $typeofrun -s $start_date
touch ${check_tar_done}

