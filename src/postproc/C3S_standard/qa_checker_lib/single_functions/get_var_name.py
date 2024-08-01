def get_var_name(field):
    """
    Get var name.
    """
    try:
        fieldname = field.standard_name
        return (fieldname) 
    except AttributeError:
        fieldname = field.long_name
        return (fieldname) 
    except:
        raise InputError('[INPUTERROR] Unrecognized variable name')

