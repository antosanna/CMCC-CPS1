import numpy as np
def check_consistency_all_field_not_encoded(field, verbose, very_verbose):
    """
    Check if any value in field is invalid
    Note that field must be not encoded (i.e, fill value is a number and not nan) in order to be able to differentiate it from real nan
    """
    exc_list=[]
    
    if verbose or very_verbose:
        print('[INFO] Checking whole field consistency of', varname)

    # check if there is any not finite(nan or inf) value
    try:
        if np.any(~(np.isfinite(field))):
            pos = np.where(~(np.isfinite(field))==True)
            if verbose or very_verbose:  
                print('Consistency check failed on ',len(list(pos[0])),'points(s). Position(s):', list(pos))   
            raise FieldError('Invalid (nan or Inf) value on field')
    except FieldError as e:
        exc_list=print_error(error_message=e, error_list=exc_list, loc1=[shortname,varname])
        return(exc_list)
