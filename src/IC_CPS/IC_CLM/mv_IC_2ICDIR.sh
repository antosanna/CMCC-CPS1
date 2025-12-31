#!/bin/sh -l
#------------------------------------------------
#-------------------------------------------------------------
# load variables from descriptor
#-------------------------------------------------------------
#------------------------------------------------
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
set -euvx

#------------------------------------------------
#-------------------------------------------------------------
# Set time variables
#-------------------------------------------------------------
#------------------------------------------------
yy=YY  #year month preceding start-date       
mm2d=MM  #month preceding start-date !!! this is 2 digits
caso=CASO
icclm=ICCLM
ichydros=ICHYD
lastday=LASTDAY
member=MEMBER
check_mv=CHECKMV


###############################################################

#------------------------------------------------
#-------------------------------------------------------------
# Copy restart to the IC_CLM_SPS directory
#-------------------------------------------------------------
#------------------------------------------------


st=`date -d ' '${yy}${mm2d}01' + 1 month' +%m`
yyyy=`date -d ' '${yy}${mm2d}01' + 1 month' +%Y`
startclm=${yyyy}-${st}-01
restdate=$startclm
set +euvx
. ${DIR_UTIL}/descr_ensemble.sh $yyyy
set -euvx
if [[ $lastday -ne 999 ]]
then
   lastday2d=`printf '%.2d' $lastday`
   lastdayp1=`date -d ' '${yy}${mm2d}$lastday2d' + 1 day' +%d`
   restdate=${yy}-${mm2d}-$lastdayp1
fi

ifbackup=`echo $caso|grep "bkup"|wc -l`  #check wether it is a backup case to modify mail title
rsync -auv $DIR_ARCHIVE/$caso/rest/${restdate}-00000/${caso}.clm2.r.${restdate}-00000.nc ${icclm}
rsync -auv $DIR_ARCHIVE/$caso/rest/${restdate}-00000/${caso}.hydros.r.${restdate}-00000.nc ${ichydros}

gzip -f $DIR_ARCHIVE/$caso/rest/${restdate}-00000/*
if [[ $lastday -eq 999 ]]
then
   gzip -f $DIR_ARCHIVE/$caso/lnd/hist/*.nc
   gzip -f $DIR_ARCHIVE/$caso/rof/hist/*.nc
fi
chmod u-w $DIR_ARCHIVE/$caso/rest/${restdate}-00000
#------------------------------------------------
#-------------------------------------------------------------
# Create log file and notificate everything went OK
#-------------------------------------------------------------
#------------------------------------------------
body="EDA${member} CLM ICs moved to $icclm and $ichydros \n
      script: \n
      $DIR_CASES/$caso/$caso.run \n
      job name: $caso \n
      logs: \n
      $DIR_CASES/$caso/"
if [[ $ifbackup -eq 0 ]] ; then
   title="[CLMIC] ${CPSSYS} ${typeofrun} notification"
else
   title="[CLMIC-backup] ${CPSSYS} ${typeofrun} notification"
fi
${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r yes -s $yyyy$st

touch ${check_mv}
exit 0
