#!/bin/sh -l
. $HOME/.bashrc
. $DIR_UTIL/descr_CPS.sh

set -eu
cd $DIR_ARCHIVE
lista=`ls *eonardo*|cut -d '.' -f1`
lista2rm=" "
for dd in $lista
do
   dim=`du -hs $dd|cut -c 1-3`
   if [[ dim -lt 256 ]]
   then
      continue
   fi
   lista2rm+=" $dd"
done
echo $lista2rm >$SCRATCHDIR/lista2rm_leo.txt
