import numpy as np
from print_error import print_error
from make_clim_error_table import make_clim_error_table
import datetime as dt
from dateutil.relativedelta import relativedelta
from calendar import monthrange
import netCDF4 as nc 

def check_climatological_ranges_monthly(fullfield, field, fieldmean, fieldstd, fieldmax, fieldmin, std_mult, verbose, very_verbose, warning):    
    """
    Check if field values are within global limit from climatological values or if values exceed climatological min/max values    Works only on 3D and 4D variables (i.e, at least time lat lon must be present)
    """
    exc_list=[]
    forecast_months=6
    forecast_moredays=4    
    print('yyyyyy----std_mult')
    print(std_mult)    



 
    # Get maximum of std for each month and level (if applicable) and then fill lat/lon dimensions with the same value
    if (len(fieldstd.dims) == 3) and (fieldstd.dims == (timename, 'lat', 'lon')):
        if very_verbose:
            print('....Computing monthly maximum (in all lat/lon) of std')
        max_std=np.nanmax(fieldstd.values, axis=(1,2),  keepdims=False)
        max_fieldstd = np.repeat(max_std[:,np.newaxis], np.shape(fieldstd.values)[1], axis=-1)
        max_fieldstd = np.repeat(max_fieldstd[:,:,np.newaxis], np.shape(fieldstd.values)[2], axis=-1)
    elif (len(fieldstd.dims) == 4) and (fieldstd.dims == (timename, levname, 'lat', 'lon')):
        if very_verbose:
            print('....Computing monthly maximum (in all lat/lon) of std by level')
        max_std = np.nanmax(fieldstd.values, axis=(2,3), keepdims=False)
        max_fieldstd = np.repeat(max_std[:,:,np.newaxis], np.shape(fieldstd.values)[2], axis=-1)
        max_fieldstd = np.repeat(max_fieldstd[:,:,:,np.newaxis], np.shape(fieldstd.values)[3], axis=-1)
    else:
        raise InputError('Test not implemented on this variable')   
    print('maxstd:')
    print(max_std)

    if very_verbose:
        print('....Creating array of std at high resolution from monthly climatological files')

    # Read start month from startdate and calculate number of days of all forecast period (forecast_monhts+forecast_moredays)
    month_days=[]
    startdate = dt.datetime.strptime(lab_std+'01', '%Y%m%d')
    print(startdate)

    for m in range(0,forecast_months):
        new_month = startdate + relativedelta(months=+m)
        month_days+=[monthrange(int(new_month.year),int(new_month.month))[1]]

    month_days+=[forecast_moredays]
    print('month_days:')
    print(str(month_days))    



    var_freq=int(fullfield.dims[timename]/sum(month_days)) # obs per day (length of field/number of days)
    #print(var_freq)
    # now create new mean/std that mach field size by repeating monthly values
    fieldstd_tmp = np.empty_like(field)
    # fill forecast months 
    start = 0    
    for i in range(0,forecast_months):
        end   = start + month_days[i]*var_freq
        print(i)
        print(start)
        print(end)

        if (len(field.dims) == 3):
            #fieldstd_tmp[start:end,:,:]  = fieldstd.values[i,:,:] # single point monthly std
            fieldstd_tmp[start:end,:,:]  = max_fieldstd[i,:,:]      # global monthly std
        elif (len(field.dims) == 4):
            #fieldstd_tmp[start:end,:,:,:]  = fieldstd.values[i,:,:,:] # single point monthly std 
            fieldstd_tmp[start:end,:,:,:]  = max_fieldstd[i,:,:,:]      # global monthly std
       
        start+=month_days[i]*var_freq

     
    if (len(field.dims) == 3):
        #fieldstd_tmp[start:fieldstd_tmp.shape[0],:,:]=fieldstd.values[forecast_months-1,:,:]
        fieldstd_tmp[start:fieldstd_tmp.shape[0],:,:]=max_fieldstd[forecast_months-1,:,:]
    elif (len(field.dims) == 4):
        #fieldstd_tmp[start:fieldstd_tmp.shape[0],:,:,:]=fieldstd.values[forecast_months-1,:,:,:]
        fieldstd_tmp[start:fieldstd_tmp.shape[0],:,:,:]=max_fieldstd[forecast_months-1,:,:,:]
 
    fieldmean_tmp = fieldmean.values
    
    #mask SIC========only for sst
    lt=np.shape(field)[0]
    meansic=np.zeros((lt,180,360))

    if shortname=='tso':
        '''     
        tsic=np.zeros((40,180,360))
        for i in np.arange(1,41):
            #print(format(i,'0>2d'))
            r=format(i,'0>2d')   
            file5=nc.Dataset('/work/csp/sp1/CESM/archive/C3S/199310/cmcc_CMCC-CM2-v20191201_hindcast_S1993100100_seaIce_6hr_surface_sitemptop_r'+r+'i00p00.nc')
            sic=np.nanmean(file5['sitemptop'][:,:,:],0)
            tsic[i-1,:,:]=sic
        
      
        meansic[0:lt,:,:]=np.nanmean(tsic,0)  
        meansic[~np.isnan(meansic)]=999
        '''
        fm=nc.Dataset('/users_home/csp/sps-dev/SPS/CMCC-SPS3.5/work/ZHIQI/range_checkfromM/mask-sic.nc')   
        meansic=fm['sitemptop'][:] 
        field.values[meansic==999]=np.nan
              
 
        fieldmean_tmp[meansic==999]=np.nan
        fieldstd_tmp[meansic==999]=np.nan
        
        #print(np.shape(std_mult))
        fieldmax.values[meansic==999]=np.nan
        fieldmin.values[meansic==999]=np.nan 
        #print('std---yyyyyyyyyy------')
    #=======================

 
    if np.shape(fieldmean_tmp) != np.shape(field) or np.shape(fieldstd_tmp) != np.shape(field) :
        raise InputError('Reconstructed mean/std variables do not match field size')

    # compute limits (mean +/- std*std_mult)
    fieldmaxlimit = fieldmean_tmp + fieldstd_tmp*std_mult
    fieldminlimit = fieldmean_tmp - fieldstd_tmp*std_mult

    # flag for raising error if needed
    raise_error=False
    # initialize table variables
    table1=[]; table2=[]; table3=[]; table4=[];
    header=[]; table=[]
    tot_points=0
    
    try:
        max_ge_limit=np.greater(field,fieldmaxlimit, where=True)
        min_le_limit=np.less(field,fieldminlimit, where=True)
        max_ge_cmax=np.greater(field,fieldmax, where=True)
        min_le_cmin=np.less(field,fieldmin, where=True)
        if max_ge_limit.any() or min_le_limit.any() or max_ge_cmax.any() or min_le_cmin.any():
                raise_error=True
                if max_ge_limit.any():
                    pos = np.where(max_ge_limit==True)

                    print('np.shape(max_ge_limit):')
                    print(np.shape(max_ge_limit))
                    
                    npoints = len(pos[0])
                    tot_points+=npoints
                    [table1, header]=make_clim_error_table(fullfield, field.dims,
                        field.values,
                        [ fieldmax.values, fieldmin.values, fieldmaxlimit, fieldmean.values, fieldstd_tmp],
                        npoints, pos, check_type='val>limit', std_mult=std_mult, verbose=verbose)
                    raise_error=True                
                
                if min_le_limit.any():
                    pos=np.where(min_le_limit==True)
                    npoints=len(pos[0])
                    tot_points+=npoints
                    [table2, header]=make_clim_error_table(fullfield, field.dims,
                        field.values,
                        [ fieldmax.values, fieldmin.values, fieldminlimit, fieldmean.values, fieldstd_tmp],
                        npoints, pos, check_type='val<limit', std_mult=std_mult, verbose=verbose)
                    raise_error=True                 
                 
#                if max_ge_cmax.any():
#                    pos=np.where(max_ge_cmax==True)
#                    npoints=len(pos[0])
#                    tot_points+=npoints
#                    [table3,header]=make_clim_error_table(fullfield, field.dims,
#                        field.values,
#                        [ fieldmax.values, fieldmin.values],
#                        npoints, pos, check_type='val>max', std_mult=std_mult, verbose=verbose)
#                    raise_error=True                    
                
#                if min_le_cmin.any():
#                    pos=np.where(min_le_cmin==True)
#                    npoints=len(pos[0])
#                    tot_points+=npoints
#                    [table4,header]=make_clim_error_table(fullfield, field.dims,
#                        field.values,
#                        [ fieldmax.values, fieldmin.values],
#                        npoints, pos, check_type='val<min', std_mult=std_mult, verbose=verbose)
#                    raise_error=True
                
                if raise_error:
                    # Merge all error lists to create a single table
                    for fulllist in [table1, table2, table3, table4]:
                        if fulllist:
                            if not table:
                                # the first time define the variable
                                table=fulllist
                            else:
                                # otherwise append the list
                                table+=fulllist
                                
                    if warning is True:
                        war_message='[FIELDWARNING] >> Field '+shortname+' ('+varname+') '+' exceeding climatological ranges on '+str(tot_points)+' points. For a complete list, see the table in error log.'
                        print(war_message)
                    else:
                        raise FieldError('Field exceeding climatological ranges on '+str(tot_points)+' points. For a complete list, see the table in error log.')
       
    except FieldError as e:
        exc_list+=print_error(error_message=e, error_list=exc_list, loc1=[shortname, varname])
        
    return(exc_list, table, header)
