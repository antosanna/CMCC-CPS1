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
header=cmcc_CERISE-${GCM_name}-v${versionSPS}-demonstrator2_${typeofrun}_S${start_date}0100
if [ -f ${check_tar_done} ]
then
   body="CERISE: tar_CERISE already done for ${start_date}. Exiting from $DIR_C3S/tar_CERISE.sh now"
   title="[CERISE] ${CPSSYS} $typeofrun notification"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" 
#   exit
fi

listavar=mrlsl
cd $WORK_CERISE_final/${start_date}

listatocheck=""
for var in ${listavar}
do
   listafiles=""
   echo $var
  if [[ -d $pushdir/${start_date}/ ]] ; then
      cd $pushdir/${start_date}
# 
       nmb_tar_pushdir=`ls $pushdir/${start_date}/${header}_*_${var}_*n*-n*.tar |wc -l`
       if [[ ${nmb_tar_pushdir} -ne 0 ]]
       then
            rm $pushdir/${start_date}/${header}_*_${var}_*n*-n*.tar
       fi
   fi
   echo "${header}_*_${var}_*n*-n*"
   cd $WORK_CERISE_final/${start_date}
   nmb_tar_wkdir=`ls $WORK_CERISE_final/${start_date}/${header}_*6hr*_${var}_*n*-n*.tar |wc -l`
   if [[ ${nmb_tar_wkdir} -ne 0 ]]
   then
        rm $WORK_CERISE_final/${start_date}/${header}_*_${var}_*n*-n*.tar
   fi  

   listatocheck+="`ls ${header}_*_${var}_*.nc | head -n $nrunC3Sfore` "

done
echo $listatocheck


cd $WORK_CERISE_final/${start_date}
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
    body="CERISE: $DIR_C3S/tar_CERISE.sh found `ls $listatocheck |wc -l`files instead of $(($nrunC3Sfore * $nfieldsC3S)) in $WORK_CERISE_final/${start_date}"
    title="[CERISE] ${CPSSYS} $typeofrun ERROR"
    ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r $typeofrun -s $start_date 
    exit 2
fi
#

# nel caso in cui change_realization.sh e' ridondante
listatocheck=" "
for var in "${var_array[@]}"
do
  listatocheck+=" `ls ${header}_*_${var}_*.nc |head -n $nrunC3Sfore`"
done

pushdir_hc=${pushdir}/${start_date} 
mkdir -p ${pushdir_hc}

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
          body="CERISE: $DIR_C3S/tar_CERISE.sh found number of days in file $nstep different from expected $fixsimdays for file $file in $WORK_CERISE_final/${start_date}. See log $DIR_LOG/$start_date/tar_CERISE..."
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
        body="CERISE: $DIR_C3S/tar_CERISE.sh found number of timesteps in file $nstep different from expected ${n6hr}  for file $file in $WORK_CERISE_final/${start_date}. See log $DIR_LOG/$start_date/tar_CERISE..."
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
         body="CERISE: $DIR_C3S/tar_CERISE.sh found number of timesteps in file $nstep different from expected ${n12hr}  for file $file in $WORK_CERISE_final/${start_date}. See log $DIR_LOG/$start_date/tar_CERISE..."
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
echo "NOW PRODUCE sha256 FILES"
for file in ${listatocheck}
do
   file="${file%.*}"
   if [ -f $file.sha256 ]
   then
     rm $file.sha256
   fi
   sha256sum ${file}.nc > $file.sha256
done

NUMB_CHECK=`expr $nrunC3Sfore + $nrunC3Sfore` # for each field we have the .nc file and .sha


#----------------------------------------------
# CHECK THROUGH ALL THE CERISE VARIABLES IF NUMBER OF FILES IS CORRECT
# THE PRODUCE TAR AND SHA256
#----------------------------------------------
echo "NOW PRODUCE  CHECK NUMBER OF FILES AND sha256 AND DO .tar"
#echo "NOW PRODUCE  CHECK NUMBER OF FILES AND DO .tar"
for var in "${var_array[@]}"
do
   if [[ $var == "hus" ]] || [[ $var == "ta" ]] || [[  $var == "ua" ]] || [[  $var == "va" ]] || [[  $var == "wap" ]] || [[  $var == "zg" ]]
   then
      continue
   fi
#controllare! non e' precisissima...
   NUMB_FOUND=`ls -1 ${header}*_${var}_*sha256 | wc -l`
   if [ $((${NUMB_FOUND} * 2)) -eq ${NUMB_CHECK} ] ; then
     
     # need to extract model,freq and type
     f=`ls -1 ${header}_*_${var}_r* | head -1`
     mft=`echo $f | cut -d '_' -f5-7`
     listafile2tar=" "
     for ens in `seq -w 01 $nrunC3Sfore`
     do
        listafile2tar+=" `ls ${header}_*_${var}_r${ens}*`"
     done
     if [ `echo $listafile2tar|wc -w` -ne  $(($nrunC3Sfore * 2)) ]
     then
         body="CERISE: standardisation error in script $DIR_C3S/tar_CERISE.sh: start date ${yyyy}${st} incorrect number of files to tar for variable: ${var} Expected $nrunC3Sfore found `echo $listafile2tar|wc -w` in $WORK_CERISE_final/${start_date}. See log $DIR_LOG/$start_date/tar_CERISE..."
         title="[CERISE] ${CPSSYS} $typeofrun ERROR"
         ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -s $yyyy$st -r $typeofrun
         exit 3
     fi
     tar -cf ${header}_${mft}_${var}_n1-n${nrunC3Sfore}.tar $listafile2tar
     
     if [ $? -eq 0 ] ; then
        sha256sum ${header}_${mft}_${var}_n1-n${nrunC3Sfore}.tar > ${header}_${mft}_${var}_n1-n${nrunC3Sfore}.sha256 
     
     #copy in dtn01 to push
        rsync -auv --remove-source-files ${header}_${mft}_${var}_n1-n${nrunC3Sfore}.* $pushdir_hc
     else
        echo "something wrong in shasum ${yyyy}${st} $var"
     fi

   else
      body="CERISE: standardisation error in script $DIR_C3S/tar_CERISE.sh: start date ${yyyy}${st} incorrect number of files to tar for variable : ${var} Expected ${NUMB_CHECK} found ${NUMB_FOUND} in $WORK_CERISE_final/${start_date}. See log $DIR_LOG/$start_date/tar_CERISE..."
      title="[CERISE] ${CPSSYS} $typeofrun ERROR"
      ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r $typeofrun -s ${yyyy}${st}
      exit
   fi
done

# var in levels must be packed in 25 file tar each
for var in hus ta ua va wap zg
do
   NUMB_FOUND=`ls -1 ${header}*_${var}_*sha256 | wc -l`
   if [ $((${NUMB_FOUND} * 2)) -eq ${NUMB_CHECK} ] ; then
# IN THE FOLLOWING CASES VARS ARE DOUBLE WE SPLIT
    
# need to extract model,freq and type
      f=`ls -1 ${header}_*_${var}_r* | head -1`
      mft=`echo $f | cut -d '_' -f5-7`
      numb_nc=$nrunC3Sfore
# BAU forecast or hindcast operational
         #first 10
      list_0=`ls ${header}_*_${var}_r0* ${header}_*_${var}_r10*`
      tar -cf ${header}_${mft}_${var}_n1-n10.tar ${list_0}
      if [ $? -eq 0 ] ; then
        sha256sum ${header}_${mft}_${var}_n1-n10.tar > ${header}_${mft}_${var}_n1-n10.sha256
        rsync -auv --remove-source-files ${header}_${mft}_${var}_n1-n10.* $pushdir_hc
      else
         echo "something wrong in shasum ${yyyy}${st} $var"
      fi

         #second 15
      list_1=`ls ${header}_*_${var}_r1[1-9]* ${header}_*_${var}_r2*`
      tar -cf ${header}_${mft}_${var}_n11-n25.tar ${list_1}
      if [ $? -eq 0 ] ; then
         sha256sum ${header}_${mft}_${var}_n11-n25.tar > ${header}_${mft}_${var}_n11-n25.sha256
         rsync -auv --remove-source-files ${header}_${mft}_${var}_n11-n25.* $pushdir_hc
      else
         echo "something wrong in shasum ${yyyy}${st} $var"
      fi

         #FOR SPS4 HINDCAST WE STOP HERE - 30 members in hindcast mode       
  
   else
      body="CERISE: standardisation error in script $DIR_C3S/tar_CERISE.sh: start date ${yyyy}${st} incorrect number of files to tar for variable: ${var} Expected ${NUMB_CHECK} found ${NUMB_FOUND} in $WORK_CERISE_final/${start_date}. See log $DIR_LOG/$start_date/tar_CERISE..."
      title="[CERISE] ${CPSSYS} $typeofrun ERROR"
      ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -s $yyyy$st -r $typeofrun
      exit
   fi #if on number of var
done  #end loop on var_array3d

#check if everything is ok inside the tarfiles
$DIR_C3S/check_tarCERISE_phase2.sh $yyyy $st $CERISEtable
stat=$?
if [ $stat -eq 0 ]
then
   body="CERISE: $DIR_LOG/tar_CERISE.sh completed for ${start_date}."
   title="[CERISE] ${CPSSYS} $typeofrun notification"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r $typeofrun -s $start_date
   touch ${check_tar_done}
else
   body="CERISE: $DIR_C3S/check_tarCERISE_phase2.sh failed for ${start_date}. Exiting now. Check and fix"
   title="[CERISE] ${CPSSYS} $typeofrun ERROR"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r $typeofrun -s $start_date
   exit 1
fi   

