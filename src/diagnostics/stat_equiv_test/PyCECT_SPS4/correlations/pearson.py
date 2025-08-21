#usr/bin/env python3
import os
import sys
import numpy                         as np
import xarray                        as xr

##############################################################################

# Input file
ifile = '/work/cmcc/cp1//CMCC-CM//archive/sps4_199301_001/atm/hist/sps4_199301_001.cam.h0.1993-01.zip.nc'

ds = xr.open_dataset(ifile)
var1=ds['PSL'].values
var2=ds['PS'].values
nlat=ds.sizes['lat']
nlon=ds.sizes['lon']
ntime=ds.sizes['time']

res = np. corrcoef(var1.flat, var2.flat)
print(res[0,1])
