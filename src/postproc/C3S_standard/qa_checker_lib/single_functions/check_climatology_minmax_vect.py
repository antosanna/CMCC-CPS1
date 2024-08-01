def check_climatology_minmax_vect(field, fieldmax, fieldmin, field2, fieldmax2, fieldmin2, dict_coord,var_dims,logdir, verbose=False, very_verbose=False, warning=False):
    import numpy as np
    import dask.array as da
    from print_error import print_error
    from make_clim_error_table import make_clim_error_table
    """
    Check if field values are within min/max climatological values
    As check_climatological_ranges() but only for min/max
    """
    exc_list=[]

    ###CHECK on DIMENSION to be implemented with dask!!
 
    # flag for raising error if needed
    raise_error=False


    # initialize table variables
    table1=[]; table2=[]
    header=[]; table=[]
    tot_points=0
  
    try:
        #ANTO&MARI modif
        #threshold=np.full_like(field.values,0.005)
        threshold=da.full_like(field,0.005)
        vector=(da.power(field,2))+(da.power(field2,2))
        vectormax=(da.power(fieldmax,2))+(da.power(fieldmax2,2))
        vectormin=(da.power(fieldmin,2))+(da.power(fieldmin2,2))

        min_le_cmin_da=da.greater((vector-vectormin)/vectormin,threshold,where=True)   #WORKING!!!
        max_ge_cmax_da=da.greater((vector-vectormax)/vectormax,threshold, where=True)


        max_ge_cmax=np.array(max_ge_cmax_da)
        min_le_cmin=np.array(min_le_cmin_da)
        if max_ge_cmax.any() or min_le_cmin.any(): 
            if max_ge_cmax.any():
                print("inside if cmax")
                pos=np.where(max_ge_cmax==True)
                print(type(pos))
                npoints=len(pos[0])
                print(npoints)
                tot_points+=npoints
                print("nmb of points over max ", tot_points)

##TABLE to BE IMPLEMENTED
#                [table1, header]=make_clim_error_table(dict_coord,var_dims,
#                    np.array(vector),
#                    [ np.array(vectormax), np.array(vectormin) ],
#                    npoints, pos, check_type='val>max',std_mult=None,verbose=True)
                raise_error=True
            if min_le_cmin.any():
                print("inside if cmin")
                pos=np.where(min_le_cmin==True)
                npoints=len(pos[0])
                tot_points+=npoints
                print(npoints)
                print("before printing error table")

##TABLE to BE IMPLEMENTED
#                [table2, header]=make_clim_error_table(dict_coord, var_dims,
#                    np.array(vector),
#                    [ np.array(vectormax), np.array(vectormin) ],
#                    npoints, pos, check_type='val<min',std_mult=None,verbose=True)
                raise_error=True
                #raise_error=False
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

