import numpy as np
import warnings
from var_tools import sel_field_slice
from general_tools import print_error

def check_minmax(field, checktype, limit, levname=None, verbose=False, very_verbose=False, warning=True):
    """
    Check if minimum/maximum value is lower/higher than given limit.
    Inputs: 
        field: variable to check
        checktype: minimum or maximum
        limit: a number with the limit value for the check. If levname is defined, then is must be a vector of limit values for each level of field which length must coincide with the field level/depth dimension
        levname: if indicated, name of dimension to be checked on which limit values are given
        verbose: True/False 
        very_verbose: True/False 
        warning: print a warning to the screen instead of raising an error
    """
    varname = field.long_name
    shortname = field.name
    if levname is None:
        # Loof for any values exceeding limit 
        if checktype in ['minimum','Minimum']:
            if np.min(field.data) < limit:
                # these find only val/pos of 1 minimum point
                pos = np.transpose(np.nonzero(field.data < limit))
                val = field.data[np.nonzero(field.data < limit)]
                abs_val = np.min(val)     
                if verbose or very_verbose:
                    print(checktype.capitalize(),'check failed on',len(list(pos)),'points among which the ', checktype,' value is:',abs_val,' and limit is:'+str(limit)+'.\nAll value(s):',val,'\nPosition(s):', list(pos),'\n')
                if warning is True:
                    war_message=' [FIELDWARNING]  >> Field '+shortname+' ('+varname+') '+checktype+' lower than limit '+str(limit)+' on '+str(len(list(pos)))+' points among which the '+checktype+' value is: '+str(abs_val)+'\n'
                    print(war_message)
                else:
                    raise FieldError('Field '+checktype+' lower than limit '+str(limit)+' on '+str(len(list(pos)))+' points.')
        elif checktype in ['maximum','Maximum']:
            if np.max(field.data) > limit:
                pos = np.transpose(np.nonzero(field.data > limit))
                val = field.data[np.nonzero(field.data > limit)]
                abs_val = np.max(val)
                if verbose or very_verbose:
                    print(checktype.capitalize(),'check failed on',len(list(pos)),'points among which the ',checktype,' value is:',abs_val,' and limit is:'+str(limit)+'.\nAll value(s):',val,'\nPosition(s):', list(pos),'\n')
                if warning is True:
                    war_message=' [FIELDWARNING]  >> Field '+shortname+' ('+varname+') '+checktype+' higher than limit '+str(limit)+' on '+str(len(list(pos)))+' points among which the '+ checktype+' value is: '+str(abs_val)+'\n'
                    print(war_message)
                else:
                    raise FieldError('Field '+checktype+' higher than limit '+str(limit)+' on '+str(len(list(pos)))+' points.')
    else:
        # Loof for any values exceeding limit by level
        if len(field.coords[levname]) != len(limit):
            raise InputError('Lenght of limit vector must be equal to number of levels of variable in check_minmax() function')
        error_list=[]
        for p in range(0, len(field.coords[levname])):
            if very_verbose:
                print('....Checking level:',levname,'[',p,'] with limit', str(limit[p]))
            
            if levname=='plev':
                fieldbylev = field.isel(plev=p)
            elif levname=='depth':
                fieldbylev = field.isel(depth=p)
            
            if checktype in ['minimum','Minimum']:
                if np.min(fieldbylev.data) < limit[p]:
                    val = np.min(fieldbylev.data)
                    pos = np.transpose(np.nonzero(fieldbylev.data < limit[p]))
                    val = fieldbylev.data[np.nonzero(fieldbylev.data < limit[p])]
                    if verbose or very_verbose:
                        print(checktype.capitalize(),'check on lev',p,'failed on',len(list(pos)),'points. Limit(',limit[p],'), Value(s):',val)
                    error_list.append(p)
            if checktype in ['maximum','Maximum']:
                if np.max(fieldbylev.data) > limit[p]:
                    val = np.max(fieldbylev.data)
                    pos = np.transpose(np.nonzero(fieldbylev.data > limit[p]))
                    val = fieldbylev.data[np.nonzero(fieldbylev.data > limit[p])]
                    if verbose or very_verbose:
                        print(checktype.capitalize(),'check on lev',p,'failed on',len(list(pos)),'points. Limit(',limit[p],'),(Value(s):',val)
                    error_list.append(p)
        if error_list:
            error_list_string=','.join(map(str, error_list))
            if warning is True:
                war_message=' [FIELDWARNING]  >> Field '+shortname+' ('+varname+') '+checktype,' exceeding in lev(s): ['+error_list_string+']'
                warnings.warn(war_message)
            else:
                raise FieldError('Field '+shortname+'('+varname+') '+checktype +' exceeding limit in lev(s): ['+error_list_string+']')

def check_2d_field(field, filling_value, constant_limit):
    """
    Check if all values in a 2D field are constant, infinite, nan, filling value or zero
    """
    if len(field.dims) > 2 :
        raise FieldError('Field has more than 2 dimensions! Cannot apply check_2d_field()')
    
    difs = np.max(field) - np.min(field)
    if np.all(np.isinf(field)) or np.all(np.isneginf(field)):
        raise FieldError('All field = Inf')
    if np.all(np.isnan(field)):
        raise FieldError('All field = nan')
    if not np.any(field):
        raise FieldError('All field = 0')
    if np.all(field==filling_value):
        raise FieldError('All field = filling')
    if not np.isfinite(field).all:
        raise FieldError('All field = not finite')
    if (difs < constant_limit):
        raise FieldError('All field = constant')
def check_temp_spike(lab_std, lab_mem, spike_error_list, field1, field2=None, field3=None, max_limit1=313, delta_limit1=30, min_limit2=5, delta_limit2=60,  max_limit3=0, verbose=False, very_verbose=False):
    """
    Performs a series of tests designed to identify anomalous temp spikes. 
    WARNING: This function works only on 2D data shaped as [time, gridpoint]
    Arguments:
        field1=TREFHT (necessary, the filter will be T>limit | dT>limit)
        field2=QREFHT (optional, the filter will be T>limit | dT>limit & dQ>limit)
        field3=ICEFRAC (optional, will find how many points had also an ice faction>limit)
    Returns:
        spike list, spikes on ice list
    Raises:
        Error when spike on ice is found
    """
    log_list = []
    point_list_ice = []

    # DMO shape
    if (len(field1.dims)) == 2 and (field1.dims == (timename,'ncol')):

        data1=field1.data
        if field2 is not None:
            data2=field2.data
        if field3 is not None:
            data3=field3.data
    # C3S shape
    elif (len(field1.dims)) == 3 and (field1.dims == (timename,'lat','lon')):
        ndims=field1.data.shape
        newdims=(ndims[0], ndims[1]*ndims[2])
        if very_verbose:
            print('Warning: Reshaping arrays',ndims,'to',newdims)
        
        data1=field1.data.reshape(newdims)
        if field2 is not None:
            data2=field2.data.reshape(newdims)
        if field3 is not None:
            data3=field3.data.reshape(newdims)
            if np.any(np.isnan(data3)) and very_verbose:
                print('Warning: There are NaN values in icefrac that will not be checked')
    else:
        raise InputError('Unsupported dimensions in spike check')
        
    # compute delta T/Q
    delta1 = np.zeros_like(data1)
    delta1[0:-2,:] = data1[1:-1, :] - data1[0:-2, :]
    delta1[-1,:] = data1[-2, :] - data1[-1, :]
    
    if field2 is not None:
        delta2 = np.zeros_like(data1) 
        delta2[0:-2,:] = data2[1:-1, :] - data2[0:-2, :]
        delta2[-1,:] = data2[-2, :] - data2[-1, :]

    # find spikes
        delta2[0:-2] = data2[1:-1, :] - data2[0:-2, :]
        delta2[0:-2] = data2[1:-1, :] - data2[0:-2, :]
    # condition 1 #refT>50
    spk_pos_c1 = np.transpose(np.nonzero((data1 > max_limit1))) #refT>50
    c1set = set([tuple(x) for x in spk_pos_c1]) 
    # condition 2 #deltaT>30
    spk_pos_c2 = np.transpose(np.nonzero(abs(delta1) > delta_limit1)) #deltaT > 30deg
    c2set = set([tuple(x) for x in spk_pos_c2])
    # condition 3 #deltaQ>60
    if field2 is not None:
        spk_pos_c3 = np.transpose(np.nonzero(abs(data2) > delta_limit2)) #deltaQ > 50%    
        c3set = set([tuple(x) for x in spk_pos_c3])
    # condition 4 #icefrac>0
    if field3 is not None:
        icefrac_pos= np.transpose(np.nonzero(data3 > max_limit3)) #icefrac > 0 
        iceset   = set([tuple(x) for x in icefrac_pos])
   
    # combine filters
    if field2 is None:
        spk_pos = np.array([x for x in (c1set | c2set)])
        if verbose or very_verbose:
            print('[INFO] N. Points found (('+varname+' value>'+str(max_limit1)+' | '+varname+' delta>'+str(delta_limit1)+' ): '+str(len(list(spk_pos))))
        if very_verbose:
            print('Locations (c1|c2):',spk_pos)

        if field3 is None:
            log_list=str(lab_std)+";"+str(lab_mem)+";"+str(len(list(spk_pos)))+";"++"\n"
            point_list=[ str(lab_std)+";"+str(lab_mem)+";"+
                     str(spk_pos[i,0])+";"+str(spk_pos[i,1])+";"+
                     str(data1[spk_pos[i,0],spk_pos[i,1]])+";"+
                     str(delta1[spk_pos[i,0],spk_pos[i,1]])+";"
                     "\n" for i in range(len(spk_pos[:,1])) ]
        else:
            c1setice = set([tuple(x) for x in spk_pos_c1]).intersection(iceset)
            c2setice = set([tuple(x) for x in spk_pos_c2]).intersection(iceset)
            spk_pos_ice = np.array([x for x in (c1setice | c2setice)])
            if verbose or very_verbose:
                print('[INFO] N. Points found (('+varname+' value>'+str(max_limit1)+' | '+varname+' delta>'+str(delta_limit1)+') &icefrac>'+str(max_limit3)+'): '+str(len(list(spk_pos_ice))))
            if very_verbose:
                print('Locations (c1|c2&icefrac):',spk_pos_ice)
            # write log with stadate, member, time step, grid point, Temp value, deltaT value, Qref value, deltaQ value, icefrac
            point_list=[ str(lab_std)+";"+str(lab_mem)+";"+
                     str(spk_pos[i,0])+";"+str(spk_pos[i,1])+";"+
                     str(data1[spk_pos[i,0],spk_pos[i,1]])+";"+
                     str(delta1[spk_pos[i,0],spk_pos[i,1]])+";"+
                     str(data3[spk_pos[i,0],spk_pos[i,1]])+
                     "\n" for i in range(len(spk_pos[:,1])) ]

            if len(list(spk_pos_ice)) > 0:
                point_list_ice=[ str(lab_std)+";"+str(lab_mem)+";"+
                     str(spk_pos_ice[i,0])+";"+str(spk_pos_ice[i,1])+";"+
                     str(data1[spk_pos_ice[i,0],spk_pos_ice[i,1]])+";"+
                     str(delta1[spk_pos_ice[i,0],spk_pos_ice[i,1]])+";"+
                     str(data3[spk_pos_ice[i,0],spk_pos_ice[i,1]])+
                     "\n" for i in range(len(spk_pos_ice[:,1])) ]

            log_list=str(lab_std)+";"+str(lab_mem)+";"+str(len(list(spk_pos)))+";"+str(len(list(spk_pos_ice)))+";"+"\n"   

    else: #field2 is not None
        spk_pos = np.array([x for x in (c1set | c2set) & c3set])
        if verbose or very_verbose:
            print('N. Points found (('+varname+' value>'+str(max_limit1)+' | '+varname+' delta>'+str(delta_limit1)+') & Qref delta>'+str(max_delta2)+'): '+str(len(list(spk_pos))))
        if very_verbose:
            print('Locations (c1|c2&c3):',spk_pos)
        if field3 is None:
            log_list=str(lab_std)+";"+str(lab_mem)+";"+str(len(list(spk_pos)))+";"++"\n"
            point_list=[ str(lab_std)+";"+str(lab_mem)+";"+
                     str(spk_pos[i,0])+";"+str(spk_pos[i,1])+";"+
                     str(data1[spk_pos[i,0],spk_pos[i,1]])+";"+
                     str(delta1[spk_pos[i,0],spk_pos[i,1]])+";"+
                     str(data2[spk_pos[i,0],spk_pos[i,1]])+";"+
                     str(delta2[spk_pos[i,0],spk_pos[i,1]])+";"+
                     "\n" for i in range(len(spk_pos[:,1])) ]
        else:
            c1setice = set([tuple(x) for x in spk_pos_c1]).intersection(iceset) 
            c2setice = set([tuple(x) for x in spk_pos_c2]).intersection(iceset)
            c3setice = set([tuple(x) for x in spk_pos_c3]).intersection(iceset)
            spk_pos_ice = np.array([x for x in (c1setice | c2setice) & c3setice])
            if verbose or very_verbose:
                print('N. Points found (('+varname+' value>'+str(max_limit1)+' | '+varname+' delta>'+str(delta_limit1)+') & Qref delta>'+str(delta_limit2)+' &icefrac'+str(max_limit3)+'): '+str(len(list(spk_pos_ice))))
            if very_verbose:
                print('Locations (c1|c2&c3&icefrac):',spk_pos_ice)
            log_list=str(lab_std)+";"+str(lab_mem)+";"+str(len(list(spk_pos)))+";"+str(len(list(spk_pos_ice)))+";"+"\n"   
            point_list=[ str(lab_std)+";"+str(lab_mem)+";"+
                     str(spk_pos[i,0])+";"+str(spk_pos[i,1])+";"+
                     str(data1[spk_pos[i,0],spk_pos[i,1]])+";"+
                     str(delta1[spk_pos[i,0],spk_pos[i,1]])+";"+
                     str(data2[spk_pos[i,0],spk_pos[i,1]])+";"+
                     str(delta2[spk_pos[i,0],spk_pos[i,1]])+";"+
                     str(data3[spk_pos[i,0],spk_pos[i,1]])+
                     "\n" for i in range(len(spk_pos[:,1])) ]
            if len(list(spk_pos_ice)) > 0:
                point_list_ice=[ str(lab_std)+";"+str(lab_mem)+";"+
                     str(spk_pos_ice[i,0])+";"+str(spk_pos_ice[i,1])+";"+
                     str(data1[spk_pos_ice[i,0],spk_pos_ice[i,1]])+";"+
                     str(delta1[spk_pos_ice[i,0],spk_pos_ice[i,1]])+";"+
                     str(data2[spk_pos_ice[i,0],spk_pos_ice[i,1]])+";"+
                     str(delta2[spk_pos_ice[i,0],spk_pos_ice[i,1]])+";"+
                     str(data3[spk_pos_ice[i,0],spk_pos_ice[i,1]])+
                     "\n" for i in range(len(spk_pos_ice[:,1])) ]

    # if list of spikes in ice is full, then raise and error, finally write the list of all spikes, spikes on ice and error list for log
    try:
        if field3 is not None and len(list(spk_pos_ice)) > 0:
            raise FieldError('Spike identified on ice')
    except FieldError as e:
        spike_error_list=print_error(error_message=e, error_list=spike_error_list, loc1=[shortname, varname])
    finally:    
        return log_list, point_list_ice, spike_error_list
def check_tsd_34dfield(field, tsd_limit, timname, levname=None, verbose=False, very_verbose=False):
    
    """
    Check if all points in field are stationary (std = 0 along time)
    """
    # TODO improve if with DMO dimension types (i.e. timname,'ncols'; timname,levname,'ncols')
    if (len(field.dims) == 3) and (field.dims == (timname, 'lat', 'lon')):
        field_stationarity = np.std(field.data, axis = 0) == tsd_limit
        if np.all(field_stationarity):
            raise FieldError('Field is stationary')

    elif (len(field.dims) == 4) and (field.dims == (timname, levname, 'lat', 'lon')):
        field_stationarity =  np.std(field.data, axis = 0) == tsd_limit 
        all_field_stationarity =  np.all(field_stationarity, axis=(1,2))
        if (np.any(field_stationarity)):
            lev_indexes = np.argwhere(all_field_stationarity==True)
            lev_list = list(lev_indexes[:,0])
            raise FieldError('Field is stationary')
            return(lev_list)

    elif (len(field.dims) == 4) and (field.dims == ('realization', timname, 'lat', 'lon')):
        field_swapped =  np.swapaxes(field.data, 0, 1) 
        field_stationarity =  np.all(np.std(field_swapped, axis = 0) == tsd_limit, axis=(1,2))
        if np.any(field_stationarity):
            ens_indexes = np.argwhere(field_stationarity==True)
            ens_list = list(ens_indexes[:,0])
            raise FieldError('Field is stationary')
            return(ens_list)

    else:
        raise InputError('[INPUTERROR] Field has unsupported dimensions')
def check_field(field, filling_value, constant_limit, check_min, min_limit, check_max, max_limit, check_tsd, tsd_limit, verbose=False, very_verbose=False):

#def check_field(field, filling_value, constant_limit, check_min, min_limit, check_max, max_limit, check_tsd, tsd_limit, verbose=False, very_verbose=False):
    """
    Check if all values in C3S field are constant, infinite, nan, filling value or zero
    """

    exc_list=[] 

    # check min
    if check_min:
        try:
            if len(min_limit) > 1:
                if verbose or very_verbose:
                    print('[INFO] Checking minimum value of', varname, 'by level')
                check_minmax(field, 'minimum', min_limit, levname=levname, verbose=verbose, very_verbose=very_verbose)
            else:
                if verbose or very_verbose:
                    print('[INFO] Checking minimum value of', varname)
                check_minmax(field, 'minimum', min_limit, levname=None, verbose=verbose, very_verbose=very_verbose)

        except FieldError as e:
            exc_list+=print_error(error_message=e, error_list=exc_list, loc1=[shortname, varname])
    
    # check max
    if check_max:
        try:
            if len(max_limit) > 1:
                if verbose or very_verbose:
                    print('[INFO] Checking maximum value of',varname, 'by level')
                check_minmax(field, 'maximum', max_limit, levname=levname, verbose=verbose, very_verbose=very_verbose)
            else:
                if verbose or very_verbose:
                    print('[INFO] Checking maximum value of',varname)
                check_minmax(field, 'maximum', max_limit, levname=None, verbose=verbose, very_verbose=very_verbose)
        except FieldError as e:
            exc_list+=print_error(error_message=e, error_list=exc_list, loc1=[shortname, varname])

    # check field separating ensemble members, pressure levels and time steps
    if (len(field.dims) < 2):
        if very_verbose:
            print('...Skypping 1D field', varname)
 
    elif (len(field.dims) == 2) and (field.dims == ('lat','lon')):
        # check empty/constant slab
        try:
            if verbose or very_verbose:
                print('[INFO] Checking consistency of 2D-slices of',varname)
            check_2d_field(field, filling_value, constant_limit)
        except FieldError as e:
            exc_list+=print_error(error_message=e, error_list=exc_list, loc1=[shortname, varname])

    elif (len(field.dims) == 2) and (field.dims == (timename,'ncol')):
        # check time sd
        if check_tsd:
            if verbose or very_verbose:
                print('[INFO] Checking time standard deviation of',varname)
            try:
                list = check_tsd_34dfield(field, tsd_limit, timename)
            except FieldError as e:
                exc_list+=print_error(error_message=e, error_list=exc_list, loc1=[shortname, varname])

    elif (len(field.dims) == 3) and (field.dims == (timename,'lat','lon')):
        slicetype='time'
        # check time sd
        if check_tsd:
            if verbose or very_verbose:
                print('[INFO] Checking time standard deviation of',varname)
            try:
                list = check_tsd_34dfield(field, tsd_limit, timename)
            except FieldError as e:
                exc_list+=print_error(error_message=e, error_list=exc_list, loc1=[shortname, varname])

        # check empty/constant slab
        if verbose or very_verbose:
            print('[INFO] Checking consistency of 2D-slices of',varname)
        for l in range(0, len(field.coords[timename])):
            field2d = sel_field_slice(field, slicetype=slicetype, index1=l, index2=None)
            try:
                if very_verbose:
                    print('....Checking ',varname,' ',timename, ': ',l)
                check_2d_field(field2d, filling_value, constant_limit)
            except FieldError as e:
                exc_list+=print_error(error_message=e, error_list=exc_list, loc1=[shortname, varname], loc2=[timename, l])

    elif (len(field.dims) == 4) and (field.dims == (timename,levname,'lat','lon')):
        slicetype='timelev'
        # check time sd
        if check_tsd:
            if verbose or very_verbose:
                print('[INFO] Checking time standard deviation of',varname)
            try:   
                list = check_tsd_34dfield(field, tsd_limit, timename, levname)
            except FieldError as e:
                exc_list+=print_error(error_message=e, error_list=exc_list, loc1=[shortname, varname], loc2=[timename, l], loc3=[levname, list])

        # check empty/constant slab
        if verbose or very_verbose:
            print('[INFO] Checking consistency of 2D-slices of',varname)
        for l in range(0, len(field.coords[timename])):
            for p in range(0, len(field.coords[levname])):
                field2d = sel_field_slice(field, slicetype=slicetype, index1=l, index2=p)
                try:
                    if very_verbose:
                        print('....Checking ',varname,' ',timename,': ',l,levname,': ',p)
                    check_2d_field(field2d, filling_value, constant_limit)
                except FieldError as e:
                    exc_list+=print_error(error_message=e, error_list=exc_list, loc1=[shortname, varname], loc2=[timename, l], loc3=[levname, p])

    elif (len(field.dims) == 4) and (field.dims == ('realization',timename,'lat','lon')):
        slicetype='timereal'
        # check time sd
        if check_tsd:
            if verbose or very_verbose:
                print('[INFO] Checking time standard deviation of',varname)
            try:  
                list = check_tsd_34dfield(field, tsd_limit, timename)
            except FieldError as e:
                exc_list+=print_error(error_message=e, error_list=exc_list, loc1=[shortname, varname], loc2=['realization', list])

        # check empty/constant slab
        if verbose or very_verbose:
            print('[INFO] Checking consistency of 2D-slices of',varname)
        for r in range(0,len(field.coords['realization'])):
            for l in range(0,len(field.coords[timename])):
                field2d = sel_field_slice(field, slicetype=slicetype, index1=l, index2=p)
                try:
                    if very_verbose:
                        print('....Checking ',varname,' realization: ',r,', ',timename,': ',l)
                    check_2d_field(field2d, filling_value, constant_limit)
                except FieldError as e:
                    exc_list+=print_error(error_message=e, error_list=exc_list, loc1=[shortname, varname], loc2=['realization', list], loc3=[timename,l])

    elif (len(field.dims) == 5) and (field.dims == ('realization',timename,levname,'lat','lon')):
        slicetype='timelevreal'
        for r in range(0, len(field.coords['realization'])):
            # check time sd
            if check_tsd:
                if verbose or very_verbose:
                    print('[INFO] Checking time standard deviation of',varname)
                try:  
                    list = check_tsd_34dfield(field.isel(realization=r), tsd_limit, timename, levname)
                except FieldError as e:
                    exc_list+=print_error(error_message=e, error_list=exc_list, loc1=[shortname, varname], loc2=['realization', r], loc3=[levname,list])
    
            # check empty/constant slab
            if verbose or very_verbose:
                print('[INFO] Checking consistency of 2D-slices of',varname)
            for l in range(0, len(field.coords[timename])):
                for p in range(0, len(field.coords[levname])):
                    field2d = sel_field_slice(field, slicetype=slicetype, index1=l, index2=r, index3=p)
                    try:
                        if very_verbose:
                            print('....Checking realization: ',r,', ',timename,': ',l,', ',levname,': ',p)
                        check_2d_field(field2d, filling_value, constant_limit)
                    except FieldError as e:
                        exc_list+=print_error(error_message=e, error_list=exc_list, loc1=[shortname, varname], loc2=['realization', r], loc3=[timename,l], loc4=[levname,p])
    
    else: 
        raise InputError('[INPUTERROR] Field ',varname, ' has unsupported dimensions')

    return exc_list

def check_consistency_all_field_not_encoded(field, verbose, very_verbose):
    """
    Check if any value in field is invalid
    Note that field must be not encoded (i.e, fill value is a number and not nan) in order to be able to differentiate it from real nan
    """
    exc_list=[]
    
    if verbose or very_verbose:
        print('[INFO] Checking whole field consistency of', varname)

    # check if there is any not finite(nan or inf) value
    try:
        if np.any(~(np.isfinite(field))):
            pos = np.where(~(np.isfinite(field))==True)
            if verbose or very_verbose:  
                print('Consistency check failed on ',len(list(pos[0])),'points(s). Position(s):', list(pos))   
            raise FieldError('Invalid (nan or Inf) value on field')
    except FieldError as e:
        exc_list=print_error(error_message=e, error_list=exc_list, loc1=[shortname,varname])
        return(exc_list)
