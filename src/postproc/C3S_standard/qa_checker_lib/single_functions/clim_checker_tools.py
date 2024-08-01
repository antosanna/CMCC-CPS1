import numpy as np
import dask.array as da 
from general_tools import print_error
from tabulate import tabulate

def check_climatology_minmax(field, fieldmax, fieldmin, logdir, verbose=False, very_verbose=False, warning=False):
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
def check_climatology_minmax_vect(field, fieldmax, fieldmin, field2, fieldmax2, fieldmin2, dict_coord,var_dims,logdir, verbose=False, very_verbose=False, warning=False):
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


def check_climatological_ranges(fullfield, field, fieldmean, fieldstd, fieldmax, fieldmin, std_mult, verbose=False, very_verbose=False, warning=True):
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

def make_clim_error_table(fullfield, dims, value, limits, npoints, pos, check_type, std_mult=None, verbose=True):
    """
    Print log with info about climatological_range test for all error points found with one of the following functions:
    check_climatological_ranges(), check_climatological_ranges_monthly(), check_climatology_minmax()
    Inputs:
        fullfield: xarray object with value of all dimensions
        dims: array with name of dimensions
        value: field values
        limits: array with values of climatological max, min and optionally limit (mean+-xstd), mean, std
        npoints: number of error points
        pos: tuple with position of error points
        check_type: one of the following: 'max_ge_limit', 'max_ge_cmax', 'min_le_limit', min_le_cmin'
        std_mult: number of times the std has been multiplied for computing the limit
    Output:
        exc_list: list of errors found
        table: list of table values
        header: list with header strings
    """
    print("inside make_clim_error_table") 
    if verbose:
        if check_type == 'val>limit' :
            print('\nField > Clim limit (mean + '+str(std_mult)+' std) found in ', npoints,' points.')
        elif check_type == 'val<limit' :
            print('\nField < Clim limit (mean - '+str(std_mult)+' std) found in ', npoints,' points.')
        elif check_type == 'val>max' :
            print('\nField > Clim max found in ', npoints,' points.')
        elif check_type == 'val<min' :
            print('\nField < Clim min found in ', npoints,' points.')

    ndims=len(dims)
    npos=np.shape(pos)[1]

    fmax=limits[0]
    fmin=limits[1] 


    if len(limits) > 2:
        flimit=limits[2]
        fmean=limits[3]
        fstd=limits[4]
        print('=====')
        print(np.shape(fmean))
        print(np.shape(fmax))
        print(np.shape(fstd))
        print('pos:')
        print(pos)


    # create header (the same for all functions)
    header=['Point']
    header.extend(['Error'])
    for x in range(0,len(dims)):
        header.extend(['Pos['+str(x)+']'])
    for x in range(0,len(dims)):
        if dims[x] == 'plev':
            header.extend([dims[x]+ '(hPa)'])
        else:
            header.extend([dims[x]])
    header.extend(['value'])
    header.extend(['max'])
    header.extend(['min'])
    header.extend(['mean+/-'+str(std_mult)+'std'])
    header.extend(['mean'])
    header.extend(['std'])

    # fill table values (limit,mean,std columns are empty for check_climatology_minmax() )
    table_values = [ [ None for y in range( 5+len(limits) ) ]for x in range( npos ) ]

    for i in range(0,npos):
        #point index
        line_values=[str(i+1)]
        #test type
        line_values+=[check_type]
        #position values
        for x in range(0,len(dims)):
            line_values+=[str(pos[x][i])]
        #coord values
        for x in range(0,len(dims)):
            if dims[x] == 'plev':
                line_values+=[str(fullfield[dims[x]].values[pos[x][i]]/100)]
            else:
                line_values+=[str(fullfield[dims[x]].values[pos[x][i]])]
        #point value, limit, mean, std, max, min
        #string depends on variable dimensions

        if len(dims) == 4:
            line_values+=[str(value[pos[0][i],pos[1][i],pos[2][i],pos[3][i]])]
            line_values+=[str(fmax[pos[0][i],pos[1][i],pos[2][i],pos[3][i]])]
            line_values+=[str(fmin[pos[0][i],pos[1][i],pos[2][i],pos[3][i]])]
            if len(limits) > 2:
                line_values+=[str(flimit[pos[0][i],pos[1][i],pos[2][i],pos[3][i]])]
                line_values+=[str(fmean[pos[0][i],pos[1][i],pos[2][i],pos[3][i]])]
                line_values+=[str(fstd[pos[0][i],pos[1][i],pos[2][i],pos[3][i]])]

        if len(dims) == 3:
            line_values+=[str(value[pos[0][i],pos[1][i],pos[2][i]])]
            line_values+=[str(fmax[pos[0][i],pos[1][i],pos[2][i]])]
            line_values+=[str(fmin[pos[0][i],pos[1][i],pos[2][i]])]
            if len(limits) > 2:
                line_values+=[str(flimit[pos[0][i],pos[1][i],pos[2][i]])]
                line_values+=[str(fmean[pos[0][i],pos[1][i],pos[2][i]])]
                line_values+=[str(fstd[pos[0][i],pos[1][i],pos[2][i]])]

        if len(dims) == 2:
            line_values+=[str(value[pos[0][i],pos[1][i]])]
            line_values+=[str(fmax[pos[0][i],pos[1][i]])]
            line_values+=[str(fmin[pos[0][i],pos[1][i]])]
            if len(limits) > 2:
                line_values+=[str(flimit[pos[0][i],pos[1][i]])]
                line_values+=[str(fmean[pos[0][i],pos[1][i]])]
                line_values+=[str(ftsd[pos[0][i],pos[1][i]])]


        # add line to table
        table_values[i]=line_values

    if verbose:
        if len(table_values)>10:
            print('First 10 points:')
            print(tabulate(table_values[0:10], headers=header, tablefmt='fancy_grid', missingval='N/A',))
        else:
            print(tabulate(table_values, headers=header, tablefmt='fancy_grid', missingval='N/A',))

    return(table_values, header)
