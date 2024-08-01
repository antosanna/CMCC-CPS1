def check_tsd_34dfield(field, tsd_limit, timname, levname=None, verbose=False, very_verbose=False):
    
    import numpy as np
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
