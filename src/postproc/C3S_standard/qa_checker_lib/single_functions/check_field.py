def check_field(field, filling_value, constant_limit, check_min, min_limit, check_max, max_limit, check_tsd, tsd_limit, verbose=False, very_verbose=False):
    from check_minmax import check_minmax
    from check_2d_field import check_2d_field
    from check_tsd_34dfield import check_tsd_34dfield
    from sel_field_slice import sel_field_slice
    from print_error import print_error

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
