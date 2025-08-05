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
   body="C3S: tar_C3S already done for ${start_date}. Exiting from $DIR_C3S/tar_C3S.sh now"
   title="[C3S] ${CPSSYS} $typeofrun notification"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" 
   exit
fi
C3Stable_cam=$DIR_POST/cam/C3S_table.txt
C3Stable_clm=$DIR_POST/clm/C3S_table_clm.txt
C3Stable_oce1=$DIR_POST/nemo/C3S_table_ocean2d_others.txt
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
   if [ $freq == "12hr" ]
   then
      var_array3d+=("$C3S")
   else
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
   cd $WORK_C3S/${start_date}
   nmb_tar_wkdir=`ls $WORK_C3S/${start_date}/cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${start_date}0100_*_${var}_*n*-n*.tar |wc -l`
   if [[ ${nmb_tar_wkdir} -ne 0 ]]
   then
        rm $WORK_C3S/${start_date}/cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${start_date}0100_*_${var}_*n*-n*.tar
   fi  

   listatocheck+="`ls cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${start_date}0100_*_${var}_*.nc | head -n $nrunC3Sfore` "

done
echo $listatocheck


cd $WORK_C3S/${start_date}
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
    body="C3S: $DIR_C3S/tar_C3S.sh found `ls $listatocheck |wc -l`files instead of $(($nrunC3Sfore * $nfieldsC3S)) in $WORK_C3S/${start_date}"
    title="[C3S] ${CPSSYS} $typeofrun ERROR"
    ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r $typeofrun -s $start_date 
    exit 2
fi
#
# change_realization if needed
#----------------------------
####MB 20240825 - COMMENTED for now
${DIR_C3S}/change_realization.sh $yyyy $st

# nel caso in cui change_realization.sh e' ridondante
listatocheck=" "
for var in "${var_array[@]}"
do
  listatocheck+=" `ls cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${start_date}0100_*_${var}_*.nc |head -n $nrunC3Sfore`"
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
      if [ $nstep -ne $fixsimdays ]
      then
          body="C3S: $DIR_C3S/tar_C3S.sh found number of days in file $nstep different from expected $fixsimdays for file $file in $WORK_C3S/${start_date}. See log $DIR_LOG/$start_date/tar_C3S..."
          title="[C3S] ${CPSSYS} forecast ERROR"
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
        body="C3S: $DIR_C3S/tar_C3S.sh found number of timesteps in file $nstep different from expected ${n6hr}  for file $file in $WORK_C3S/${start_date}. See log $DIR_LOG/$start_date/tar_C3S..."
        title="[C3S] ${CPSSYS} forecast ERROR"
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
         body="C3S: $DIR_C3S/tar_C3S.sh found number of timesteps in file $nstep different from expected ${n12hr}  for file $file in $WORK_C3S/${start_date}. See log $DIR_LOG/$start_date/tar_C3S..."
         title="[C3S] ${CPSSYS} forecast ERROR"
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
   if [ -f $file.sha256 ]
   then
     rm $file.sha256
   fi
   sha256sum ${file}.nc > $file.sha256
done

donotsend=0
NUMB_CHECK=`expr $nrunC3Sfore + $nrunC3Sfore` # for each field we have the .nc file and .sha


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
   if [ $((${NUMB_FOUND} * 2)) -eq ${NUMB_CHECK} ] ; then
     
     # need to extract model,freq and type
     f=`ls -1 cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_*_${var}_r* | head -1`
     mft=`echo $f | cut -d '_' -f5-7`
     listafile2tar=" "
     for ens in `seq -w 01 $nrunC3Sfore`
     do
        listafile2tar+=" `ls cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_*_${var}_r${ens}*`"
     done
     if [ `echo $listafile2tar|wc -w` -ne $(($nrunC3Sfore * 2)) ]
     then
         body="C3S: standardisation error in script $DIR_C3S/tar_C3S.sh: start date ${yyyy}${st} incorrect number of files to tar for variable: ${var} Expected $(($nrunC3Sfore * 2)) found `echo $listafile2tar|wc -w` in $WORK_C3S/${start_date}. See log $DIR_LOG/$start_date/tar_C3S..."
         title="[C3S] ${CPSSYS} $typeofrun ERROR"
         ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -s $yyyy$st -r $typeofrun
         exit 3
     fi
     tar -cf cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_${mft}_${var}_n1-n${nrunC3Sfore}.tar $listafile2tar
     
     if [ $? -eq 0 ] ; then
        sha256sum cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_${mft}_${var}_n1-n${nrunC3Sfore}.tar > cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_${mft}_${var}_n1-n${nrunC3Sfore}.sha256 
     
     #copy in dtn01 to push
        rsync -auv --remove-source-files cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_${mft}_${var}_n1-n${nrunC3Sfore}.* $pushdir_hc
     else
        echo "something wrong in shasum ${yyyy}${st} $var"
     fi

   else
#mail MACHINE DEPENDENT chek if present
      body="C3S: standardisation error in script $DIR_C3S/tar_C3S.sh: start date ${yyyy}${st} incorrect number of files to tar for variable : ${var} Expected ${NUMB_CHECK} found ${NUMB_FOUND} in $WORK_C3S/${start_date}. See log $DIR_LOG/$start_date/tar_C3S..."
      title="[C3S] ${CPSSYS} $typeofrun ERROR"
      ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r $typeofrun -s ${yyyy}${st}
      donotsend=1
      exit
   fi
done

# var in levels must be packed in 25 file tar each
for var in "${var_array3d[@]}"
do
   NUMB_FOUND=`ls -1 cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}*_${var}_*sha256 | wc -l`
   if [ $((${NUMB_FOUND} * 2)) -eq ${NUMB_CHECK} ] ; then
# IN THE FOLLOWING CASES VARS ARE DOUBLE WE SPLIT
    
# need to extract model,freq and type
      f=`ls -1 cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_*_${var}_r* | head -1`
      mft=`echo $f | cut -d '_' -f5-7`
      numb_nc=$nrunC3Sfore
      if [[ $nrunC3Sfore -lt 10 ]] ; then  #SHOULD BE THE TEST CASE
         if [[ `whoami` == "$operational_user" ]] && [[ "$machine" == "juno" ]]
         then
              body="nrunC3Sfore set to $nrunC3Sfore instead of the required for operations. Exiting from tar_C3S.sh"
              title="[C3S] ${CPSSYS} $typeofrun ERROR"
              ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -s $yyyy$st -r $typeofrun
              exit 2
         fi
         list_0=`ls cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_*_${var}_r0*`
         tar -cf cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_${mft}_${var}_n1-n10.tar ${list_0}
         if [ $? -eq 0 ] ; then
             sha256sum cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_${mft}_${var}_n1-n10.tar > cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_${mft}_${var}_n1-n10.sha256
             rsync -auv --remove-source-files cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_${mft}_${var}_n1-n10.* $pushdir_hc
         else
              echo "something wrong in shasum ${yyyy}${st} $var"
         fi
      else 
# BAU forecast or hindcast operational
         #first 10
         list_0=`ls cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_*_${var}_r0* cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_*_${var}_r10*`
         tar -cf cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_${mft}_${var}_n1-n10.tar ${list_0}
         if [ $? -eq 0 ] ; then
            sha256sum cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_${mft}_${var}_n1-n10.tar > cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_${mft}_${var}_n1-n10.sha256
           rsync -auv --remove-source-files cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_${mft}_${var}_n1-n10.* $pushdir_hc
         else
            echo "something wrong in shasum ${yyyy}${st} $var"
         fi

         #second 10
         list_1=`ls cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_*_${var}_r1[1-9]* cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_*_${var}_r20*`
         tar -cf cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_${mft}_${var}_n11-n20.tar ${list_1}
         if [ $? -eq 0 ] ; then
            sha256sum cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_${mft}_${var}_n11-n20.tar > cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_${mft}_${var}_n11-n20.sha256
            rsync -auv --remove-source-files cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_${mft}_${var}_n11-n20.* $pushdir_hc
         else
            echo "something wrong in shasum ${yyyy}${st} $var"
         fi

         #third  10
         list_2=`ls -1 cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_*_${var}_r2[1-9]* cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_*_${var}_r30*`
         tar -cf cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_${mft}_${var}_n21-n30.tar ${list_2}
         if [ $? -eq 0 ] ; then
            sha256sum cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_${mft}_${var}_n21-n30.tar > cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_${mft}_${var}_n21-n30.sha256
            rsync -auv --remove-source-files cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_${mft}_${var}_n21-n30.* $pushdir_hc
         else
            echo "something wrong in shasum ${yyyy}${st} $var"
         fi
         #FOR SPS4 HINDCAST WE STOP HERE - 30 members in hindcast mode       
  
         if [ $nrunC3Sfore -eq 50 ]
         then 
             #fourth 10
             list_3=`ls -1 cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_*_${var}_r3[1-9]* cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_*_${var}_r40*`
             tar -cf cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_${mft}_${var}_n31-n40.tar ${list_3}
             if [ $? -eq 0 ] ; then
                   sha256sum cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_${mft}_${var}_n31-n40.tar > cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_${mft}_${var}_n31-n40.sha256
                   rsync -auv --remove-source-files cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_${mft}_${var}_n31-n40.* $pushdir_hc
             else
                  echo "something wrong in shasum ${yyyy}${st} $var"
             fi

             #fifth 10
             list_4=`ls -1 cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_*_${var}_r4[1-9]* cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_*_${var}_r50*`
             tar -cf cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_${mft}_${var}_n41-n50.tar ${list_4}
             if [ $? -eq 0 ] ; then
               sha256sum cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_${mft}_${var}_n41-n50.tar > cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_${mft}_${var}_n41-n50.sha256
               rsync -auv --remove-source-files cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_${mft}_${var}_n41-n50.* $pushdir_hc
             else
                echo "something wrong in shasum ${yyyy}${st} $var"
             fi 
         fi
      fi
   else
      body="C3S: standardisation error in script $DIR_C3S/tar_C3S.sh: start date ${yyyy}${st} incorrect number of files to tar for variable: ${var} Expected ${NUMB_CHECK} found ${NUMB_FOUND} in $WORK_C3S/${start_date}. See log $DIR_LOG/$start_date/tar_C3S..."
      title="[C3S] ${CPSSYS} $typeofrun ERROR"
      ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -s $yyyy$st -r $typeofrun
      donotsend=1
      exit
   fi #if on number of var
done  #end loop on var_array3d

#check if everything is ok inside the tarfiles
$DIR_C3S/check_tarC3S.sh $yyyy $st
stat=$?
if [ $stat -eq 0 ]
then
   body="C3S: $DIR_LOG/tar_C3S.sh completed for ${start_date}."
   title="[C3S] ${CPSSYS} $typeofrun notification"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r $typeofrun -s $start_date
   touch ${check_tar_done}
else
   body="C3S: $DIR_C3S/check_tarC3S.sh failed for ${start_date}. Exiting now. Check and fix"
   title="[C3S] ${CPSSYS} $typeofrun ERROR"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r $typeofrun -s $start_date
   exit 1
fi   

#--------------------------------------------
# NOW SUBMIT PUSH4ECMWF (only forecast)
#--------------------------------------------
skip=1
if [[ $skip -eq 0 ]]
then
if [[ $typeofrun == "forecast" ]]
then
   input="$yyyy $st"
   ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_m -r $sla_serialID -S qos_resv -j launch_diag_web_$yyyy$st -l $DIR_LOG/$typeofrun/$yyyy$st -d $DIR_DIAG -s launch_diagnostic_webpage.sh -i "$input"
  
   body="Diagnostics from C3S just launched. Check plots on mail and website update in 40 minute time. When you are ready, submit $DIR_SPS35/launch_end_forecast_${CPSSYS}.sh manually"
   title="[C3S] ${CPSSYS} $typeofrun notification"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" 

fi
fi

#--------------------------------------------
# NOW COMPRESS ICs RELATIVE TO CURRENT START-DATE
#--------------------------------------------
#if [ `whoami` == $operational_user ]
#then
#   $IC_SPS35/compress_ICs_current_startdate.sh $st $yyyy
#fi
