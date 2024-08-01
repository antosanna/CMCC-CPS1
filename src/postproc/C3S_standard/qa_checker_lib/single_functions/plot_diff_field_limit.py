import numpy as np
import os
import matplotlib.pyplot as plt 
# plt.style.use('seaborn-white')
from matplotlib import cm
from matplotlib.colors import ListedColormap, ListedColormap, LinearSegmentedColormap
from mpl_toolkits.axes_grid1 import AxesGrid
import cartopy.crs as ccrs
from cartopy.mpl.geoaxes import GeoAxes
from cartopy.mpl.ticker import LongitudeFormatter, LatitudeFormatter

def plot_diff_field_limit(fullfield, field, fieldlimit, condition, condition_type, lab_std, lab_mem, logdir, verbose=False, very_verbose=False):

    # arrays and titles for plot
    plot_lon =field.lon.values
    plot_lat=field.lat.values
    condition_10 = np.where(condition==True, 1, 0)
    condition_sum = np.nansum(condition_10, axis=0)
    condition_val = np.ma.masked_where(condition==False, field, copy=True)
    if condition_type == 1:
        plot1_title='Number of times field > mean+7std along forecast\n'+str(lab_std)+'_0'+str(lab_mem)
        plot2_title='Max value when field > mean+7std along forecast\n'+str(lab_std)+'_0'+str(lab_mem)
        plot3_title='Field - Limit with limit when field > mean+7std along forecast\n'+str(lab_std)+'_0'+str(lab_mem)
        condition_extreme_val = np.nanmax(condition_val, axis=0)
        condition_dif = np.ma.masked_where(condition==False, field-fieldlimit, copy=True)
        condition_maxdif = np.nanmax(condition_dif, axis=0)
    elif condition_type == 2:
        plot1_title='Number of times field < mean-7std along forecast\n'+str(lab_std)+'_0'+str(lab_mem)
        plot2_title='Min value when field < mean-7std along forecast\n'+str(lab_std)+'_0'+str(lab_mem)
        plot3_title='Limit - Field with limit when field < mean-7std along forecast\n'+str(lab_std)+'_0'+str(lab_mem)
        condition_extreme_val = np.nanmin(condition_val, axis=0)
        condition_dif = np.ma.masked_where(condition==False, fieldlimit-field, copy=True)
        condition_maxdif = np.nanmax(condition_dif, axis=0)
    elif condition_type == 3:
        plot1_title='Number of times field > max along forecast\n'+lab_std+'_0'+lab_mem
        plot2_title='Max value when field > max along forecast\n'+lab_std+'_'+lab_mem
        plot3_title='Field - Limit with limit when field > max along forecast\n'+lab_std+'_'+lab_mem
        condition_extreme_val = np.nanmax(condition_val, axis=0)
        condition_dif = np.ma.masked_where(condition==False, field-fieldlimit, copy=True)
        condition_maxdif = np.nanmax(condition_dif, axis=0)
    elif condition_type == 4:
        plot1_title='Number of times field < min along forecast\n'+lab_std+'_0'+lab_mem
        plot2_title='Min value when field < min along forecast\n'+lab_std+'_'+lab_mem
        plot3_title='Limit - Field with limit when field < min along forecast\n'+lab_std+'_'+lab_mem
        condition_extreme_val = np.nanmin(condition_val, axis=0)
        condition_dif = np.ma.masked_where(condition==False, fieldlimit-field, copy=True)
        condition_maxdif = np.nanmax(condition_dif, axis=0)
    else:
        print('Non recognized condition_type')
    # Config plots, also depending on field size
    plot1_file=os.path.join(logdir,'times_condition'+str(condition_type)+'_'+varname+'_'+lab_std+'_0'+lab_mem+'.png')
    plot2_file=os.path.join(logdir,'max_values_condition'+str(condition_type)+'_'+varname+'_'+lab_std+'_0'+lab_mem+'.png')
    plot3_file=os.path.join(logdir,'dif_limit_condition'+str(condition_type)+'_'+varname+'_'+lab_std+'_0'+lab_mem+'.png')
    if (len(field.dims) == 3) and (field.dims == (timename,'lat','lon')): 
        nrows = 1
        ncols = 1
        yticks_pos = [0]
        xticks_pos = [0]
        interm_colorbar_pos = [0]
    elif (len(field.dims) == 4) and (field.dims == (timename,levname,'lat','lon')):
        nlevs = len(fullfield[levname])
        nrows = 4
        ncols = int(nlevs/nrows)
        yticks_pos = [0,3,6,9]
        xticks_pos = [9,10,11]
        interm_colorbar_pos = [0,3,6,9]
    else:
        print('Unsupported number of dimensions')
    # PLOT1 cummulative number of times over forecast hitting limit by grid point
    vmin=1
    vmax=30
    levels=np.arange(vmin,vmax,2)
    cmap1=cm.get_cmap('tab20b')
    cmap1.set_under('w', 1)
    projection = ccrs.PlateCarree()
    axes_class = (GeoAxes, dict(map_projection=projection))
    fig = plt.figure(figsize=[12.8, 9.6])
    fig.suptitle(plot1_title, fontsize=15)
    axgr = AxesGrid(fig, 111, axes_class=axes_class,
                    nrows_ncols=(nrows, ncols),
                    axes_pad=0.3,
                    cbar_location='right',
                    cbar_mode='single',
                    cbar_pad=0.2,
                    cbar_size='3%',
                    cbar_set_cax=True,
                    label_mode='')  # note the empty label_mode
    for i, ax in enumerate(axgr):
        ax.coastlines()
        if i in yticks_pos: 
            ax.set_yticks(np.linspace(-90, 90, 5), crs=projection)
        if i in xticks_pos:
            ax.tick_params(axis='x', labelrotation=45)
            ax.set_xticks(np.linspace(-180, 180, 5), crs=projection)
        lon_formatter = LongitudeFormatter(zero_direction_label=True)
        lat_formatter = LatitudeFormatter()
        ax.xaxis.set_major_formatter(lon_formatter)
        ax.yaxis.set_major_formatter(lat_formatter)
        ax.xaxis.grid(True)
        ax.yaxis.grid(True)
        ax.set_title('Level '+str(int(fullfield[levname].values[i]/100))+' hPa')
        p = ax.contourf(plot_lon, plot_lat, condition_sum[i,:,:],
                        transform = projection,
                        cmap = cmap1,
                        vmin = vmin, vmax = vmax, levels=levels)
        
    axgr.cbar_axes[0].colorbar(p, ticks=np.arange(1,30,2), extend='min')
    fig.savefig(plot1_file)
    #plt.show()
    # PLOT2 Max value of temperature where limit is hitted
    fig = plt.figure(figsize=[12.8, 9.6])
    fig.suptitle(plot2_title, fontsize=15)
    axgr = AxesGrid(fig, 111, axes_class=axes_class,
                    nrows_ncols=(nrows, ncols),
                    axes_pad=0.3,
                    cbar_location='right',
                    cbar_mode='edge',
                    cbar_pad=0.2,
                    cbar_size='5%',
                    label_mode='')  # note the empty label_mode
    for i, ax in enumerate(axgr):
        ax.coastlines()
        if i in yticks_pos: 
            ax.set_yticks(np.linspace(-90, 90, 5), crs=projection)
        if i in xticks_pos:
            ax.tick_params(axis='x', labelrotation=45)
            ax.set_xticks(np.linspace(-180, 180, 5), crs=projection)
        lon_formatter = LongitudeFormatter(zero_direction_label=True)
        lat_formatter = LatitudeFormatter()
        ax.xaxis.set_major_formatter(lon_formatter)
        ax.yaxis.set_major_formatter(lat_formatter)
        ax.xaxis.grid(True)
        ax.yaxis.grid(True)
        ax.set_title('Level '+str(int(fullfield[levname].values[i]/100))+' hPa')
        if i in interm_colorbar_pos:
            vmin=np.min(condition_extreme_val[i:i+3,:,:])
            vmax=np.max(condition_extreme_val[i:i+3,:,:])
            if (vmax-vmin) >=1:
                levels=np.arange(int(vmin), int(vmax), 10)
            else:
                levels=np.arange(vmin, vmax, 0.2)
        p = ax.contourf(plot_lon, plot_lat, condition_extreme_val[i,:,:],
                        transform=projection,
                        cmap='viridis',
                        vmin=vmin, vmax=vmax, levels=levels)
        axgr.cbar_axes[i].colorbar(p, ticks=levels)
    fig.savefig(plot2_file)
    #plt.show()
    # PLOT3 Diff field-fieldmax of temperature where limit is hitted
    vmin=np.min(condition1_maxdif)
    vmax=np.max(condition1_maxdif)
    levels=np.arange(int(vmin), int(vmax), 1)
    projection = ccrs.PlateCarree()
    axes_class = (GeoAxes, dict(map_projection=projection))
    fig = plt.figure(figsize=[12.8, 9.6])
    fig.suptitle(plot3_title, fontsize=15)
    axgr = AxesGrid(fig, 111, axes_class=axes_class,
                    nrows_ncols=(4, 3),
                    axes_pad=0.3,
                    cbar_location='right',
                    cbar_mode='single',
                    cbar_pad=0.2,
                    cbar_size='3%',
                    label_mode='')  # note the empty label_mode
    for i, ax in enumerate(axgr):
        ax.coastlines()
        if i in yticks_pos: 
            ax.set_yticks(np.linspace(-90, 90, 5), crs=projection)
        if i in xticks_pos:
            ax.tick_params(axis='x', labelrotation=45)
            ax.set_xticks(np.linspace(-180, 180, 5), crs=projection)
        lon_formatter = LongitudeFormatter(zero_direction_label=True)
        lat_formatter = LatitudeFormatter()
        ax.xaxis.set_major_formatter(lon_formatter)
        ax.yaxis.set_major_formatter(lat_formatter)
        ax.xaxis.grid(True)
        ax.yaxis.grid(True)
        ax.set_title('Level '+str(int(fullfield[levname].values[i]/100))+' hPa')
        p = ax.contourf(plot_lon, plot_lat, condition1_maxdif[i,:,:],
                        transform=projection,
                        cmap='rainbow',
                        vmin=vmin, vmax=vmax, levels=levels)
    axgr.cbar_axes[0].colorbar(p, ticks=levels, extend='min')
    fig.savefig(plot3_file)
    #plt.show()
