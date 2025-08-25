#!/bin/sh -l

. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh

set -euvx

yyyy=`date +%Y`
mm=`date +%m`

cd $DIR_WEB/forecast_dev
listmap=`ls -1 *${yyyy}*${mm}*png`
cd -
for ll in $listmap 
do
  llnew=`echo ${ll/seasonal_l/l}`
  rsync -auv $DIR_WEB/forecast_dev/$ll $DIR_WEB/forecast_prod/$llnew
done

cd $DIR_WEB/forecast-indexes_dev
listindex=`ls -1 *${yyyy}*${mm}*png`
cd -
for ll in $listindex
do
  llnew=`echo ${ll/_mem_/_}`
  rsync -auv $DIR_WEB/forecast-indexes_dev/${ll} $DIR_WEB/forecast-indexes_prod/${llnew}
done

#rename also animate gif 
cd $DIR_WEB/forecast-indexes_dev
filegif=`ls -1 *${yyyy}*${mm}*gif`
cd -
filegifnew=`echo ${filegif/_ensmean_/_}`
rsync -auv $DIR_WEB/forecast-indexes_dev/${filegif} $DIR_WEB/forecast-indexes_prod/${filegifnew}

$DIR_UTIL/aggiorna_web.sh 

exit 0
