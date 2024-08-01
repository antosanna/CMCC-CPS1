import numpy as np
from print_error import print_error
from make_clim_error_table import make_clim_error_table
import datetime as dt
from dateutil.relativedelta import relativedelta
from calendar import monthrange
import netCDF4 as nc 
def check_climatological_ranges_monthly(fullfield, field, fieldmean, fieldstd, fieldmax, fieldmin, std_mult, verbose, very_verbose, warning):
    
    Check if field values are within global limit from climatological values or if values exceed climatological min/max values
    Works only on 3D and 4D variables (i.e, at least time lat lon must be present)
    
    exc_list=[]
    forecast_months=6
    forecast_moredays=3

    # Get maximum of std for each month and level (if applicable) and then fill lat/lon dimensions with the same value
    if (len(fieldstd.dims) == 3) and (fieldstd.dims == (timename, 'lat', 'lon')):
        if very_verbose:
            print('....Computing monthly maximum (in all lat/lon) of std')
        max_std=np.amax(fieldstd.values, axis=(1,2),  keepdims=False)
        max_fieldstd = np.repeat(max_std[:,np.newaxis], np.shape(fieldstd.values)[1], axis=-1)
        max_fieldstd = np.repeat(max_fieldstd[:,:,np.newaxis], np.shape(fieldstd.values)[2], axis=-1)
    elif (len(fieldstd.dims) == 4) and (fieldstd.dims == (timename, levname, 'lat', 'lon')):
        if very_verbose:
            print('....Computing monthly maximum (in all lat/lon) of std by level')
        max_std = np.amax(fieldstd.values, axis=(2,3), keepdims=False)
        max_fieldstd = np.repeat(max_std[:,:,np.newaxis], np.shape(fieldstd.values)[2], axis=-1)
        max_fieldstd = np.repeat(max_fieldstd[:,:,:,np.newaxis], np.shape(fieldstd.values)[3], axis=-1)
    else:
        raise InputError('Test not implemented on this variable')   
    print('maxstd:')
    print(max_std)

    # create arrays with same dimensions as high frequency repeating values for each month
    if very_verbose:
        print('....Creating array of std at high resolution from monthly climatological files')

    # Read start month from startdate and calculate number of days of all forecast period (forecast_monhts+forecast_moredays)
    month_days=[]
    startdate = dt.datetime.strptime(lab_std+'01', '%Y%m%d')
    
    print(startdate)   
       
     
    for m in range(0,forecast_months):
        new_month = startdate + relativedelta(months=+m)
        month_days+=[monthrange(int(new_month.year),int(new_month.month))[1]]
       

    # add last 3 days
    month_days+=[forecast_moredays]
        
    var_freq=int(fullfield.dims[timename]/sum(month_days)) # obs per day (length of field/number of days)
    #print(var_freq)
    # now create new mean/std that mach field size by repeating monthly values
    fieldstd_tmp = np.empty_like(field)
    fieldmean_tmp = np.empty_like(field)
    # fill forecast months 
    start = 0
    
    for i in range(0,forecast_months):    
        end   = start + month_days[i]*var_freq
        print(start)
        print(end)
        if (len(field.dims) == 3):
            #fieldmean_tmp[start:end,:,:] = fieldmean.values[i,:,:]
            fieldstd_tmp[start:end,:,:]  = fieldstd.values[i,:,:] # single point monthly std
            #fieldstd_tmp[start:end,:,:]  = max_fieldstd[i,:,:]      # global monthly std
        elif (len(field.dims) == 4):
            #fieldmean_tmp[start:end,:,:,:] = fieldmean.values[i,:,:,:]
            fieldstd_tmp[start:end,:,:,:]  = fieldstd.values[i,:,:,:] # single point monthly std
            #fieldstd_tmp[start:end,:,:,:]  = max_fieldstd[i,:,:,:]      # global monthly std
        start+=month_days[i]*var_freq
        
      
 
    # fill last days  
    if (len(field.dims) == 3): 
        #fieldmean_tmp[start:fieldstd_tmp.shape[0],:,:]=fieldmean.values[forecast_months-1,:,:]
        fieldstd_tmp[start:fieldstd_tmp.shape[0],:,:]=fieldstd.values[forecast_months-1,:,:]
        #fieldstd_tmp[start:fieldstd_tmp.shape[0],:,:]=max_fieldstd[forecast_months-1,:,:]
    elif (len(field.dims) == 4):
        #fieldmean_tmp[start:fieldstd_tmp.shape[0],:,:,:]=fieldmean.values[forecast_months-1,:,:,:]
        fieldstd_tmp[start:fieldstd_tmp.shape[0],:,:,:]=fieldstd.values[forecast_months-1,:,:,:]
        #fieldstd_tmp[start:fieldstd_tmp.shape[0],:,:,:]=max_fieldstd[forecast_months-1,:,:,:]
   
    fieldmean_tmp = fieldmean.values
    

    # 2REMOVE
    # if very_verbose and (len(field.dims) == 4):
        # print('\n\n[INFO] Confirm std values: should be the same within a month, variyng on levels, the same for all points (max=min for lat/lon slices')
        # print('Time variation')
        # print(fieldstd_tmp[:,0,0,0])
        # print('Level variation')
        # print(fieldstd_tmp[0,:,0,0])
        # print('Month 1 lev 0 Max=Min in lat/lon slice')
        # print(str(np.min(fieldstd_tmp[0,0,:,:]))+'='+str(np.max(fieldstd_tmp[0,0,:,:])))
        # print('Month 1 lev 1 Max=Min in lat/lon slice')
        # print(str(np.min(fieldstd_tmp[0,1,:,:]))+'='+str(np.max(fieldstd_tmp[0,1,:,:])))
        # print('\n\n')

    # check reconstructed mean/std size
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
            if verbose or very_verbose:
                
                if max_ge_limit.any():
                    pos = np.where(max_ge_limit==True)
                    npoints = len(pos[0])
                    tot_points+=npoints
                    [table1, header]=make_clim_error_table(fullfield, field.dims,
                        field.values,
                        [ fieldmax.values, fieldmin.values, fieldmaxlimit.values, fieldmean.values, fieldstd.values],
                        npoints, pos, check_type='val>limit', std_mult=std_mult, verbose=verbose)
                    print('table--------')
                
                if min_le_limit.any():
                    pos=np.where(min_le_limit==True)
                    npoints=len(pos[0])
                    tot_points+=npoints
                    [table2,header]=make_clim_error_table(fullfield, field.dims,
                        field.values, 
                        [ fieldmax.values, fieldmin.values, fieldminlimit.values, fieldmean.values, fieldstd.values], 
                        npoints, pos, check_type='val<limit', std_mult=std_mult, verbose=verbose)

             
                else:
                    print('555555')

                if max_ge_cmax.any():
                    pos=np.where(max_ge_cmax==True)
                    npoints=len(pos[0])
                    tot_points+=npoints
                    [table3,header]=make_clim_error_table(fullfield, field.dims,
                        field.values, 
                        [ fieldmax.values, fieldmin.values], 
                        npoints, pos, check_type='val>max', std_mult=std_mult, verbose=verbose)
                 #   raise_error=True
                else:
                    print('gecmax')

                if min_le_cmin.any():
                    pos=np.where(min_le_cmin==True)
                    npoints=len(pos[0])
                    tot_points+=npoints
                    [table4, header]=make_clim_error_table(fullfield, field.dims,
                        field.values, 
                        [ fieldmax.values, fieldmin.values], 
                        npoints, pos, check_type='val<min', std_mult=std_mult, verbose=verbose)
                  #  raise_error=True
                else:
                    print('lecmin')
                print('raiiiiiiiiiiiiiii')
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

                    # raise warning/error
                    if warning is True:
                        war_message='[FIELDWARNING] >> Field '+shortname+' ('+varname+') '+' exceeding climatological ranges on '+str(tot_points)+' points. For a complete list, see the table in error log.'
                        print(war_message)
                    else:
                        raise FieldError('Field exceeding climatological ranges on '+str(tot_points)+' points. For a complete list, see the table in error log.')
        else:
            if verbose or very_verbose:
                print('[INFO] Climatological range tests passed')
        
    except FieldError as e:
        exc_list+=print_error(error_message=e, error_list=exc_list, loc1=[shortname, varname])
    
    return(exc_list, table, header)
