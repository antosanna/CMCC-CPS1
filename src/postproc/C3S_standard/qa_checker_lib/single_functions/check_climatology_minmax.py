def check_climatology_minmax(field, fieldmax, fieldmin, logdir, verbose=False, very_verbose=False, warning=False):
    import numpy as np
    import dask.array as da
    from print_error import print_error
    from make_clim_error_table import make_clim_error_table
    """
    Check if field values are within min/max climatological values
    As check_climatological_ranges() but only for min/max
    """
    exc_list=[]

    print("inside function check_climatology_minmax")
    # check dimensioni compatibili tra field=fieldmean=fieldstd
    if field.dims != fieldmax.dims or field.dims != fieldmin.dims:
        raise InputError('Field, min and max fields must have the same dimensions')
    print("field dims are ", field.dims)
    # flag for raising error if needed
    raise_error=False

    # initialize table variables
    table1=[]; table2=[]
    header=[]; table=[]
    tot_points=0
    
    try:
        #ANTO&MARI modif
        threshold=np.full_like(field.values,0.005)
        #threshold_neg=np.full_like(field.values,-0.02)
        
        # in a positive word, this works! 
        #min_le_cmin=np.less((field.values-fieldmin.values)/fieldmin.values,threshold_neg,where=True)
  
        #reversed order in the difference to avoid absolute value (requiring too much memory)
        min_le_cmin=np.greater((fieldmin.values-field.values)/np.abs(fieldmin.values),threshold,where=True)   #WORKING!!!
        
        max_ge_cmax=np.greater((field.values-fieldmax.values)/fieldmax.values,threshold, where=True)
        
        """
        max_ge_cmax=np.greater(field,fieldmax, where=True)
        min_le_cmin=np.less(field,fieldmin, where=True)
        """
        if max_ge_cmax.any() or min_le_cmin.any():
            if max_ge_cmax.any():
                print("inside if cmax")
                pos=np.where(max_ge_cmax==True)
                print(type(pos))
                npoints=len(pos[0])
                tot_points+=npoints
                print("nmb of points over max ", tot_points)  
                [table1, header]=make_clim_error_table(field, field.dims,
                    field.values, 
                    [ fieldmax.values, fieldmin.values ], 
                    npoints, pos, check_type='val>max',std_mult=None,verbose=True)
                raise_error=True

            if min_le_cmin.any():
                print("inside if cmin") 
                pos=np.where(min_le_cmin==True)
                npoints=len(pos[0])
                tot_points+=npoints
                print(pos)
                print("before printing error table")
                [table2, header]=make_clim_error_table(field, field.dims,
                    field.values, 
                    [ fieldmax.values, fieldmin.values ], 
                    npoints, pos, check_type='val<min',std_mult=None,verbose=True)
                raise_error=True

            if raise_error:
                # Merge all error lists to create a single table
                for fulllist in [table1, table2]:
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
                print('[INFO] Climatological min/max range not exceeded')

    except FieldError as e:
        exc_list+=print_error(error_message=e, error_list=exc_list, loc1=[shortname, varname])
    
    return(exc_list, table, header)
