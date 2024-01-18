#!/bin/sh -l
#-----------------------------------------------------------------------
# Update template postproc and submit .case.lt_archive
#-----------------------------------------------------------------------
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

set -euxv

remote=sps-dev@fdtn-zeus
DIR_ARCHIVE1_remote=/work/csp/sps-dev/CMCC-CM/archive/
DIR_CASES_remote=/work/csp/sps-dev/CPS/CMCC-CPS1/cases
      for caso in sps4_199308_004 sps4_199308_005 sps4_199308_006 sps4_199308_007 sps4_199308_008
      do
         rsync -auv $remote:$DIR_ARCHIVE1_remote/$caso $DIR_ARCHIVE1
         touch $DIR_ARCHIVE1/$caso.transfer_to_Juno_DONE
      done
