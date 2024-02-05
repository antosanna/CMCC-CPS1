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
# 7) remove $caso data from C3S/..
if [ -d $DIR_ARCHIVE_C3S/$startdate ] ; then
         cd $DIR_ARCHIVE_C3S/$startdate
         # if exist some c3s files remove them
         if [ $(ls -1 cmcc_CMCC-CM3-v${versionSPS}_${typeofrun}_S${startdate}0100*r${member}i00p00.nc | wc -l ) -gt 0 ]; then
               rm -f cmcc_CMCC-CM3-v${versionSPS}_${typeofrun}_S${startdate}0100*r${member}i00p00.nc
         fi
         # if exist some c3s logs files remove them (c3s logs with ok)
         if [ $(ls -1 *r${member}i00p00_ok | wc -l ) -gt 0 ]; then
            rm -f *r${member}i00p00_ok
         fi
         # if exist some c3s logs files remove them (qa,meta,tmpl logs)
         if [ $(ls -1 *_ok_0${member} | wc -l ) -gt 0 ]; then
            rm -f *_ok_0${member}
         fi
         # if exist some c3s logs files remove them c*m_C3SDONE
         if [ $(ls -1 ${caso}_c*m_C3SDONE | wc -l ) -gt 0 ]; then
            rm -f ${caso}_c*m_C3SDONE 
         fi
fi # end 7)
#  8) remove ${caso}_DMO_arch_ok checkfile
checkfile_mvcase=`ls $DIR_LOG/${typeofrun}/$yyyy$st/${caso}_DMO_arch_ok | wc -l`
if [[ $checkfile_mvcase -ne 0 ]]
then
   rm $DIR_LOG/${typeofrun}/$yyyy$st/${caso}_DMO_arch_ok
fi 
# 9) remove ${caso}_homelog_arch_ok
homelog=$DIR_LOG/$typeofrun/$yyyy$st/${caso}_homelog_arch_ok
if [[ `ls ${homelog}* |wc -l` -ne 0 ]]
then
   rm ${homelog}*
fi

