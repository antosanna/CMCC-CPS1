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
C3Stablecam=$DIR_POST/cam/C3S_table.txt
C3Stableclm=$DIR_POST/clm/C3S_table_clm.txt
C3Stableocean=$DIR_POST/nemo/C3S_table_ocean2d.txt
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
done } < $C3Stablecam
{
while IFS=, read -r flname C3S realm prec coord lname sname units freq level addfact coord2 cell
do
   var_array2d+=("$C3S")
done } < $C3Stableclm
{
read 
while IFS=, read -r flname C3S lname sname units realm level addfact coord cell varflg reflev model fillval
do
   var_array2d+=("$C3S")
done } < $C3Stableocean
# AA -

cd $pushdir/$yyyy$st


for var in ${var_array3d[@]}
do
   mm=1
   lista=`ls *_${var}_*.tar`
   for t in $lista
   do
         isec=`ls $t|rev|cut -d '.' -f2|cut -c 1-2|rev`
         mm=$(( $isec - 9 ))
         listafile=`tar -tf ${t}|grep nc`
         wclistafile=`tar -tf ${t}|grep nc|wc -l`
         wclistasha=`tar -tf ${t}|grep sha256|wc -l`
         if [ $wclistafile -ne 10 ]
         then
            #echo "numero di file nel tar $var non corretto $wclistafile instead of 10"
            echo "number of files inside tar $var is wrong: $wclistafile instead of 10"
            exit
         fi
         if [ $wclistasha -ne 10 ]
         then
            #echo "numero di shasum nel tar $var non corretto $wclistasha instead of 10"
            echo "number of shasum inside tar $var is wrong: $wclistasha instead of 10"
            exit
         fi
         for file in $listafile
         do
             number=`echo $file|rev|cut -d '.' -f2|cut -d '_' -f1|rev|cut -c 2-3`
             if [ $((10#$number)) -ne $mm ]
             then
                echo "wrong number in $file"
                exit
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
      listafile=`tar -tf ${t}|grep nc`
      wclistafile=`tar -tf ${t}|grep nc|wc -l`
      wclistasha=`tar -tf ${t}|grep sha256|wc -l`
      if [ $wclistafile -ne $nrunC3Sfore ]
      then
         #echo "numero di file nel tar $var non corretto $wclistafile instead of $nrunC3Sfore"
         echo "number of files inside tar $var is wrong: $wclistafile instead of $nrunC3Sfore"
         exit
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
             exit
          fi
          mm=$(($mm + 1))
      done
   done
done
