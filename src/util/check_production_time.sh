#!/bin/sh -l
# TO BE TESTED
. ~/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
#set -evx
set -e
usage() { echo "Usage: $0 [-m <machine string >] [-s <start-date month string >] [-y <start-date year 4i >] [-e <ensemble number 2i OPTIONAL>] [-f <find-spikes-flag string OPTIONAL>] [-q <quality-check-flag string OPTIONAL>] [-m <meta-checker-flag string OPTIONAL>] [-t <tmpl-checker-flag string OPTIONAL>] [-d <working dir string OPTIONAL>]" 1>&2; exit 1; }

while getopts ":m:s:y:e:f:q:m:t:d:" o; do
    case "${o}" in
        m)
            machine=${OPTARG}
            ;;
        q)
            qa=${OPTARG}
            ;;
        e)
            ens_number=${OPTARG}
            ;;
        f)
            findspike=${OPTARG}
            ;;
        s)
            st=${OPTARG}
            ;;
        y)
            listayears=${OPTARG}
            ;;
        m)
            meta=${OPTARG}
            ;;
        t)
            tmpl=${OPTARG}
            ;;
        d)
            WORK_C3S=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done

if [ -z $machine ]
then
   echo "missing machine"
   usage
fi
if [ -z $listayears ]
then
   echo "missing start-date year. Getting default defined here"
   listayears="2003 2020"
fi
if [ -z $st ]
then
   echo "missing start-date month Getting default defined here"
   sst=11
fi

lista_redoqa=" "
lista_redometa=" "
lista_redotmpl=" "
lista_redofindspike=" "
lista_redoqa_error=" "
lista_redometa_error=" "
lista_redotmpl_error=" "
lista_redofindspike_error=" "

set -ex
cd $WORK_C3S
for yyyy in $listayears
do
   . $DIR_UTIL/descr_ensemble.sh $yyyy

   if [ -z $ens_number ]
   then
      echo "missing ensemble list. Getting default defined here"
      ens_number=`seq -w 01 $nrunC3Sfore`
   fi
   cd $WORK_C3S/${yyyy}$st
   for member in $ens_number
   do
       listaens=`ls cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_*_r${member}i00p00.nc`
       if [ -n $qa ]     #meaning qa null
       then
         check=qa_checker_ok_0${member}
         if [ ! -f $check ]
         then
                echo "questo file $check non e' stato prodotto. Rifare"
                lista_redoqa+=" ${SPSsystem}_${yyyy}${st}_0${member}"
         else
            for file in $listaens
            do
               if [[ $file -nt ${check} ]]
               then
                   echo "questo file $file e piu nuovo del suo check $check "
                   lista_redoqa+=" ${SPSsystem}_${yyyy}${st}_0${member}"
                   rm ${check}
                   break
               fi
            done
         fi
         if [ "$lista_redoqa" == " " ]
         then
             echo "qa checks all right"
         fi
       fi
       if [ -n $meta ] 
       then
         check=meta_checker_ok_0${member}
         if [ ! -f $check ]
         then
            echo "$check does not exist"
            lista_redometa+=" ${SPSsystem}_${yyyy}${st}_0${member}"
         else   
            for file in $listaens
            do
               if [[ $file -nt ${check} ]]
               then
                   echo "questo file $file e piu nuovo del suo check $check "
                   lista_redometa+=" ${SPSsystem}_${yyyy}${st}_0${member}"
                   rm ${check}
                   break
               fi
            done
         fi
         if [ "$lista_redometa" == " " ]
         then
             echo "meta checks all right"
         fi
       fi
       if [ -n $tmpl ] 
       then
         check=tmpl_checker_ok_0${member}
         if [ ! -f $check ]
         then
            echo "$check does not exist"
            lista_redotmpl+=" ${SPSsystem}_${yyyy}${st}_0${member}"
         else   
            for file in $listaens
            do
              if [[ $file -nt ${check} ]]
              then
                  echo "questo file $file e piu nuovo del suo check $check "
                  lista_redotmpl+=" ${SPSsystem}_${yyyy}${st}_0${member}"
                   rm ${check}
                  break
              fi
            done
         fi
         if [ "$lista_redotmpl" == " " ]
         then
             echo "tmpl checks all right"
         fi
       # lista separata per findspikes_c3s_ok (solo tmax)
       fi
       if [ -n $findspike ] 
       then
         listaens_tas=`ls cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_*tas*_r${member}i00p00.nc`
         check=findspikes_c3s_ok_0${member}
         if [ ! -f $check ]
         then
            echo "$check does not exist"
            lista_redofindspike+=" ${SPSsystem}_${yyyy}${st}_0${member}"
         else   
            for file in $listaens_tas
            do
               if [[ $file -nt ${check} ]]
               then
                   echo "questo file $file e piu nuovo del suo check $check "
                   lista_redofindspike+=" ${SPSsystem}_${yyyy}${st}_0${member}"
                   rm ${check}
                   break
               fi
            done
         fi
         if [ "$lista_redofindspike" == " " ]
         then
             echo "findspike checks all right"
         fi
      fi
   done
done

# Relaunch cases in lista_redo*
for caso in $lista_redofindspike
do
   yyyy=`echo $caso|cut -d '_' -f2|cut -c 1-4`
   st=`echo $caso|cut -d '_' -f2|cut -c 5-6`
   member=`echo $caso|cut -d '_' -f3|cut -c 2-3`
   findsp_check=$DIR_CASES/$caso/logs/findspikes_redo_0${member}
   var="tasmax"
   varfile="cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_atmos_day_surface_tasmax_r${member}i00p00.nc"
   checkerversion=c3s_qa_checker.py
   set +e
   conda activate CHECK_ENV_DEV
   set -e
   mkdir -p ${DIR_LOG}/CHECKER/${yyyy}${st}
   python ${DIR_UTIL}/${checkerversion} $varfile -p ${WORK_C3S}/${yyyy}${st} -v $var -exp ${yyyy}${st} -j ${DIR_UTIL}/qa_checker_table.json -real 0${member} -l ${DIR_LOG}/CHECKER/${yyyy}${st} --verbose >> ${DIR_LOG}/CHECKER/${yyyy}${st}/log_${var}_spikes_${yyyy}${st}_${member}
  if [ ! -f ${DIR_LOG}/CHECKER/${yyyy}${st}/list_spikes_on_ice_${yyyy}${st}_${member}.txt ]
  then
    mkdir -p $WORK_C3S/${yyyy}${st}/
    touch $WORK_C3S/${yyyy}${st}/findspikes_c3s_ok_${member}
  fi
  
  # check that ok file was produced
  if [ ! -f $WORK_C3S/${yyyy}${st}/findspikes_c3s_ok_${member} ]
  then
    lista_redofindspike_error+=" $caso"
  fi
done

for caso in $lista_redoqa
do
   yyyy=`echo $caso|cut -d '_' -f2|cut -c 1-4`
   st=`echo $caso|cut -d '_' -f2|cut -c 5-6`
   member=`echo $caso|cut -d '_' -f3|cut -c 2-3`
   checkfile=$DIR_CASES/$caso/logs/qa_redo_${yyyy}${st}_0${member}_ok
   mkdir -p $DIR_CASES/$caso/logs/
   if [ -f $checkfile ]
   then
      rm $checkfile
   fi
   mkdir -p ${DIR_LOG}/CHECKER/${yyyy}${st}
   ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_l -j qa_checker_main_${yyyy}${st}${member} -l ${DIR_LOG}/CHECKER/$yyyy$st -d ${DIR_C3S} -s launch_c3s_qa_checker_1member.sh -i "${yyyy}${st} $member $checkfile ${WORK_C3S}/$yyyy$st/"
   
  #wait for job to finish and check that ok file was produced
  while `true`
  do
    if [ -f $checkfile ]
    then
      break
    fi
    sleep  300
  done   

  if [ ! -f $checkfile ]
  then
    lista_redoqa_error=+=" $caso"
  fi
done

for caso in $lista_redometa
do
   yyyy=`echo $caso|cut -d '_' -f2|cut -c 1-4`
   st=`echo $caso|cut -d '_' -f2|cut -c 5-6`
   member=`echo $caso|cut -d '_' -f3|cut -c 2-3`
   ${DIR_C3S}/c3s_metadata_checker_1member.sh ${yyyy}${st} $member ${WORK_C3S}/$yyyy$st
   
   # check that ok file was produced
   if [ ! -f $WORK_C3S/${yyyy}$st/meta_checker_ok_0${member} ]
   then
    lista_redometa_error+=" $caso"
   fi
done

for caso in $lista_redotmpl
do
   yyyy=`echo $caso|cut -d '_' -f2|cut -c 1-4`
   st=`echo $caso|cut -d '_' -f2|cut -c 5-6`
   member=`echo $caso|cut -d '_' -f3|cut -c 2-3`
   ${DIR_C3S}/launch_c3s_tmpl_checker.sh ${yyyy}${st} $member ${WORK_C3S}/$yyyy$st
   
   # check that ok file was produced
   if [ ! -f $WORK_C3S/${yyyy}$st/tmpl_checker_ok_0${member} ]
   then 
     lista_redotmpl_error+=" $caso"
   fi
done

#send mail with cases with error
cnt_lista_redoqa_error=`echo $lista_redoqa_error |wc -w`
cnt_lista_redometa_error=`echo $lista_redometa_error |wc -w`
cnt_lista_redotmpl_error=`echo $lista_redotmpl_error |wc -w`
cnt_lista_redofindspike_error=`echo $lista_redofindspike_error |wc -w`
if [ $cnt_lista_redoqa_error -gt 0 ] || [ $cnt_lista_redometa_error -gt 0 ] || [ $cnt_lista_redotmpl_error -gt 0 ] || [ $cnt_lista_redofindspike_error -gt 0 ]
then
  title="[${SPSSYS} ERROR] Error in $DIR_UTIL/check_production_time "
  body="Some of the traffic lights were older than the corresponding checked file and were relaunched but some error occured during the check. \n
        Cases with error in qa: $lista_redoqa_error \n 
        Cases with error in tmpl: $lista_redotmpl_error \n 
        Cases with error in meta: $lista_redometa_error \n 
        Cases with error in spike: $lista_redofindspike_error \n 
        More info in the log files in ${DIR_LOG}/CHECKER/$yyyy$st"
  ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "$typeofrun" -s $yyyy$st
  exit 1
fi

exit 0
