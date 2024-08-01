def get_lev_name(field):
    """
    Get name of level variable (expected in the first or second dimension)
    """
    if field.dims[0] in ('plev','depth'):
        levname = field.dims[0]
    elif field.dims[1] in ('plev','depth'):
        levname = field.dims[1]
    else:
        raise InputError('Unrecognized level variable name. Coordinate plev or depth is expected on the first or second position of the variable.')
    return levname
