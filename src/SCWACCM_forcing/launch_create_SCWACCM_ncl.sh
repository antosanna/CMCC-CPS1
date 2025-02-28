#!/bin/sh -l
. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/load_ncl
set -euvx

export codepath="$SCRATCHDIR/SCWACCM_forcing/code" 
export in_dir=$SCRATCHDIR/SCWACCM_forcing/gpfs/fs1/p/acom/acom-climate/cesm2/postprocess/b.e21.BWSSP585cmip6.f09_g17.CMIP6-SSP5-8.5-WACCM.001/atm/proc/spec_chem_day_5/

export out_dir=$SCRATCHDIR/SCWACCM_forcing/gpfs/fs1/p/acom/acom-climate/cesm2/postprocess/b.e21.BWSSP585cmip6.f09_g17.CMIP6-SSP5-8.5-WACCM.001/atm/proc/scratch_test/
mkdir -p ${out_dir}

#this file has been created starting from temporary files (5day averages, zonal mean, variable per variable) as retrieved from NCAR clusters using the following script:
#CreateSCWACCMforcingFileTseries.ncl 
export in_file=spec_chem_day_5.nc3

#from this file we want to derive a time series of 10 year-climatologies
export out_file=${out_dir}/test_out.nc

ncl create_SCWACCM_from5days.ncl

exit 0
