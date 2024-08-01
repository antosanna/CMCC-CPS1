def print_error(error_message, error_list, loc1, loc2=None, loc3=None, loc4=None, warning=False):
    """
    Prints FIELDERROR message with location information to screen and populates error_list to be written in log file
    error_message: string with error details
    error_list: array where to append the error_message
    loc1: [shortname, varname]
    loc2, loc3, loc4: optional arrays with [dimname,value] for complex messages (i.e, multidimensional checks)
    warning: if True, then print a warning insted of an error
    """
    if warning is True:
        error_type='FIELDWARNING'
    else:
        error_type='FIELDERROR'

    message='\n['+error_type+']  >> '+str(error_message)+' << Located at '+loc1[0]+' ('+loc1[1]+') '+'\n'

    for loc in [loc2,loc3,loc4]:
        if loc is not None:
            message=message+', '+loc[0]+': ['+str(loc[1])+']'

    print(message)
    error_list.append(message)
    return(error_list)
