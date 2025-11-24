#!/bin/sh -l
#--------------------------------
#BSUB -q s_long
#BSUB -J checktar
#BSUB -e logs/checktar_%J.err
#BSUB -o logs/checktar_%J.out
#BSUB -P 0490

# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. ${DIR_UTIL}/load_cdo

set -euxv

#----------------------------
#  INPUT SECTION
#----------------------------
yyyy=$1 #2000
st=$2   #10

set +euvx
. ${DIR_UTIL}/descr_ensemble.sh $yyyy
set -euxv

#memberstocheck=20
#
start_date=${yyyy}${st}
CERISEtable=$3

#
{
while IFS=, read -r C3S 
do
   var_array+=("$C3S")
done } < $CERISEtable

cd $pushdir/$yyyy$st


for var in hus ta ua va wap zg
do
   mm=1
   lista=`ls *_${var}_*.tar`
   for t in $lista
   do
         isec=`ls $t|rev|cut -d '.' -f2|cut -c 1-2|rev`
         if [[ $isec -eq 25 ]]
         then
            mm=11
         elif [[ $isec -eq 10 ]]
         then
            mm=1
         fi
         listafile=`tar -tf ${t}|grep nc`
         wclistafile=`tar -tf ${t}|grep nc|wc -l`
         wclistasha=`tar -tf ${t}|grep sha256|wc -l`
         if [ $wclistafile -ne $(($isec - $mm + 1)) ] 
         then
            echo "number of files inside tar $var is wrong: $wclistafile instead of 10"
            exit 1
         fi
         if [ $wclistasha -ne $(($isec - $mm + 1)) ] 
         then
            echo "number of shasum inside tar $var is wrong: $wclistasha instead of 12"
            exit
         fi
         for file in $listafile
         do
             number=`echo $file|rev|cut -d '.' -f2|cut -d '_' -f1|rev|cut -c 2-3`
             if [ $((10#$number)) -ne $mm ]
             then
                echo "wrong number in $file"
                exit 1
             fi
             echo $mm
             mm=$(($mm + 1))
         done
   done  # loop for tar
done

for var in ${var_array2d[@]}
do
   lista=`ls *_${var}_*.tar`
   for t in $lista
   do
      echo $t
      listafile=`tar -tf ${t}|grep  "\.nc"`
      wclistafile=`tar -tf ${t}|grep  "\.nc"|wc -l`
      wclistasha=`tar -tf ${t}|grep sha256|wc -l`
      if [ $wclistafile -ne $nrunC3Sfore ]
      then
         echo "number of files inside tar $var is wrong: $wclistafile instead of $nrunC3Sfore"
         exit 1
      fi
      if [ $wclistasha -ne $nrunC3Sfore ]
      then
         echo "number of shasum inside tar $var is wrong: $wclistasha instead of $nrunC3Sfore"
         exit
      fi
      mm=1
      for file in $listafile
      do
          number=`echo $file|rev|cut -d '.' -f2|cut -d '_' -f1|rev|cut -c 2-3`
          if [ $((10#$number)) -ne $mm ]
          then
             echo "wrong number in $file"
             exit 1
          fi
          mm=$(($mm + 1))
      done
   done
done
