#!/bin/sh -l
#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# PARAMS to be set
#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
yyyy=$1
n_ic_cam=10
n_ic_clm=3
nrunhind=30  # 30 number of realizations required in hindcast
if [[ $yyyy -lt 2023 ]]
then
   n_ic_nemo=4
   nmax4modify_trip=40 #line from which modify_triplette acts
   #in hindcast different from $nrunmax to avoid possibility of running twice the same members
   #for startdate initially launched for 40 members
#   nrunmax=30      # 30 number of realizations you want to produce
   nrunmax=30      # 30 number of realizations you want to produce
   nrunC3Sfore=$nrunhind  # 30 number of realizations required to C3S forecast
   typeofrun="hindcast"
   debug_push=0    # if 0 you are going to send results to ECMWF
   # PAY ATTENTION!!! THESE ARE DEFINED FOR ZEUS BUT STAY HERE TO GUARANTEE PORTABILITY +
   export apprun=c3s2            #THESE COULD BE MODIFIED
   export S_apprun=SERIAL_cps   #THESE COULD BE MODIFIED
   #DATA_ECACCESS_CAM=$DATA_ECACCESS/ERA5/snapshot
   #DATA_ECACCESS_CLM=$DATA_ECACCESS/ERA5/6hourly
   # PAY ATTENTION!!! THESE ARE DEFINED FOR ZEUS BUT STAY HERE TO GUARANTEE PORTABILITY -
else
   n_ic_nemo=5 #until we fix ERS/COBE OIS2 runs
   nrunmax=55      # 40 number of realizations you want to produce
   nrunC3Sfore=50  # 40 number of realizations required to C3S forecast
   nmax4modify_trip=$nrunmax #line from which modify_triplette acts
   typeofrun="forecast"
   debug_push=0    # if 0 you are going to send results to ECMWF
                   # if 1 you are doing a sending test to Zeus
                   # if 2 you are doing a sending test to ECMWF
#---

   # PAY ATTENTION!!! THESE ARE DEFINED FOR ZEUS BUT STAY HERE TO GUARANTEE PORTABILITY +
   export apprun=cps            #THESE COULD BE MODIFIED
   export S_apprun=SERIAL_cps   #THESE COULD BE MODIFIED
   #DATA_ECACCESS_CAM=$DATA_ECACCESS/ERA5/snapshot
   #DATA_ECACCESS_CLM=$DATA_ECACCESS/ERA5/6hourly
   # PAY ATTENTION!!! THESE ARE DEFINED FOR ZEUS BUT STAY HERE TO GUARANTEE PORTABILITY -
fi
nchunks=$(($nrunC3Sfore / 10)) # 4 chunks to tar of 3d atm fields
if [[ $(($nrunC3Sfore % 10)) -ne 0 ]]
then
   nchunks=$(($nchunks + 1))
fi
