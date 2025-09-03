#!/bin/sh -l

. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
set -euvx

caso=$1
cd $DIR_ARCHIVE/
if [[ ! -d $DIR_ARCHIVE/$caso ]]
then
   continue
fi 
cd $DIR_ARCHIVE/$caso/rest
n_dirrest=`ls |grep 00000|wc -l`
if [[ $n_dirrest -ne 1 ]]
then
   stdate=`echo $caso|cut -d "_" -f2`
   title="[$CPSSYS] ERROR: more than one rest dir found"
   body="Case $caso presents more than one restart directory. lt_archive_moredays exited"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M $body -t $title -r "yes" -s $stdate
   exit 1
fi
dirrest=`ls |grep 00000`
cd $DIR_ARCHIVE/$caso/rest/$dirrest
if [[ `ls *.h?.* |wc -l` -ne 0 ]]
then 
			list2rm=`ls *.h?.*`
			rm $list2rm
fi
cd $DIR_ARCHIVE/$caso/rest
tar -czvf $dirrest.tar.gz $dirrest
rm -rf $dirrest
