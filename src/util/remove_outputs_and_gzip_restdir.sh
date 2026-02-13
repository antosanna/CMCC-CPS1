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
n_tarfile=`ls |grep *.tar |wc -l`
if [[ $n_tarfile -eq 1 ]] 
then
   tarfile=`ls |grep 00000.tar`
   cd $DIR_ARCHIVE/$caso/rest
   gzip $tarfile
   rm $tarfile
   echo "tar for caso $caso already done, yet not compressed. Now fixed and exit"
   exit 0
fi
n_dirrest=`ls |grep 00000|grep -v *.tar.gz |wc -l`
if [[ $n_dirrest -ne 1 ]]
then
   if [[ $n_dirrest -eq 0 ]] && [[ `ls  $DIR_ARCHIVE/$caso/rest/*.tar.gz |wc -l` -eq 1 ]] ; then
      echo "tar for caso $caso already done, exiting now"
      exit 0
   fi
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
# if exist, remove links
flink=`find . -type l`
for ff in $flink
do
   unlink $ff
done

tar -czvf $dirrest.tar.gz $dirrest
rm -rf $dirrest
