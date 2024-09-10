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
lista_redoqa_error=" "
lista_redometa_error=" "

set -ex
cd $WORK_C3S
for yyyy in $listayears
do
   set +exuv
   . $DIR_UTIL/descr_ensemble.sh $yyyy
   set -ex
   if [[ -z $ens_number ]]
   then
      echo "missing ensemble list. Getting default defined here"
      ens_number=`seq -w 01 $nrunC3Sfore`
   fi
   
   startdate=${yyyy}${st}
   cd $WORK_C3S/${yyyy}$st
   for member in $ens_number
   do
       set +euvx
       . $dictionary
       set -ex
#$SCRATCHDIR/C3Schecker/$typeofrun/$startdate/$member/${member}_c3s_meta_ok
       listaens=`ls cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_*_r${member}i00p00.nc`
       if [ -n $qa ]     #meaning qa null
       then
         if [ ! -f $check_c3s_qa_ok ]
         then
                echo "this checkfile $check_c3s_qa_ok has not been produced. Rerun the checker"
                lista_redoqa+=" ${SPSSystem}_${yyyy}${st}_0${member}"
         else
            for file in $listaens
            do
               if [[ $file -nt $check_c3s_qa_ok  ]]
               then
                   echo "This file $file is newer than the checkfile $check_c3s_qa_ok "
                   lista_redoqa+=" ${SPSSystem}_${yyyy}${st}_0${member}"
                   rm ${check_c3s_qa_ok}
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
         if [ ! -f $check_c3s_meta_ok ]
         then
            echo "${check_c3s_meta_ok} does not exist"
            lista_redometa+=" ${SPSSystem}_${yyyy}${st}_0${member}"
         else   
            for file in $listaens
            do
               if [[ $file -nt $check_c3s_meta_ok ]]
               then
                   echo "This file $file is newer than the checkfile $check_c3s_meta_ok "
                   lista_redometa+=" ${SPSSystem}_${yyyy}${st}_0${member}"
                   rm ${check_c3s_meta_ok}
                   break
               fi
            done
         fi
         if [ "$lista_redometa" == " " ]
         then
             echo "meta checks all right"
         fi
       fi
   done
done


for caso in $lista_redoqa
do
   yyyy=`echo $caso|cut -d '_' -f2|cut -c 1-4`
   st=`echo $caso|cut -d '_' -f2|cut -c 5-6`
   real=`echo $caso|cut -d '_' -f3|cut -c 2-3`
   outdirC3S=${WORK_C3S}/$yyyy$st
   #checkfile=$DIR_CASES/$caso/logs/qa_redo_${yyyy}${st}_0${member}_ok
   #mkdir -p $DIR_CASES/$caso/logs/
   #if [ -f $checkfile ]
   #then
   #   rm $checkfile
   #fi
   #mkdir -p ${DIR_LOG}/$typeofrun/${yyyy}${st}
   #${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_l -j qa_checker_main_${yyyy}${st}${member} -l ${DIR_LOG}/CHECKER/$yyyy$st -d ${DIR_C3S} -s launch_c3s_qa_checker_1member.sh -i "${yyyy}${st} $member $checkfile ${WORK_C3S}/$yyyy$st/"
   
  $DIR_C3S/launch_c3s_qa_checker.sh $yyyy$st $real $outdirC3S

  if [ ! -f $check_c3s_qa_ok ]
  then
    lista_redoqa_error=+=" $caso"
  fi
done

for caso in $lista_redometa
do
   yyyy=`echo $caso|cut -d '_' -f2|cut -c 1-4`
   st=`echo $caso|cut -d '_' -f2|cut -c 5-6`
   real=`echo $caso|cut -d '_' -f3|cut -c 2-3`
   startdate=${yyyy}$st
   dir_log_checker==$SCRATCHDIR/C3Schecker/$typeofrun/$startdate/$real/
   outdirC3S=${WORK_C3S}/$yyyy$st
#   ${DIR_C3S}/c3s_metadata_checker_1member.sh ${yyyy}${st} $member ${WORK_C3S}/$yyyy$st

   ${DIR_C3S}/launch_c3s-nc-checker.sh $startdate $real $outdirC3S $dir_log_checker
   
   # check that ok file was produced
   if [ ! -f  ${check_c3s_meta_ok} ]
   then
    lista_redometa_error+=" $caso"
   fi
done


#send mail with cases with error
cnt_lista_redoqa_error=`echo $lista_redoqa_error |wc -w`
cnt_lista_redometa_error=`echo $lista_redometa_error |wc -w`
if [[ $cnt_lista_redoqa_error -gt 0 ]] || [[ $cnt_lista_redometa_error -gt 0 ]] 
then
  title="[${CPSSYS} ERROR] Error in $DIR_UTIL/check_production_time "
  body="Some of the traffic lights were older than the corresponding checked file and were relaunched but some error occured during the check. \n
        Cases with error in c3s_qa_checker: $lista_redoqa_error \n 
        Cases with error in c3s-nc-checker: $lista_redometa_error \n"
  
  ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "$typeofrun" -s $yyyy$st
  exit 1
fi

exit 0
