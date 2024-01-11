#!/bin/sh -l 
#BSUB -J test_postproc_final_cam
#BSUB -e /work/csp/cp1/CPS/CMCC-CPS1/logs/tests/test_postproc_final_cam_%J.err
#BSUB -o /work/csp/cp1/CPS/CMCC-CPS1/logs/tests/test_postproc_final_cam_%J.out
#BSUB -P 0490
#BSUB -M 10000
#BSUB -q s_medium

# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. $DIR_UTIL/load_nco
. $DIR_UTIL/load_cdo

set -evxu


caso=$1
ft=$2

yyyy=$3
st=$4
ens=$5
wkdir=$6
finalfile=$7

. ${DIR_UTIL}/descr_ensemble.sh $yyyy
ic=`cat $DIR_CASES/${caso}/logs/ic_${caso}.txt`
#
set +evxu
. $dictionary
set -evxu

if [[ ! -f $check_merge_cam_files ]]
then
   #--------------------------------------------
   # cam define mulptiplier for timestep (daily,6h,12h)
   #--------------------------------------------
   case $ft in
     h1 ) mult=4 ;; # 6h
     h2 ) mult=2 ;; # 12h
     h3 ) mult=1 ;; # daily
   esac
   #--------------------------------------------
   #$caso.cam.$ft.nc is a temp file, input for $DIR_POST/regridSEne60_C3S.sh
   #--------------------------------------------
   if [ ! -f $finalfile ]
   then
      echo "starting compression for file $ft "`date`
      if [[ ! -f $wkdir/pre.$caso.cam.$ft.$yyyy-$st.zip.nc ]]
      then
         $compress $DIR_ARCHIVE/$caso/atm/hist/$caso.cam.$ft.$yyyy-$st-01-00000.nc $wkdir/pre.$caso.cam.$ft.$yyyy-$st.zip.nc
      fi
#         ic=(from txt in casedir)
      ncatted -O -a ic,global,a,c,"$ic" $wkdir/pre.$caso.cam.$ft.$yyyy-$st.zip.nc
    
      nt=`cdo -ntime $wkdir/pre.$caso.cam.$ft.$yyyy-$st.zip.nc`
    
      expected_ts=$(( $fixsimdays * $mult + 1 ))
      if [ $nt -lt $expected_ts  ]
      then
         body="ERROR Total number of timesteps for files $wkdir/pre.$caso.cam.$ft.$yyyy-$st.nc , ne to $expected_ts but is $nt. Exit "
         title="${CPSSYS} forecast ERROR "
         ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" 
         exit 1
      elif [ $nt -gt $expected_ts  ]
      then
         ncks -O -F -d time,1,$expected_ts $wkdir/pre.$caso.cam.$ft.$yyyy-$st.zip.nc $wkdir/tmp.$caso.cam.$ft.$yyyy-$st.zip.nc  
         rsync -auv $wkdir/tmp.$caso.cam.$ft.$yyyy-$st.zip.nc $wkdir/pre.$caso.cam.$ft.$yyyy-$st.zip.nc   
      fi
   
   # remove nr.1 timestep according to filetyp $ft
      if [ $ft == "h3" ]
      then
      # take from 2nd timestep
         echo "start ncks for $ft "`date`
         ncks -O -F -d time,2, $wkdir/pre.$caso.cam.$ft.$yyyy-$st.zip.nc $wkdir/tmp.$caso.cam.$ft.$yyyy-$st.zip.nc  
         rsync -auv $wkdir/tmp.$caso.cam.$ft.$yyyy-$st.zip.nc $finalfile		      
         echo "end of ncks for $ft "`date`
      else
      # take all but last timestep
         echo "start ncks for $ft "`date`
         nstep=`cdo -ntime $wkdir/pre.$caso.cam.$ft.$yyyy-$st.zip.nc` 		
         nstepm1=$(($nstep - 1))
         ncks -O -F -d time,1,$nstepm1 $wkdir/pre.$caso.cam.$ft.$yyyy-$st.zip.nc $wkdir/tmp.$caso.cam.$ft.$yyyy-$st.zip.nc  
         rsync -auv $wkdir/tmp.$caso.cam.$ft.$yyyy-$st.zip.nc $finalfile
         echo "end of ncks for $ft "`date`
      fi
   fi
fi
touch $check_merge_cam_files
