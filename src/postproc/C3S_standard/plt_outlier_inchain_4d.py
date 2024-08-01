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

from matplotlib import cm
from matplotlib.colors import ListedColormap, ListedColormap, LinearSegmentedColormap
from mpl_toolkits.axes_grid1 import AxesGrid
import datetime as dt
from dateutil.relativedelta import relativedelta
from calendar import monthrange
from mpl_toolkits.basemap import Basemap

from itertools import groupby
def plt_lev_var(fname,firsttime,leadtime,levs_dict,var,outlat,outlon,marker,cfig,numstep,vmax,vmin,plotf_name,time_tag):
    
    cmap='viridis'
    col='grey'
    linew=1
    linew2=0.5
    fs=11
    fsc=8
    
    filec3s=nc.Dataset(fname)
    lat=filec3s['lat'][:]
    lon=filec3s['lon'][:]
    
    lat2=list(filec3s['lat'][:])
    lon2=list(filec3s['lon'][:])
    
    
    ltime=filec3s['leadtime'][:]
    pos_ltime=np.where(np.array(ltime) == leadtime)[0]
    if levs_dict=='surface':
       ta=filec3s[var][pos_ltime,:,:]
       title_tag=levs_dict
    else:
       level=filec3s['plev'][:]/100.0    
       pos=np.where(np.array(level) == float(levs_dict))[0]    
       ta=filec3s[var][pos_ltime,pos,:,:]
       title_tag=levs_dict+'hPa'

    print(title_tag)
    ta=np.squeeze(ta)   
    
    outnum=np.shape(outlat)[0]
    #point=np.zeros((2,outnum),dtype=np.float64)
    #point[0,:]=outlat
    #point[1,:]=outlon
   
    print('numb outlier inside ', outnum) 
    ax1 = [0.01+1.1*numstep, 0.8, 1.2, 0.6]                         
    ax2=[0.01+1.1*numstep, 0.01, 1.2, 0.6]
    cax1=[1.1+1.1*numstep, 0.8, 0.02, 0.6]
    cax2=[1.1+1.1*numstep, 0.01, 0.02, 0.6]
    
    #test MB 
    
    fig=plt.figure(cfig)
       
    #plt outlier
   
    ax = fig.add_axes(ax1)
    m = Basemap(area_thresh=10000.,llcrnrlon=0,llcrnrlat=-90,urcrnrlon=360,urcrnrlat=90,resolution='l',projection='cyl',lat_0=0.,lon_0=0.,ax=ax)
    m.drawcoastlines(linewidth=linew2,zorder=4,color=col)        
    X,Y = np.meshgrid(lon,lat)
    mx,my = m(X,Y)
    cs=m.contourf(mx,my,ta,levels = np.linspace(vmin,vmax,11),extend='both',cmap=cmap,zorder=3)
    parallels = np.arange(-80.,90,20.)
    m.drawparallels(parallels,color=col,linewidth=linew,dashes=[1,0.1],labels=[1,0,0,0],fontsize=7.5,zorder=2)
    meridians = np.arange(60.,360.,60.)
    m.drawmeridians(meridians,color=col,linewidth=linew,dashes=[1,0.1],labels=[0,0,0,1],fontsize=7.5,zorder=2)
    
    
     
    for i in np.arange(outnum):
        xxout,yyout=m(outlon[i],outlat[i])
        if marker[i] == '+':
           colorm='red'
        elif marker[i]=='_':
           colorm='black' #'cyan'
        m.plot(float(xxout),float(yyout),marker[i],color=colorm,mfc='none',markersize=8 ,zorder=3)
        #m.plot(xxout,yyout,'D',color='r',alpha=.3)
    
    del(xxout)
    del(yyout)   
    xx,yy=m(100,98)      
    #plt.text(xx,yy,'Outliers: '+var+' '+title_tag+' leadtime:'+str(ltime[int(firsttime)]),fontsize=fs)
    plt.text(xx,yy,'Outliers: '+var+' '+title_tag+' leadtime: '+time_tag,fontsize=fs)
    
    
    xx,yy=m(-10,-120)      
    
    ax.spines['bottom'].set_linewidth(linew)
    ax.spines['top'].set_linewidth(linew)
    ax.spines['left'].set_linewidth(linew)
    ax.spines['right'].set_linewidth(linew)
    
    cbar1=fig.colorbar(cs,cax=plt.axes(cax1)) #51
    cbar1.ax.tick_params(labelsize=fsc, width=linew,length=1)
    plt.savefig(plotf_name,bbox_inches = 'tight',dpi=500) 
    plt.close() 
#=============
def get_vamxmin(fname,leadtime,levs_dict,var,outlat,outlon):  #,cfig,nnn,numstep):
    
    file=nc.Dataset(fname)
       
    lat2=list(file['lat'][:])
    lon2=list(file['lon'][:])   

    ltime=file['leadtime'][:]
    pos_ltime=np.where(np.array(ltime) == leadtime)[0]    

    if levs_dict=='surface':
       ta=file[var][pos_ltime,:,:]
    else:
       level=file['plev'][:]/100.0
       pos=np.where(np.array(level) == float(levs_dict))[0]    
       ta=file[var][pos_ltime,pos,:,:]


    ta=np.squeeze(ta)   
    
    outnum=np.shape(outlat)[0]
    point=np.zeros((2,outnum),dtype=np.float64)
    point[0,:]=outlat
    point[1,:]=outlon
        
    for i in np.arange(0,outnum):
        ta[lat2.index(point[0,i]),lon2.index(point[1,i])]=np.nan
    
    vmax=np.nanmax(ta)
    vmin=np.nanmin(ta)
    
    return vmax,vmin

#==============
def argParser():
    """
    Argument parser.
    """
    parser = argparse.ArgumentParser(prog='Plotting routine for C3SDataChecker',
        description=""" CMCC Checker for SPS3.5 data routine for plotting outlier. """)
    parser.add_argument("file", help="file to process. If a math pattern is indicated, then double quotes are needed")
    parser.add_argument("-v","--var", 
            help="name of the variable to process. (default:reads all vars in file)")
    parser.add_argument("-f", "--infile", help="input file")
    parser.add_argument("-p", "--inpath", help="input path")
    parser.add_argument("-l", "--logdir", help="log path")
    parser.add_argument("-sd", "--startdate",help="startdate (format $yyyy$st)")
    parser.add_argument("-real","--realization",help="ensemble member (2dig format)")
    parser.add_argument("-j","--json", default=os.path.join(os.getcwd(),"qa_checker_table.json"),help="Json file (default: qa_checker_table.json in current directory)")
    parser.add_argument("-pl","--plotname",help="Plot file name")
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



def consecutive_times(trainData):

    time_index_orig=list(trainData.iloc[:,2])
    time_index=[int(i) for n, i in enumerate(time_index_orig) if i not in time_index_orig[:n]]
    # Enumerate and get differences between counter—integer pairs
    # Group by differences (consecutive integers have equal differences)  
    gb = groupby(enumerate(time_index), key=lambda x: x[0] - x[1])
    # Repack elements from each group into list
    all_groups = ([i[1] for i in g] for _, g in gb)
    # Filter out one element lists
    consec_times=list(filter(lambda x: len(x) > 1, all_groups))
    
    ##loop to re-add single timestep
    for aa in time_index:
       if aa not in sum(consec_times,[]):
           consec_times.append([aa])
    return(consec_times)

#===main func=============
# Read arguments
args = argParser()

#inpath and inputf refer to netcdf files
inpath=args.inpath
inputf=args.infile

filec3s=nc.Dataset(inputf)
ltime=filec3s['leadtime'][:]
#e.g.file='clim_error_list_ta_sps3.5_199401_27.outlier'
err_file=args.file   

logdir=args.logdir

print('[INFO] Reading json table: ',args.json)
try:
    with open(args.json, "r") as read_file:
      json_table = json.load(read_file)
      clim_checked_vars  = json_table["checks"]["clim_checked_vars"]
      plev=json_table["checks"]["plev"]
except:
    raise InputError("Cannot read json file or its content")
    if args.verbose:
       traceback.print_exc()


#name3d=['clt','psl','tas','tdps','uas','vas','hfls','hfss','lweprc','lwepr','lweprsn','prw','rlds','rls','rlt','rsds','rsdt','rss','rst','tasmax','tasmin','tauu','tauv','wsgmax','orog','sftlf','tsl','lwee','lwesnw','mrroab','mrroas','rhosn','tso','sitemptop','sic','zg']
#name4d=['hus','ta','ua','va','zg','mrlsl','mlotstheta001','mlotstheta003','sithick','sos','sot300','t14d','t17d','t20d','t26d','t28d','thetaot300','zos']



file_name=err_file
pltname=str(args.plotname)
#varname -> variable to be checked
varname=args.var
startdate=args.startdate
real=args.realization
lev4check=clim_checked_vars[varname][0]
print(lev4check)

orig_table=pd.read_csv(err_file,sep='\s+')


df_dict={}
if lev4check != 0:
   outlier_lev=[]
   for lev in plev:
     perlev=orig_table.loc[orig_table['plev(hPa)'] == str(lev)+".0hPa"]
     if perlev.empty:
       print('no outlier on level '+str(lev)+' hPa')
     else:
       print(perlev)
       perlev=perlev.drop(['Pos[1]','plev(hPa)'], axis=1)
       outlier_lev.append(lev)
       perlev=perlev[0:np.shape(perlev)[0]]
       df_dict[str(lev)]=perlev
else:
   print(np.shape(orig_table))
   orig_table=orig_table[0:np.shape(orig_table)[0]]
   df_dict['surface']=orig_table

print(df_dict)
for levs in df_dict.keys():
    print('inside loop')
    trainData=df_dict[levs]
    train_upper=trainData[trainData['Error'].str.contains('val>max',na=False)]
    train_lower=trainData[trainData['Error'].str.contains('val<min',na=False)]
    print(trainData)
    print(train_upper)
    print(train_lower)
    time_index_orig=list(trainData.iloc[:,2])
    consec_upper=[]
    consec_lower=[]
    if len(train_upper) !=0:
       consec_upper=consecutive_times(train_upper)
    if len(train_lower) !=0:
       consec_lower=consecutive_times(train_lower)

    if np.logical_and(len(train_upper)!=0,len(train_lower)!=0):
       tmp=list(set(sum(consec_upper+consec_lower,[])))
       gb = groupby(enumerate(tmp), key=lambda x: x[0] - x[1])
       all_groups = ([i[1] for i in g] for _, g in gb)
       consec_times=list(filter(lambda x: len(x) > 1, all_groups))
       for aa in tmp:
          if aa not in sum(consec_times,[]):
             consec_times.append([aa])
  
    else:
       consec_times=consec_upper+consec_lower

    time_index_orig=list(trainData.iloc[:,2])
    nmb_plots=len(consec_times)
    
    leadtime=trainData.iloc[:,5]
    leadtime=leadtime.astype(np.float64)
    leadtime=leadtime.tolist()
    for cfig in range(nmb_plots):
        print("chunck number ",cfig)
        print (consec_times[cfig])
        lon_out=[]
        lat_out=[]
        marker=[]
        first_time=consec_times[cfig][0]
        if len(consec_times[cfig]) != 1 : 
           time_tag=str(ltime[first_time])+'-'+str(ltime[consec_times[cfig][-1]])
        else : 
           time_tag=str(ltime[first_time])
        for j in consec_times[cfig]:
           pos3=np.argwhere(np.array(time_index_orig).astype(int) == j)
           for i in range(len(pos3)):
              lat=trainData.iloc[pos3[i],6].values[0]
              lon=trainData.iloc[pos3[i],7].values[0]
              if trainData.iloc[pos3[i],1].values[0] == 'val<min':
                    marker.append("_")
              elif trainData.iloc[pos3[i],1].values[0] == 'val>max':
                    marker.append("+")
              lat_out.append(lat)
              lon_out.append(lon)
           if cfig==0:
               vmax,vmin=get_vamxmin(inputf,leadtime[pos3[0][0]],levs,varname,np.array(lat_out),np.array(lon_out)) #,cfig,nnn,j)
        print("coords for cfig ",cfig)
        print(lat_out)
        print(lon_out)
        plotf_name=logdir+'/'+pltname+'_'+levs+'_'+str(cfig)+'.pdf'
        plt_lev_var(inputf,first_time,leadtime[pos3[0][0]],levs,varname,np.array(lat_out),np.array(lon_out),marker,cfig,j,vmax,vmin,plotf_name,time_tag)
        #plt.savefig(logdir+'/Outliers-'+startdate+'_'+real+'_'+varname+'_'+levs+'_'+str(cfig)+'.pdf',bbox_inches = 'tight')

