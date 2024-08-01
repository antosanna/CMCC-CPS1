def check_temp_spike(lab_std, lab_mem, spike_error_list, field1, field2=None, field3=None, max_limit1=313, delta_limit1=30, min_limit2=5, delta_limit2=60,  max_limit3=0, verbose=False, very_verbose=False):
    import numpy as np
    from print_error import print_error
    """
    Performs a series of tests designed to identify anomalous temp spikes. 
    WARNING: This function works only on 2D data shaped as [time, gridpoint]
    Arguments:
        field1=TREFHT (necessary, the filter will be T>limit | dT>limit)
        field2=QREFHT (optional, the filter will be T>limit | dT>limit & dQ>limit)
        field3=ICEFRAC (optional, will find how many points had also an ice faction>limit)
    Returns:
        spike list, spikes on ice list
    Raises:
        Error when spike on ice is found
    """
    log_list = []
    point_list_ice = []

    # DMO shape
    if (len(field1.dims)) == 2 and (field1.dims == (timename,'ncol')):

        data1=field1.data
        if field2 is not None:
            data2=field2.data
        if field3 is not None:
            data3=field3.data
    # C3S shape
    elif (len(field1.dims)) == 3 and (field1.dims == (timename,'lat','lon')):
        ndims=field1.data.shape
        newdims=(ndims[0], ndims[1]*ndims[2])
        if very_verbose:
            print('Warning: Reshaping arrays',ndims,'to',newdims)
        
        data1=field1.data.reshape(newdims)
        if field2 is not None:
            data2=field2.data.reshape(newdims)
        if field3 is not None:
            data3=field3.data.reshape(newdims)
            if np.any(np.isnan(data3)) and very_verbose:
                print('Warning: There are NaN values in icefrac that will not be checked')
    else:
        raise InputError('Unsupported dimensions in spike check')
        
    # compute delta T/Q
    delta1 = np.zeros_like(data1)
    delta1[0:-2,:] = data1[1:-1, :] - data1[0:-2, :]
    delta1[-1,:] = data1[-2, :] - data1[-1, :]
    
    if field2 is not None:
        delta2 = np.zeros_like(data1) 
        delta2[0:-2,:] = data2[1:-1, :] - data2[0:-2, :]
        delta2[-1,:] = data2[-2, :] - data2[-1, :]

    # find spikes
        delta2[0:-2] = data2[1:-1, :] - data2[0:-2, :]
        delta2[0:-2] = data2[1:-1, :] - data2[0:-2, :]
    # condition 1 #refT>50
    spk_pos_c1 = np.transpose(np.nonzero((data1 > max_limit1))) #refT>50
    c1set = set([tuple(x) for x in spk_pos_c1]) 
    # condition 2 #deltaT>30
    spk_pos_c2 = np.transpose(np.nonzero(abs(delta1) > delta_limit1)) #deltaT > 30deg
    c2set = set([tuple(x) for x in spk_pos_c2])
    # condition 3 #deltaQ>60
    if field2 is not None:
        spk_pos_c3 = np.transpose(np.nonzero(abs(data2) > delta_limit2)) #deltaQ > 50%    
        c3set = set([tuple(x) for x in spk_pos_c3])
    # condition 4 #icefrac>0
    if field3 is not None:
        icefrac_pos= np.transpose(np.nonzero(data3 > max_limit3)) #icefrac > 0 
        iceset   = set([tuple(x) for x in icefrac_pos])
   
    # combine filters
    if field2 is None:
        spk_pos = np.array([x for x in (c1set | c2set)])
        if verbose or very_verbose:
            print('[INFO] N. Points found (('+varname+' value>'+str(max_limit1)+' | '+varname+' delta>'+str(delta_limit1)+' ): '+str(len(list(spk_pos))))
        if very_verbose:
            print('Locations (c1|c2):',spk_pos)

        if field3 is None:
            log_list=str(lab_std)+";"+str(lab_mem)+";"+str(len(list(spk_pos)))+";"++"\n"
            point_list=[ str(lab_std)+";"+str(lab_mem)+";"+
                     str(spk_pos[i,0])+";"+str(spk_pos[i,1])+";"+
                     str(data1[spk_pos[i,0],spk_pos[i,1]])+";"+
                     str(delta1[spk_pos[i,0],spk_pos[i,1]])+";"
                     "\n" for i in range(len(spk_pos[:,1])) ]
        else:
            c1setice = set([tuple(x) for x in spk_pos_c1]).intersection(iceset)
            c2setice = set([tuple(x) for x in spk_pos_c2]).intersection(iceset)
            spk_pos_ice = np.array([x for x in (c1setice | c2setice)])
            if verbose or very_verbose:
                print('[INFO] N. Points found (('+varname+' value>'+str(max_limit1)+' | '+varname+' delta>'+str(delta_limit1)+') &icefrac>'+str(max_limit3)+'): '+str(len(list(spk_pos_ice))))
            if very_verbose:
                print('Locations (c1|c2&icefrac):',spk_pos_ice)
            # write log with stadate, member, time step, grid point, Temp value, deltaT value, Qref value, deltaQ value, icefrac
            point_list=[ str(lab_std)+";"+str(lab_mem)+";"+
                     str(spk_pos[i,0])+";"+str(spk_pos[i,1])+";"+
                     str(data1[spk_pos[i,0],spk_pos[i,1]])+";"+
                     str(delta1[spk_pos[i,0],spk_pos[i,1]])+";"+
                     str(data3[spk_pos[i,0],spk_pos[i,1]])+
                     "\n" for i in range(len(spk_pos[:,1])) ]

            if len(list(spk_pos_ice)) > 0:
                point_list_ice=[ str(lab_std)+";"+str(lab_mem)+";"+
                     str(spk_pos_ice[i,0])+";"+str(spk_pos_ice[i,1])+";"+
                     str(data1[spk_pos_ice[i,0],spk_pos_ice[i,1]])+";"+
                     str(delta1[spk_pos_ice[i,0],spk_pos_ice[i,1]])+";"+
                     str(data3[spk_pos_ice[i,0],spk_pos_ice[i,1]])+
                     "\n" for i in range(len(spk_pos_ice[:,1])) ]

            log_list=str(lab_std)+";"+str(lab_mem)+";"+str(len(list(spk_pos)))+";"+str(len(list(spk_pos_ice)))+";"+"\n"   

    else: #field2 is not None
        spk_pos = np.array([x for x in (c1set | c2set) & c3set])
        if verbose or very_verbose:
            print('N. Points found (('+varname+' value>'+str(max_limit1)+' | '+varname+' delta>'+str(delta_limit1)+') & Qref delta>'+str(max_delta2)+'): '+str(len(list(spk_pos))))
        if very_verbose:
            print('Locations (c1|c2&c3):',spk_pos)
        if field3 is None:
            log_list=str(lab_std)+";"+str(lab_mem)+";"+str(len(list(spk_pos)))+";"++"\n"
            point_list=[ str(lab_std)+";"+str(lab_mem)+";"+
                     str(spk_pos[i,0])+";"+str(spk_pos[i,1])+";"+
                     str(data1[spk_pos[i,0],spk_pos[i,1]])+";"+
                     str(delta1[spk_pos[i,0],spk_pos[i,1]])+";"+
                     str(data2[spk_pos[i,0],spk_pos[i,1]])+";"+
                     str(delta2[spk_pos[i,0],spk_pos[i,1]])+";"+
                     "\n" for i in range(len(spk_pos[:,1])) ]
        else:
            c1setice = set([tuple(x) for x in spk_pos_c1]).intersection(iceset) 
            c2setice = set([tuple(x) for x in spk_pos_c2]).intersection(iceset)
            c3setice = set([tuple(x) for x in spk_pos_c3]).intersection(iceset)
            spk_pos_ice = np.array([x for x in (c1setice | c2setice) & c3setice])
            if verbose or very_verbose:
                print('N. Points found (('+varname+' value>'+str(max_limit1)+' | '+varname+' delta>'+str(delta_limit1)+') & Qref delta>'+str(delta_limit2)+' &icefrac'+str(max_limit3)+'): '+str(len(list(spk_pos_ice))))
            if very_verbose:
                print('Locations (c1|c2&c3&icefrac):',spk_pos_ice)
            log_list=str(lab_std)+";"+str(lab_mem)+";"+str(len(list(spk_pos)))+";"+str(len(list(spk_pos_ice)))+";"+"\n"   
            point_list=[ str(lab_std)+";"+str(lab_mem)+";"+
                     str(spk_pos[i,0])+";"+str(spk_pos[i,1])+";"+
                     str(data1[spk_pos[i,0],spk_pos[i,1]])+";"+
                     str(delta1[spk_pos[i,0],spk_pos[i,1]])+";"+
                     str(data2[spk_pos[i,0],spk_pos[i,1]])+";"+
                     str(delta2[spk_pos[i,0],spk_pos[i,1]])+";"+
                     str(data3[spk_pos[i,0],spk_pos[i,1]])+
                     "\n" for i in range(len(spk_pos[:,1])) ]
            if len(list(spk_pos_ice)) > 0:
                point_list_ice=[ str(lab_std)+";"+str(lab_mem)+";"+
                     str(spk_pos_ice[i,0])+";"+str(spk_pos_ice[i,1])+";"+
                     str(data1[spk_pos_ice[i,0],spk_pos_ice[i,1]])+";"+
                     str(delta1[spk_pos_ice[i,0],spk_pos_ice[i,1]])+";"+
                     str(data2[spk_pos_ice[i,0],spk_pos_ice[i,1]])+";"+
                     str(delta2[spk_pos_ice[i,0],spk_pos_ice[i,1]])+";"+
                     str(data3[spk_pos_ice[i,0],spk_pos_ice[i,1]])+
                     "\n" for i in range(len(spk_pos_ice[:,1])) ]

    # if list of spikes in ice is full, then raise and error, finally write the list of all spikes, spikes on ice and error list for log
    try:
        if field3 is not None and len(list(spk_pos_ice)) > 0:
            raise FieldError('Spike identified on ice')
    except FieldError as e:
        spike_error_list=print_error(error_message=e, error_list=spike_error_list, loc1=[shortname, varname])
    finally:    
        return log_list, point_list_ice, spike_error_list
