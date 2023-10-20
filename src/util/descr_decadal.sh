#!/bin/sh -l
#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# PARAMS to be set
#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
nrunmax=40      # 40 number of realizations you want to produce
nrunC3Sfore=40  # 40 number of realizations required to C3S forecast
nchunks=$(($nrunC3Sfore / 10)) # 4 chunks to tar of 3d atm fields
if [[ $(($nrunC3Sfore % 10)) -ne 0 ]]
then
   nchunks=$(($nchunks + 1))
fi
typeofrun="hindcast"
debug_push=1    # if 0 you are going to send results to ECMWF
iniy=1960
endy=2022
# PAY ATTENTION!!! THESE ARE DEFINED FOR ZEUS BUT STAY HERE TO GUARANTEE PORTABILITY +
export apprun=sps35            #THESE COULD BE MODIFIED
export S_apprun=SERIAL_sps35   #THESE COULD BE MODIFIED
#DATA_ECACCESS_CAM=$DATA_ECACCESS/ERA5/snapshot
#DATA_ECACCESS_CLM=$DATA_ECACCESS/ERA5/6hourly
# PAY ATTENTION!!! THESE ARE DEFINED FOR ZEUS BUT STAY HERE TO GUARANTEE PORTABILITY -
