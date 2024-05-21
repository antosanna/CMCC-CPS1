#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Jan 17 11:47:35 2022

@author: yangzhiqi
"""
import matplotlib
matplotlib.use('pdf')
import matplotlib.pyplot as plt
import netCDF4 as nc
import numpy as np
import os
import pandas as pd
from mpl_toolkits.basemap import Basemap
import glob

import traceback
import fnmatch
import sys
import argparse
import re

import xarray as xr
import json
import warnings
import time
import tracemalloc
import shutil


# plt.style.use('seaborn-white')
from matplotlib import cm
from matplotlib.colors import ListedColormap, ListedColormap, LinearSegmentedColormap
from mpl_toolkits.axes_grid1 import AxesGrid
import cartopy.crs as ccrs
from cartopy.mpl.geoaxes import GeoAxes
from cartopy.mpl.ticker import LongitudeFormatter, LatitudeFormatter
import datetime as dt
from dateutil.relativedelta import relativedelta
from calendar import monthrange
#from plt_lev_var import plt_lev_var


def plt_lev_var(ymmem,fname,dy_fname,leadtime,lev,var,dy_name,outlat,outlon,cfig,nnn,numstep,vmax,vmin,dyvmax,dyvmin):
    
    cmap='viridis'
    col='grey'
    linew=1
    linew2=0.5
    fs=11
    fsc=8
    
    file=nc.Dataset(fname)
    lat=file['lat'][:]
    lon=file['lon'][:]
    
    lat2=list(file['lat'][:])
    lon2=list(file['lon'][:])
    
    
    ltime=file['leadtime'][:]
    pos_ltime=np.where(np.array(ltime) == leadtime)[0]
   
    if lev=='3d':
       ta=file[var][pos_ltime,:,:]
    else:
       level=file['plev'][:]/100.0    
       pos=np.where(np.array(level) == lev)[0]    
       ta=file[var][pos_ltime,pos,:,:]


    ta=np.squeeze(ta)   
    
    outnum=np.shape(outlat)[0]
    point=np.zeros((2,outnum))
    point[0,:]=outlat
    point[1,:]=outlon
    
    
    for i in np.arange(0,outnum):
        ta[lat2.index(point[0,i]),lon2.index(point[1,i])]=np.nan
    
    
    
    
    ax1 = [0.01+1.1*numstep, 0.8, 1.2, 0.6]                         
    ax2=[0.01+1.1*numstep, 0.01, 1.2, 0.6]
    cax1=[1.1+1.1*numstep, 0.8, 0.02, 0.6]
    cax2=[1.1+1.1*numstep, 0.01, 0.02, 0.6]
      
    
    
    fig=plt.figure(cfig)
    
       
    #plt outlier
   
    ax = fig.add_axes(ax1)
    m = Basemap(area_thresh=10000.,llcrnrlon=0,llcrnrlat=-90,urcrnrlon=360,urcrnrlat=90,resolution='l',projection='cyl',lat_0=0.,lon_0=0.,ax=ax)
    m.drawcoastlines(linewidth=linew2,zorder=4)        
    X,Y = np.meshgrid(lon,lat)
    mx,my = m(X,Y)
    cs=m.contourf(mx,my,ta,levels = np.linspace(vmin,vmax,11),extend='both',cmap=cmap,zorder=3)
    parallels = np.arange(-80.,90,20.)
    m.drawparallels(parallels,color=col,linewidth=linew,dashes=[1,0.1],labels=[1,0,0,0],fontsize=7.5,zorder=2)
    meridians = np.arange(60.,360.,60.)
    m.drawmeridians(meridians,color=col,linewidth=linew,dashes=[1,0.1],labels=[0,0,0,1],fontsize=7.5,zorder=2)
    
    
     
    for i in np.arange(outnum):
        xxout,yyout=m(outlon[i],outlat[i])
        m.plot(xxout,yyout,'+',color='r',markersize=8,zorder=4)
       
    xx,yy=m(100,98)      
    plt.text(xx,yy,'Outliers: '+var+'_'+str(lev)+' hPa'+'_leadtime:'+str(leadtime),fontsize=fs)
    
    
    xx,yy=m(-10,-120)      
    plt.text(xx,yy,'Outliers: '+str(outnum)+' points.More details:work/ZHIQI/range_checkfromM/',fontsize=fs)
    
    ax.spines['bottom'].set_linewidth(linew)
    ax.spines['top'].set_linewidth(linew)
    ax.spines['left'].set_linewidth(linew)
    ax.spines['right'].set_linewidth(linew)
    
    #orientation="horizontal",
    cbar1=fig.colorbar(cs,cax=plt.axes(cax1)) #51
    cbar1.ax.tick_params(labelsize=fsc, width=linew,length=1)
    
    
    
    
    
    #cbar1.set_ticks(cslev)
    #cbar1.set_ticklabels((-1,-0.8,-0.6,-0.4,-0.2,-0.01,0,0.01,0.2,0.4,0.6,0.8,1))
    
    
    
#--dy--

    file=nc.Dataset(dy_fname)
    
    '''
    lat=file['lat'][:]
    lon=file['lon'][:]
    level=file['plev'][:]/100.0
    ltime=file['leadtime'][:]
    pos_ltime=np.where(np.array(ltime) == leadtime)[0]
    
    pos=np.where(np.array(level) == lev)[0]
    '''
    
    if lev=='3d':
       ta2=file[dy_name][pos_ltime,:,:]
    else:
       ta2=file[dy_name][pos_ltime,pos[0],:,:]
 
    ta2=np.squeeze(ta2)
     
    
    fig=plt.figure(cfig)
    
    
       
    #plt outlier
   
    ax = fig.add_axes(ax2)
    m = Basemap(area_thresh=10000.,llcrnrlon=0,llcrnrlat=-90,urcrnrlon=360,urcrnrlat=90,resolution='l',projection='cyl',lat_0=0.,lon_0=0.,ax=ax)
    m.drawcoastlines(linewidth=linew2,zorder=4)        
    X,Y = np.meshgrid(lon,lat)
    mx,my = m(X,Y)
    cs=m.contourf(mx,my,ta2,levels = np.linspace(dyvmin,dyvmax,11),extend='both',cmap=cmap,zorder=3)
    parallels = np.arange(-80.,90,20.)
    m.drawparallels(parallels,color=col,linewidth=linew,dashes=[1,0.1],labels=[1,0,0,0],fontsize=7.5,zorder=2)
    meridians = np.arange(60.,360.,60.)
    m.drawmeridians(meridians,color=col,linewidth=linew,dashes=[1,0.1],labels=[0,0,0,1],fontsize=7.5,zorder=2)
     
    outnum=np.shape(outlat)[0]
    '''
    for i in np.arange(outnum):
        xxout,yyout=m(outlon[i],outlat[i])
        m.plot(xxout,yyout,'+',color='r',markersize=8,zorder=4)
    '''    
    xx,yy=m(100,98)      
    plt.text(xx,yy,'Dynamical: '+dy_name+'_'+str(lev)+' hPa'+'_leadtime:'+str(leadtime),fontsize=fs)
    
    
    xx,yy=m(-320,-120)      
    #plt.text(xx,yy,'Outliers: '+str(outnum)+' points.More details:/users_home/csp/sps-dev/SPS/CMCC-SPS3.5/work/ZHIQI/range_checkfromM/logs',fontsize=fs)
    
    ax.spines['bottom'].set_linewidth(linew)
    ax.spines['top'].set_linewidth(linew)
    ax.spines['left'].set_linewidth(linew)
    ax.spines['right'].set_linewidth(linew)
    
    #orientation="horizontal",
    cbar1=fig.colorbar(cs,cax=plt.axes(cax2)) #51
    cbar1.ax.tick_params(labelsize=fsc, width=linew,length=1)
    

    
    

#---/users_home/csp/sps-dev/SPS/CMCC-SPS3.5/work/ZHIQI/
#/Users/yangzhiqi/Downloads/range_checkfromM/


#    plt.savefig('Outliers-'+ymmem+var+'_'+str(lev)+'hPa'+'_leadtime'+str(leadtime)+'.pdf',bbox_inches = 'tight')  
#    plt.show()
#=============
def get_vamxmin(ymmem,fname,dy_fname,leadtime,lev,var,dy_name,outlat,outlon,cfig,nnn,numstep):
    
    file=nc.Dataset(fname)
       
    lat2=list(file['lat'][:])
    lon2=list(file['lon'][:])   

    ltime=file['leadtime'][:]
    pos_ltime=np.where(np.array(ltime) == leadtime)[0]    

    if lev=='3d':
       ta=file[var][pos_ltime,:,:]
    else:
       level=file['plev'][:]/100.0
       pos=np.where(np.array(level) == lev)[0]    
       ta=file[var][pos_ltime,pos,:,:]


    ta=np.squeeze(ta)   
    
    outnum=np.shape(outlat)[0]
    point=np.zeros((2,outnum))
    point[0,:]=outlat
    point[1,:]=outlon
        
    for i in np.arange(0,outnum):
        ta[lat2.index(point[0,i]),lon2.index(point[1,i])]=np.nan
    
    vmax=np.nanmax(ta)
    vmin=np.nanmin(ta)
    #----
    file=nc.Dataset(dy_fname)   


    if lev=='3d':
       ta2=file[dy_name][pos_ltime[0],:,:]
    else: 
       ta2=file[dy_name][pos_ltime[0],pos[0],:,:]
   
    ta2=np.squeeze(ta2)
    
    dyvmax=np.nanmax(ta2)
    dyvmin=np.nanmin(ta2)
    
    

    return vmax,vmin,dyvmax,dyvmin






#==============
def argParser():
    """
    Argument parser.
    """
    parser = argparse.ArgumentParser(prog='C3SDataChecker',
        description=""" CMCC Checker for SPS3.5 data. """)
    parser.add_argument("file", help="file to process. If a math pattern is indicated, then double quotes are needed")
    parser.add_argument("-v","--var", 
            help="name of the variable to process. (default:reads all vars in file)")
    parser.add_argument("-f", "--infile", help="input file")
    parser.add_argument("-p", "--inpath", help="input path")
    parser.add_argument("-l", "--logdir", help="log path")
    args = parser.parse_args()
    return(args)

class InputError(Exception):
    pass

def check_path_exists(path):
    """
    Check if path exists.
    """
    if not (os.path.exists(path)):
        raise InputError('INPUTERROR Unknown file or path '+path)    

def find_files(file, path='.'):
    """
    Find files in a path matching a string.
    """
    files = fnmatch.filter(os.listdir(path), file)
    if len(files) == 0:
        raise InputError('[INPUTERROR] 0 Files found in the path matching file name')
    return(files)



#===main func=============
# Read arguments
args = argParser()

check_path_exists(args.path)
#files = find_files(args.file, args.path)
print(args)


inputf=args.inpath+'/'+args.infile
#inputf='/Users/yangzhiqi/Downloads'
#g=files[0]

#e.g.file='clim_error_list_ta_sps3.5_199401_27.outlier'
File=args.file   

logdir=args.logdir

name3d=['clt','psl','tas','tdps','uas','vas','hfls','hfss','lweprc','lwepr','lweprsn','prw','rlds','rls','rlt','rsds','rsdt','rss','rst','tasmax','tasmin','tauu','tauv','wsgmax','orog','sftlf','tsl','lwee','lwesnw','mrroab','mrroas','rhosn','tso','sitemptop','sic']
name4d=['hus','ta','ua','va','zg','mrlsl','mlotstheta001','mlotstheta003','sithick','sos','sot300','t14d','t17d','t20d','t26d','t28d','thetaot300','zos']


#for file_list in np.arange(0,np.shape(g)[0]):
#/users_home/csp/sps-dev/SPS/CMCC-SPS3.5/work/ZHIQI/range_checkfromM/
#File=os.path.join('/users_home/csp/sps-dev/SPS/CMCC-SPS3.5/work/ZHIQI/range_checkfromM/',g)

#File=os.path.join('/users_home/csp/sps-dev/SPS/CMCC-SPS3.5/work/ZHIQI/range_checkfromM/',g)
#file_name=g
end_vname=file_name.index('_sps3.5')


ymmem=file_name[file_name.index('_sps3.5')+8:file_name.index('.txt')]
print(ymmem)

varname=file_name[16:end_vname]
print(varname)

if varname in name3d:
    print(varname+'3d')    
elif varname in name4d:
    print(varname+'4d')  


#pwd = os.getcwd()
#os.chdir(os.path.(File))
#trainData = pd.read_csv(os.path.basename(File),sep='\s+')
trainData = pd.read_csv(File,sep='\s+')
trainData=trainData[1:np.shape(trainData)[0]]
#print(trainData)file_name

#=========3d=====4d============
#-----4d----
if varname in name4d:
   lev=trainData.iloc[:,7]
   lev = lev.astype(np.float64)
   lev = lev.tolist()
   levlist=set(lev)
   levlist=sorted(levlist)
   levnum=np.shape(levlist)[0]
   cfig=1
   for i in np.arange(0,levnum):
       pos = np.where(np.array(lev) == levlist[i])[0]
       leadtime=trainData.iloc[pos,6]
       leadtime=leadtime.astype(np.float64)
       leadtime=leadtime.tolist()
       leadtimelist=set(leadtime)
       leadtimelist=sorted(leadtimelist)
       leadtimenum=np.shape(leadtimelist)[0]
       nnn=leadtimenum
       for j in np.arange(0,leadtimenum):
           pos2=np.where(np.array(leadtime) == leadtimelist[j])[0]
           #latlon=np.zeros((np.shape(pos2)[0], 2))
           lat=trainData.iloc[pos2,8]
           lon=trainData.iloc[pos2,9]
           lat=lat.astype(np.float64)
           lat=lat.tolist()
           lon=lon.astype(np.float64)
           lon=lon.tolist()
           #plot hindcast_ta_sps3.5_201010_35_levlist[i]
           #cmcc_CMCC-CM2-v20191201_hindcast_S2010100100_atmos_12hr_pressure_ta_r35i00p00.nc
           dy_name='zg'
           dy_fname=inpath+'/cmcc_CMCC-CM2-v20191201_forecast_S'+ymmem[0:6]+'0100_atmos_12hr_pressure_'+dy_name+'_r'+ymmem[7:9]+'i00p00.nc'
           if j==0:
               vmax,vmin,dyvmax,dyvmin=get_vamxmin(ymmem,inputf,dy_fname,leadtimelist[j],levlist[i],varname,dy_name,lat,lon,cfig,nnn,j)
           print(vmax)
           print(vmin)
           print(dyvmax)
           print(dyvmin)
           plt_lev_var(ymmem,inputf,dy_fname,leadtimelist[j],levlist[i],varname,dy_name,lat,lon,cfig,nnn,j,vmax,vmin,dyvmax,dyvmin)
       cfig=cfig+1
       plt.savefig(logdir+'/Outliers-'+ymmem+varname+'_'+str(levlist[i])+'hPa'+'.pdf',bbox_inches = 'tight')
       #plt.show()
#-----3d----    
elif varname in name3d:

    cfig=1
   
    leadtime=trainData.iloc[:,5]
    leadtime=leadtime.astype(np.float64)
    leadtime=leadtime.tolist()        
    #list()
    leadtimelist=set(leadtime)    
    leadtimelist = sorted(leadtimelist)    
    #leadtime=list(leadtime)
    leadtimenum=np.shape(leadtimelist)[0]   
    nnn=leadtimenum    
    #----------------------    
    for j in np.arange(0,leadtimenum):
        
        pos2=np.where(np.array(leadtime) == leadtimelist[j])[0]
        
        #latlon=np.zeros((np.shape(pos2)[0], 2))
        lat=trainData.iloc[pos2,6]
        lon=trainData.iloc[pos2,7]
        
        lat=lat.astype(np.float64)
        lat=lat.tolist()
        
        lon=lon.astype(np.float64)
        lon=lon.tolist()    
        #plot hindcast_ta_sps3.5_201010_35_levlist[i]
        #cmcc_CMCC-CM2-v20191201_hindcast_S2010100100_atmos_12hr_pressure_ta_r35i00p00.nc
        #cmcc_CMCC-CM2-v20191201_hindcast_S2010100100_atmos_12hr_pressure_ta_r35i00p00.nc
        
        dy_name='psl'
        dy_fname=inpath+'/cmcc_CMCC-CM2-v20191201_forecast_S'+ymmem[0:6]+'0100_atmos_6hr_surface_'+dy_name+'_r'+ymmem[7:9]+'i00p00.nc'
        
        print('j')
        print(j)
        if j==0:
            vmax,vmin,dyvmax,dyvmin=get_vamxmin(ymmem,inputf,dy_fname,leadtimelist[j],'3d',varname,dy_name,lat,lon,cfig,nnn,j)
        
        print(vmax)
        print(vmin)
        print(dyvmax)
        print(dyvmin)
        
        print('j')
        print(j)
        plt_lev_var(ymmem,inputf,dy_fname,leadtimelist[j],'3d',varname,dy_name,lat,lon,cfig,nnn,j,vmax,vmin,dyvmax,dyvmin)
        print(leadtimelist[j])
        print('j')
        print(j)
        print('end')
                    
    cfig=cfig+1
    
    plt.savefig(logdir+'/Outliers-'+ymmem+varname+'_surf'+'.pdf',bbox_inches = 'tight')  
    #plt.show()
        
    
    

    
    
    
    
    
