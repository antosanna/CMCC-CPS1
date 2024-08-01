def check_2d_field(field, filling_value, constant_limit):
    import numpy as np
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
