
def check_climatological_ranges(fullfield, field, fieldmean, fieldstd, fieldmax, fieldmin, std_mult, verbose=False, very_verbose=False, warning=True):
    import numpy as np
    from print_error import print_error
    from make_clim_error_table import make_clim_error_table
    from tabulate import tabulate
    """
    Check if field values are within 3sd from climatological values or if values exceed climatological min/max values
    """
    exc_list=[]

    # check that dimensions are coherent between field, fieldmean, fieldstd
    if field.dims != fieldmean.dims or field.dims != fieldstd.dims or field.dims != fieldmax.dims or field.dims != fieldmin.dims:
        raise InputError('Field and all climatological fields max must have the same dimensions')

    # compute limits (mean +/- std*std_mult)
    fieldmaxlimit = fieldmean + fieldstd*std_mult
    fieldminlimit = fieldmean - fieldstd*std_mult

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
            if max_ge_limit.any():
                pos = np.where(max_ge_limit==True)
                npoints = len(pos[0])
                tot_points+=npoints

                [table1, header]=make_clim_error_table(fullfield, field.dims,
                    field.values, 
                    [ fieldmax.values, fieldmin.values, fieldmaxlimit.values, fieldmean.values, fieldstd.values], 
                    npoints, pos, check_type='val>limit', std_mult=std_mult, verbose=verbose)
                raise_error=True
            
            if min_le_limit.any():
                pos=np.where(min_le_limit==True)
                npoints=len(pos[0])
                tot_points+=npoints
            
                [table2, header]=make_clim_error_table(fullfield, field.dims,
                    field.values, 
                    [ fieldmax.values, fieldmin.values, fieldminlimit.values, fieldmean.values, fieldstd.values], 
                    npoints, pos, check_type='val<limit', std_mult=std_mult, verbose=verbose)
                raise_error=True

            if max_ge_cmax.any():
                pos=np.where(max_ge_cmax==True)
                npoints=len(pos[0])
                tot_points+=npoints

                [table3,header]=make_clim_error_table(fullfield, field.dims,
                    field.values, 
                    [ fieldmax.values, fieldmin.values], 
                    npoints, pos, check_type='val>max', std_mult=std_mult, verbose=verbose)
                raise_error=True

            if min_le_cmin.any():
                pos=np.where(min_le_cmin==True)
                npoints=len(pos[0])
                tot_points+=npoints

                [table4,header]=make_clim_error_table(fullfield, field.dims,
                    field.values, 
                    [ fieldmax.values, fieldmin.values], 
                    npoints, pos, check_type='val<min', std_mult=std_mult, verbose=verbose)
                raise_error=True
            
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
                    # print(tabulate(table, headers=header, tablefmt='fancy_grid', missingval='N/A',))

                else:
                    raise FieldError('Field exceeding climatological ranges on '+str(tot_points)+' points. For a complete list, see the table in error log.')
        else:
            if verbose or very_verbose:
                print('[INFO] Climatological range tests passed.')

    except FieldError as e:
        exc_list+=print_error(error_message=e, error_list=exc_list, loc1=[shortname, varname])
        # print(tabulate(table, headers=header, tablefmt='fancy_grid', missingval='N/A',))
    
    return(exc_list, table, header)
