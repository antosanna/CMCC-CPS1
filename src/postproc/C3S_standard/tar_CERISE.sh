#!/bin/sh -l 
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
if [ -f ${check_tar_done} ]
then
   body="CERISE: tar_CERISE already done for ${start_date}. Exiting from $DIR_C3S/tar_CERISE.sh now"
   title="[CERISE] ${CPSSYS} $typeofrun notification"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" 
   exit
fi

dim=`ls $WORK_CERISE/$start_date/*r01i00p00.nc|wc -l`
listavar=`ls $WORK_CERISE/$start_date/*r01i00p00.nc|rev|cut -d '_' -f2|rev`
if [ $dim -ne $nfieldsC3S ]
then
   echo "!!!!!!!!!!!!!!!!!!!!!"
   echo "you are postprocessing only $dim variables instead of the $nfieldsC3S ones"
   echo "check it beforegoing on and comment these lines"
   echo "!!!!!!!!!!!!!!!!!!!!!"
   exit
fi
cd $WORK_C3S/${start_date}

listatocheck=""
for var in ${listavar}
do
   listafiles=""
   echo $var
  if [[ -d $pushdir/${start_date}/ ]] ; then
      cd $pushdir/${start_date}
# 
       nmb_tar_pushdir=`ls $pushdir/${start_date}/cmcc_CERISE-${GCM_name}-v${versionSPS}_${typeofrun}_S${start_date}0100_*_${var}_*n*-n*.tar |wc -l`
       if [[ ${nmb_tar_pushdir} -ne 0 ]]
       then
            rm $pushdir/${start_date}/cmcc_CERISE-${GCM_name}-v${versionSPS}_${typeofrun}_S${start_date}0100_*_${var}_*n*-n*.tar
       fi
   fi
   echo "cmcc_CERISE-${GCM_name}-v${versionSPS}_${typeofrun}_S${start_date}0100_*_${var}_*n*-n*"
   cd $WORK_CERISE/${start_date}
   nmb_tar_wkdir=`ls $WORK_CERISE/${start_date}/cmcc_CERISE-${GCM_name}-v${versionSPS}_${typeofrun}_S${start_date}0100_*_${var}_*n*-n*.tar |wc -l`
   if [[ ${nmb_tar_wkdir} -ne 0 ]]
   then
        rm $WORK_CERISE/${start_date}/cmcc_CERISE-${GCM_name}-v${versionSPS}_${typeofrun}_S${start_date}0100_*_${var}_*n*-n*.tar
   fi  

   listatocheck+="`ls cmcc_CERISE-${GCM_name}-v${versionSPS}_${typeofrun}_S${start_date}0100_*_${var}_*.nc | head -n $nrunC3Sfore` "

done
echo $listatocheck


cd $WORK_CERISE/${start_date}
if [[ `ls $listatocheck|wc -l` -eq 0 ]]
then
   echo "$listatocheck is empty! Please check if this is really what you want"
   exit
fi
#----------------------------
#  CHEKC THAT ALL NEEDED MEMBERS ARE THERE
#----------------------------

if [ `ls $listatocheck |wc -l` -ne $(($nrunC3Sfore * $nfieldsC3S)) ]
then
    body="CERISE: $DIR_C3S/tar_CERISE.sh found `ls $listatocheck |wc -l`files instead of $(($nrunC3Sfore * $nfieldsC3S)) in $WORK_C3S/${start_date}"
    title="[CERISE] ${CPSSYS} $typeofrun ERROR"
    ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r $typeofrun -s $start_date 
    exit 2
fi
#

# nel caso in cui change_realization.sh e' ridondante
listatocheck=" "
for var in "${var_array[@]}"
do
  listatocheck+=" `ls cmcc_CERISE-${GCM_name}-v${versionSPS}_${typeofrun}_S${start_date}0100_*_${var}_*.nc |head -n $nrunC3Sfore`"
done
#
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
      if [ $nstep -ne $fixsimdays ]
      then
          body="CERISE: $DIR_C3S/tar_CERISE.sh found number of days in file $nstep different from expected $fixsimdays for file $file in $WORK_C3S/${start_date}. See log $DIR_LOG/$start_date/tar_CERISE..."
          title="[CERISE] ${CPSSYS} forecast ERROR"
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
  n6hr=`expr $fixsimdays \* 4`
  for file in ${lista6hrly}
  do
     nstep=`cdo -ntime $file`
     if [ $n6hr -ne $nstep ]
     then
        body="CERISE: $DIR_C3S/tar_CERISE.sh found number of timesteps in file $nstep different from expected ${n6hr}  for file $file in $WORK_C3S/${start_date}. See log $DIR_LOG/$start_date/tar_CERISE..."
        title="[CERISE] ${CPSSYS} forecast ERROR"
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
   n12hr=`expr $fixsimdays \* 2`
   for file in ${lista12hrly}
   do
      nstep=`cdo -ntime $file`
      if [ $n12hr -ne $nstep ]
      then
         body="CERISE: $DIR_C3S/tar_CERISE.sh found number of timesteps in file $nstep different from expected ${n12hr}  for file $file in $WORK_C3S/${start_date}. See log $DIR_LOG/$start_date/tar_CERISE..."
         title="[CERISE] ${CPSSYS} forecast ERROR"
         ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r $typeofrun -s $start_date
         exit 1
      else
         echo "number of timesteps in file $nstep correct"
      fi
   done
fi
#
#----------------------------------------------
# PRODUCE SHA256 not required by CERISE
#----------------------------------------------
#echo "NOW PRODUCE sha256 FILES"
#for file in ${listatocheck}
#do
#   file="${file%.*}"
#   if [ -f $file.sha256 ]
#   then
#     rm $file.sha256
#   fi
#   sha256sum ${file}.nc > $file.sha256
#done

donotsend=0
#NUMB_CHECK=`expr $nrunC3Sfore + $nrunC3Sfore` # for each field we have the .nc file and .sha
NUMB_CHECK=$nrunC3Sfore


#----------------------------------------------
# CHECK THROUGH ALL THE CERISE VARIABLES IF NUMBER OF FILES IS CORRECT
# THE PRODUCE TAR AND SHA256
#----------------------------------------------
#echo "NOW PRODUCE  CHECK NUMBER OF FILES AND sha256 AND DO .tar"
echo "NOW PRODUCE  CHECK NUMBER OF FILES AND DO .tar"
# cmcc_CERISE-${GCM_name}-v${versionSPS}_forecast_S2018050100_ocean_6hr_surface_tso_n1-n${nrunmax}.tar
for var in "${var_array2d[@]}"
do
#controllare! non e' precisissima...
   NUMB_FOUND=`ls -1 cmcc_CERISE-${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}*_${var}_*nc | wc -l`
   if [ ${NUMB_FOUND} -eq ${NUMB_CHECK} ] ; then
     
     # need to extract model,freq and type
     f=`ls -1 cmcc_CERISE-${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_*_${var}_r* | head -1`
     mft=`echo $f | cut -d '_' -f5-7`
     listafile2tar=" "
     for ens in `seq -w 01 $nrunC3Sfore`
     do
        listafile2tar+=" `ls cmcc_CERISE-${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_*_${var}_r${ens}*`"
     done
     if [ `echo $listafile2tar|wc -w` -ne $nrunC3Sfore ]
     then
         body="CERISE: standardisation error in script $DIR_C3S/tar_CERISE.sh: start date ${yyyy}${st} incorrect number of files to tar for variable: ${var} Expected $nrunC3Sfore found `echo $listafile2tar|wc -w` in $WORK_C3S/${start_date}. See log $DIR_LOG/$start_date/tar_CERISE..."
         title="[CERISE] ${CPSSYS} $typeofrun ERROR"
         ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -s $yyyy$st -r $typeofrun
         exit 3
     fi
     tar -cf cmcc_CERISE-${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_${mft}_${var}_n1-n${nrunC3Sfore}.tar $listafile2tar
     
     if [ $? -eq 0 ] ; then
#        sha256sum cmcc_CERISE-${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_${mft}_${var}_n1-n${nrunC3Sfore}.tar > cmcc_CERISE-${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_${mft}_${var}_n1-n${nrunC3Sfore}.sha256 
     
     #copy in dtn01 to push
        rsync -auv --remove-source-files cmcc_CERISE-${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_${mft}_${var}_n1-n${nrunC3Sfore}.* $pushdir_hc
     else
        echo "something wrong in shasum ${yyyy}${st} $var"
     fi

   else
      body="CERISE: standardisation error in script $DIR_C3S/tar_CERISE.sh: start date ${yyyy}${st} incorrect number of files to tar for variable : ${var} Expected ${NUMB_CHECK} found ${NUMB_FOUND} in $WORK_C3S/${start_date}. See log $DIR_LOG/$start_date/tar_CERISE..."
      title="[CERISE] ${CPSSYS} $typeofrun ERROR"
      ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r $typeofrun -s ${yyyy}${st}
      donotsend=1
      exit
   fi
done

# var in levels must be packed in 25 file tar each
for var in "hus ta ua va wap zg"
do
   NUMB_FOUND=`ls -1 cmcc_CERISE-${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}*_${var}_*nc | wc -l`
   if [ ${NUMB_FOUND} -eq ${NUMB_CHECK} ] ; then
# IN THE FOLLOWING CASES VARS ARE DOUBLE WE SPLIT
    
# need to extract model,freq and type
      f=`ls -1 cmcc_CERISE-${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_*_${var}_r* | head -1`
      mft=`echo $f | cut -d '_' -f5-7`
      numb_nc=$nrunC3Sfore
# BAU forecast or hindcast operational
         #first 10
      list_0=`ls cmcc_CERISE-${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_*_${var}_r0* cmcc_CERISE-${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_*_${var}_r10*`
      tar -cf cmcc_CERISE-${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_${mft}_${var}_n1-n10.tar ${list_0}
      if [ $? -eq 0 ] ; then
#            sha256sum cmcc_CERISE-${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_${mft}_${var}_n1-n10.tar > cmcc_CERISE-${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_${mft}_${var}_n1-n10.sha256
        rsync -auv --remove-source-files cmcc_CERISE-${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_${mft}_${var}_n1-n10.* $pushdir_hc
      else
         echo "something wrong in shasum ${yyyy}${st} $var"
      fi

         #second 10
      list_1=`ls cmcc_CERISE-${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_*_${var}_r1[1-9]* cmcc_CERISE-${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_*_${var}_r20*`
      tar -cf cmcc_CERISE-${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_${mft}_${var}_n11-n20.tar ${list_1}
      if [ $? -eq 0 ] ; then
#            sha256sum cmcc_CERISE-${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_${mft}_${var}_n11-n20.tar > cmcc_CERISE-${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_${mft}_${var}_n11-n20.sha256
         rsync -auv --remove-source-files cmcc_CERISE-${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_${mft}_${var}_n11-n20.* $pushdir_hc
      else
         echo "something wrong in shasum ${yyyy}${st} $var"
      fi

         #third  10
      list_2=`ls -1 cmcc_CERISE-${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_*_${var}_r2[1-9]* cmcc_CERISE-${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_*_${var}_r30*`
      tar -cf cmcc_CERISE-${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_${mft}_${var}_n21-n30.tar ${list_2}
      if [ $? -eq 0 ] ; then
#            sha256sum cmcc_CERISE-${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_${mft}_${var}_n21-n30.tar > cmcc_CERISE-${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_${mft}_${var}_n21-n30.sha256
         rsync -auv --remove-source-files cmcc_CERISE-${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_${mft}_${var}_n21-n30.* $pushdir_hc
      else
         echo "something wrong in shasum ${yyyy}${st} $var"
      fi
         #FOR SPS4 HINDCAST WE STOP HERE - 30 members in hindcast mode       
  
   else
      body="CERISE: standardisation error in script $DIR_C3S/tar_CERISE.sh: start date ${yyyy}${st} incorrect number of files to tar for variable: ${var} Expected ${NUMB_CHECK} found ${NUMB_FOUND} in $WORK_C3S/${start_date}. See log $DIR_LOG/$start_date/tar_CERISE..."
      title="[CERISE] ${CPSSYS} $typeofrun ERROR"
      ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -s $yyyy$st -r $typeofrun
      donotsend=1
      exit
   fi #if on number of var
done  #end loop on var_array3d

#check if everything is ok inside the tarfiles
$DIR_C3S/check_tarCERISE.sh $yyyy $st
stat=$?
if [ $stat -eq 0 ]
then
   body="CERISE: $DIR_LOG/tar_CERISE.sh completed for ${start_date}."
   title="[CERISE] ${CPSSYS} $typeofrun notification"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r $typeofrun -s $start_date
   touch ${check_tar_done}
else
   body="CERISE: $DIR_C3S/check_tarCERISE.sh failed for ${start_date}. Exiting now. Check and fix"
   title="[CERISE] ${CPSSYS} $typeofrun ERROR"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r $typeofrun -s $start_date
   exit 1
fi   

