def get_var_name(field):
    """ 
    Get var name.
    """
    try:
        fieldname = field.standard_name
        return (fieldname) 
    except AttributeError:
        fieldname = field.long_name
        return (fieldname) 
    except:
        raise InputError('[INPUTERROR] Unrecognized variable name')

def get_lev_name(field):
    """ 
    Get name of level variable (expected in the first or second dimension)
    """
    if field.dims[0] in ('plev','depth'):
        levname = field.dims[0]
    elif field.dims[1] in ('plev','depth'):
        levname = field.dims[1]
    else:
        raise InputError('Unrecognized level variable name. Coordinate plev or depth is expected on the first or second position of the variable.')
    return levname

def get_time_name(field):
    """ 
    Get name of time variable. Note that time is expected to be the first dimension.
    """
    timename = field.dims[0]
    if timename not in ('time','leadtime'):
        raise InputError('Unrecognized time variable name. Coordinate time or leadtime is expected on the first position of the variable.')
    return timename

def var_in_list(varname, varlist):
    """ 
    Returns True if var in varlist.
    """
    result=True if (varname in varlist) else False
    return(result)

def sel_field_slice(field, slicetype, index1, index2=None, index3=None):
    """ 
    Returns 2d slice (lat-lon) of a multidimensional field given the indexes to select
    slicetype depends on variable dimensions and can be time, timelev, timereal, timelevreal
    """

    if slicetype=='time':
        # slice in time
        if timename == 'leadtime':
            field2d = field.isel(leadtime=index1)
        elif timename == 'time':
            field2d = field.isel(time=index1)
    elif slicetype=='timelev':
        # slice in time and plev
        if timename == 'leadtime':
            if levname == 'plev':
                field2d = field.isel(leadtime=index1, plev=index2)
            elif levname == 'depth':
                field2d = field.isel(leadtime=index1, depth=index2)
        elif timename == 'time':
            if levname == 'plev':
                field2d = field.isel(time=index1, plev=index2)
            elif levname == 'depth':
                field2d = field.isel(time=index1, depth=index2)
    elif slicetype=='timereal':
        # slice in time and realization
        if timename=='leadtime':
            field2d = field.isel(realization=index2, leadtime=index1)
        elif timename=='time':
            field2d = field.isel(realization=index2, time=index1)
    elif slicesype=='timelevreal':
        # slice in time, realization and plev
        if timename == 'leadtime':
            if levname == 'plev':
                field2d = field.isel(realization=index2, leadtime=index1, plev=index3)
            elif levname == 'depth':
                field2d = field.isel(realization=index2, leadtime=index1, depth=index3)
        elif timename == 'time':
            if levname == 'plev':
                field2d = field.isel(realization=index2, time=index1, plev=index3)
            if levname == 'depth':
                field2d = field.isel(realization=index2, time=index1, depth=index3)
    else:
        raise ProgramError('Unrecognized slicetype')
    
    return(field2d)

