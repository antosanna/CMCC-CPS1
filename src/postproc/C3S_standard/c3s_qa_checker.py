#usr/bin/env python3
# -*- coding: utf-8 -*-
#"""
#Perform a series of quality checks on SPS3.5 data. Input data can be:
#     raw model output
#     model output for C3S
#
#@author: Maria del Mar Chaves Montero @ CMCC, CSP division Nov 2019
#"""
#==========================================================================
# Preamble
#==========================================================================
global varname
global shortname
global timename
global levname
global lab_std


import os
import traceback
#import fnmatch
import sys
#import argparse
#import re
import numpy as np
import xarray as xr
import json
import warnings
import time
import tracemalloc
#import shutil
#from fpdf import FPDF
from tabulate import tabulate
#import dask.array as da

#import matplotlib.pyplot as plt
## plt.style.use('seaborn-white')
#from matplotlib import cm
#from matplotlib.colors import ListedColormap, ListedColormap, LinearSegmentedColormap
#from mpl_toolkits.axes_grid1 import AxesGrid
#import cartopy.crs as ccrs
#from cartopy.mpl.geoaxes import GeoAxes
#from cartopy.mpl.ticker import LongitudeFormatter, LatitudeFormatter
#import datetime as dt
#from dateutil.relativedelta import relativedelta
#from calendar import monthrange
#import netCDF4 as nc


from qa_checker_lib.argParser import argParser

from qa_checker_lib.general_tools import (
            check_emails, 
            check_path_exists, 
            find_files, 
            check_file_size,
            print_error, 
            write_log, 
            get_labels_from_filename)

from qa_checker_lib.var_tools import (
            get_var_name, 
            get_time_name, 
            get_lev_name,
            var_in_list,
            sel_field_slice)

from qa_checker_lib.checker_tools import (
            check_minmax, 
            check_tsd_34dfield,
            check_consistency_all_field_not_encoded, 
            check_2d_field, 
            check_field) 
from qa_checker_lib.checker_tools_onlyspike import (
            check_temp_spike, check_temp_spike_new)

from qa_checker_lib.clim_checker_tools import (
            check_minmax_interval,
            check_climatological_ranges, 
            check_interquantile_interval,
            check_interquantile_interval_prec,
            check_climatology_minmax,
            check_climatology_minmax_vect,
            check_monthly_minmax,
            make_clim_error_table,
            make_clim_error_table_tol,
            change_value)

from qa_checker_lib.errors import *

#from qa_checker_plots import plot_diff_field_limit,plot_mean_field,plot_max_field plot_min_field,\
#                             plot_time_series_field, construct, create_summary

#==========================================================================
# Main function
#==========================================================================

def main():
   

    # Ignore warnings
    warnings.filterwarnings("ignore")
    
    # Read arguments
    args = argParser()

    # Trace program timing
    start_time = time.process_time()
    
    # Trace program memory allocation
    if args.trace_mem:
        tracemalloc.start()

    # Define global variables that will be seen by all functions
    #global varname
    #global shortname
    #global timename
    #global levname
    #global lab_std

    # Read json table with external arguments 
    # Check file existence
    check_path_exists(args.json)     

    #print(args.json)
    
    # Open json and read limits
    print('[INFO] Reading json table: ',args.json)
    try:
        with open(args.json, "r") as read_file:
            json_table = json.load(read_file)
            hindcast_period    = json_table["hindcast_period"]
            system             = json_table["system"]
            C3Svars            = json_table["checks"]["C3S_variables"]
            DMOvars            = json_table["checks"]["DMO_variables"]
            masked_vars        = json_table["checks"]["masked_vars"]            
            excluded_vars      = json_table["checks"]["excluded_vars"]
            min_checked_vars   = json_table["checks"]["min_checked_vars"]
            max_checked_vars   = json_table["checks"]["max_checked_vars"]
            tsd_checked_vars   = json_table["checks"]["tsd_checked_vars"]
            spike_checked_vars = json_table["checks"]["spike_checked_vars"]
            clim_checked_vars  = json_table["checks"]["clim_checked_vars"]
            
    except:
        raise InputError("Cannot read json file or its content")
        if args.verbose:
            traceback.print_exc()

    # Read file(s) to check
    # Check file existence 
    check_path_exists(args.path)
    files = find_files(args.file, args.path)
        

    # Print list of file(s)
    if (len(files)<=1):
        print('[INFO] Processing file:')
    else:
        print('[INFO] List of files:')
    print(files)
    print('')
        

    #!!!!!!!!!
    # Fix suffix variables for output naming
    # Add underscore to suffix and preffix if present
    # TODO maybe exp, real can be taken from file name instead of external argument?
    exp  = "_"+args.log_exp_suffix if args.log_exp_suffix else args.log_exp_suffix
    real = "_"+args.log_real_suffix if args.log_real_suffix else args.log_real_suffix
    # If there is more than 1 file the output needs a suffix for the file, otherwise it will be overwritten!
    file_suffix="_f" if (len(files) > 1) else ""
    

    # Loop on file(s)
    for f in range(0,len(files)):
        
        if (len(files)>1) and (args.verbose):
            print('[INFO] Processing file:')
            print(files[f])
                   
        # Check file size > 0
        try:
            check_file_size(os.path.join(args.path,files[f]))
        except InputError as e:
            print('[INPUTERROR] >>', str(e))

        # Initialize error list for file
        file_output_list=[]
        


        # Quality checks on file 
        try:
            # Read the file
            DS = xr.open_dataset(os.path.join(args.path,files[f]), decode_times=False )
             
            #print(DS)
            # Get the list of variables where to apply the checks: selected variable OR all variables in the file with more than 2D except coordinates and bounds
            if args.var is not None:
                varlist = [args.var, None]
            else:
                varlist = list(DS.data_vars.keys())
            
            print('varlist:')             
            print(varlist)  
        
            
            # Loop on variable(s)
            for v in varlist:
                if v is not None and (v not in excluded_vars) and ((v in C3Svars) or (v in DMOvars)):
                    # Initialize error list variables for each variable in file
                    error_in_var=False
                    ice_spike_list=[]; spike_error_list=[]
                    dropT_list=[]
                    output_list=[]; consistency_list=[]; generallist=[]; 
                    climlist=[]; table_values=[]; table_header=[]
                    # TODO REMOVE ALL climlist2 
                    climlist2=[]; table_values2=[]; table_header2=[]

                    # Get some info about the variable
                    varname = get_var_name(DS[v])
                    shortname = DS[v].name
                    timename=None
                    levname=None
                    if (shortname != 'orog') and (shortname != 'sftlf') :
                        timename = get_time_name(DS[v])
                    if ('plev' in DS.dims) or ('depth' in DS.dims):
                        levname  = get_lev_name(DS[v])
                    print("[INFO] Variable ",shortname, DS[v].dims)
                    print("[INFO] Variable ",shortname,' shape',DS[v].shape,"\n")
                
                   
                    #if v in C3Svars:
                    #    DSchunk= da.from_array(DS[v].values, chunks=(100,180,360))
                    #    #DSchunk= da.from_array(DS['uas'].values, chunks=(100,180,360))
                    #    print("DSchunk done for var" + v)
                    
                    # get label information from file name
                    # This is a critical point that limits the application of this program to files that follow specific naming convention (now the CMCC SPS3.5 DMO/C3S data)
                    # For adding new filename types, follow the info of the get_labels_from_filename() function.
                    [lab_tmp, lab_preffix,lab_nohind, lab_std, lab_year, lab_month, lab_mem] = get_labels_from_filename(files[f], v, [C3Svars,DMOvars])         
                    print('tmp:')
                    print(lab_tmp)
                    print('std:')
                    print(lab_std)
                    print('year:')
                    print(lab_year)
                    print('month:')
                    print(lab_month)
                    print('mem:')
                    print(lab_mem)
              
                    # set flags for var min/max/time sd that must be checked
                    check_min   = var_in_list(v, min_checked_vars)
                    check_max   = var_in_list(v, max_checked_vars)
                    check_tsd   = var_in_list(v, tsd_checked_vars)
                    check_spike = var_in_list(v, spike_checked_vars)
                    print(spike_checked_vars)
                    check_clim  = var_in_list(v,clim_checked_vars)
                    # get min/max limits for var
                    minlim = min_checked_vars[shortname] if (check_min) else None
                    maxlim = max_checked_vars[shortname] if (check_max) else None
                    #get level for climatological check
                    lev4check=clim_checked_vars[shortname][0]  if(check_clim) else None
                    tolerance=clim_checked_vars[shortname][1]  if(check_clim) else None
                    only_spike=args.only_spike
                    if only_spike:
                       check_min=False
                       check_max=False
                       check_tsd=False
                       check_clim=False    
                
                    # get fill_value or default
                    var_ismasked   = var_in_list(v, masked_vars)
                    if var_ismasked:
                        fill_value = DS[v].encoding['_FillValue']
                    else:
                        fill_value=1e+20
               
                    # Consistency check ok all field on NON-DECODED DATA in order to avoid _Fill_Value to be set to nan by python encoding and therefore undistinguishable from actual nans
                    with xr.open_dataset(os.path.join(args.path,files[f]), decode_times=False, decode_cf=False) as DSnotdecoded:
                        consistency_list = check_consistency_all_field_not_encoded(DSnotdecoded[v], varname, shortname, verbose=args.verbose, very_verbose=args.very_verbose)
                    
                    print('consistencylist:')
                    print(consistency_list)
                    # General checks
                    generallist = check_field(DS[v], varname, shortname, timename, levname, filling_value=fill_value, constant_limit=1e-9, check_min=check_min, min_limit=minlim, check_max=check_max, max_limit=maxlim, check_tsd=check_tsd, tsd_limit=0,verbose=args.verbose, very_verbose=args.very_verbose)
                    print('generallist:')
                    print(generallist)     
           
                    # Spike check
                    if check_spike:
                        if args.verbose:
                            print('[INFO] Performing spike diagnostic with threshold d1='+str(args.delta1)+' and d2='+str(args.delta2))

                        if shortname=='TREFMNAV' or shortname=='tasmin':
                           ice_spike_list, dropT_list, spike_error_list = check_temp_spike_new(varname,shortname,timename, files[f], spike_error_list, field1=DS[v], min_limit1=220, delta_limit1=float(args.delta1),delta_limit2=float(args.delta2), verbose=args.verbose, very_verbose=args.very_verbose)
                        else:
                            raise InputError('Spike check in this variable has not been implemented')


                    # Climatology range check
                    if check_clim and args.path_clim and args.quantile_value:
                        print('[INFO] Performing quantile interval check')
                        low_quantile=float(args.quantile_value)
                        high_quantile=round(1.-low_quantile,2)
                        str_high_quantile="{:.2f}".format(high_quantile)
                        str_low_quantile="{:.2f}".format(low_quantile) 
                        # Opening climatological files if they exist
                        if lev4check == 0 :
                            file_quant_max=lab_preffix+"_"+lab_month+"."+hindcast_period+"_"+shortname+"_"+str_high_quantile+"quantile_max.monthly.C3S.nc"
                            file_quant_min=lab_preffix+"_"+lab_month+"."+hindcast_period+"_"+shortname+"_"+str_low_quantile+"quantile_min.monthly.C3S.nc"
                            #file_quant_max=lab_preffix+"_"+lab_month+"."+hindcast_period+"_"+shortname+"_"+str_high_quantile+"quantile.nc"
                            #file_quant_min=lab_preffix+"_"+lab_month+"."+hindcast_period+"_"+shortname+"_"+str_low_quantile+"quantile.nc"
                        else :
                            file_quant_max=lab_preffix+"_"+lab_month+"."+hindcast_period+"_"+shortname+"_"+str(lev4check)+"hPa_"+str_high_quantile+"quantile_max.monthly.C3S.nc"
                            file_quant_min=lab_preffix+"_"+lab_month+"."+hindcast_period+"_"+shortname+"_"+str(lev4check)+"hPa_"+str_low_quantile+"quantile_min.monthly.C3S.nc"
                            #file_quant_max=lab_preffix+"_"+lab_month+"."+hindcast_period+"_"+shortname+"_"+str(lev4check)+"hPa_"+str_high_quantile+"quantile.nc"
                            #file_quant_min=lab_preffix+"_"+lab_month+"."+hindcast_period+"_"+shortname+"_"+str(lev4check)+"hPa_"+str_low_quantile+"quantile.nc"
                        try:
                            if args.very_verbose:
                                print(f"....Looking for quantile files quantile value {args.quantile_value} at {os.path.join(args.path_clim,lab_month,shortname)}")
                            check_path_exists(os.path.join(args.path_clim,lab_month,shortname,file_quant_min))
                            check_path_exists(os.path.join(args.path_clim,lab_month,shortname,file_quant_max))

                        except:
                            if args.verbose:
                                print("[INFO] Files for quantile check range cware selected according to the quantile value input which expresses the lower quantile value")
                                print("   Files must be named as follows: ")
                                print("        [preffix]_[startdate].[hindcast-period]_[shortname]_[quantile value]quantile.nc")
                                print("        [preffix]_[startdate].[hindcast-period]_[shortname]_[1 - quantile value]quantile.nc")
                                print("        i.e cmcc_CMCC-CM2-v20191201_hindcast_11.1993-2016_hus_0.10quantile.nc")
                            raise InputError('Cannot open one or more climatological files in '+os.path.join(args.path_clim,lab_month,shortname)+' \n'+file_quant_min+", \n"+file_quant_max)
                        # open upper quantile
                        try:
                            DSupperq  = xr.open_dataset(os.path.join(args.path_clim,lab_month,shortname,file_quant_max))
                        except:
                            print("error qhile opening DSupperq")
                        try:
                            DSlowerq  = xr.open_dataset(os.path.join(args.path_clim,lab_month,shortname,file_quant_min))
                        except:
                            print("error qhile opening DSupperq")

                        #read_up=np.round(DSupperq['threshold'].values,2)
                        #print(read_up)
                        #assert np.round(DSupperq['threshold'].values,2) == high_quantile, print(f"Higher quantile {round(DSupperq.threshold,2)} read in input file differs from the value {high_quantile} expected")
                        #assert np.round(DSlowerq['threshold'].values,2) == low_quantile, print(f"Lower quantile {round(DSlowerq.threshold,2)} read in input file differs from the value {low_quantile} expected")
                            
# read min and max from hindcast climatology
                        file_clim_max=lab_preffix+"_"+lab_month+"."+hindcast_period+"_"+shortname+"_max.nc"
                        file_clim_min=lab_preffix+"_"+lab_month+"."+hindcast_period+"_"+shortname+"_min.nc"

                        try:
                            if args.very_verbose:
                                print("....Looking for climatological files at "+os.path.join(args.path_clim,lab_month,shortname))
                            check_path_exists(os.path.join(args.path_clim,lab_month,shortname,file_clim_min))
                            check_path_exists(os.path.join(args.path_clim,lab_month,shortname,file_clim_max))


                        except:
                            if args.verbose:
                                print("[INFO] Files for climatological range must follow some rules:")
                                print("   Two files are excepted: one with the mean and one with the standard deviation")
                                print("   All climatological files contain a variable with same name and dimensions than the checked variable")
                                print("   Files must be named as follows: ")
                                print("        [preffix]_[startdate].[hindcast-period]_[shortname]_min.nc")
                                print("        [preffix]_[startdate].[hindcast-period]_[shortname]_max.nc")
                                print("        [preffix]_[startdate].[hindcast-period]_[shortname]_emean_highfreq.nc")
                                print("        i.e cmcc_CMCC-CM2-v20191201_hindcast_11.1993-2016_hus_min.nc")
                            raise InputError('Cannot open one or more climatological files in '+os.path.join(args.path_clim,lab_month,shortname)+' \n'+file_clim_min+", \n"+file_clim_max+", \n"+file_clim_mean)
                        # open climatology
                        DSmax  = xr.open_dataset(os.path.join(args.path_clim,lab_month,shortname,file_clim_max), decode_times=False)
                        DSmin  = xr.open_dataset(os.path.join(args.path_clim,lab_month,shortname,file_clim_min), decode_times=False)

# cmcc_CMCC-CM2-v20191201_hindcast_02.1993-2016_psl_max.monthly.C3S.nc
                        file_clim_monmax=lab_preffix+"_"+lab_month+"."+hindcast_period+"_"+shortname+"_max.monthly.C3S.nc"  ####
                        file_clim_monmin=lab_preffix+"_"+lab_month+"."+hindcast_period+"_"+shortname+"_min.monthly.C3S.nc"  ####

                        try:

                            if args.very_verbose:
                                print("....Looking for climatological files at "+os.path.join(args.path_clim,lab_month,shortname))
                            check_path_exists(os.path.join(args.path_clim,lab_month,shortname,file_clim_monmin))
                            check_path_exists(os.path.join(args.path_clim,lab_month,shortname,file_clim_monmax))


                        except:
                            if args.verbose:
                                print("[INFO] Files for climatological range must follow some rules:")
                                print("   Two files are excepted: one with the mean and one with the standard deviation")
                                print("   All climatological files contain a variable with same name and dimensions than the checked variable")
                                print("   Files must be named as follows: ")
                                print("        [preffix]_[startdate].[hindcast-period]_[shortname]_min.nc")
                                print("        [preffix]_[startdate].[hindcast-period]_[shortname]_max.nc")
                                print("        [preffix]_[startdate].[hindcast-period]_[shortname]_emean_highfreq.nc")
                                print("        i.e cmcc_CMCC-CM2-v20191201_hindcast_11.1993-2016_hus_min.nc")
                            raise InputError('Cannot open one or more climatological files in '+os.path.join(args.path_clim,lab_month,shortname)+' \n'+file_clim_monmin+", \n"+file_clim_monmax)
                       

                        DSmonmax  = xr.open_dataset(os.path.join(args.path_clim,lab_month,shortname,file_clim_monmax), decode_times=False)
                        DSmonmin  = xr.open_dataset(os.path.join(args.path_clim,lab_month,shortname,file_clim_monmin), decode_times=False)


                        #[climlist, table_values, table_header]  = check_interquantile_interval(DS[v], DSmax[v], DSupperq[v], DSmin[v], DSlowerq[v],lev4check,args.mult_fact, args.logdir, verbose=args.verbose, very_verbose=args.very_verbose,  warning=True)
                        [climlist, table_values, table_header]  = check_interquantile_interval(DS[v], DSmax[v], DSmonmax[v], DSupperq[v], DSmin[v],DSmonmin[v],DSlowerq[v],lev4check,args.mult_fact, args.logdir, verbose=args.verbose, very_verbose=args.very_verbose,  warning=True)
                        
                    elif check_clim and args.path_clim:
                        print('[INFO] Performing climatological max/min check on monthly records')
        

# read monthly min and max from hindcast climatology
# cmcc_CMCC-CM2-v20191201_hindcast_02.1993-2016_psl_max.monthly.C3S.nc
                        file_clim_monmax=lab_preffix+"_"+lab_month+"."+hindcast_period+"_"+shortname+"_max.monthly.C3S.nc"  ####
                        file_clim_monmin=lab_preffix+"_"+lab_month+"."+hindcast_period+"_"+shortname+"_min.monthly.C3S.nc"  ####
                        #file_clim_monmax=lab_preffix+"_"+lab_month+"."+hindcast_period+"_"+shortname+"_zonmax.monthly.C3S.nc"  ####
                        #file_clim_monmin=lab_preffix+"_"+lab_month+"."+hindcast_period+"_"+shortname+"_zonmin.monthly.C3S.nc"  ####
                        if args.updateclim:
                            file_clim_monmax=lab_nohind+"_"+lab_month+"_"+shortname+"_max.monthly.C3S.nc"
                            file_clim_monmin=lab_nohind+"_"+lab_month+"_"+shortname+"_min.monthly.C3S.nc"
                        try:
                            if args.very_verbose:
                                print("....Looking for climatological files at "+os.path.join(args.path_clim,lab_month,shortname))
                            check_path_exists(os.path.join(args.path_clim,lab_month,shortname,file_clim_monmin))
                            check_path_exists(os.path.join(args.path_clim,lab_month,shortname,file_clim_monmax))


                        except:
                            if args.verbose:
                                print("[INFO] Files for climatological range must follow some rules:")
                                print("   Two files are excepted: one with the mean and one with the standard deviation")
                                print("   All climatological files contain a variable with same name and dimensions than the checked variable")
                                print("   Files must be named as follows: ")
                                print("        [preffix]_[startdate].[hindcast-period]_[shortname]_min.nc")       ###
                                print("        [preffix]_[startdate].[hindcast-period]_[shortname]_max.nc")       ### 
                                print("        [preffix]_[startdate].[hindcast-period]_[shortname]_emean_highfreq.nc")   ###
                                print("        i.e cmcc_CMCC-CM2-v20191201_hindcast_11.1993-2016_hus_min.nc")   ###
                            raise InputError('Cannot open one or more climatological files in '+os.path.join(args.path_clim,lab_month,shortname)+' \n'+file_clim_monmin+", \n"+file_clim_monmax)
                        # open climatology
                        #TO-BE_MODIF
                        #if shortname=='psl':
                        #   file_clim_monmax="cmcc_CMCC-CM2-v20191201_07_psl_max.monthly.C3S.nc"                           
                        #   file_clim_monmin="cmcc_CMCC-CM2-v20191201_07_psl_min.monthly.C3S.nc"
                        DSmonmax  = xr.open_dataset(os.path.join(args.path_clim,lab_month,shortname,file_clim_monmax), decode_times=False)
                        DSmonmin  = xr.open_dataset(os.path.join(args.path_clim,lab_month,shortname,file_clim_monmin), decode_times=False)
                        filemonmax_path=os.path.join(args.path_clim,lab_month,shortname,file_clim_monmax)
                        filemonmin_path=os.path.join(args.path_clim,lab_month,shortname,file_clim_monmin)
                        tmpdir=args.scratchdir
                        #[climlist, table_values, table_header]= check_monthly_minmax_tolerance(DS[v],tolerance, DSmonmax[v], DSmonmin[v], filemonmax_path, filemonmin_path,DSmonmax,DSmonmin,tmpdir, args.logdir, verbose=args.verbose, very_verbose=args.very_verbose,  warning=True)
                        #[climlist, table_values, table_header]= check_monthly_minmax(DS[v],DSmonmax[v], DSmonmin[v], filemonmax_path, filemonmin_path,DSmonmax,DSmonmin,tmpdir, args.logdir, verbose=args.verbose, very_verbose=args.very_verbose,  warning=True)
                        [climlist, table_values, table_header]= check_minmax_interval(DS[v],DSmonmax[v], DSmonmin[v],tolerance, args.logdir, verbose=args.verbose, very_verbose=args.very_verbose,  warning=True) 
                    # Merge all error lists, of all variables
                    # TODO REMOVE climlist2
                    for fulllist in [consistency_list, generallist, climlist, spike_error_list, climlist2]:
                        if fulllist:
                            error_in_var=True
                            file_output_list+=fulllist

                    # Print logs/summary for variable: 
                    # Print table of clim errors for variable if test failed
                    if table_values:
                        logname=os.path.join(args.logdir,"clim_error_list_"+shortname+exp+real+file_suffix+".outlier")
                        with open(logname, 'w') as f:
                            f.write(tabulate(table_values, headers=table_header))
                        if args.verbose:
                            print('[INFO] Log file written: '+logname)

                    # TO REMOVE (this operates only on last variable but for testing is ok)
                    if table_values2:
                        logname=os.path.join(args.logdir,"hf_clim_error_list_"+shortname+exp+real+file_suffix+".outlier")
                        with open(logname, 'w') as f:
                            f.write(tabulate(table_values2, headers=table_header2))
                        if args.verbose:
                            print('[INFO] Log file written: '+logname)

                    # Print summary report for variable if summary_report flag is present
                    # TODO You can improve this condition adding other options, i.e, when any error is found (error_in_var is True), or for certain variables (define summary_vars in json)
                    if args.summary_report is True:
                        create_summary(DS, DS[v], table_values, args.logdir, lab_std, lab_mem, files[f], args.verbose, args.very_verbose)
                        if args.verbose:
                            print('[INFO] Summary report file written in '+os.path.join(args.logdir,'summary'))

        # exit in case of InputError,FieldError or SysError
        except InputError as e:
            print('[INPUTERROR] ',files[f],'>>', str(e) ,'for variable', shortname)
        
        #except FieldError as e:
        #    print('[FIELDERROR] ',files[f],'>>', str(e), 'for variable', shortname)
        
        except:
            print('[SYSERROR] Unexpected error:', sys.exc_info()[0], 'on ', sys.exc_info()[2])
       	    if args.verbose:
                traceback.print_exc()
 
        finally:
            if args.write_log and file_output_list:
                logname=os.path.join(args.logdir,"qa_checker_error_list"+exp+real+file_suffix+".txt")
                write_log(logname, files[f], file_output_list, args.verbose, args.very_verbose)
                if args.verbose:
                    print('[INFO] Log file written: '+logname)
            if args.dropTlist & any(dropT_list):
                logname=args.dropTlist
                write_log(logname, files[f], dropT_list, args.verbose, args.very_verbose)
            if ice_spike_list:
                logname=args.spikelist
                write_log(logname, files[f], ice_spike_list, args.verbose, args.very_verbose)
                if args.verbose:
                    print('[INFO] Log file written: '+logname)
            
            print('[INFO] Finished diagnose')
            
    # print program execution information
    if args.trace_mem:
        current, peak = tracemalloc.get_traced_memory()
        print("[INFO] Current memory usage is {current / 10**6}MB; Peak was {peak /10**6}MB")
        tracemalloc.stop()
    
    print ("[INFO] Execution time was",time.process_time() - start_time, "seconds")
    
"""
class PDF(FPDF):
    def __init__(self,   orientation = 'P', filename=''):
        super().__init__()
        # Page orientation
        orientation = orientation.lower()
        if orientation in ('p', 'portrait'):
            self.def_orientation = 'P'
            self.w_pt = self.fw_pt
            self.h_pt = self.fh_pt
            self.WIDTH = 210
            self.HEIGHT = 297
        elif orientation in ('l', 'landscape'):
            self.def_orientation = 'L'
            self.w_pt = self.fh_pt
            self.h_pt = self.fw_pt
            self.WIDTH = 297
            self.HEIGHT = 210
        else:
            self.error('Incorrect orientation: ' + orientation)
        self.cur_orientation = self.def_orientation
        self.w = self.w_pt / self.k
        self.h = self.h_pt / self.k
        self.filename=filename
        
    def header(self):
        self.set_font('Arial', 'B', 11)
        self.cell(self.WIDTH - 80)
        self.cell(50, 1, 'QA CHECKER SUMMARY REPORT', 0, 0, 'R')
        self.ln(5)
        self.cell(self.WIDTH - 80)
        self.cell(50, 1, self.filename, 0, 0, 'R')
        
    def footer(self):
        # Page numbers in the footer
        self.set_y(-15)
        self.set_font('Arial', 'I', 8)
        self.set_text_color(128)
        self.cell(0, 10, 'Page ' + str(self.page_no()), 0, 0, 'C')

    def page_body(self, images):
        # Determine how many plots there are per page and set positions
        # and margins accordingly
        if len(images) == 3:
            self.image(images[0], 15, 35, self.WIDTH - 30)
            self.image(images[1], 15, self.WIDTH / 2 + 15, self.WIDTH - 30)
            self.image(images[2], 15, self.WIDTH / 2 + 105, self.WIDTH - 30)
        elif len(images) == 2:
            self.image(images[0], 15, 35, self.WIDTH - 30)
            self.image(images[1], 15, self.WIDTH / 2 + 15, self.WIDTH - 30)
        else:
            self.image(images[0], 15, 35, self.WIDTH - 30)
            
    def print_page(self, images):
        # Generates the report
        self.add_page()
        self.page_body(images)

"""

#==========================================================================
# Main sentinel
#==========================================================================
if __name__ == '__main__':
   global varname
   global shortname
   global timename
   global levname
   global lab_std
   main()
