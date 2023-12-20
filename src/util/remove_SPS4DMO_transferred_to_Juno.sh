#!/bin/sh -l
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

set -euxv

for st in 08 10 11
do
   for yyyy in `seq $iniy_hind $endy_hind`
   do
      listacasi=`ls $DIR_ARCHIVE|grep ${st}_0`
      for caso in $listacasi
      do
         if [[ -f $DIR_ARCHIVE/$caso.transfer_from_Zeus_DONE ]]
         then
            if [[ -d $DIR_ARCHIVE/$caso ]]
            then
               rm -rf $DIR_ARCHIVE/$caso/*
               rmdir $DIR_ARCHIVE/$caso
            fi
         fi
      done
   done
done
