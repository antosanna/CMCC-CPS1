import numpy as np
import warnings
from qa_checker_lib.var_tools import sel_field_slice
from qa_checker_lib.general_tools import print_error
from qa_checker_lib.errors import *

def check_temp_spike_rollstd(varn,shortn,timen,filename, error_list, field1,window_size=30,thresh=2.0,verbose=False, very_verbose=False):
    point_list=[]
    spk_pos_tot=None

    data=field1.data
    time, nlat, nlon = data.shape
    spike_mask = np.zeros((time, nlat, nlon), dtype=bool)
    std_diff = np.zeros((time, nlat, nlon))
    std_dev_orig=np.zeros((nlat,nlon))
    std_dev_new=np.zeros((nlat,nlon))
    half_window = window_size // 2

    for lat in range(nlat):
        for lon in range(nlon):
            timeseries = data[:, lat, lon]
            
            for t in range(time):
                start_idx = max(0, t - half_window)
                end_idx = max(window_size, t + half_window)
                window_data = timeseries[start_idx:end_idx]
                
                std_normal = np.std(window_data)
                std_dev_orig[lat,lon]=std_normal
                window_no_min = np.delete(window_data, np.argmin(window_data))
                std_no_min = np.std(window_no_min)
                std_dev_new[lat,lon]=std_no_min
                std_diff[t, lat, lon] = std_normal - std_no_min
                spike_mask[t, lat, lon] = std_diff[t, lat, lon] > thresh
       
    spk_pos_tot=np.argwhere(spike_mask==True)

    if len(spk_pos_tot) > 0:
          point_list=["std_dev test: Dstd>"+str(thresh)+" "+filename +";"+str(len(spk_pos_tot))+";\n"+
                    "Time;Lat;Lon;stdev_orig,stdev_new,delta_stdev"+"\n"  ]
          point_list.append([
                    str(spk_pos_tot[i][0])+";"+str(spk_pos_tot[i][1])+";"+str(spk_pos_tot[i][2])+";"+
                    str(std_dev_orig[spk_pos_tot[i][1],spk_pos_tot[i][2]])+";"+
                    str(std_dev_new[spk_pos_tot[i][1],spk_pos_tot[i][2]])+";"+
                    str(std_diff[spk_pos_tot[i][1],spk_pos_tot[i][2]])+";"+
                    "\n" for i in range(len(spk_pos_tot))])
    try:
        if len(list(spk_pos_tot)) == 0:
            print('no spikes found')
    except FieldError as e:
        error_list=print_error(error_message=e, error_list=error_list, loc1=[shortn, varn])
    finally:
        #return point_list_c1,point_list_c2,point_list_c1andc2,point_list_noc3,point_list, error_list
        return point_list, error_list




def check_temp_spike_std(varn,shortn,timen,filename, error_list, field1,freq_split=30,thresh=2.0,verbose=False, very_verbose=False):
    point_list=[]
    spk_pos=None
    
    data1=field1.data
    nmb_time=np.shape(data1)[0]
    if nmb_time <= int(freq_split) :
      split=1
    else:
      split=int(nmb_time/int(freq_split))
   
    data_split=np.array_split(data1,split)
    spk_pos_tot=[]
    std_dev_orig=[]
    std_dev_new=[]
    delta_std=[]
    time_len=0
    for i in range(split):
       data_min=np.min(data_split[i],axis=0)
       data4stdev_mon=np.where(data_split[i]>data_min[None,:,:],data_split[i],np.nan)
       std_dev_new_mon=np.nanstd(data4stdev_mon,axis=0)
       std_dev_orig_mon=np.nanstd(data_split[i],axis=0)
       ref_mult_mon=np.full_like(std_dev_new_mon,thresh)
       delta_std_mon=std_dev_orig_mon-std_dev_new_mon
       spk_pos_xy=np.argwhere(delta_std_mon>ref_mult_mon)
       print("coord spike")
       print(spk_pos_xy)
       for ii in range(len(spk_pos_xy)):
          pos_in_split=np.argmin(data_split[i][:,spk_pos_xy[ii][0],spk_pos_xy[ii][1]],axis=0)
          len_split=np.shape(data_split[i])[0]
          redo_test=0
          #at the beginning/end of the chunck, recompute std_dev test centering the windows in the middle of the spike
          if (i!=0 and i!=split-1) and (pos_in_split==0 or pos_in_split==len_split-1):
             redo_test=1
             wind_redo=int(freq_split/2)
          elif (i==0 and pos_in_split==len_split-1) or (i==split-1 and pos_in_split==0):
             redo_test=1
             wind_redo=int(freq_split/2)
          if redo_test !=0:
             spk_pos_tim=time_len+np.argmin(data_split[i][:,spk_pos_xy[ii][0],spk_pos_xy[ii][1]],axis=0)
             data_retry=data1[spk_pos_tim-wind_redo:spk_pos_tim+wind_redo,spk_pos_xy[ii][0],spk_pos_xy[ii][1]]
             data_retry_min=np.min(data_retry,axis=0)
             data4std_retry=np.where(data_retry>data_retry_min,data_retry,np.nan)
             std_retry_new=np.nanstd(data4std_retry)
             std_retry_orig=np.nanstd(data_retry)
             delta_std_retry=std_retry_orig-std_retry_new
             if delta_std_retry<thresh:
                continue
          if i==0:
            spk_pos_tim=np.argmin(data_split[i][:,spk_pos_xy[ii][0],spk_pos_xy[ii][1]],axis=0)
          else:
            spk_pos_tim=time_len+np.argmin(data_split[i][:,spk_pos_xy[ii][0],spk_pos_xy[ii][1]],axis=0)

          spk_coord=np.array([spk_pos_tim,spk_pos_xy[ii][0],spk_pos_xy[ii][1]])
          spk_pos_tot.append(spk_coord)
          std_dev_orig.append(std_dev_orig_mon[spk_pos_xy[ii][0],spk_pos_xy[ii][1]])
          std_dev_new.append(std_dev_new_mon[spk_pos_xy[ii][0],spk_pos_xy[ii][1]])
          delta_std.append(std_dev_orig_mon[spk_pos_xy[ii][0],spk_pos_xy[ii][1]]-std_dev_new_mon[spk_pos_xy[ii][0],spk_pos_xy[ii][1]])
 
       time_len+=np.shape(data_split[i])[0] 
    if len(spk_pos_tot) > 0:
          point_list=["std_dev test: Dstd>"+str(thresh)+" "+filename +";"+str(len(spk_pos_tot))+";\n"+
                    "Time;Lat;Lon;stdev_orig,stdev_new,delta_stdev"+"\n"  ]
          point_list.append([
                    str(spk_pos_tot[i][0])+";"+str(spk_pos_tot[i][1])+";"+str(spk_pos_tot[i][2])+";"+
                    str(std_dev_orig[i])+";"+
                    str(std_dev_new[i])+";"+
                    str(delta_std[i])+";"+
                    "\n" for i in range(len(spk_pos_tot))])
    try:
        if len(list(spk_pos)) == 0:
            print('no spikes found')
    except FieldError as e:
        error_list=print_error(error_message=e, error_list=error_list, loc1=[shortn, varn])
    finally:
        #return point_list_c1,point_list_c2,point_list_c1andc2,point_list_noc3,point_list, error_list
        return point_list, error_list


def check_temp_spike_obs(varn,shortn,timen,filename, error_list, field1, min_limit1=-90, delta_limit1=50, delta_limit2=30,verbose=False, very_verbose=False):
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
    point_list=[]
    point_list_noc3=[]
    point_list_c1=[]
    point_list_c2=[]
    point_list_c1andc2=[]
    spk_pos=None

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
    # condition 3 #deltaT(Dt2)> -25 (go up more than 25deg wrt the original point)
    spk_pos_c3 = np.transpose(np.nonzero(ddelta1 > - delta_limit2))
    print(f"dim spk_pos_c3 {len(spk_pos_c3[:,1])}")
    if len(spk_pos_c3[:,1]) > 0:
        c3set = set([tuple(x) for x in spk_pos_c3])

    if len(spk_pos_c1[:,1]) > 0 :
          print("if c1")
          point_list_c1=["only c1: T<"+str(min_limit1)+"\n"+str(filename)+";"+str(len(list(spk_pos_c1)))+";\n"+
                    "Time;Lat:Lon;Tmin;ddelta1;ddelta2"+"\n"  ]
          point_list_c1.append([
                    str(spk_pos_c1[i,0])+";"+str(spk_pos_c1[i,1])+";"+str(spk_pos_c1[i,2])+";"+
                    str(data1[spk_pos_c1[i,0],spk_pos_c1[i,1],spk_pos_c1[i,2]])+";"+
                    str(delta1[spk_pos_c1[i,0],spk_pos_c1[i,1],spk_pos_c1[i,2]])+";"+
                    str(ddelta1[spk_pos_c1[i,0],spk_pos_c1[i,1],spk_pos_c1[i,2]])+";"+
                    "\n" for i in range(len(spk_pos_c1[:,1]))])

    if len(spk_pos_c2[:,1])> 0:
          print("if c2")
          point_list_c2=["only c2: DT>"+str(delta_limit1)+"\n"+str(filename)+";"+str(len(list(spk_pos_c2)))+";\n"+
                    "Time;Lat:Lon;Tmin;ddelta1;ddelta2"+"\n" ]
          point_list_c2.append([
                    str(spk_pos_c2[i,0])+";"+str(spk_pos_c2[i,1])+";"+str(spk_pos_c2[i,2])+";"+
                    str(data1[spk_pos_c2[i,0],spk_pos_c2[i,1],spk_pos_c2[i,2]])+";"+
                    str(delta1[spk_pos_c2[i,0],spk_pos_c2[i,1],spk_pos_c2[i,2]])+";"+
                    str(ddelta1[spk_pos_c2[i,0],spk_pos_c2[i,1],spk_pos_c2[i,2]])+";"+
                    "\n" for i in range(len(spk_pos_c2[:,1]))])

    if len(spk_pos_c2[:,1]>0) and len(spk_pos_c1[:,1])>0:
          print("if c1&c2")
          spk_pos_c1andc2=np.array([x for x in (c1set & c2set)])
          if (len(spk_pos_c1andc2) > 0):
             point_list_c1andc2=["c1&c2: T<"+str(min_limit1)+" DT>"+str(delta_limit1)+"\n"+str(filename)+";"+str(len(list(spk_pos_c1andc2)))+";\n"+
                    "Time;Lat:Lon;Tmin;ddelta1;ddelta2;"+"\n"  ]
             point_list_c1andc2.append([
                    str(spk_pos_c1andc2[i,0])+";"+str(spk_pos_c1andc2[i,1])+";"+str(spk_pos_c1andc2[i,2])+";"+
                    str(data1[spk_pos_c1andc2[i,0],spk_pos_c1andc2[i,1],spk_pos_c1andc2[i,2]])+";"+
                    str(delta1[spk_pos_c1andc2[i,0],spk_pos_c1andc2[i,1],spk_pos_c1andc2[i,2]])+";"+
                    str(ddelta1[spk_pos_c1andc2[i,0],spk_pos_c1andc2[i,1],spk_pos_c1andc2[i,2]])+";"+
                    "\n" for i in range(len(spk_pos_c1andc2[:,1]))])

    #if len(spk_pos_c1[:,1]) > 0 and len(spk_pos_c2[:,1]) > 0 and  len(spk_pos_c3[:,1])==0:
    #   spk_pos_noc3 = np.array([x for x in (c1set & c2set)])
    #   point_list_noc3=["c1&c2: T<"+str(min_limit1)+" DT>"+str(delta_limit1)+" no c3\n"+str(filename)+";"+str(len(list(spk_pos_noc3)))+";\n"+
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
              point_list=[str(filename)+";"+str(len(list(spk_pos)))+";\n"+
                    "Time;Lat:Lon;Tmin;ddelta1;ddelta2"+"\n"  ]
              point_list.append([
                    str(spk_pos[i,0])+";"+str(spk_pos[i,1])+";"+str(spk_pos[i,2])+";"+
                    str(data1[spk_pos[i,0],spk_pos[i,1],spk_pos[i,2]])+";"+
                    str(delta1[spk_pos[i,0],spk_pos[i,1],spk_pos[i,2]])+";"+
                    str(ddelta1[spk_pos[i,0],spk_pos[i,1],spk_pos[i,2]])+";"+
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



def check_temp_spike(varn,shortn,timen,filename, error_list, field1, min_limit1=183, delta_limit1=-30, delta_limit2=5,verbose=False, very_verbose=False):
    """
    Performs a series of tests designed to identify anomalous temp spikes. 
    The rationale is that a spike is defined if a threshold is exceeded AND 
    if it is ONLY at maximum 2 time shots
    Arguments:
        field1=TMIN 
    Returns:
        spike list, spikes on ice list
    Raises:
        Error when spike is found
    """
    point_list=[]
    spk_pos=None
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
    dddelta1=np.zeros_like(data1)
    #ddelta1[0:-2,:,:]=data1[2:len(data1),:,:]-data1[0:len(data1)-2,:,:]
    #ddelta1[-2:len(ddelta1),:,:]=data1[-4:-2,:,:]-data1[-2:len(data1),:,:]
   
    #the difference t(i+2)-t(i) is assigned to ddelta1 at t(i+1)
    #at the extremes ddelta[0]/ddelta[-1] the difference with the contigous time step is given
    ddelta1[1:-1,:,:]=data1[2:len(data1),:,:]-data1[0:len(data1)-2,:,:]
    ddelta1[0,:,:]=data1[1,:,:]-data1[0,:,:]
    ddelta1[-1,:,:]=data1[-1,:,:]-data1[-2,:,:]
    
    #the difference t(i+3)-t(i) is assigned to ddelta1 at t(i+1)
    #at the extremes dddelta[0]/dddelta[-2,-1] the difference with two contigous time step is given
    dddelta1[1:-2,:,:]=data1[3:len(data1),:,:]-data1[0:len(data1)-3,:,:]
    dddelta1[0,:,:]=data1[2,:,:]-data1[0,:,:]
    dddelta1[-2,:,:]=data1[-1,:,:]-data1[-3,:,:]
    dddelta1[-1,:,:]=data1[-1,:,:]-data1[-2,:,:]

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
    #t3-t0 t4-t1 t5-t2 t6-t3 t7-t4     dddelta1
    # -60    0     0     60  0
    #
    #the checker should recognize at time step t3 the spike since
    #  --> in t3 data1   > thershold
    #  --> in t3 delta1  > threshold for derivative t(i+1)-t(i)
    #  --> in t3 ddelta1 < threshold for derivative t(i+2)-t(i)
    #  --> in t3 dddelta1< threshold for derivative t(i+3)-t(i)  (to account for 2 day spikes)
 
    if verbose or very_verbose:
        print(f"delta computed")
    # find spikes
    # condition 1 #refT<183
    spk_pos_c1 = np.transpose(np.nonzero((data1< min_limit1))) 
    if verbose or very_verbose:
        print(f"dim spk_pos_c1 {len(spk_pos_c1[:,1])}")
    if len(spk_pos_c1[:,1]) > 0:
        c1set = set([tuple(x) for x in spk_pos_c1]) 

    # condition 2 #deltaT(Dt)>-30
    #to take care of the  sign (deltaT < -30)
    spk_pos_c2 = np.transpose(np.nonzero(delta1 < delta_limit1)) 
    if verbose or very_verbose:
        print(f"dim spk_pos_c2 {len(spk_pos_c2[:,1])}")
    if len(spk_pos_c2[:,1]) > 0:
        c2set = set([tuple(x) for x in spk_pos_c2])

    # condition 3 #deltaT(Dt2)> -5 (go up more than 25deg wrt the original point)
    spk_pos_c3 = np.transpose(np.nonzero(ddelta1 > - delta_limit2)) 
    if verbose or very_verbose:
        print(f"dim spk_pos_c3 {len(spk_pos_c3[:,1])}")
    if len(spk_pos_c3[:,1]) > 0:
        c3set = set([tuple(x) for x in spk_pos_c3])

    # condition 4 #deltaT(Dt3)> -5 (go up more than 25deg wrt the original point)
    spk_pos_c4 = np.transpose(np.nonzero(dddelta1 > - delta_limit2))
    if verbose or very_verbose:
        print(f"dim spk_pos_c4 {len(spk_pos_c4[:,1])}")
    if len(spk_pos_c4[:,1]) > 0:
        c4set = set([tuple(x) for x in spk_pos_c4])


    # combine filters
    if len(spk_pos_c2[:,1]) > 0 and len(spk_pos_c4[:,1]) > 0 :
            if very_verbose:
                print("original condition only on deltat3") 
            spk_pos = np.array([x for x in (c2set & c4set)])
            if len(spk_pos) > 0:
              if verbose or very_verbose:
                  print('[INFO] N. Points found (( TMIN delta>'+str(delta_limit1)+' TMIN(DT3) delta>-'+str(delta_limit2)+' ): '+str(len(list(spk_pos))))
              if verbose or very_verbose:
                  print('Locations (c2&c4):',spk_pos)
              point_list=[str(filename)+";"+str(len(list(spk_pos)))+";\n"+
                    "Time;Lat:Lon;Tmin;ddelta1;ddelta2;ddelta3"+"\n"  ]
              point_list.append([
                    str(spk_pos[i,0])+";"+str(spk_pos[i,1])+";"+str(spk_pos[i,2])+";"+
                    str(data1[spk_pos[i,0],spk_pos[i,1],spk_pos[i,2]])+";"+
                    str(delta1[spk_pos[i,0],spk_pos[i,1],spk_pos[i,2]])+";"+
                    str(ddelta1[spk_pos[i,0],spk_pos[i,1],spk_pos[i,2]])+";"+
                    str(dddelta1[spk_pos[i,0],spk_pos[i,1],spk_pos[i,2]])+";"+
                    "\n" for i in range(len(spk_pos[:,1]))])

    if verbose or very_verbose:
        print('returning list')
    # if list of spikes is full, then raise and error, finally write the list of all spikes and error list for log
    try:
        if len(list(spk_pos)) == 0:
            print('no spikes found') 
    except FieldError as e:
        error_list=print_error(error_message=e, error_list=error_list, loc1=[shortn, varn])
    finally:    
        #return point_list, error_list
        return point_list, error_list






def check_temp_spike_new(varn,shortn,timen,filename, error_list, field1, min_limit1=183, delta_limit1=50, delta_limit2=30,verbose=False, very_verbose=False):
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
    point_list=[]
    point_list_noc3=[]
    point_list_c1=[]
    point_list_c2=[]
    point_list_c1andc2=[]
    spk_pos=None
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

    #the difference t(i+2)-t(i+1) is assigned to ddelta1 at t(i+1)
    #at the extremes ddelta[0]/ddelta[-1] the difference with the contigous time step is given
    ddelta1[1:-1,:,:]=data1[2:len(data1),:,:]-data1[1:len(data1)-1,:,:]
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
    #t2-t1 t3-t2 t4-t3 t5-t4 t6-t5
    #  0    -60   60    0    0         ddelta1
    #
    #the checker should recognize at time step t3 the spike since
    #  --> in t3 data1   < thershold
    #  --> in t3 delta1  < threshold for derivative t(i+1)-t(i)
    #  --> in t3 ddelta1 > threshold for derivative t(i+2)-t(i+1)
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

    # condition 3 #deltaT(Dt2)> 25 (go up more than 25deg from the spike point)
    spk_pos_c3 = np.transpose(np.nonzero(ddelta1 > delta_limit2))
    print(f"dim spk_pos_c3 {len(spk_pos_c3[:,1])}")
    if len(spk_pos_c3[:,1]) > 0:
        c3set = set([tuple(x) for x in spk_pos_c3])

    if len(spk_pos_c1[:,1]) > 0 :
          print("if c1")
          point_list_c1=["only c1: T<"+str(min_limit1)+"\n"+str(filename)+";"+str(len(list(spk_pos_c1)))+";\n"+
                    "Time;Lat:Lon;Tmin;ddelta1;ddelta2"+"\n"  ]
          point_list_c1.append([
                    str(spk_pos_c1[i,0])+";"+str(spk_pos_c1[i,1])+";"+str(spk_pos_c1[i,2])+";"+
                    str(data1[spk_pos_c1[i,0],spk_pos_c1[i,1],spk_pos_c1[i,2]])+";"+
                    str(delta1[spk_pos_c1[i,0],spk_pos_c1[i,1],spk_pos_c1[i,2]])+";"+
                    str(ddelta1[spk_pos_c1[i,0],spk_pos_c1[i,1],spk_pos_c1[i,2]])+";"+
                    "\n" for i in range(len(spk_pos_c1[:,1]))])

    if len(spk_pos_c2[:,1])> 0:
          print("if c2")
          point_list_c2=["only c2: DT>"+str(delta_limit1)+"\n"+str(filename)+";"+str(len(list(spk_pos_c2)))+";\n"+
                    "Time;Lat:Lon;Tmin;ddelta1;ddelta2"+"\n" ]
          point_list_c2.append([
                    str(spk_pos_c2[i,0])+";"+str(spk_pos_c2[i,1])+";"+str(spk_pos_c2[i,2])+";"+
                    str(data1[spk_pos_c2[i,0],spk_pos_c2[i,1],spk_pos_c2[i,2]])+";"+
                    str(delta1[spk_pos_c2[i,0],spk_pos_c2[i,1],spk_pos_c2[i,2]])+";"+
                    str(ddelta1[spk_pos_c2[i,0],spk_pos_c2[i,1],spk_pos_c2[i,2]])+";"+
                    "\n" for i in range(len(spk_pos_c2[:,1]))])

    if len(spk_pos_c2[:,1]>0) and len(spk_pos_c1[:,1])>0:
          print("if c1&c2")
          spk_pos_c1andc2=np.array([x for x in (c1set & c2set)])
          if (len(spk_pos_c1andc2) > 0):
             point_list_c1andc2=["c1&c2: T<"+str(min_limit1)+" DT>"+str(delta_limit1)+"\n"+str(filename)+";"+str(len(list(spk_pos_c1andc2)))+";\n"+
                    "Time;Lat:Lon;Tmin;ddelta1;ddelta2"+"\n"  ]
             point_list_c1andc2.append([
                    str(spk_pos_c1andc2[i,0])+";"+str(spk_pos_c1andc2[i,1])+";"+str(spk_pos_c1andc2[i,2])+";"+
                    str(data1[spk_pos_c1andc2[i,0],spk_pos_c1andc2[i,1],spk_pos_c1andc2[i,2]])+";"+
                    str(delta1[spk_pos_c1andc2[i,0],spk_pos_c1andc2[i,1],spk_pos_c1andc2[i,2]])+";"+
                    str(ddelta1[spk_pos_c1andc2[i,0],spk_pos_c1andc2[i,1],spk_pos_c1andc2[i,2]])+";"+
                    "\n" for i in range(len(spk_pos_c1andc2[:,1]))])

    #if len(spk_pos_c1[:,1]) > 0 and len(spk_pos_c2[:,1]) > 0 and  len(spk_pos_c3[:,1])==0:
    #   spk_pos_noc3 = np.array([x for x in (c1set & c2set)])
    #   point_list_noc3=["c1&c2: T<"+str(min_limit1)+" DT>"+str(delta_limit1)+" no c3\n"+str(filename)+";"+str(len(list(spk_pos_noc3)))+";\n"+
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
                  print('[INFO] N. Points found (( TMIN delta>'+str(delta_limit1)+' TMIN(DT2) delta>-'+str(delta_limit2)+' ): '+str(len(list(spk_pos))))
              if very_verbose:
                  print('Locations (c2&c3):',spk_pos)
              point_list=[str(filename)+";"+str(len(list(spk_pos)))+";\n"+
                    "Time;Lat:Lon;Tmin;ddelta1;ddelta2"+"\n"  ]
              point_list.append([
                    str(spk_pos[i,0])+";"+str(spk_pos[i,1])+";"+str(spk_pos[i,2])+";"+
                    str(data1[spk_pos[i,0],spk_pos[i,1],spk_pos[i,2]])+";"+
                    str(delta1[spk_pos[i,0],spk_pos[i,1],spk_pos[i,2]])+";"+
                    str(ddelta1[spk_pos[i,0],spk_pos[i,1],spk_pos[i,2]])+";"+
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
