def get_time_name(field):
    """
    Get name of time variable. Note that time is expected to be the first dimension.
    """
    timename = field.dims[0]
    if timename not in ('time','leadtime'):
        raise InputError('Unrecognized time variable name. Coordinate time or leadtime is expected on the first position of the variable.')
    return timename

