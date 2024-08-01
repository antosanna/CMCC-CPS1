import os
import xarray as xr
import numpy as np
#import dask.array as da 
from qa_checker_lib.general_tools import print_error
from tabulate import tabulate
from qa_checker_lib.errors import *
from shutil import copyfile

def check_minmax_interval(field, fldmonmax, fldmonmin, tolerance_const,logdir, verbose=False, very_verbose=False, warning=False):
    """
    Check if field values are within interquantile interval Tukey (1977) 
    a value is defined as outlier if it exceeds one of the quantiles 
    for more than the quantile interval times mult_fact
    """
    raise_error=False
    exc_list=[]
    varname = field.long_name
    shortname = field.name
    print("test inside function " +shortname)
    fieldv=field.values

    if type(tolerance_const) == list:
       tolerance=np.zeros_like(fieldv)
       for i in range(len(tolerance_const)):
           #multiple level
           tolerance[:,i,:,:] += tolerance_const[i]
    else:
       tolerance=np.full_like(fieldv,tolerance_const)

    fieldmonmin=fldmonmin.values
    fieldmonmax=fldmonmax.values

    fieldmonmin_tol=fldmonmin.values - tolerance
    fieldmonmax_tol=fldmonmax.values + tolerance

    mult_fact=1.
    factor=np.full_like(fieldv,mult_fact)
    #factor=np.ones_like(fieldv)
    if shortname == "lwepr":
       fieldv=np.where(fieldv>=0.0002,fieldv,0.)
       fieldmonmin=np.where(fieldmonmin>=0.0002,fieldmonmin,0.)
       fieldmonmax=np.where(fieldmonmax>=0.0002,fieldmonmax,0.)
       fieldmonmin_tol=np.where(fieldmonmin_tol>=0.0002,fieldmonmin_tol,0.)
       fieldmonmax_tol=np.where(fieldmonmax_tol>=0.0002,fieldmonmax_tol,0.)

    interextr_interval=(fieldmonmax-fieldmonmin)*factor
    print("interextr_interval defined")
#define tow new empty arrays to fill with outliers
    upper_outliers=np.empty(np.shape(fieldv))
    lower_outliers=np.empty(np.shape(fieldv))
    upper_outliers_tol=np.empty(np.shape(fieldv))
    lower_outliers_tol=np.empty(np.shape(fieldv))

    try:

        upper_thresh=(fieldmonmax+interextr_interval)
        lower_thresh=np.where(fieldmonmin>=0.,fieldmonmin-interextr_interval,-(-fieldmonmin+interextr_interval))
        if shortname=='tso':
           lats=field.lat.values
           for lt in range(len(lats)):
              if np.abs(lats[lt]) < 59.0 :
                 upper_outliers[:,lt,:]=np.greater(np.round(fieldv[:,lt,:]),np.ceil(upper_thresh[:,lt,:]),where=True)
                 lower_outliers[:,lt,:]=np.less(np.round(fieldv[:,lt,:]),np.floor(lower_thresh[:,lt,:]),where=True)
        else:
           upper_outliers=np.greater(np.round(fieldv),np.ceil(upper_thresh),where=True)
           lower_outliers=np.less(np.round(fieldv),np.floor(lower_thresh),where=True)
           print("checked for outliers")

        upper_thresh_tol=(fieldmonmax_tol+interextr_interval)
        lower_thresh_tol=np.where(fieldmonmin_tol>=0.,fieldmonmin_tol-interextr_interval,-(-fieldmonmin_tol+interextr_interval))
        if shortname=='tso':
           lats=field.lat.values
           for lt in range(len(lats)):
              if np.abs(lats[lt]) < 59.0 :
                 upper_outliers_tol[:,lt,:]=np.greater(np.round(fieldv[:,lt,:]),np.ceil(upper_thresh_tol[:,lt,:]),where=True)
                 lower_outliers_tol[:,lt,:]=np.less(np.round(fieldv[:,lt,:]),np.floor(lower_thresh_tol[:,lt,:]),where=True)
        else:
           upper_outliers_tol=np.greater(np.round(fieldv),np.ceil(upper_thresh_tol),where=True)
           lower_outliers_tol=np.less(np.round(fieldv),np.floor(lower_thresh_tol),where=True)
           print("checked for outliers")

        table1=[]; table2=[]
        header=[]; table=[]
        tot_points=0
        if upper_outliers.any():
           print('inside if upper')
           pos=np.where(upper_outliers==True)
           pos_tol=np.where(upper_outliers_tol==True)
           argpos=np.argwhere(lower_outliers==True)
           argpos_tol=np.argwhere(lower_outliers_tol==True)
           tol_check=['']*len(pos[0])
           print('number points ',len(pos[0]))
           print('number points outside tol',len(pos_tol[0]))
           if len(pos_tol[0]) == len(pos[0]):
              tol_check=['outside']*len(pos[0])
           elif len(pos_tol[0])<len(pos[0]):
                tol_check=['inside']*len(pos[0])
                indici=[]
                for tollist in argpos_tol:
                   for i,notlist in enumerate(argpos):
                       print('we compare this')
                       print(tollist)
                       print('with this')
                       print(notlist)
                       if np.array_equal(tollist,notlist) :
                          indici.append(i)
                          break
                for j in indici:
                   tol_check[j]='outside'

           if pos_tol[0].size == 0:
              tol_check=['inside']*len(pos[0])

           print(tol_check)
           npoints=len(pos[0])
           tot_points+=npoints
           print("nmb of points over upper quantile ", tot_points)

           if shortname == 'tauu' or shortname=='tauv':
                  [table1, header]=make_clim_error_table_tol(field, field.dims,
                       fieldv,[upper_thresh,lower_thresh, fieldv-upper_thresh,tol_check],
                       npoints, pos,check_type='val>max',std_mult=None,verbose=True)
           else:
                 [table1, header]=make_clim_error_table_tol(field, field.dims,
                       fieldv,[np.ceil(upper_thresh), np.floor(lower_thresh), np.round(fieldv)-np.ceil(upper_thresh),tol_check],
                       npoints, pos,check_type='val>max',std_mult=None,verbose=True)

           raise_error=True

        tot_points=0
        if lower_outliers.any():
           print('inside if lower')
           pos=np.where(lower_outliers==True)
           pos_tol=np.where(lower_outliers_tol==True)
           argpos=np.argwhere(lower_outliers==True)
           argpos_tol=np.argwhere(lower_outliers_tol==True)
           tol_check=['']*len(pos[0])
           print('number points ',len(pos[0]))
           print('number points outside tol',len(pos_tol[0]))
           if len(pos_tol[0]) == len(pos[0]):
              tol_check=['outside']*len(pos[0])
           elif len(pos_tol[0])<len(pos[0]):
                tol_check=['inside']*len(pos[0])
                indici=[]
                for tollist in argpos_tol:
                   for i,notlist in enumerate(argpos):
                       #print('we compare this')
                       #print(tollist)
                       #print('with this')
                       #print(notlist)
                       if np.array_equal(tollist,notlist) :

                          indici.append(i)
                          break
                for j in indici:
                   tol_check[j]='outside'
                #for i in range(len(pos_tol[0])):
                #   print(argpos_tol[i])
                #   print("--------")
                #   tol_check[np.argwhere(np.array(argpos)==np.array(argpos_tol[i]))[0][0]]='outside'
                #   print(np.argwhere(argpos==argpos_tol[i]))
                #   print("--------")
           if pos_tol[0].size == 0:
              tol_check=['inside']*len(pos[0])  
         
           print(tol_check)
           npoints=len(pos[0])
           tot_points+=npoints
           print("nmb of points below lower quantile ", tot_points)

           if shortname == 'tauu' or shortname=='tauv':
                  [table1, header]=make_clim_error_table_tol(field, field.dims,
                       fieldv,[upper_thresh, lower_thresh,fieldv-lower_thresh,tol_check],
                       npoints, pos, check_type='val<min',std_mult=None,verbose=True)
           else:
                 [table1, header]=make_clim_error_table_tol(field, field.dims,
                       fieldv,[np.ceil(upper_thresh), np.floor(lower_thresh),np.round(fieldv)-np.floor(lower_thresh),tol_check],
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
           else:
              raise ThresholdError("One quantile has been exceeded")

    except ThresholdError as e:
        exc_list+=print_error(error_message=e, error_list=exc_list, loc1=[shortname, varname])


    return(exc_list, table, header)




def check_monthly_minmax(field,fldmonmax, fldmonmin,filemonmax,filemonmin,dsmax,dsmin,tmpdir,logdir, verbose=False, very_verbose=False, warning=False):

    raise_error=False
    exc_list=[]
    varname = field.long_name
    
    shortname = field.name
    fieldv=field.values
    fieldmonmin=fldmonmin.values 
    fieldmonmax=fldmonmax.values 
    if shortname == "lwepr":
       fieldv=np.where(fieldv>=0.0002,fieldv,0.)
   
    upper_outliers=np.empty(np.shape(fieldv))
    lower_outliers=np.empty(np.shape(fieldv))
    try:
       if shortname=='tso':
          lats=field.lat.values
          for lt in range(len(lats)):
             if np.abs(lats[lt]) < 59.0 :
                upper_outliers[:,lt,:]=np.greater(np.round(fieldv[:,lt,:]),np.ceil(fieldmonmax[:,lt,:]),where=True)
                lower_outliers[:,lt,:]=np.less(np.round(fieldv[:,lt,:]),np.floor(fieldmonmin[:,lt,:]),where=True) 
       else:  
          upper_outliers=np.greater(np.round(fieldv),np.ceil(fieldmonmax),where=True)
          lower_outliers=np.less(np.round(fieldv),np.floor(fieldmonmin),where=True) 
       # initialize table variables
       table1=[]; table2=[]
       header=[]; table=[]
       tot_points=0
       if upper_outliers.any():
          print('inside if upper')
          pos=np.where(upper_outliers==True)
          npoints=len(pos[0])
          tot_points+=npoints
          print("nmb of points over upper limit ", tot_points)
          if shortname == 'tauu' or shortname=='tauv':
                 [table1, header]=make_clim_error_table(field, field.dims,
                       fieldv,[fieldmonmax, fieldmonmin, fieldv-fieldmonmax],
                       npoints, pos, check_type='val>max',std_mult=None,verbose=True)
          else:
                 [table1, header]=make_clim_error_table(field, field.dims,
                       fieldv,[np.ceil(fieldmonmax), np.floor(fieldmonmin), np.round(fieldv)-np.ceil(fieldmonmax)],
                       npoints, pos, check_type='val>max',std_mult=None,verbose=True)           
          raise_error=True
          filename=filemonmax
          change_value(dsmax,shortname,fieldv,fldmonmax.dims,pos,filename,tmpdir,'max')

       tot_points=0
       if lower_outliers.any():
          print('inside if lower')
          pos=np.where(lower_outliers==True)
          npoints=len(pos[0])
          tot_points+=npoints
          print("nmb of points below lower limit ", tot_points)
          if shortname == 'tauu' or shortname=='tauv':
                 [table2, header]=make_clim_error_table(field, field.dims,
                    fieldv,[fieldmonmax, fieldmonmin,fieldv-fieldmonmin],
                    npoints, pos, check_type='val<min',std_mult=None,verbose=True)
          else:
                 [table2, header]=make_clim_error_table(field, field.dims,
                    fieldv,[np.ceil(fieldmonmax), np.floor(fieldmonmin),np.round(fieldv)-np.floor(fieldmonmin)],
                    npoints, pos, check_type='val<min',std_mult=None,verbose=True)
          raise_error=True
          filename=filemonmin
          change_value(dsmin,shortname,fieldv,fldmonmin.dims,pos,filename,tmpdir,'min')

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
           else:
              raise ThresholdError("Climatological range has been exceeded")

    except ThresholdError as e:
        exc_list+=print_error(error_message=e, error_list=exc_list, loc1=[shortname, varname])


    return(exc_list, table, header)

def check_monthly_minmax_tolerance(field,tolerance_const,fldmonmax, fldmonmin,filemonmax,filemonmin,dsmax,dsmin,tmpdir,logdir, verbose=False, very_verbose=False, warning=False):

    raise_error=False
    exc_list=[]
    varname = field.long_name

    shortname = field.name
    fieldv=field.values
    if type(tolerance_const) == list:
       tolerance=np.zeros_like(fieldv)
       for i in range(len(tolerance_const)):
           #multiple level
           tolerance[:,i,:,:] += tolerance_const[i]
    else:
       tolerance=np.full_like(fieldv,tolerance_const)
    fieldmonmin=(fldmonmin.values - tolerance)
    fieldmonmax=(fldmonmax.values + tolerance)
    if shortname == "lwepr":
       fieldv=np.where(fieldv>=0.0002,fieldv,0.)

    upper_outliers=np.empty(np.shape(fieldv))
    lower_outliers=np.empty(np.shape(fieldv))
    try:
       if shortname=='tso':
          lats=field.lat.values
          for lt in range(len(lats)):
             if np.abs(lats[lt]) < 60.0 :
                upper_outliers[:,lt,:]=np.greater(np.round(fieldv[:,lt,:]),np.ceil(fieldmonmax[:,lt,:]),where=True)
                lower_outliers[:,lt,:]=np.less(np.round(fieldv[:,lt,:]),np.floor(fieldmonmin[:,lt,:]),where=True)
       else:
          upper_outliers=np.greater(np.round(fieldv),np.ceil(fieldmonmax),where=True)
          lower_outliers=np.less(np.round(fieldv),np.floor(fieldmonmin),where=True)
       # initialize table variables
       table1=[]; table2=[]
       header=[]; table=[]
       tot_points=0
       if upper_outliers.any():
          print('inside if upper')
          pos=np.where(upper_outliers==True)
          npoints=len(pos[0])
          tot_points+=npoints
          print("nmb of points over upper limit ", tot_points)
          if shortname == 'tauu' or shortname=='tauv':
                 [table1, header]=make_clim_error_table(field, field.dims,
                       fieldv,[fieldmonmax, fieldmonmin, fieldv-fieldmonmax],
                       npoints, pos, check_type='val>max',std_mult=None,verbose=True)
          else:
                 [table1, header]=make_clim_error_table(field, field.dims,
                       fieldv,[np.ceil(fieldmonmax), np.floor(fieldmonmin), np.round(fieldv)-np.ceil(fieldmonmax)],
                       npoints, pos, check_type='val>max',std_mult=None,verbose=True)
          raise_error=True
          #filename=filemonmax
          #change_value(dsmax,shortname,fieldv,fldmonmax.dims,pos,filename,tmpdir,'max')

       tot_points=0
       if lower_outliers.any():
          print('inside if lower')
          pos=np.where(lower_outliers==True)
          npoints=len(pos[0])
          tot_points+=npoints
          print("nmb of points below lower limit ", tot_points)
          if shortname == 'tauu' or shortname=='tauv':
                 [table2, header]=make_clim_error_table(field, field.dims,
                    fieldv,[fieldmonmax, fieldmonmin,fieldv-fieldmonmin],
                    npoints, pos, check_type='val<min',std_mult=None,verbose=True)
          else:
                 [table2, header]=make_clim_error_table(field, field.dims,
                    fieldv,[np.ceil(fieldmonmax), np.floor(fieldmonmin),np.round(fieldv)-np.floor(fieldmonmin)],
                    npoints, pos, check_type='val<min',std_mult=None,verbose=True)
          raise_error=True
          #filename=filemonmin
          #change_value(dsmin,shortname,fieldv,fldmonmin.dims,pos,filename,tmpdir,'min')

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
           else:
              raise ThresholdError("Climatological range has been exceeded")

    except ThresholdError as e:
        exc_list+=print_error(error_message=e, error_list=exc_list, loc1=[shortname, varname])



def change_value(dss,vname,fvalue,dims,pos,filename,tmpdir,flag):
    copyfile(filename,tmpdir+os.path.basename(filename))
    ds=xr.open_dataset(tmpdir+os.path.basename(filename),decode_times=False)
    dslim2=ds[vname].values
    dslim=np.array(ds[vname].values)
    #here the input is the max or min datastructure to be replaced
    filenamenew=tmpdir+os.path.basename(filename)+"_new"
    if np.shape(pos)[0] == 3:
        
       i=np.shape(pos)[1]
       for i in range(np.shape(pos)[1]):
         
           if flag == 'max':
                valtosub=np.ceil(fvalue[pos[0][i],pos[1][i],pos[2][i]])
           elif flag == 'min':
                valtosub=np.floor(fvalue[pos[0][i],pos[1][i],pos[2][i]])
           else :
               valtosub=fvalue[pos[0][i],pos[1][i],pos[2][i]]
           dslim[pos[0][i],pos[1][i],:]=valtosub
    elif np.shape(pos)[0]==4:
       i=np.shape(pos)[1]
       for i in range(np.shape(pos)[1]):
             
           if flag == 'max':
                valtosub=np.ceil(fvalue[pos[0][i],pos[1][i],pos[2][i],pos[3][i]])
           elif flag == 'min':
                valtosub=np.floor(fvalue[pos[0][i],pos[1][i],pos[2][i],pos[3][i]])
           else :
               valtosub=fvalue[pos[0][i],pos[1][i],pos[2][i],pos[3][i]]
           dslim[pos[0][i],pos[1][i],pos[2][i],:]=valtosub
  
       
    #print('out from the loop')
    #print(dslim[pos[0][i],pos[1][i],pos[2][i]])
    #print(dslim2[pos[0][i],pos[1][i],pos[2][i]])
    #if (dslim != dslim2).any():
    #    print('at least a different one') 
    #    test=dslim
    #else:
    #    test=np.zeros_like(dslim)
    #    print('all the same')
    ds[vname].values[:]=dslim[:]
    ds.to_netcdf(path=filenamenew)

def check_interquantile_interval(field, fldmax, fldmonmax, quant_max, fldmin, fldmonmin, quant_min, lev4check,mult_fact, logdir, verbose=False, very_verbose=False, warning=False):
    """
    Check if field values are within interquantile interval Tukey (1977) 
    a value is defined as outlier if it exceeds one of the quantiles 
    for more than the quantile interval times mult_fact
    """
    raise_error=False
    exc_list=[]
    varname = field.long_name
    shortname = field.name
    print("test inside function ", lev4check)
    if lev4check==0:   #surf vars
        field4tab=field
        fieldv=field.values
        fieldmonmin=fldmonmin.values
        fieldmonmax=fldmonmax.values

    else:
        field4tab=field.sel(plev=lev4check*100)
        fieldv=field.sel(plev=lev4check*100).values
        fieldmonmin=fldmonmin.sel(plev=lev4check*100).values
        fieldmonmax=fldmonmax.sel(plev=lev4check*100).values


    qmax=quant_max.values
    qmin=quant_min.values
    factor=np.full_like(fieldv,mult_fact) 
    #factor=np.ones_like(fieldv) 
    if shortname == "lwepr":
       fieldv=np.where(fieldv>=0.0002,fieldv,0.) 
       
    interquant_interval=(qmax-qmin)*factor
    #interquant_interval=(fieldmonmax-fieldmonmin)*factor
    print("interquant_interval defined")
#define tow new empty arrays to fill with outliers
    upper_outliers=np.empty(np.shape(fieldv))
    lower_outliers=np.empty(np.shape(fieldv))

    try:

        upper_thresh=(fieldmonmax+interquant_interval)
        lower_thresh=np.where(fieldmonmin>=0.,fieldmonmin-interquant_interval,-(-fieldmonmin+interquant_interval))
        
        if shortname=='tso':
           lats=field.lat.values
           for lt in range(len(lats)):
              if np.abs(lats[lt]) < 59.0 :
                 upper_outliers[:,lt,:]=np.greater(np.round(fieldv[:,lt,:]),np.ceil(upper_thresh[:,lt,:]),where=True)
                 lower_outliers[:,lt,:]=np.less(np.round(fieldv[:,lt,:]),np.floor(lower_thresh[:,lt,:]),where=True)
        else:
           upper_outliers=np.greater(np.round(fieldv),np.ceil(upper_thresh),where=True)
           lower_outliers=np.less(np.round(fieldv),np.floor(lower_thresh),where=True)
           print("checked for outliers")
# first test if value exceeds hindcast max
        #above_max=np.where(fieldv>fieldmonmax,fieldv,np.nan)   
#then tests it against quantile
        #upper_outliers=np.greater(above_max,upper_thresh,where=True)
# first test if value exceeds hindcast min
        #below_min=np.where(fieldv<fieldmonmin,fieldv,np.nan)   
#then tests it against quantile
        #lower_outliers=np.less(below_min,lower_thresh,where=True)
        # initialize table variables
        table1=[]; table2=[]
        header=[]; table=[]
        tot_points=0
        if upper_outliers.any():
           print('inside if upper')
           pos=np.where(upper_outliers==True)
           npoints=len(pos[0])
           tot_points+=npoints
           print("nmb of points over upper quantile ", tot_points)  

           if shortname == 'tauu' or shortname=='tauv':
                  [table1, header]=make_clim_error_table(field, field.dims,
                       fieldv,[upper_thresh,lower_thresh, fieldv-upper_thresh],
                       npoints, pos, check_type='val>max',std_mult=None,verbose=True)
           else:
                 [table1, header]=make_clim_error_table(field, field.dims,
                       fieldv,[np.ceil(upper_thresh), np.floor(lower_thresh), np.round(fieldv)-np.ceil(upper_thresh)],
                       npoints, pos, check_type='val>max',std_mult=None,verbose=True)

           raise_error=True

        tot_points=0
        if lower_outliers.any():
           print('inside if lower')
           pos=np.where(lower_outliers==True)
           npoints=len(pos[0])
           tot_points+=npoints
           print("nmb of points below lower quantile ", tot_points)  

           if shortname == 'tauu' or shortname=='tauv':
                  [table1, header]=make_clim_error_table(field, field.dims,
                       fieldv,[upper_thresh, lower_thresh,fieldv-lower_thresh],
                       npoints, pos, check_type='val<min',std_mult=None,verbose=True)
           else:
                 [table1, header]=make_clim_error_table(field, field.dims,
                       fieldv,[np.ceil(upper_thresh), np.floor(lower_thresh),np.round(fieldv)-np.floor(lower_thresh)],
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
           else:
              raise ThresholdError("One quantile has been exceeded")
             
    except ThresholdError as e:
        exc_list+=print_error(error_message=e, error_list=exc_list, loc1=[shortname, varname])


    return(exc_list, table, header)

def check_interquantile_interval_prec(field, fldmax, quant_max, fldmean, fldmin, quant_min, mult_fact, logdir, verbose=False, very_verbose=False, warning=False):
    """
    Check if field values are within interquantile interval Tukey (1977) 
    a value is defined as outlier if it exceeds one of the quantiles 
    for more than the quantile interval times mult_fact
    Here modified to account for Gamma distribution and extended right queue:
    interquantile range replace by qmax-mean
    """
    print('inside prec check function') 
    raise_error=False
    exc_list=[]
    varname = field.long_name
    shortname = field.name
    fieldv=field.values
    qmax=quant_max.values
    qmin=quant_min.values
    factor=np.full_like(fieldv,mult_fact) 
    print('before if lwepr')
    if shortname == "lwepr":
       print ('inside lwepr precision condition')
       fieldv=np.where(fieldv>=0.0002,fieldv,0.) 

    low_interquant_interval=(qmax-qmin)*factor
    print("low interquant_interval defined")
    up_interquant_interval=(fldmax.values-fldmean.values)*factor
    print("up interquant_interval defined")
#define tow new empty arrays to fill with outliers
    upper_outliers=np.empty(np.shape(fieldv))
    print("upper_outliers defined")
    lower_outliers=upper_outliers

    try:
        upper_thresh=(fldmax.values+up_interquant_interval)
        lower_thresh=np.where(qmin>=0.,qmin-low_interquant_interval,-(-qmin+low_interquant_interval))
# first test if value exceeds hindcast max
        above_max=np.where(fieldv>fldmax.values,fieldv,np.nan)   
#then tests it against quantile
        upper_outliers=np.greater(above_max,upper_thresh,where=True)   
# first test if value exceeds hindcast min
        below_min=np.where(fieldv<fldmin.values,fieldv,np.nan)   
#then tests it against quantile
        lower_outliers=np.less(below_min,lower_thresh,where=True)   

        # initialize table variables
        table1=[]; table2=[]
        header=[]; table=[]
        tot_points=0
        if upper_outliers.any():
           print('inside if upper')
           pos=np.where(upper_outliers==True)
           npoints=len(pos[0])
           tot_points+=npoints
           print("nmb of points over upper quantile ", tot_points)  
           [table1, header]=make_clim_error_table(field, field.dims,
                    fieldv, 
                    [ fldmonmax.values,fldmonmin.values, up_interquant_interval ], 
                    npoints, pos, check_type='val>upper_quantile',std_mult=None,verbose=True)
           raise_error=True

        tot_points=0
        if lower_outliers.any():
           print('inside if lower')
           pos=np.where(lower_outliers==True)
           npoints=len(pos[0])
           tot_points+=npoints
           print("nmb of points below lower quantile ", tot_points)  
           [table2, header]=make_clim_error_table(field, field.dims,
                    fieldv, 
                    [ fldmonmax.values, fldmonmin.values, low_interquant_interval ], 
                    npoints, pos, check_type='val<lower_quantile',std_mult=None,verbose=True)
           raise_error=True
        print('everything fine here')
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
              raise ThresholdError("One quantile has been exceeded")
             
    except ThresholdError as e:
        exc_list+=print_error(error_message=e, error_list=exc_list, loc1=[shortname, varname])


    return(exc_list, table, header)

def check_climatology_minmax(field, fieldmax, fieldmin,threshold_const,flag_rev, logdir, verbose=False, very_verbose=False, warning=False):
    """
    Check if field values are within min/max climatological values
    As check_climatological_ranges() but only for min/max
    """
    varname = field.long_name
    shortname = field.name
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
        threshold=np.full_like(field.values,threshold_const)  #order of magnitude
        #threshold_neg=np.full_like(field.values,-0.02)
        
        # in a positive word, this works! 
        #min_le_cmin=np.less((field.values-fieldmin.values)/fieldmin.values,threshold_neg,where=True)

        #reversed order in the difference to avoid absolute value (requiring too much memory)
        min_le_cmin1=np.greater((fieldmin.values-field.values)/np.abs(fieldmin.values),threshold,where=True)   #WORKING!!!
        max_ge_cmax1=np.greater((field.values-fieldmax.values)/fieldmax.values,threshold, where=True)
        
        if flag_rev != 0 :
           newmin=np.where(np.logical_and(min_le_cmin1,-fieldmax.values < fieldmin.values),-fieldmax.values,fieldmin.values)
           newmax=np.where(np.logical_and(max_ge_cmax1,-fieldmin.values>fieldmax),-fieldmin.values,fieldmax.values)
           min_le_cmin=np.greater((newmin-field.values)/np.abs(newmin),threshold,where=True)   #WORKING!!!
           max_ge_cmax=np.greater((field.values-newmax)/newmax,threshold, where=True)
        else:
           min_le_cmin=min_le_cmin1
           max_ge_cmax=max_ge_cmax1

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
        threshold=da.full_like(field,0.05)
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



def make_clim_error_table_tol(fullfield, dims, value, limits, npoints, pos, check_type, std_mult=None, verbose=True):
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
    flimit=limits[2]
    ftol=limits[3]
    # create header (the same for all functions)
    startfill=5
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
    if check_type == "val<min" or check_type == "val>max" :
       header.extend(['max'])
       header.extend(['min'])
       header.extend(['delta'])
       header.extend(['tolerance'])

    # fill table values (limit,mean,std columns are empty for check_climatology_minmax() )
    table_values = [ [ None for y in range( startfill+len(limits) ) ]for x in range( npos ) ]

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
                line_values+=[str(fullfield[dims[x]].values[pos[x][i]]/100)+"hPa"]
            else:
                line_values+=[str(fullfield[dims[x]].values[pos[x][i]])]
        #point value, limit, mean, std, max, min
        #string depends on variable dimensions

        if len(dims) == 4:
            line_values+=[str(value[pos[0][i],pos[1][i],pos[2][i],pos[3][i]])]
            line_values+=[str(fmax[pos[0][i],pos[1][i],pos[2][i],pos[3][i]])]
            line_values+=[str(fmin[pos[0][i],pos[1][i],pos[2][i],pos[3][i]])]
            line_values+=[str(flimit[pos[0][i],pos[1][i],pos[2][i],pos[3][i]])]
            line_values+=[ftol[i]]

        if len(dims) == 3:
            line_values+=[str(value[pos[0][i],pos[1][i],pos[2][i]])]
            line_values+=[str(fmax[pos[0][i],pos[1][i],pos[2][i]])]
            line_values+=[str(fmin[pos[0][i],pos[1][i],pos[2][i]])]
            line_values+=[str(flimit[pos[0][i],pos[1][i],pos[2][i]])]
            line_values+=[ftol[i]]

        if len(dims) == 2:
            line_values+=[str(value[pos[0][i],pos[1][i]])]
            line_values+=[str(fmax[pos[0][i],pos[1][i]])]
            line_values+=[str(fmin[pos[0][i],pos[1][i]])]
            line_values+=[str(flimit[pos[0][i],pos[1][i]])]
            line_values+=[ftol[i]]


        # add line to table
        table_values[i]=line_values

    if verbose:
        if len(table_values)>10:
            print('First 10 points:')
            print(tabulate(table_values[0:10], headers=header, tablefmt='fancy_grid', missingval='N/A',))
        else:
            print(tabulate(table_values, headers=header, tablefmt='fancy_grid', missingval='N/A',))

    return(table_values, header)






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

    if len(limits) > 3:
        flimit=limits[2]
        fmean=limits[3]
        fstd=limits[4]
        print('=====')
        print(np.shape(fmean))
        print(np.shape(fmax))
        print(np.shape(fstd))
        print('pos:')
        print(pos)
    elif len(limits)==3:
        flimit=limits[2] 
    # create header (the same for all functions)
    startfill=5
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
    if check_type == "val<min" or check_type == "val>max" :
       header.extend(['max'])
       header.extend(['min'])
       header.extend(['delta'])
    elif check_type == "val>upper_quantile" or check_type == "val<lower_quantile":
       header.extend(['max'])
       header.extend(['min'])
       header.extend(['clim_range'])
#    header.extend(['interq_range'])
    header.extend(['mean+/-'+str(std_mult)+'std'])
    header.extend(['mean'])
    header.extend(['std'])

    # fill table values (limit,mean,std columns are empty for check_climatology_minmax() )
    table_values = [ [ None for y in range( startfill+len(limits) ) ]for x in range( npos ) ]

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
                line_values+=[str(fullfield[dims[x]].values[pos[x][i]]/100)+"hPa"]
            else:
                line_values+=[str(fullfield[dims[x]].values[pos[x][i]])]
        #point value, limit, mean, std, max, min
        #string depends on variable dimensions

        if len(dims) == 4:
            line_values+=[str(value[pos[0][i],pos[1][i],pos[2][i],pos[3][i]])]
            line_values+=[str(fmax[pos[0][i],pos[1][i],pos[2][i],pos[3][i]])]
            line_values+=[str(fmin[pos[0][i],pos[1][i],pos[2][i],pos[3][i]])]
            if len(limits) == 3:
                line_values+=[str(flimit[pos[0][i],pos[1][i],pos[2][i],pos[3][i]])]
            elif len(limits) >3 :
                line_values+=[str(flimit[pos[0][i],pos[1][i],pos[2][i],pos[3][i]])]
                line_values+=[str(fmean[pos[0][i],pos[1][i],pos[2][i],pos[3][i]])]
                line_values+=[str(fstd[pos[0][i],pos[1][i],pos[2][i],pos[3][i]])]

        if len(dims) == 3:
            line_values+=[str(value[pos[0][i],pos[1][i],pos[2][i]])]
            line_values+=[str(fmax[pos[0][i],pos[1][i],pos[2][i]])]
            line_values+=[str(fmin[pos[0][i],pos[1][i],pos[2][i]])]
            if len(limits) ==3 :
               line_values+=[str(flimit[pos[0][i],pos[1][i],pos[2][i]])]
            elif len(limits) > 3:
                line_values+=[str(flimit[pos[0][i],pos[1][i],pos[2][i]])]
                line_values+=[str(fmean[pos[0][i],pos[1][i],pos[2][i]])]
                line_values+=[str(fstd[pos[0][i],pos[1][i],pos[2][i]])]

        if len(dims) == 2:
            line_values+=[str(value[pos[0][i],pos[1][i]])]
            line_values+=[str(fmax[pos[0][i],pos[1][i]])]
            line_values+=[str(fmin[pos[0][i],pos[1][i]])]
            if len(limits) ==3:
               line_values+=[str(flimit[pos[0][i],pos[1][i]])]
            if len(limits) >3:
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
