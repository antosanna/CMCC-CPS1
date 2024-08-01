import numpy as np
import warnings

def check_minmax(field, checktype, limit, levname=None, verbose=False, very_verbose=False, warning=True):
    """
    Check if minimum/maximum value is lower/higher than given limit.
    Inputs: 
        field: variable to check
        checktype: minimum or maximum
        limit: a number with the limit value for the check. If levname is defined, then is must be a vector of limit values for each level of field which length must coincide with the field level/depth dimension
        levname: if indicated, name of dimension to be checked on which limit values are given
        verbose: True/False 
        very_verbose: True/False 
        warning: print a warning to the screen instead of raising an error
    """
    varname = field.long_name
    shortname = field.name
    if levname is None:
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
                    war_message=' [FIELDWARNING]  >> Field '+shortname+' ('+varname+') '+checktype+' lower than limit '+str(limit)+' on '+str(len(list(pos)))+' points among which the '+checktype+' value is: '+str(abs_val)+'\n'
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
                    war_message=' [FIELDWARNING]  >> Field '+shortname+' ('+varname+') '+checktype+' higher than limit '+str(limit)+' on '+str(len(list(pos)))+' points among which the '+ checktype+' value is: '+str(abs_val)+'\n'
                    print(war_message)
                else:
                    raise FieldError('Field '+checktype+' higher than limit '+str(limit)+' on '+str(len(list(pos)))+' points.')
    else:
        # Loof for any values exceeding limit by level
        if len(field.coords[levname]) != len(limit):
            raise InputError('Lenght of limit vector must be equal to number of levels of variable in check_minmax() function')
        error_list=[]
        for p in range(0, len(field.coords[levname])):
            if very_verbose:
                print('....Checking level:',levname,'[',p,'] with limit', str(limit[p]))
            
            if levname=='plev':
                fieldbylev = field.isel(plev=p)
            elif levname=='depth':
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
                war_message=' [FIELDWARNING]  >> Field '+shortname+' ('+varname+') '+checktype,' exceeding in lev(s): ['+error_list_string+']'
                warnings.warn(war_message)
            else:
                raise FieldError('Field '+shortname+'('+varname+') '+checktype +' exceeding limit in lev(s): ['+error_list_string+']')

