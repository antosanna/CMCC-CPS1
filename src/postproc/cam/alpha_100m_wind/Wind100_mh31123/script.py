import xarray as xr
import os
import numpy as np

datadir = '/work/csp/mh31123/scratch/Wind100/Data_alpha/alpha_185days/01m/'
files = [os.path.join(datadir, f'alpha_{year}01.nc') for year in range(1993, 2022)]

# Open all files as a single dataset
datasets = []
for f in files:
    with xr.open_dataset(f, chunks={'time': 1}) as ds:
        datasets.append(ds.copy())

combined = xr.concat(datasets, dim='file')

mean_dataset = combined.mean(dim='file')

# Save the result
mean_dataset.to_netcdf('/work/csp/mh31123/scratch/Wind100/Data_alpha/alpha_185days/combined_mean_alpha1.nc')
#mean_dataset.to_netcdf('combined_mean_alpha1.nc')
