#!/bin/sh -l 

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
wkdir_clm=$5
finalfile=$6
checkfile=$7
ic=$8
mult=$9
set +evxu
. ${DIR_UTIL}/descr_ensemble.sh $yyyy
set -evxu
#we are in workdir
cd ${wkdir_clm}


if [[ ! -f $checkfile ]]
then

   if [[ ! -f $finalfile ]]
   then
     #--------------------------------------------
     # clm (I) compress clm output and append ic attribute
     #--------------------------------------------
          
      if [[ ! -f pre.$caso.clm2.$ft.$yyyy-$st.zip.nc ]] 
      then 
         $compress $DIR_ARCHIVE/$caso/lnd/hist/$caso.clm2.$ft.$yyyy-$st-01-00000.nc pre.$caso.clm2.$ft.$yyyy-$st.zip.nc
      fi
      ncatted -O -a ic,global,a,c,"$ic" pre.$caso.clm2.$ft.$yyyy-$st.zip.nc

     #--------------------------------------------
     # clm (II) check that number of timesteps is the expected one and remove extra timestep
     #--------------------------------------------

      expected_ts=$(( $fixsimdays * $mult + 1 ))
      nt=`cdo -ntime pre.$caso.clm2.$ft.$yyyy-$st.zip.nc`
      if [ $nt -lt $expected_ts  ]
      then
          body="ERROR Total number of timesteps for file pre.$caso.clm2.$ft.$yyyy-$st.zip.nc , ne to $expected_ts but is $nt. Exit "
          title="${CPSSYS} forecast notification - ERROR "
          ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "$typeofrun" -s $yyyy$st
          exit 1
      elif [ $nt -gt $expected_ts  ]
      then
          ncks -O -F -d time,1,$expected_ts pre.$caso.clm2.$ft.$yyyy-$st.zip.nc tmp.$caso.clm2.$ft.$yyyy-$st.zip.nc  
          mv tmp.$caso.clm2.$ft.$yyyy-$st.zip.nc pre.$caso.clm2.$ft.$yyyy-$st.zip.nc  
      fi
     # remove nr.1 timestep according to filetyp $ft
     # take from 2nd timestep
      echo "start of ncks for clm one file "`date`
      ncks -O -F -d time,2, pre.$caso.clm2.$ft.$yyyy-$st.zip.nc tmp.$caso.clm2.$ft.$yyyy-$st.zip.nc
      echo "end of ncks for clm one file "`date`
      mv tmp.$caso.clm2.$ft.$yyyy-$st.zip.nc $finalfile #$DIR_ARCHIVE/$caso/lnd/hist/$caso.clm2.$ft.$yyyy-$st.zip.nc
   fi
fi
