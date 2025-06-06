#!/bin/sh -l 

# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. $DIR_UTIL/load_nco
. $DIR_UTIL/load_cdo

set -evxu


caso=$1
ft=$2
wkdir=$3
finalfile=$4
ic=$5

#
st=`echo $caso|cut -d '_' -f2 |cut -c5-6`
yyyy=`echo $caso|cut -d '_' -f2 |cut -c1-4`
ens=`echo $caso|cut -d '_' -f 3 `

set +evxu
. ${DIR_UTIL}/descr_ensemble.sh $yyyy
set -evxu
#
set +evxu
. $dictionary
set -evxu

if [[ ! -f ${check_merge_cam_files}_${ft} ]]
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
   inputfile=$DIR_ARCHIVE/$caso/atm/hist/$caso.cam.$ft.$yyyy-$st-01-00000.nc
   if [ -f $inputfile -a $st == "05" -a $typeofrun == "hindcast" ] || [ ! -f $finalfile ]
   then
      echo "starting compression for file $ft "`date`
      if [[ ! -f $wkdir/pre.$caso.cam.$ft.$yyyy-$st.zip.nc ]]
      then
         ${DIR_UTIL}/compress.sh $DIR_ARCHIVE/$caso/atm/hist/$caso.cam.$ft.$yyyy-$st-01-00000.nc $wkdir/pre.$caso.cam.$ft.$yyyy-$st.zip.nc
      fi
#         ic=(from txt in casedir)
      ncatted -O -a ic,global,a,c,"$ic" $wkdir/pre.$caso.cam.$ft.$yyyy-$st.zip.nc
    
      nt=`cdo -ntime $wkdir/pre.$caso.cam.$ft.$yyyy-$st.zip.nc`
    
      expected_ts=$(( $fixsimdays * $mult + 1 ))
      if [ $nt -lt $expected_ts  ]
      then
         body="ERROR Total number of timesteps for files $wkdir/pre.$caso.cam.$ft.$yyyy-$st.nc , ne to $expected_ts but is $nt. Exit "
         title="${CPSSYS} forecast ERROR "
         ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "$typeofrun" -s $yyyy$st -E $ens
         exit 1
      elif [ $nt -gt $expected_ts  ]
      then
         ncks -O -F -d time,1,$expected_ts $wkdir/pre.$caso.cam.$ft.$yyyy-$st.zip.nc $wkdir/tmp.$caso.cam.$ft.$yyyy-$st.zip.nc  
         mv $wkdir/tmp.$caso.cam.$ft.$yyyy-$st.zip.nc $wkdir/pre.$caso.cam.$ft.$yyyy-$st.zip.nc   
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
touch ${check_merge_cam_files}_${ft}
