#!/bin/sh -l
#BSUB -J copy_SPS4DMO_from_Leonardo_spike
#BSUB -q s_download
#BSUB -o /work/cmcc/cp1/CPS/CMCC-CPS1/logs/leonardo_transfer/copy_SPS4DMO_from_Leonardo_spike.out.%J  
#BSUB -e /work/cmcc/cp1/CPS/CMCC-CPS1/logs/leonardo_transfer/copy_SPS4DMO_from_Leonardo_spike.err.%J  
#BSUB -P 0490
#BSUB -M 1000

. $HOME/.bashrc
. $DIR_UTIL/descr_CPS.sh
# First check that no other this script is running
if [ `${DIR_UTIL}/findjobs.sh -m ${machine} -n copy_SPS4DMO_from_Leonardo -c yes ` -gt 4 ]
then
   exit
fi
#load module for sshpass
module load intel-2021.6.0/sshpass/.1.06-zarp3
set -uvx

leo_dir=/leonardo_work/CMCC_reforeca/CMCC-CM/archive/

listacasi="$1" 
for caso in $listacasi
do 
   check_started=$DIR_TEMP/$caso.copy4spike_started
   touch ${check_started}
   checkfile_spike=$DIR_TEMP/$caso.redone4spike  #flag to check transfer of re-run cases for spike
   checkfile=$DIR_ARCHIVE/$caso.transfer_from_Leonardo_DONE
   checkfile_zeus=$DIR_ARCHIVE/$caso.transfer_from_Zeus_DONE
   if [[ -f $checkfile_spike ]]
   then
      #On Leonardo $checkfile have been already deleted before modify_triplette
      #This checkfile drives the removal of $DIR_ARCHIVE directories on Leonardo
      #To allow automatic relaunch of this script the presence of $checkfile_spike is needed, since it identifies the completed transfer of $caso after the spike correction
      rsync -auv --rsh="sshpass -f $HOME/.sshpasswd ssh -l a07cmc00" $checkfile a07cmc00@dmover1.leonardo.cineca.it:${leo_dir}/  #probably redundant but harmless 
      continue
   fi
   if [[ -f $checkfile ]] 
   then
     #not all spike cases have been originally run on Leonardo
     rm $checkfile
   fi
   if [[ -f ${checkfile_zeus} ]]  
   then
     #not all spike cases have been originally run on Leonardo -> some originally on Zeus - remove flag for clarity
     rm ${checkfile_zeus}
   fi
   if [[ -d $DIR_ARCHIVE/$caso ]]
   then
     chmod -R u+w $DIR_ARCHIVE/$caso
     rm -rf $DIR_ARCHIVE/$caso
     echo "removed old $DIR_ARCHIVE/$caso" 
   fi  
   rsync -auv --rsh="sshpass -f $HOME/.sshpasswd ssh -l a07cmc00" a07cmc00@dmover1.leonardo.cineca.it:${leo_dir}/$caso ${DIR_ARCHIVE}
   stat=$?
   if [[ $stat -eq 0 ]]
   then
      chmod -R ug-w ${DIR_ARCHIVE}/$caso
      touch ${checkfile_spike}
      touch $checkfile
      rsync -auv --rsh="sshpass -f $HOME/.sshpasswd ssh -l a07cmc00" $checkfile a07cmc00@dmover1.leonardo.cineca.it:${leo_dir}/
      dim=`du -hs $DIR_ARCHIVE/$caso|cut -c 1-3`
      if [[ dim -lt 256 ]]
      then
         continue
      fi
   fi

done
