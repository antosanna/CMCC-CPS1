import numpy as np
import warnings
from qa_checker_lib.var_tools import sel_field_slice
from qa_checker_lib.general_tools import print_error
from qa_checker_lib.errors import *

def check_minmax(field, checktype, limit, levn=None, verbose=False, very_verbose=False, warning=True):
    """
    Check if minimum/maximum value is lower/higher than given limit.
    Inputs: 
        field: variable to check
        checktype: minimum or maximum
        limit: a number with the limit value for the check. If levn is defined, then is must be a vector of limit values for each level of field which length must coincide with the field level/depth dimension
        levn: if indicated, name of dimension to be checked on which limit values are given
        verbose: True/False 
        very_verbose: True/False 
        warning: print a warning to the screen instead of raising an error
    """
    varn = field.long_name
    shortn = field.name
    if levn is None:
        # Loof for any values exceeding limit 
        if checktype in ['minimum','Minimum']:
            if np.min(field.data) < limit:
                # these find only val/pos of 1 minimum point
                pos = np.transpose(np.nonzero(field.data < limit))
                val = field.data[np.nonzero(field.data < limit)]
                abs_val = np.min(val)     
                if verbose or very_verbose:
                    print(checktype.capitalize(),'check failed on',len(list(pos)),'points among which the ', checktype,' value is:',abs_val,' and limit is:'+str(limit)+'.\nAll value(s):',val,'\nPosition(s):', list(pos),'\n')
                if warning is True:
                    war_message=' [FIELDWARNING]  >> Field '+shortn+' ('+varn+') '+checktype+' lower than limit '+str(limit)+' on '+str(len(list(pos)))+' points among which the '+checktype+' value is: '+str(abs_val)+'\n'
                    print(war_message)
                else:
                    raise FieldError('Field '+checktype+' lower than limit '+str(limit)+' on '+str(len(list(pos)))+' points.')
        elif checktype in ['maximum','Maximum']:
            if np.max(field.data) > limit:
                pos = np.transpose(np.nonzero(field.data > limit))
                val = field.data[np.nonzero(field.data > limit)]
                abs_val = np.max(val)
                if verbose or very_verbose:
                    print(checktype.capitalize(),'check failed on',len(list(pos)),'points among which the ',checktype,' value is:',abs_val,' and limit is:'+str(limit)+'.\nAll value(s):',val,'\nPosition(s):', list(pos),'\n')
                if warning is True:
                    war_message=' [FIELDWARNING]  >> Field '+shortn+' ('+varn+') '+checktype+' higher than limit '+str(limit)+' on '+str(len(list(pos)))+' points among which the '+ checktype+' value is: '+str(abs_val)+'\n'
                    print(war_message)
                else:
                    raise FieldError('Field '+checktype+' higher than limit '+str(limit)+' on '+str(len(list(pos)))+' points.')
    else:
        # Loof for any values exceeding limit by level
        if len(field.coords[levn]) != len(limit):
            raise InputError('Lenght of limit vector must be equal to number of levels of variable in check_minmax() function')
        error_list=[]
        for p in range(0, len(field.coords[levn])):
            if very_verbose:
                print('....Checking level:',levn,'[',p,'] with limit', str(limit[p]))
            
            if levn=='plev':
                fieldbylev = field.isel(plev=p)
            elif levn=='depth':
                fieldbylev = field.isel(depth=p)
            
            if checktype in ['minimum','Minimum']:
                if np.min(fieldbylev.data) < limit[p]:
                    val = np.min(fieldbylev.data)
                    pos = np.transpose(np.nonzero(fieldbylev.data < limit[p]))
                    val = fieldbylev.data[np.nonzero(fieldbylev.data < limit[p])]
                    if verbose or very_verbose:
                        print(checktype.capitalize(),'check on lev',p,'failed on',len(list(pos)),'points. Limit(',limit[p],'), Value(s):',val)
                    error_list.append(p)
            if checktype in ['maximum','Maximum']:
                if np.max(fieldbylev.data) > limit[p]:
                    val = np.max(fieldbylev.data)
                    pos = np.transpose(np.nonzero(fieldbylev.data > limit[p]))
                    val = fieldbylev.data[np.nonzero(fieldbylev.data > limit[p])]
                    if verbose or very_verbose:
                        print(checktype.capitalize(),'check on lev',p,'failed on',len(list(pos)),'points. Limit(',limit[p],'),(Value(s):',val)
                    error_list.append(p)
        if error_list:
            error_list_string=','.join(map(str, error_list))
            if warning is True:
                war_message=' [FIELDWARNING]  >> Field '+shortn+' ('+varn+') '+checktype,' exceeding in lev(s): ['+error_list_string+']'
                warnings.warn(war_message)
            else:
                raise FieldError('Field '+shortn+'('+varn+') '+checktype +' exceeding limit in lev(s): ['+error_list_string+']')

def check_2d_field(field, filling_value, constant_limit):
    """
    Check if all values in a 2D field are constant, infinite, nan, filling value or zero
    """
    if len(field.dims) > 2 :
        raise FieldError('Field has more than 2 dimensions! Cannot apply check_2d_field()')
    
    difs = np.max(field) - np.min(field)
    if np.all(np.isinf(field)) or np.all(np.isneginf(field)):
        raise FieldError('All field = Inf')
    if np.all(np.isnan(field)):
        raise FieldError('All field = nan')
    if not np.any(field):
        raise FieldError('All field = 0')
    if np.all(field==filling_value):
        raise FieldError('All field = filling')
    if not np.isfinite(field).all:
        raise FieldError('All field = not finite')
    if (difs < constant_limit):
        raise FieldError('All field = constant')
def check_temp_spike_std(maskfield,sicfield,varn,shortn,timen,lab_std, lab_mem, error_list, field1,mult=3,verbose=False, very_verbose=False):
    mask=maskfield.data
    sic=sicfield.data
    point_list=[]
    spk_pos=None
    
    # compute delta T
    data1=field1.data
    data_lowperc=np.min(data1,axis=0) #np.percentile(data1,1,axis=0)
    data_upperc=np.max(data1,axis=0)  #np.percentile(data1,99,axis=0)
    data4stdev=np.where(np.logical_or(data1<data_upperc[None,:,:],data1>data_lowperc[None,:,:]),data1,np.nan)
    std_dev=np.nanstd(data4stdev,axis=0)
    
    delta1 = np.zeros_like(data1)
    #the difference t(i+1)-t(i) is assigned to delta1 at t(i+1)
    delta1[1:len(delta1)]=data1[1:len(data1)]-data1[0:-1]
    delta1[0]=data1[1]-data1[0]

    spk_pos = np.transpose(np.nonzero((delta1 > mult*std_dev)))
    if len(spk_pos[:,1]) > 0:
          point_list=["std_dev test: DT>"+str(mult)+"*std_dev\n"+str(lab_std)+";"+str(lab_mem) +";"+str(len(list(spk_pos)))+";\n"+
                    "Time;Lat:Lon;Tmin;ddelta1;stdev;mask;sic"+"\n"  ]
          point_list.append([
                    str(spk_pos[i,0])+";"+str(spk_pos[i,1])+";"+str(spk_pos[i,2])+";"+
                    str(data1[spk_pos[i,0]-1,spk_pos[i,1],spk_pos[i,2]])+";"+
                    str(delta1[spk_pos[i,0],spk_pos[i,1],spk_pos[i,2]])+";"+
                    str(std_dev[spk_pos[i,1],spk_pos[i,2]])+";"+
                    str(mask[spk_pos[i,1],spk_pos[i,2]])+";"+
                    str(sic[spk_pos[i,0],spk_pos[i,1],spk_pos[i,2]])+";"+
                    "\n" for i in range(len(spk_pos[:,1]))])
    try:
        if len(list(spk_pos)) == 0:
            print('no spikes found')
    except FieldError as e:
        error_list=print_error(error_message=e, error_list=error_list, loc1=[shortn, varn])
    finally:
        #return point_list_c1,point_list_c2,point_list_c1andc2,point_list_noc3,point_list, error_list
        return point_list, error_list


def check_temp_spike(maskfield,sicfield,varn,shortn,timen,lab_std, lab_mem, error_list, field1, min_limit1=183, delta_limit1=50, delta_limit2=30,verbose=False, very_verbose=False):
    """
    Performs a series of tests designed to identify anomalous temp spikes. 
    The rationale is that a spike is defined if a threshold is exceeded AND 
    if it is ONLY at one time shot
    Arguments:
        field1=TMIN 
    Returns:
        spike list, spikes on ice list
    Raises:
        Error when spike on ice is found
    """
    mask=maskfield.data
    sic=sicfield.data
    point_list=[]
    point_list_noc3=[]
    point_list_c1=[]
    point_list_c2=[]
    point_list_c1andc2=[]
    spk_pos=None
    if (len(field1.dims)) == 3 and (field1.dims == (timen,'lat','lon')):
        ndims=field1.data.shape
        newdims=(ndims[0], ndims[1]*ndims[2])
        if very_verbose:
            print('Warning: Reshaping arrays',ndims,'to',newdims)
        
        data1=field1.data.reshape(newdims)
    else:
        raise InputError('Unsupported dimensions in spike check')
        
    # compute delta T
    data1=field1.data
    delta1 = np.zeros_like(data1)
#------------------------------------------------------------
#------------------------------------------------------------

  #  delta1[0:-2,:,:] = data1[1:-1, :,:] - data1[0:-2, :,:]
  #  delta1[-1,:,:] = data1[-2, :,:] - data1[-1, :,:]
  #  delta1[0:-1,:,:]=data1[1:len(data1),:,:]-data1[0:-1,:,:]
  #  delta1[-1,:,:]=data1[-2, :,:] - data1[-1, :,:]

    #the difference t(i+1)-t(i) is assigned to delta1 at t(i+1)
    delta1[1:len(delta1)]=data1[1:len(data1)]-data1[0:-1]
    delta1[0]=data1[1]-data1[0]

    ddelta1=np.zeros_like(data1)
    #ddelta1[0:-2,:,:]=data1[2:len(data1),:,:]-data1[0:len(data1)-2,:,:]
    #ddelta1[-2:len(ddelta1),:,:]=data1[-4:-2,:,:]-data1[-2:len(data1),:,:]
   
    #the difference t(i+2)-t(i) is assigned to ddelta1 at t(i+1)
    #at the extremes ddelta[0]/ddelta[-1] the difference with the contigous time step is given
    ddelta1[1:-1,:,:]=data1[2:len(data1),:,:]-data1[0:len(data1)-2,:,:]
    ddelta1[0,:,:]=data1[1,:,:]-data1[0,:,:]
    ddelta1[-1,:,:]=data1[-1,:,:]-data1[-2,:,:]
    
    # SPIKE EXAMPLE
    #
    #--------\        /-------  0
    #         \      /
    #          \    /
    #           \  /
    #            \/           -60
    #            
    #
    #
    #  1    2     3     4     5       time-index
    #
    #
    #  t1    t2   t3    t4    t5
    #  0     0   -60    0     0        data1
    #
    #t1-t0 t2-t1 t3-t2 t4-t3 t5-t4
    #  0     0   -60   60    0         delta1
    #
    #t2-t0 t3-t1 t4-t2 t5-t3 t6-t4
    #  0    -60   0    60    0         ddelta1
    #
    #the checker should recognize at time step t3 the spike since
    #  --> in t3 data1   > thershold
    #  --> in t3 delta1  > threshold for derivative t(i+1)-t(i)
    #  --> in t3 ddelta1 < threshold for derivative t(i+2)-t(i)
    #
 
    print(f"delta computed")
    # find spikes
    # condition 1 #refT<183
    spk_pos_c1 = np.transpose(np.nonzero((data1< min_limit1))) 
    print(f"dim spk_pos_c1 {len(spk_pos_c1[:,1])}")
    if len(spk_pos_c1[:,1]) > 0:
        c1set = set([tuple(x) for x in spk_pos_c1]) 
    # condition 2 #deltaT(Dt)>50
    #spk_pos_c2 = np.transpose(np.nonzero(abs(delta1) > delta_limit1)) 
    #to take care of the  sign (deltaT < -35)
    spk_pos_c2 = np.transpose(np.nonzero(delta1 < delta_limit1)) 
    print(f"dim spk_pos_c2 {len(spk_pos_c2[:,1])}")
    if len(spk_pos_c2[:,1]) > 0:
        c2set = set([tuple(x) for x in spk_pos_c2])
    # condition 3 #deltaT(Dt2)<30
    spk_pos_c3 = np.transpose(np.nonzero(abs(ddelta1) < delta_limit2)) 
    print(f"dim spk_pos_c3 {len(spk_pos_c3[:,1])}")
    if len(spk_pos_c3[:,1]) > 0:
        c3set = set([tuple(x) for x in spk_pos_c3])

    if len(spk_pos_c1[:,1]) > 0 :
          print("if c1")
          point_list_c1=["only c1: T<"+str(min_limit1)+"\n"+str(lab_std)+";"+str(lab_mem) +";"+str(len(list(spk_pos_c1)))+";\n"+
                    "Time;Lat:Lon;Tmin;ddelta1;ddelta2;mask;sic"+"\n"  ]
          point_list_c1.append([
                    str(spk_pos_c1[i,0])+";"+str(spk_pos_c1[i,1])+";"+str(spk_pos_c1[i,2])+";"+
                    str(data1[spk_pos_c1[i,0],spk_pos_c1[i,1],spk_pos_c1[i,2]])+";"+
                    str(delta1[spk_pos_c1[i,0],spk_pos_c1[i,1],spk_pos_c1[i,2]])+";"+
                    str(ddelta1[spk_pos_c1[i,0],spk_pos_c1[i,1],spk_pos_c1[i,2]])+";"+
                    str(mask[spk_pos_c1[i,1],spk_pos_c1[i,2]])+";"+
                    str(sic[spk_pos_c1[i,0],spk_pos_c1[i,1],spk_pos_c1[i,2]])+";"+
                    "\n" for i in range(len(spk_pos_c1[:,1]))])

    if len(spk_pos_c2[:,1])> 0:
          print("if c2")
          point_list_c2=["only c2: DT>"+str(delta_limit1)+"\n"+str(lab_std)+";"+str(lab_mem) +";"+str(len(list(spk_pos_c2)))+";\n"+
                    "Time;Lat:Lon;Tmin;ddelta1;ddelta2;mask;sic"+"\n" ]
          point_list_c2.append([
                    str(spk_pos_c2[i,0])+";"+str(spk_pos_c2[i,1])+";"+str(spk_pos_c2[i,2])+";"+
                    str(data1[spk_pos_c2[i,0],spk_pos_c2[i,1],spk_pos_c2[i,2]])+";"+
                    str(delta1[spk_pos_c2[i,0],spk_pos_c2[i,1],spk_pos_c2[i,2]])+";"+
                    str(ddelta1[spk_pos_c2[i,0],spk_pos_c2[i,1],spk_pos_c2[i,2]])+";"+       
                    str(mask[spk_pos_c2[i,1],spk_pos_c2[i,2]])+";"+
                    str(sic[spk_pos_c2[i,0],spk_pos_c2[i,1],spk_pos_c2[i,2]])+";"+       
                    "\n" for i in range(len(spk_pos_c2[:,1]))])

    if len(spk_pos_c2[:,1]>0) and len(spk_pos_c1[:,1])>0:
          print("if c1&c2")
          spk_pos_c1andc2=np.array([x for x in (c1set & c2set)])
          if (len(spk_pos_c1andc2) > 0):
             point_list_c1andc2=["c1&c2: T<"+str(min_limit1)+" DT>"+str(delta_limit1)+"\n"+str(lab_std)+";"+str(lab_mem) +";"+str(len(list(spk_pos_c1andc2)))+";\n"+
                    "Time;Lat:Lon;Tmin;ddelta1;ddelta2;mask;sic"+"\n"  ]        
             point_list_c1andc2.append([
                    str(spk_pos_c1andc2[i,0])+";"+str(spk_pos_c1andc2[i,1])+";"+str(spk_pos_c1andc2[i,2])+";"+
                    str(data1[spk_pos_c1andc2[i,0],spk_pos_c1andc2[i,1],spk_pos_c1andc2[i,2]])+";"+
                    str(delta1[spk_pos_c1andc2[i,0],spk_pos_c1andc2[i,1],spk_pos_c1andc2[i,2]])+";"+
                    str(ddelta1[spk_pos_c1andc2[i,0],spk_pos_c1andc2[i,1],spk_pos_c1andc2[i,2]])+";"+
                    str(mask[spk_pos_c1andc2[i,1],spk_pos_c1andc2[i,2]])+";"+
                    str(sic[spk_pos_c1andc2[i,0],spk_pos_c1andc2[i,1],spk_pos_c1andc2[i,2]])+";"+
                    "\n" for i in range(len(spk_pos_c1andc2[:,1]))]) 

    #if len(spk_pos_c1[:,1]) > 0 and len(spk_pos_c2[:,1]) > 0 and  len(spk_pos_c3[:,1])==0:
    #   spk_pos_noc3 = np.array([x for x in (c1set & c2set)])
    #   point_list_noc3=["c1&c2: T<"+str(min_limit1)+" DT>"+str(delta_limit1)+" no c3\n"+str(lab_std)+";"+str(lab_mem) +";"+str(len(list(spk_pos_noc3)))+";\n"+
    #                "Time;Lat:Lon;Tmin;ddelta1;ddelta2"  ]
    #   point_list_noc3.append([
    #                str(spk_pos_noc3[i,0])+";"+str(spk_pos_noc3[i,1])+";"+str(spk_pos_noc3[i,2])+";"+
    #                str(data1[spk_pos_noc3[i,0],spk_pos_noc3[i,1],spk_pos_noc3[i,2]])+";"+
    #                str(delta1[spk_pos_noc3[i,0],spk_pos_noc3[i,1],spk_pos_noc3[i,2]])+";"+
    #                str(ddelta1[spk_pos_noc3[i,0],spk_pos_noc3[i,1],spk_pos_noc3[i,2]])+";"+
    #                "\n" for i in range(len(spk_pos_noc3[:,1]))])
    # combine filters
    #if len(spk_pos_c1[:,1]) > 0 and len(spk_pos_c2[:,1]) > 0 and len(spk_pos_c3[:,1]) > 0 :
    if len(spk_pos_c2[:,1]) > 0 and len(spk_pos_c3[:,1]) > 0 :
            print("original condition") 
            spk_pos = np.array([x for x in (c2set & c3set)])
            if len(spk_pos) > 0:
              if verbose or very_verbose:
                  print('[INFO] N. Points found (( TMIN delta>'+str(delta_limit1)+'TMIN(DT2) delta<'+str(delta_limit2)+' ): '+str(len(list(spk_pos))))
              if very_verbose:
                  print('Locations (c2&c3):',spk_pos)
              point_list=[str(lab_std)+";"+str(lab_mem) +";"+str(len(list(spk_pos)))+";\n"+
                    "Time;Lat:Lon;Tmin;ddelta1;ddelta2;mask;sic"+"\n"  ]
              point_list.append([
                    str(spk_pos[i,0])+";"+str(spk_pos[i,1])+";"+str(spk_pos[i,2])+";"+
                    str(data1[spk_pos[i,0],spk_pos[i,1],spk_pos[i,2]])+";"+
                    str(delta1[spk_pos[i,0],spk_pos[i,1],spk_pos[i,2]])+";"+
                    str(ddelta1[spk_pos[i,0],spk_pos[i,1],spk_pos[i,2]])+";"+
                    str(mask[spk_pos[i,1],spk_pos[i,2]])+";"+
                    str(sic[spk_pos[i,0],spk_pos[i,1],spk_pos[i,2]])+";"+
                    "\n" for i in range(len(spk_pos[:,1]))])

    print('returning list')
    # if list of spikes is full, then raise and error, finally write the list of all spikes and error list for log
    try:
        if len(list(spk_pos)) == 0:
            print('no spikes found') 
    except FieldError as e:
        error_list=print_error(error_message=e, error_list=error_list, loc1=[shortn, varn])
    finally:    
        #return point_list_c1,point_list_c2,point_list_c1andc2,point_list_noc3,point_list, error_list
        return point_list_c1,point_list_c2,point_list_c1andc2,point_list, error_list

def check_tsd_34dfield(field, tsd_limit, timname, levn=None, verbose=False, very_verbose=False):
    
    """
    Check if all points in field are stationary (std = 0 along time)
    """
    # TODO improve if with DMO dimension types (i.e. timname,'ncols'; timname,levn,'ncols')
    if (len(field.dims) == 3) and (field.dims == (timname, 'lat', 'lon')):
        field_stationarity = np.std(field.data, axis = 0) == tsd_limit
        if np.all(field_stationarity):
            raise FieldError('Field is stationary')

    elif (len(field.dims) == 4) and (field.dims == (timname, levn, 'lat', 'lon')):
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
def check_field(field, varn, shortn, timen, levn, filling_value, constant_limit, check_min, min_limit, check_max, max_limit, check_tsd, tsd_limit, verbose=False, very_verbose=False):

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
                    print('[INFO] Checking minimum value of', varn, 'by level')
                check_minmax(field, 'minimum', min_limit, levn=levn, verbose=verbose, very_verbose=very_verbose)
            else:
                if verbose or very_verbose:
                    print('[INFO] Checking minimum value of', varn)
                check_minmax(field, 'minimum', min_limit, levn=None, verbose=verbose, very_verbose=very_verbose)

        except FieldError as e:
            exc_list+=print_error(error_message=e, error_list=exc_list, loc1=[shortn, varn])
    
    # check max
    if check_max:
        try:
            if len(max_limit) > 1:
                if verbose or very_verbose:
                    print('[INFO] Checking maximum value of',varn, 'by level')
                check_minmax(field, 'maximum', max_limit, levn=levn, verbose=verbose, very_verbose=very_verbose)
            else:
                if verbose or very_verbose:
                    print('[INFO] Checking maximum value of',varn)
                check_minmax(field, 'maximum', max_limit, levn=None, verbose=verbose, very_verbose=very_verbose)
        except FieldError as e:
            exc_list+=print_error(error_message=e, error_list=exc_list, loc1=[shortn, varn])

    # check field separating ensemble members, pressure levels and time steps
    if (len(field.dims) < 2):
        if very_verbose:
            print('...Skypping 1D field', varn)
 
    elif (len(field.dims) == 2) and (field.dims == ('lat','lon')):
        # check empty/constant slab
        try:
            if verbose or very_verbose:
                print('[INFO] Checking consistency of 2D-slices of',varn)
            check_2d_field(field, filling_value, constant_limit)
        except FieldError as e:
            exc_list+=print_error(error_message=e, error_list=exc_list, loc1=[shortn, varn])

    elif (len(field.dims) == 2) and (field.dims == (timen,'ncol')):
        # check time sd
        if check_tsd:
            if verbose or very_verbose:
                print('[INFO] Checking time standard deviation of',varn)
            try:
                list = check_tsd_34dfield(field, tsd_limit, timen)
            except FieldError as e:
                exc_list+=print_error(error_message=e, error_list=exc_list, loc1=[shortn, varn])

    elif (len(field.dims) == 3) and (field.dims == (timen,'lat','lon')):
        slicetype='time'
        # check time sd
        if check_tsd:
            if verbose or very_verbose:
                print('[INFO] Checking time standard deviation of',varn)
            try:
                list = check_tsd_34dfield(field, tsd_limit, timen)
            except FieldError as e:
                exc_list+=print_error(error_message=e, error_list=exc_list, loc1=[shortn, varn])

        # check empty/constant slab
        if verbose or very_verbose:
            print('[INFO] Checking consistency of 2D-slices of',varn)
        for l in range(0, len(field.coords[timen])):
            field2d = sel_field_slice(field,slicetype=slicetype, index1=l, index2=None)
            try:
                if very_verbose:
                    print('....Checking ',varn,' ',timen, ': ',l)
                check_2d_field(field2d, filling_value, constant_limit)
            except FieldError as e:
                exc_list+=print_error(error_message=e, error_list=exc_list, loc1=[shortn, varn], loc2=[timen, l])

    elif (len(field.dims) == 4) and (field.dims == (timen,levn,'lat','lon')):
        slicetype='timelev'
        # check time sd
        if check_tsd:
            if verbose or very_verbose:
                print('[INFO] Checking time standard deviation of',varn)
            try:   
                list = check_tsd_34dfield(field, tsd_limit, timen, levn)
            except FieldError as e:
                exc_list+=print_error(error_message=e, error_list=exc_list, loc1=[shortn, varn], loc2=[timen, l], loc3=[levn, list])

        # check empty/constant slab
        if verbose or very_verbose:
            print('[INFO] Checking consistency of 2D-slices of',varn)
        for l in range(0, len(field.coords[timen])):
            for p in range(0, len(field.coords[levn])):
                field2d = sel_field_slice(field,slicetype=slicetype, index1=l, index2=p)
                try:
                    if very_verbose:
                        print('....Checking ',varn,' ',timen,': ',l,levn,': ',p)
                    check_2d_field(field2d, filling_value, constant_limit)
                except FieldError as e:
                    exc_list+=print_error(error_message=e, error_list=exc_list, loc1=[shortn, varn], loc2=[timen, l], loc3=[levn, p])

    elif (len(field.dims) == 4) and (field.dims == ('realization',timen,'lat','lon')):
        slicetype='timereal'
        # check time sd
        if check_tsd:
            if verbose or very_verbose:
                print('[INFO] Checking time standard deviation of',varn)
            try:  
                list = check_tsd_34dfield(field, tsd_limit, timen)
            except FieldError as e:
                exc_list+=print_error(error_message=e, error_list=exc_list, loc1=[shortn, varn], loc2=['realization', list])

        # check empty/constant slab
        if verbose or very_verbose:
            print('[INFO] Checking consistency of 2D-slices of',varn)
        for r in range(0,len(field.coords['realization'])):
            for l in range(0,len(field.coords[timen])):
                field2d = sel_field_slice(field,slicetype=slicetype, index1=l, index2=p)
                try:
                    if very_verbose:
                        print('....Checking ',varn,' realization: ',r,', ',timen,': ',l)
                    check_2d_field(field2d, filling_value, constant_limit)
                except FieldError as e:
                    exc_list+=print_error(error_message=e, error_list=exc_list, loc1=[shortn, varn], loc2=['realization', list], loc3=[timen,l])

    elif (len(field.dims) == 5) and (field.dims == ('realization',timen,levn,'lat','lon')):
        slicetype='timelevreal'
        for r in range(0, len(field.coords['realization'])):
            # check time sd
            if check_tsd:
                if verbose or very_verbose:
                    print('[INFO] Checking time standard deviation of',varn)
                try:  
                    list = check_tsd_34dfield(field.isel(realization=r), tsd_limit, timen, levn)
                except FieldError as e:
                    exc_list+=print_error(error_message=e, error_list=exc_list, loc1=[shortn, varn], loc2=['realization', r], loc3=[levn,list])
    
            # check empty/constant slab
            if verbose or very_verbose:
                print('[INFO] Checking consistency of 2D-slices of',varn)
            for l in range(0, len(field.coords[timen])):
                for p in range(0, len(field.coords[levn])):
                    field2d = sel_field_slice(field,slicetype=slicetype, index1=l, index2=r, index3=p)
                    try:
                        if very_verbose:
                            print('....Checking realization: ',r,', ',timen,': ',l,', ',levn,': ',p)
                        check_2d_field(field2d, filling_value, constant_limit)
                    except FieldError as e:
                        exc_list+=print_error(error_message=e, error_list=exc_list, loc1=[shortn, varn], loc2=['realization', r], loc3=[timen,l], loc4=[levn,p])
    
    else: 
        raise InputError('[INPUTERROR] Field ',varn, ' has unsupported dimensions')

    return exc_list

def check_consistency_all_field_not_encoded(field, varn, shortn,  verbose, very_verbose):
    """
    Check if any value in field is invalid
    Note that field must be not encoded (i.e, fill value is a number and not nan) in order to be able to differentiate it from real nan
    """
    exc_list=[]
    if verbose or very_verbose:
        print('[INFO] Checking whole field consistency of', varn)

    # check if there is any not finite(nan or inf) value
    try:
        if np.any(~(np.isfinite(field))):
            pos = np.where(~(np.isfinite(field))==True)
            if verbose or very_verbose:  
                print('Consistency check failed on ',len(list(pos[0])),'points(s). Position(s):', list(pos))   
            raise FieldError('Invalid (nan or Inf) value on field')
    except FieldError as e:
        exc_list=print_error(error_message=e, error_list=exc_list, loc1=[shortn,varn])
        return(exc_list)
