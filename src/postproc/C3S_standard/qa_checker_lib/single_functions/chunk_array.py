import dask.array as da
def chunk_array(dsv,chunksize=100):
    print("inside chunk_array")
    print("chunksize is ",chunksize)
    if ('plev' in dsv.dims) or ('depth' in dsv.dims):
    #check number of horizontal dims (from third index onward : time,lev,xxx)
        print("3d variables")
        horiz_dims=dsv.shape[2:]
        if len(horiz_dims) == 2 :
                           
           #lat lon case (C3S or DMO-FV)
           dsch = da.from_array(dsv.values, chunks=(chunksize,dsv.shape[1],horiz_dims[0],horiz_dims[1]))
        else:
           #ncol case (DMO-SE)
           dsch = da.from_array(dsv.values, chunks=(chunksize,dsv.shape[1],horiz_dims[0]))
    else:
        #spatial 2d variable
        horiz_dims=dsv.shape[1:]
        print("2d variables")
        if len(horiz_dims) == 2 :
           print("C3S type")
           #lat lon case (C3S or DMO-FV)
           #dsch = da.from_array(dsv.values, chunks(chunksize,horiz_dims[0],horiz_dims[1]))
           dsch = da.from_array(dsv.values, chunks=(chunksize,180,360))
        else:
           #ncol case (DMO-SE)
           dsch = da.from_array(dsv.values, chunks=(chunksize,horiz_dims[0]))
    return(dsch)
