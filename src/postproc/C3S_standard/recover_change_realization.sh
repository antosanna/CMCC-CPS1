#!/bin/sh -l

# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. ${DIR_UTIL}/load_nco

set -evxu
skip=0
# get input from previous script
yyyy=2025         #year start-date
st=05         #month start-date (2 figures)

set +uevx
. $DIR_UTIL/descr_ensemble.sh $yyyy
set -evxu

skip=0    # if 1 do not do the renumbering and go to extra member removal section
tochange=()
tobecome=()
#define working dir
wkdir=$WORK_C3S/${yyyy}${st}
cd $wkdir

list_ens=`ls all_checkers_ok_???`


if [[ $skip -eq 0 ]]
then
   #arr2 contains only numbers present in $ensmble but not in $ensembleECMWF
   arr2=`echo ${ensembleECMWF[@]} ${ensembleECMWF[@]} ${ensemble[@]} | tr ' ' '\n' | sort | uniq -u `
   echo ${arr2[@]}
   # now create arrays from strings
   #first numbers to be changed
   for elem in ${arr1[@]} ; do
      tobecome+=("${elem}")
   done
   #then numbers to be set
   for elem in ${arr2[@]} ; do
      tochange+=("${elem}")
   done
   echo ${tochange[@]}
   echo ${tobecome[@]}
   dim=`echo ${tochange[@]}|wc -w`
   #
   if [ $dim -ne 0 ]
   then
      mkdir -p $DIR_LOG/$typeofrun/${yyyy}${st}/change_realization
      body="Starting renumbering for $dim members in forecast $yyyy$st from ${tochange[@]} to ${tobecome[@]}. Script is $DIR_C3S/tar_C3S.sh"
      title="[C3S] ${CPSSYS} forecast notification"
      ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r $typeofrun -s $yyyy$st
      
      #DEFINE TEMPORARY DIR new
      mkdir  -p $wkdir/new
      for ((i=0;i<$dim;i+=1))
      do
         cd $wkdir
         echo ${tochange[$i]} ${tobecome[$i]}
   # at the end of the day you will have to remove ${SPSSystem}_${yyyy}${st}_0${tobecome[$i]} everywhere so to keep only data effectively used to produce the C3S  20210802
         if [[ -f $DIR_LOG/$typeofrun/$yyyy$st/${SPSSystem}_${yyyy}${st}_0${tochange[$i]}_change_realization_to_${tobecome[$i]} ]]
         then
            continue
         fi
         touch $DIR_LOG/$typeofrun/$yyyy$st/${SPSSystem}_${yyyy}${st}_0${tochange[$i]}_change_realization_to_${tobecome[$i]}
         old_removed=$DIR_LOG/$typeofrun/$yyyy$st/change_realization/${SPSSystem}_${yyyy}${st}_0${tochange[$i]}_C3S_removed
         if [[ ! -f $old_removed ]]
         then
            lista1=`ls *r${tochange[$i]}i00p00.nc`
            for file in $lista1
            do
               out=`echo $file |cut -d '_' -f1-8`
         # Change realization att
               if [[ ! -f  $wkdir/new/${out}_r${tobecome[$i]}i00p00.nc ]]
               then
                  #ncap2 -Oh -s 'realization="r'${tobecome[$i]}'i00p00"' $file $wkdir/new/${out}_r${tobecome[$i]}i00p00.nc
# new syntax preserving the mandatory 13 characters
                  ncap2 -Oh -s 'realization(0:8)="r'${tobecome[$i]}'i00p00"' $file $wkdir/new/${out}_r${tobecome[$i]}i00p00.nc 
               fi
                  sha256sum $wkdir/new/${out}_r${tobecome[$i]}i00p00.nc > $wkdir/new/${out}_r${tobecome[$i]}i00p00.sha256 
            done
   #do the same for DMO files +
            if [[ $skip -eq 0 ]]
            then 
               caso2change=${SPSSystem}_${yyyy}${st}_0${tochange[$i]}
               caso_tobecome=${SPSSystem}_${yyyy}${st}_0${tobecome[$i]}
               cd ${DIR_ARCHIVE}/
               if [[ -d ${DIR_ARCHIVE}/$caso_tobecome ]]
               then
                  chmod -R u+wX $caso_tobecome
                  ####for safety####
                  mkdir -p $SCRATCHDIR/change_realization/$yyyy$st
                  rsync -auv $caso_tobecome $SCRATCHDIR/change_realization/$yyyy$st/.
                  chmod -R u+wX $caso2change
                  rsync -auv $caso2change $SCRATCHDIR/change_realization/$yyyy$st/.
                  ####for safety####
                  rm -rf $caso_tobecome
               fi
               mv $caso2change $caso_tobecome
               cd ${DIR_ARCHIVE}/$caso_tobecome
               chmod -R u+w ${DIR_ARCHIVE}/$caso_tobecome
               for dir in rof lnd ice atm
               do
                   dirflag=$DIR_LOG/$typeofrun/${yyyy}${st}/change_realization/${caso2change}_${caso_tobecome}_${dir}_done
                   if [[ -f $dirflag ]]
                   then
                      continue
                   fi
                   cd ${DIR_ARCHIVE}/$caso_tobecome/$dir/hist/
                   filelist=`ls *`
                   for file in $filelist
                   do
                      #keepname=`echo $file|cut -d '.' -f3-`
                      keepname=`echo $file|cut -d '.' -f2-`
                      mv $file ${caso_tobecome}.${keepname}
                   done
                   touch $dirflag
               done
               for dir in ocn
               do
                   cd ${DIR_ARCHIVE}/$caso_tobecome/$dir/hist/
                   dirflag=$DIR_LOG/$typeofrun/${yyyy}${st}/change_realization/${caso2change}_${caso_tobecome}_${dir}_done
                   if [[ -f $dirflag ]]
                   then
                      continue
                   fi
                   filelist=`ls *`
                      for file in $filelist
                   do
                      keepname=`echo $file|cut -d '_' -f4-`
                      mv $file ${caso_tobecome}_${keepname}
                   done
                   touch $dirflag
               done
               dir=rest
               cd ${DIR_ARCHIVE}/$caso_tobecome/$dir/????-??-01-00000
               dirflag=$DIR_LOG/$typeofrun/${yyyy}${st}/change_realization/${caso2change}_${caso_tobecome}_${dir}_done1
               if [[ ! -f $dirflag ]]
               then
                  #filelist=`ls *|grep -v restart`
                  filelist=`ls *.nc|grep -v restart`
                  for file in $filelist
                  do
                     keepname=`echo $file|cut -d '.' -f2-`
                     mv $file ${caso_tobecome}.${keepname}
                  done
                  touch $dirflag
               fi
               dirflag=$DIR_LOG/$typeofrun/${yyyy}${st}/change_realization/${caso2change}_${caso_tobecome}_${dir}_done2
               if [[ ! -f $dirflag ]]
               then
                  filelist=`ls *.nc|grep restart`
                  for file in $filelist
                  do
                     keepname=`echo $file|cut -d '_' -f4-`
                     mv $file ${caso_tobecome}_${keepname}
                  done
                  touch $dirflag
               fi
      set +e
      # in case already run you may not found those files
               rm $wkdir/*r${tochange[$i]}i00p00.*
               rsync -auv --remove-source-files $wkdir/new/*r${tobecome[$i]}i00p00.nc $wkdir
               rsync -auv --remove-source-files $wkdir/new/*r${tobecome[$i]}i00p00.sha256 $wkdir
               touch $old_removed
      set -e
            fi
            chmod -R u-w $DIR_ARCHIVE/$caso_tobecome
   #RECOMPUTE daily C3S for these members
            checkfile_daily=$SCRATCHDIR/wk_C3S_daily/$yyyy$st/C3S_daily_mean_2d_${tobecome[$i]}_ok
         #checkfile_daily=$FINALARCHC3S/$yyyy$st/qa_checker_daily_ok_${tobecome[$i]}
   # this is needed so that if in any case the tar_C3S.sh is relaunched it will not try to redo the renumbering (see section 1.)
            touch $WORK_C3S/$yyyy$st/all_checkers_ok_0${tobecome[$i]}
   # rm the previously compute checkfile_daily
            if [ -f $checkfile_daily ]
            then
               rm $checkfile_daily
            fi
            ens=${tobecome[$i]}
            ${DIR_POST}/C3S_standard/launch_C3S_daily_mean.sh $st $yyyy $ens
         #$DIR_UTIL/submitcommand.sh -m $machine -M 1600 -q $serialq_l -t "2" -r $sla_serialID -S qos_resv -j C3S_daily_after_change_realization_${yyyy}$st${ens} -l ${DIR_LOG}/${typeofrun}/${yyyy}${st}/ -d ${DIR_POST}/C3S_standard -s launch_C3S_daily_mean.sh -i "$st $yyyy $ens $checkfile_daily"
         fi    # skip this section for POP 202505
      done
   
   fi
fi

#----------------------------------------------------
###EXTRA MEMBERS DMO - removing section!
# will be done by crontab the 15th of the month
#----------------------------------------------------
