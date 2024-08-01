import numpy as np
import os
import xarray as xr
import matplotlib.pyplot as plt 
# plt.style.use('seaborn-white')
from matplotlib import cm
from matplotlib.colors import ListedColormap, ListedColormap, LinearSegmentedColormap
from mpl_toolkits.axes_grid1 import AxesGrid
import cartopy.crs as ccrs
from cartopy.mpl.geoaxes import GeoAxes
from cartopy.mpl.ticker import LongitudeFormatter, LatitudeFormatter
import time

def plot_mean_field(fullfield, field, title, logdir, plotname="plot_1.png"):
    """
    Plot panel of monthly mean
    """
    figname=os.path.join(logdir,plotname)
    fullfield_decoded=xr.decode_cf(fullfield)

    plotfield = field.assign_coords(leadtime=fullfield_decoded.time)
    plotfield = plotfield.groupby('time.month').mean(dim='leadtime')

    nrows=2; ncols=3;
    yticks_lab = [0,3,6]
    xticks_lab = [3,4,5]
    projection = ccrs.PlateCarree()
    axes_class = (GeoAxes, dict(map_projection=projection))
    fig = plt.figure(figsize=[12, 6])
    fig.suptitle(title, fontsize=15)
    axgr = AxesGrid(fig, 111, axes_class=axes_class,
                    nrows_ncols=(nrows, ncols),
                    axes_pad=0.5,
                    cbar_location='right',
                    cbar_mode='each',
                    cbar_pad=0.05,
                    cbar_size='2%',
                    cbar_set_cax=True,
                    label_mode='')  # note the empty label_mode
    for i, ax in enumerate(axgr):
        vmin=np.min(plotfield.isel(month=i))+0.00001
        vmax=np.max(plotfield.isel(month=i))+0.00001
        levels=np.arange(vmin,vmax,2)
        ax.coastlines()
        ax.set_yticks(np.linspace(-90, 90, 5), crs=projection)
        ax.tick_params(axis='x', labelrotation=45)
        ax.set_xticks(np.linspace(-180, 180, 5), crs=projection)
        if i not in yticks_lab: 
            ax.tick_params(labelleft=False)    
        if i not in xticks_lab:
            ax.tick_params(labelbottom=False)    
        lon_formatter = LongitudeFormatter(zero_direction_label=True)
        lat_formatter = LatitudeFormatter()
        ax.xaxis.set_major_formatter(lon_formatter)
        ax.yaxis.set_major_formatter(lat_formatter)
        ax.xaxis.grid(True)
        ax.yaxis.grid(True)
        ax.set_title('Month '+str(i+1))
        p = ax.contourf(plotfield.lon.values, plotfield.lat.values, plotfield.isel(month=i),
                        transform = projection, cmap='jet',
                        vmin = vmin, vmax = vmax)
                        # vmin = vmin, vmax = vmax, levels=levels)
        axgr.cbar_axes[i].colorbar(p)
        # axgr.cbar_axes[i].colorbar(p, ticks=levels)
    fig.savefig(figname)
