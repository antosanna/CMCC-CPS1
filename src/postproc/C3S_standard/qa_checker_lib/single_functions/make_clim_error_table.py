from tabulate import tabulate
import numpy as np

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
