import os
import xarray as xr
import numpy as np
import matplotlib.pyplot as plt 
# plt.style.use('seaborn-white')
from matplotlib import cm
from matplotlib.colors import ListedColormap, ListedColormap, LinearSegmentedColormap
from mpl_toolkits.axes_grid1 import AxesGrid
import cartopy.crs as ccrs
from cartopy.mpl.geoaxes import GeoAxes
from cartopy.mpl.ticker import LongitudeFormatter, LatitudeFormatter

def plot_time_series_field(fullfield, field, title, logdir, plotname="plot_4.png"):
    """
    Plot monthly global mean time series panel
    """
    figname=os.path.join(logdir,plotname)
    fullfield_decoded=xr.decode_cf(fullfield)

    plotfield = field.assign_coords(leadtime=fullfield_decoded.time)
    # add here if for dimension name!
    plotfield = plotfield.mean(dim=["lat","lon"])
    fig, ax = plt.subplots(figsize=[12, 6])
    fig.suptitle(title, fontsize=15)
    plotfield.plot.line(ax = ax, xticks=plotfield.leadtime.values[::15])
    ax.set_xlabel('Forecast time')
    ax.xaxis.grid(True)
    ax.yaxis.grid(True)
    ax.set_title('')

    fig.savefig(figname) 
