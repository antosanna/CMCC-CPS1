import netCDF4
import numpy as np
import csv
from datetime import datetime as dt
from datetime import timedelta  as td
from calendar import monthrange
import calendar
import os
import glob
import sys
import pandas as pd
from scipy import interpolate

def printdb(text,dbmode):
    if dbmode:
        print(text)

def getdzgrnd(c3s_el, f, dbmode):
    # get ground levels from netcdf file (just one time) - they are the middle level in the cell
    dz0=f.variables['levgrnd'][:].data
    # create the delta z levels array (see http://www.cesm.ucar.edu/models/cesm2/land/CLM50_Tech_Note.pdf)
    dzgrnd=np.zeros(dz0.size)

    printdb("   id    TOP       MID       BOT       DZ      ",dbmode)
    for idx,lev in enumerate(dz0):
        top=0 if idx == 0 else bot #top is the bottom level of previous iteration
        mid=lev
        dzl=2*(mid-top)
        bot=mid+0.5*dzl
        dzgrnd[idx]=dzl
        # if dbg mode is active print
        printdb("%4.0f %9.3f %9.3f %9.3f %9.3f" % (idx,top,mid,bot,dzl),dzgrnd[idx],dbmode) 

    flag_error = False
    # for construction, dzgrnd must be gt 0, if any of them is == 0 raise error
    if np.any(dzgrnd<=0):
        flag_error = True
        raise ValueError('Error on getdzgrnd(). dzgrnd[:] has some value <= 0, and should be not')
    
    return dzgrnd,flag_error

def check_timeseries_NEW2(nc_file, c3s_line, index, dbmode,modelname):
    ''' This function simply extract data from file taking into account eventual levels'''
    # params selections depending on input freq
    if c3s_line[8] == 'day' or c3s_line[8] == '6hr':
        # Soil moisture is used to calculate both mrlsl and its integral mrso 
        if 'depth' in c3s_line[12] or 'mrso' in  c3s_line[1]:
            print(vars_list)
            list_of_levels = [nc_file.variables[lev][:] for lev in vars_list[::-1]]
            var_c3s = np.stack(list_of_levels, axis=1)
        else:
            var_c3s = nc_file.variables[c3s_line[0]][:]
    else:
        sys.exit(1)

    # check for number of time_steps in variables serie
    var_time = nc_file.variables['time'][:]
   
    error_flag = False

    return var_time, var_c3s, error_flag

def create_C3S_file(nc_file, atm_elem, ltime_dim, yy, st, ic_ens,templfile,nlsl):

    # CREATING DIMENSIONS
    nc_file.createDimension('lat', 180)
    nc_file.createDimension('lon', 360)
    #nc_file.createDimension('leadtime', None)  # unlimited axis (can be appended to) TODO this give a record coordinate (UNLIMITED) dim
    nc_file.createDimension('leadtime', ltime_dim)  
    nc_file.createDimension('str31', 31)
    nc_file.createDimension('bnds', 2)

    # Create Dimension depth in case of soil moisture (levels) mrlsl
    # see in table 2.2.3 soil layer struct clm5 tech notes (https://escomp.github.io/ctsm-docs/versions/release-clm5.0/html/tech_note/Ecosystem/CLM50_Tech_Note_Ecosystem.html#table-soil-layer-structure)
    #From CLM userguid: "The soil column can be discretized into an arbitrary number of layers. The default vertical discretization (Table 2.2.3) uses N_{levgrnd} = 25 layers, of which N_{levsoi} = 20 are hydrologically and biogeochemically active." 

    Layer_node_depth = np.array([0.010,0.040,0.090,0.160,0.260,0.400,0.580,0.800,1.060,1.360,1.700,2.080,2.500,2.990,3.580,4.270,5.060,5.950,6.940,8.030,9.795,13.328,19.483,28.871,41.998])

#0.007100635, 0.027925, 0.06225858, 0.1188651, 0.2121934, 0.3660658, 0.6197585, 1.038027, 1.727635, 2.864607, 4.739157, 7.829766,12.92532, 21.32647, 35.17762])
    # bounds
    ln_bnd0 = np.array([0,0.020,0.060,0.120,0.200,0.320,0.480,0.680,0.920,1.200,1.520,1.880,2.280,2.720,3.260,3.900,4.640,5.480,6.420,7.460,8.600,10.990,15.666,23.301,34.441])

#0.01750,0.04510,0.09060,0.16550,0.28910,0.49290,0.82890,1.38280,2.29610,3.80190,6.28450,10.37750,17.12590,28.25200])
    ln_bnd1 = np.array([0.020,0.060,0.120,0.200,0.320,0.480,0.680,0.920,1.200,1.520,1.880,2.280,2.720,3.260,3.900,4.640,5.480,6.420,7.460,8.600,10.990,15.666,23.301,34.441,49.556])
#0.01750,0.04510,0.09060,0.16550,0.28910,0.49290,0.82890,1.38280,2.29610,3.80190,6.28450,10.37750,17.12590,28.25200,42.10320])
    # since in clm5 the 5 latest levels are bedrock we retain only the first 20 soil levels
    Layer_node_depth = Layer_node_depth[:-nlsl]
    ln_bnd0 = ln_bnd0[:-nlsl]
    ln_bnd1 = ln_bnd1[:-nlsl]

    if 'depth' in atm_elem[12] and atm_elem[1] != 'mrso' :
        nc_file.createDimension('depth', len(Layer_node_depth))    
        depth = nc_file.createVariable('depth', np.float64, ('depth',), zlib=True, complevel=6, shuffle=True)
        depth[:] = Layer_node_depth
        depth.units = 'm'
        depth.long_name = 'depth'
        depth.standard_name = 'depth'
        depth.axis = 'Z' 
        depth.positive = 'down'    
        # Create bounds
        depth_bnds = nc_file.createVariable('depth_bnds', np.float64, ('depth','bnds'), zlib=True, complevel=6, shuffle=True)
        depth.bounds = 'depth_bnds'      
        depth_bnds[:,0] = ln_bnd0
        depth_bnds[:,1] = ln_bnd1

    
    # CREATING GLOBAL ATTRIBUTES from $DIR_TEMPL/C3S_globalatt.txt (pipe separator)
    try:
        df_global = pd.read_csv(templfile,sep='=',names=['A', 'B'], header=None)
    except:
        print(" CLM postproc - python - problem with file "+templfile)

    nc_file.Conventions  = df_global.loc[ df_global['A'].str.strip() ==  'Conventions'].values[0][1].strip() #'CF-1.6 C3S-0.1'
    nc_file.title        = df_global.loc[ df_global['A'].str.strip() ==  'title'].values[0][1].strip() #'CMCC seasonal forecast model output prepared for C3S'
    nc_file.references   = df_global.loc[ df_global['A'].str.strip() ==  'references'].values[0][1].strip() #'The new CMCC Seasonal Prediction System, CMCC report RP0253,' \
    nc_file.source       = df_global.loc[ df_global['A'].str.strip() ==  'source'].values[0][1].strip() #'cmcc_CMCC-CM2-v20160423:  atmos: CAM(ne60np4 L46);' \
    nc_file.institute_id = df_global.loc[ df_global['A'].str.strip() ==  'institute_id'].values[0][1].strip() #'cmcc'
    nc_file.institution  = df_global.loc[ df_global['A'].str.strip() ==  'institution'].values[0][1].strip() #'CMCC, Centro Euro-Mediterraneo sui Cambiamenti Climatici, Bologna, Italy'
    nc_file.contact      = df_global.loc[ df_global['A'].str.strip() ==  'contact'].values[0][1].strip() #'http://copernicus-support.ecmwf.int'
    nc_file.project      = df_global.loc[ df_global['A'].str.strip() ==  'project'].values[0][1].strip() #'C3S Seasonal Forecast'
    nc_file.creation_date= dt.now().strftime("%Y-%m-%dT%H:%M:%SZ")
    nc_file.forecast_reference_time = yy +'-' + st + '-01T00:00:00Z'
    nc_file.commit        = df_global.loc[ df_global['A'].str.strip() ==  'commit'].values[0][1].strip() # '2017-10-01T9:35:32Z' 
    nc_file.modeling_realm= atm_elem[10]
    nc_file.forecast_type = forecast_t
    nc_file.frequency     = atm_elem[8]
    nc_file.level_type    = atm_elem[9]
    nc_file.comment       = df_global.loc[ df_global['A'].str.strip() ==  'comment'].values[0][1].strip() #'Run by CMCC at CMCC Supercomputing Center, University of Salento'
    nc_file.history       = ''
    nc_file.summary       = df_global.loc[ df_global['A'].str.strip() ==  'summary'].values[0][1].strip() #'Seasonal Forecast data produced by CMCC' \
    nc_file.keywords      = df_global.loc[ df_global['A'].str.strip() ==  'keywords'].values[0][1].strip() #
    nc_file.ic = ic_ens

    # CREATING VARIABLES
    lat = nc_file.createVariable('lat', np.float64, ('lat',),
                                 zlib=True, complevel=6, shuffle=True)
    lat[:] = -89.5 + (180. / len(lat)) * np.arange(len(lat))         # south pole to north pole
    lat.units = 'degrees_north'
    lat.long_name = 'latitude'
    lat.standard_name = 'latitude'
    lat.axis = 'Y'
    lat.bounds = 'lat_bnds'
    lat.valid_min = -90.
    lat.valid_max = 90.

    lon = nc_file.createVariable('lon', np.float64, ('lon',),
                                 zlib=True, complevel=6, shuffle=True)
    lon[:] = (180. / len(lat)) * np.arange(len(lon)) + 0.5           # Greenwich meridian eastward
    lon.units = 'degrees_east'
    lon.long_name = 'longitude'
    lon.standard_name = 'longitude'
    lon.axis = 'X'
    lon.bounds = 'lon_bnds'
    lon.valid_min = 0.
    lon.valid_max = 360.

    lat_bnds = nc_file.createVariable('lat_bnds', np.float64, ('lat', 'bnds'),
                                      zlib=True, complevel=6, shuffle=True)
    lat_bnds[:, 0] = -90. + (180. / len(lat)) * np.arange(len(lat))
    lat_bnds[:, 1] = -89. + (180. / len(lat)) * np.arange(len(lat))

    lon_bnds = nc_file.createVariable('lon_bnds', np.float64, ('lon', 'bnds'),
                                      zlib=True, complevel=6, shuffle=True)
    lon_bnds[:, 0] = (180. / len(lat)) * np.arange(len(lon))
    lon_bnds[:, 1] = (180. / len(lat)) * np.arange(len(lon)) + 1

    if atm_elem[8] == 'day' or atm_elem[8] == '6hr':
        str_time_unit = 'days'
    else:
        str_time_unit = 'hours'

    time = nc_file.createVariable('time', np.float64, ('leadtime',),
                                  zlib=True, complevel=6, shuffle=True)
    time.units = str_time_unit  + ' since ' + yy + '-' + st + '-01T00:00:00Z'
    time.long_name = 'Verification time of the forecast'
    time.standard_name = 'time'
    time.calendar = 'gregorian'
    if atm_elem[8] == 'day' and 'leadtime: point' not in atm_elem[13]:
        time.bounds = 'time_bnds'
    if atm_elem[8] == '6hr' and 'leadtime: point' not in atm_elem[13]:
        time.bounds = 'time_bnds'

    if 'leadtime: point' not in atm_elem[13]:
        time_bnds = nc_file.createVariable('time_bnds', np.float64, ('leadtime', 'bnds'),
                                       zlib=True, complevel=6, shuffle=True)
        leadtime_bnds = nc_file.createVariable('leadtime_bnds', np.float64, ('leadtime', 'bnds'),
                                               zlib=True, complevel=6, shuffle=True)

    leadtime = nc_file.createVariable('leadtime', np.float64, ('leadtime',),
                                      zlib=True, complevel=6, shuffle=True)

    leadtime.units = str_time_unit
    leadtime.long_name = 'Time elapsed since the start of the forecast'
    leadtime.standard_name = 'forecast_period'
    
    if atm_elem[8] == 'day' and 'leadtime: point' not in atm_elem[13]:
        leadtime.bounds = 'leadtime_bnds'
    if atm_elem[8] == '6hr' and 'leadtime: point' not in atm_elem[13]:
        leadtime.bounds = 'leadtime_bnds'

    # reftime
    reftime = nc_file.createVariable('reftime', np.float64, ())
    reftime.long_name = 'Start date of the forecast'
    reftime.standard_name = 'forecast_reference_time'
    reftime.calendar = 'gregorian'
    reftime.units = str_time_unit + ' since ' + yy + '-' + st + '-01T00:00:00Z'

    hcrs = nc_file.createVariable('hcrs', 'c', ())
    hcrs.grid_mapping_name = 'latitude_longitude'

    # realization
    realization = nc_file.createVariable('realization', 'S1', ('str31',),
                                         zlib=True, complevel=6, shuffle=True)
    realization.units = '1'
    realization.long_name = 'realization'
    realization.standard_name = 'realization'
    realization.axis = 'E'

    # In case of mrso we need extravariable soildepth and soildepthbounds
    if atm_elem[1] == 'mrso':
        nc_file.createDimension('soildepth', 1)
        soildepth = nc_file.createVariable('soildepth', np.float64, ('lat', 'lon',),
                                 zlib=True, complevel=6, shuffle=True)
        soildepth_bnds = nc_file.createVariable('soildepth_bnds', np.float64, ('lat','lon','bnds'),
                                      zlib=True, complevel=6, shuffle=True)
        soildepth.bounds = 'soildepth_bnds'
        soildepth[:,:] = np.full((len(lat), len(lon)), Layer_node_depth[-1]) # create a constant 2D matrix with the value of the last soil layer
        soildepth.units = 'm'
        printdb(Layer_node_depth[-1],dbmode)
        soildepth_bnds[:,:,0] = 0
        soildepth_bnds[:,:,1] = np.full((len(lat), len(lon)), Layer_node_depth[-1])


def modify_C3S(ncfile, atm_elem):
    '''Modifiy nc file applying arithmetic if indicatated in C3S table (list)'''
    # rename variable
    if atm_elem[0] != 'tdps':
        ncfile.renameVariable(atm_elem[0], atm_elem[1])

    # set new attributes
    ncfile.variables[atm_elem[1]].long_name = atm_elem[5]
    ncfile.variables[atm_elem[1]].standard_name = atm_elem[6]
    ncfile.variables[atm_elem[1]].units = atm_elem[7]
    ncfile.variables[atm_elem[1]].coordinates = atm_elem[12]
    if atm_elem[13] == 'leadtime: mean':       # TODO if = "mean" C3S requires interval value and unit
        #ncfile.variables[atm_elem[1]].cell_methods = atm_elem[13] + ' (interval: 1 ' + atm_elem[8] + ')'
        ncfile.variables[atm_elem[1]].cell_methods = atm_elem[13] + ' (interval: 0.5 hour)'
    else:
        ncfile.variables[atm_elem[1]].cell_methods = atm_elem[13]

    # apply arithmetic if necessary
    if atm_elem[11]:
        if atm_elem[11][0] == "*":
            ncfile[atm_elem[1]][:] = ncfile[atm_elem[1]][:] * float(atm_elem[11][1:])
        elif atm_elem[11][0] == "+":
            ncfile[atm_elem[1]][:] = ncfile[atm_elem[1]][:] + float(atm_elem[11][1:])

    ncfile.variables[atm_elem[1]].grid_mapping = 'hcrs'


def create_c3s_var2(c3s_el,cmcc_file,ic,dbmode,modelname,output_dir,repo_dir,templfile,nlsl,lsmfile):

    first_time = True
    #for idx, cmcc_f in enumerate(cmcc_files):
    # open with netcdf4
    f = netCDF4.Dataset(cmcc_file, 'r')
    # check time series and get var_f = variable
    print("before check_timeseries_NEW2")
    [time_var, var_f, flag_error] = check_timeseries_NEW2(f, c3s_el, 0, dbmode,modelname)
    print("flag_error after check_timeseries_NEW2", flag_error)
    # exit the function if detected an error
    if flag_error: return

    # time_dim_tot = time_dim
    new_var = var_f[:]

    #here it is not necessary to descard bedrock (as in CLM4.5) because now the var is defined on levsoi 
    #which is equivalent to top nlevsoi(=20) levels of levgrnd
    if c3s_el[0] == "H2OSOI2":
        printdb(new_var.shape,dbmode)
        new_var = new_var[:,:,:,:,:]
        print("if H2OSOI2")
        print(np.shape(new_var))
        printdb(new_var.shape,dbmode)

#    if c3s_el[0] == "SNOTTOPL":
#        printdb(new_var.shape,dbmode)
#        new_var = new_var[:,:,:]
#        print("if SNOTTOPL")
#        print(np.shape(new_var))
#        printdb(new_var.shape,dbmode)

    # additionally perform integration for mrso over levels (check_timeseries_NEW2 return a stack over axis 1)
    if c3s_el[1] == "mrso":
        print("computing integral mrso")
        printdb(["mrso dim pre",new_var.shape],dbmode)        
        new_var = np.sum(new_var,axis=2)
        printdb(["mrso dim post",new_var.shape],dbmode)

    # Modify SNOW to get rid of numerical not significant value coming from RHOSNO_bulk=H2OSNO/SNOWDP
    if c3s_el[0] == "RHOSNO":
        new_var[new_var <= 50] = 50.0        
        # 1e+15 is safety since numerical values of rho can reach e1. In thi way fill value is not affected
        new_var[(new_var > 450) & (new_var < 1e+10) ] = 450.0 
   
    #time_dim_tot = time_var.size
    time_dim_tot = new_var.shape[0]

    # realization
    realization = 'r' + pp + 'i00p00'
       
    # create the new NetCDF file
    file_name = output_dir + '/' + prefix + '_' + c3s_el[10] + '_' + \
                c3s_el[8] + '_' + c3s_el[9] + '_' + c3s_el[1] + '_' + \
                realization + '.nc'
    
    # remove file if exist yet (should not)
    try:
        os.remove(file_name)
        print("Removed pre existent file ", file_name) 
    except:
        pass   

    ncf = netCDF4.Dataset(file_name, mode='w', format='NETCDF4_CLASSIC')

    create_C3S_file(ncf, c3s_el, time_dim_tot, year, month,ic,templfile,nlsl)

    if 'depth' in c3s_el[12] and c3s_el[1] != 'mrso' :
        print("creating 4d vars netcdf")
        ncf.createVariable(c3s_el[0], c3s_el[3], 
                           ("leadtime", "depth", "lat", "lon",),  
                           zlib=True, complevel=6, shuffle=True,fill_value=np.float32(1.e+20)) 
    else:
        ncf.createVariable(c3s_el[0], c3s_el[3], 
                       ("leadtime", "lat", "lon",), 
                       zlib=True, complevel=6, shuffle=True,fill_value=np.float32(1.e+20))   
    # store variable 
    print(np.shape(c3s_el[0][:]))
    print(np.shape(new_var[:]))
    ncf.variables[c3s_el[0]][:] = new_var[:]

    ncf.variables['realization'][:] = list('{0: <31}'.format('r' + pp + 'i00p00'))  # to have exactly 31 chars
    ncf.variables['reftime'][:] = 0

    # in land we expect day
    print(c3s_el[0])
    print(c3s_el[8])
    if c3s_el[8] == 'day':
        ncf.variables['time'][:] = np.arange(0, time_dim_tot)
        ncf.variables['leadtime'][:] = np.arange(0, time_dim_tot)
    elif c3s_el[8] == '6hr':
        ncf.variables['time'][:] = np.arange(0, float(int(time_dim_tot/4)),0.25,dtype=np.float32)
        ncf.variables['leadtime'][:] = np.arange(0, float(int(time_dim_tot/4)),0.25,dtype=np.float32)
#        ncf.variables['time'][:] = np.arange(0., 185.,0.25,dtype=np.float32)
#        ncf.variables['leadtime'][:] = np.arange(0., 185.,0.25,dtype=np.float32)
#        ncf.variables['time'][:] = np.arange(0, time_dim_tot)
#        ncf.variables['leadtime'][:] = np.arange(0,time_dim_tot)
    else:
        print("In land we expect only day and 6hr, fix it.")
        sys.exit(1)
    
    # for variables differents from leadtime: point we need for bounds
    if 'leadtime: point' not in c3s_el[13]:
        ncf.variables['time_bnds'][:, 0] = ncf.variables['time'][:]
        ncf.variables['time_bnds'][:, 1] = ncf.variables['time'][:] + 1
        ncf.variables['leadtime_bnds'][:, 0] = ncf.variables['leadtime'][:]
        ncf.variables['leadtime_bnds'][:, 1] = ncf.variables['leadtime'][:] + 1
        ncf.variables['time'][:] += 0.5
        ncf.variables['leadtime'][:] += 0.5

    # modify file applying math if necessary
    print("pre-modify")
    modify_C3S(ncf, c3s_el)
    print("post-modify")    

    # finally apply the mask
    if c3s_el[2] == 'lnd':
        # mask the ocean
        print("var shape before masking",ncf.variables[c3s_el[1]][:].shape)
        f_lsm = netCDF4.Dataset(lsmfile,'r')
        f_lsm_mask = f_lsm.variables['lsmC3S_SPS4'][:]
        # here land is 1 and sea 0 we want opposite
        # change land=-1
        tmpmask = np.where( f_lsm_mask == 1, -1, f_lsm_mask )
        # change oce=1
        tmpmask = np.where( tmpmask == 0, 1, tmpmask )
        # change land=0
        tmpmask = np.where( tmpmask == -1, 0, tmpmask )
        f_lsm_mask = tmpmask
        # create mask for 3D data
        f_lsm_mask_3d = np.repeat(f_lsm_mask[np.newaxis, :, :], new_var.shape[0], axis=0)

        mask = f_lsm_mask_3d
        # if depth dimension is present in land file then use mask_4d
        if "depth" in c3s_el[12] and c3s_el[1] != 'mrso' :
            # create mask for 4D data
            #f_lsm_mask_4d = np.repeat(f_lsm_mask[np.newaxis, :, :], new_var.shape[0], axis=0)
            print("masking 3d vars")
            f_lsm_mask_4d = np.repeat(f_lsm_mask_3d[:, np.newaxis, :, :], new_var.shape[2], axis=1)
            # by default mask is a 3d var            
            #if dbmode: print(f_lsm_mask_3d.shape,f_lsm_mask_4d.shape,new_var.shape)
            mask = f_lsm_mask_4d
        # mask the variable
        ncf.variables[c3s_el[1]][:] = np.ma.masked_array(ncf.variables[c3s_el[1]][:], mask=mask)

        # if values are greater then 1.e+10 mask them 
        ncf.variables[c3s_el[1]][:] = np.ma.masked_greater(ncf.variables[c3s_el[1]], 1.e+10)   

        # apply missing value for all land vars
        ncf.variables[c3s_el[1]].missing_value = np.float32(1.e+20)



    ncf.close()

def createdir(dirname):
    if not os.path.exists(dirname):
        os.makedirs(dirname)

if __name__ == '__main__':
    # TODO: substitute print with logging, pass prefix hindcast/forecst from arguments, import environment variable
     
    # activate test mode (in operational mode must be False)
    dbmode = False
    # nrs of last soil levels to remove (clm 4,5 - 5 last soil lev are bedrock)
    nlsl=5

    # pass input
    startdate = str(sys.argv[1])
    ensemble   = str(sys.argv[2])
    h_type     = str(sys.argv[3])
    forecast_t = str(sys.argv[4])
    input_file  = str(sys.argv[5])
    modelname  = str(sys.argv[6])
    outputdir  = str(sys.argv[7])
    logdir     = str(sys.argv[8])
    repo_dir   = str(sys.argv[9])
    ic         = str(sys.argv[10])        
    templfile  = str(sys.argv[11])
    clmC3Stable= str(sys.argv[12])
    case       = str(sys.argv[13])
    lsmfile    = str(sys.argv[14])   
    prefix     = str(sys.argv[15]) 
 
    year = startdate[0:4]
    month = startdate[4:6]
    pp = ensemble[1:3]
    case = case #modelname + "_"+startdate+"_"+ensemble
    print(case)
    # input directory
     
    # output directory
    output_dir = outputdir #+'/'+case+'/C3S'

    createdir(output_dir)
        
    # define the prefix cmcc_CMCC-CM2-v20191201_hindcast
    #prefix = 'cmcc_CMCC-CM3-v'+versionSPS+'_' + forecast_t + '_S' + startdate +'0100'

    # C3S table list (note that we use same file H2OSOI to calculate both mrlsl and its integral mrso)

    # Mod Name,C3S Name,File Type,data type,dimension               ,long_name                       ,standard_name                   ,   units,frequency,level_type,modeling_realm,Arithmetic expr,coordinates                                      ,cell_methods
    #'H2OSOI2', 'mrlsl',    'lnd',     'f8','leadtime depth lat lon','moisture_content_of_soil_layer','moisture_content_of_soil_layer','kg m-2',    'day',    'soil',        'land',             '','reftime realization time leadtime depth lat lon','leadtime: point'
    # C3S_table_lst=[
    # ['QOVER' ,'mrroas','lnd','f8','leadtime lat lon','Surface Run-off Amount','surface_runoff_amount','kg m-2','day','surface','land','*86400','reftime realization time leadtime lat lon','leadtime: sum'],
    # ['QDRAI' ,'mrroab','lnd','f8','leadtime lat lon','Subsurface Run-off Amount','subsurface_runoff_amount','kg m-2','day','surface','land','*86400','reftime realization time leadtime lat lon','leadtime: sum'],
    # ['H2OSNO','lwesnw','lnd','f8','leadtime lat lon','Liquid Water Equivalent Thickness of Surface Snow Amount','lwe_thickness_of_surface_snow_amount','m','day','surface','land','*0.001','reftime realization time leadtime lat lon','leadtime: point'],
    # ['H2OSOI2','mrlsl','lnd','f8','leadtime depth lat lon','Water Content per Unit Area of Soil Layers','moisture_content_of_soil_layer','kg m-2','day','soil','land','','reftime realization time leadtime depth lat lon','leadtime: point'],
    # ['H2OSOI2','mrso','lnd','f8' ,'leadtime lat lon','Total Soil Moisture Content','soil_moisture_content','kg m-2','day','soil','land','','reftime realization time leadtime soildepth lat lon','leadtime: point soildepth: sum'],
    # ['RHOSNO','rhosn' ,'lnd','f8','leadtime lat lon','Snow Density','snow_density','kg m-3','day','surface','land','','reftime realization time leadtime lat lon','leadtime: point']
    # ]

    # C3S_table_lst=[
    # ['QOVER' ,'mrroas','lnd','f4','leadtime lat lon','Surface Run-off Amount','surface_runoff_amount','kg m-2','day','surface','land','*86400','reftime realization time leadtime lat lon','leadtime: sum'],
    # ['QDRAI' ,'mrroab','lnd','f4','leadtime lat lon','Subsurface Run-off Amount','subsurface_runoff_amount','kg m-2','day','surface','land','*86400','reftime realization time leadtime lat lon','leadtime: sum'],
    # ['H2OSNO','lwesnw','lnd','f4','leadtime lat lon','Liquid Water Equivalent Thickness of Surface Snow Amount','lwe_thickness_of_surface_snow_amount','m','day','surface','land','*0.001','reftime realization time leadtime lat lon','leadtime: point'],
    # ['H2OSOI2','mrlsl','lnd','f4','leadtime depth lat lon','Water Content per Unit Area of Soil Layers','moisture_content_of_soil_layer','kg m-2','day','soil','land','','reftime realization time leadtime depth lat lon','leadtime: point'],
    # ['RHOSNO','rhosn' ,'lnd','f4','leadtime lat lon','Snow Density','snow_density','kg m-3','day','surface','land','','reftime realization time leadtime lat lon','leadtime: point']
    # ]

    # WARNING ! any whitespace in clmC3Stable counts !!!
    clmC3Stable_file = pd.read_csv(clmC3Stable,sep=',', header=None)
    clmC3Stable_ftyp = clmC3Stable_file.loc[clmC3Stable_file.iloc[:, 14] == h_type]
    # Set NaN to empty list entry
    C3S_table_lst = clmC3Stable_ftyp.fillna('').values.tolist()

    #H2OSNO come in [mm] from CLM

    c3s_list = C3S_table_lst 
    # print(C3S_table_lst)
    # sys.exit()
    # log file
    if not dbmode:
        orig_stdout = sys.stdout
        full_logdir=logdir +'/'+forecast_t+'/'+ startdate
        createdir(full_logdir)
 
        f = open( full_logdir+ '/clm_postpc_C3S_' + ensemble + '_'+ h_type +'.log', 'w')
        sys.stdout = f

    # input file to be analyzed
    # sps3.5_201812_001.clm2.h1.reg1x1.nc
    files_type = ['clm2']
    files_from_model = input_file
    print(c3s_list)
    for c3s_elem in c3s_list:
        print('Start var',c3s_elem[0])

        var_name = c3s_elem[0]
        freq = c3s_elem[8]
        vars_list = var_name.split()
       
        
        create_c3s_var2(c3s_elem,files_from_model,ic,dbmode,modelname,output_dir,repo_dir,templfile,nlsl,lsmfile)

        print('Done var',c3s_elem[0])

    if not dbmode:        
        sys.stdout = orig_stdout
        f.close()
