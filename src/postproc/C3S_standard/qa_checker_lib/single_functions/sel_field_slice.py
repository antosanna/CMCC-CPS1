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
