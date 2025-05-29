#!/bin/sh -l

. $HOME/.bashrc
. $DIR_UTIL/descr_CPS.sh

set -euvx

caso=$1

# ******************************************
# Start here
# ******************************************


# ******************************************
# Main loop
# ******************************************
   # Get basic info from $caso
echo "$caso ***************************************** "
st=`echo $caso|cut -d '_' -f 2|cut -c 5-6`
yyyy=`echo $caso|cut -d '_' -f 2|cut -c 1-4`
. $DIR_UTIL/descr_ensemble.sh $yyyy
member=`echo $caso|cut -d '_' -f 3|cut -c 2-3`
startdate=${yyyy}${st}

# 1) remove $caso in cases
if [ -d $DIR_CASES/$caso ] ; then
         cd $DIR_CASES
         rm -rf $caso
fi
      
# 2) remove $caso in work
if [ -d $WORK_CPS/$caso ] ; then
         cd $WORK_CPS 
         rm -rf $caso
fi
# 3) remove $caso in CESM/archive/
if [ -d $DIR_ARCHIVE/$caso ] ; then
         cd $DIR_ARCHIVE
         rm -rf $caso

fi
if [ -d $WORK/CPS/CMCC-CPS1/cases_from_Leonardo/$caso ] ; then
   
   cd $WORK/CPS/CMCC-CPS1/cases_from_Leonardo/
   rm -rf $caso
fi
# 7) remove $caso data from C3S/..
if [ -d $DIR_ARCHIVE_C3S/$startdate ] ; then
         cd $DIR_ARCHIVE_C3S/$startdate
         # if exist some c3s files remove them
         if [ $(ls -1 cmcc_CMCC-CM3-v${versionSPS}_${typeofrun}_S${startdate}0100*r${member}i00p00.nc | wc -l ) -gt 0 ]; then
               rm -f cmcc_CMCC-CM3-v${versionSPS}_${typeofrun}_S${startdate}0100*r${member}i00p00.nc
         fi
         # if exist some c3s logs files remove them (c3s logs with ok)
         if [[ -d $SCRATCHDIR/regrid_C3S/$caso ]]
         then
            rm -fr $SCRATCHDIR/regrid_C3S/$caso
         fi
         if [[ -d $HEALED_DIR_ROOT/$caso ]]
         then
            rm -fr $HEALED_DIR_ROOT/$caso
         fi

fi # end 7)
# remove flag for transfer from Leonardo
if [ -f ${DIR_ARCHIVE}/${caso}.transfer_from_Leonardo_DONE ] ; then
   rm ${DIR_ARCHIVE}/${caso}.transfer_from_Leonardo_DONE
fi
