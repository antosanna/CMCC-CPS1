import fnmatch
import os
import re
from qa_checker_lib.errors import *

def check_emails(fromaddr, toaddrs):
    """ 
    Check correctness of 2 email addresses provided.
    """
    regex = '^\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+$'
    if (re.search(regex,fromaddr)):
        pass
    else:  
        raise ProgramError('[PROGRAMERROR] in function check_emails(). Error in sender email')
    recipient=0
    while recipient < len(toaddrs.split(',')):
        if (re.search(regex,toaddrs.split(',')[recipient])):
            pass
        else:  
            raise ProgramError('[PROGRAMERROR] in function check_emails(). Error in recipient mail')
        recipient += 1

def check_path_exists(path):
    """ 
    Check if path exists.
    """
    if not (os.path.exists(path)):
        raise InputError('[INPUTERROR] Unknown file or path '+path)

def check_file_size(file, min_size=0):
    """ 
    Check file size.
    """
    if os.stat(file).st_size <= min_size:
        raise InputError('[INPUTERROR] File Size error')

def write_log(logname, filename, loglist, verbose=False, very_verbose=False):
    """ 
    Removes log file if exists and write new log with error list
    """
    if os.path.exists(logname):
        os.remove(logname) #this deletes the file if exists
    if verbose or very_verbose:
        print("[INFO] Writing log: "+logname)
    with open(logname, "a") as f:
        f.writelines("####################\n")
        f.writelines("File checked: "+filename+"\n")
        f.writelines("#####################\n")
        for item in loglist:
            f.writelines(item)   

def find_files(file, path='.'):
    """ 
    Find files in a path matching a string.
    """
    files = fnmatch.filter(os.listdir(path), file)
    if len(files) == 0:
        raise InputError('[INPUTERROR] 0 Files found in the path matching file name')
    return(files)   

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

def get_labels_from_filename(file, varname, filename_types):
    """
    Extract information from filename.
    The extraction is done by position, so it depends on the filename convention. 
    Actually only 2 types of files are accepted. The variables names of each type of file are listed 
    in the json file under C3Svars and DMOvars. If you want to add a different type of file, add a new list to the json,
    add a new entry to the if cycle on this function and a new filename_type in calling this function.
    Inputs:
        - file: filename
        - varname: variable name
        - filename_types: tuple with types of files codified in json table (i.e., [C3Svars, DMOvars])
    """
    lab_tmp = file.split("_")
    if varname in filename_types[0]:
        #C3Svars filename convention [model]_[version]_[typeofrun]_S[yyyymmddss]_[realm]_[freq]_[pressure]_[var]_[suffix].nc')
        try:
            lab_std     = lab_tmp[3][1:7]
            lab_year    = lab_std[0:4]
            lab_month   = lab_std[4:6]
            lab_mem     = lab_tmp[8].split(".")[0][1:3]
#            lab_preffix = lab_tmp[0]+"_"+lab_tmp[1]+"_"+lab_tmp[2]
            lab_preffix = lab_tmp[0]+"_"+lab_tmp[1]+"_hindcast"
            lab_nohind=lab_tmp[0]+"_"+lab_tmp[1]
        except:
            raise InputError('Error splitting file name. File name must match expected format for SPS3.5 C3S: [model]_[version]_[typeofrun]_S[yyyymmddss]_[realm]_[freq]_[pressure]_[var]_[suffix].nc')
    elif varname in filename_types[1]:
        #DMOvars filename convention [preffix]_[yyyymm]_[member].[suffix].nc
        try:
            lab_std     = lab_tmp[1]
            lab_year    = lab_std[0:4]
            lab_month   = lab_std[4:6]
            lab_mem     = lab_tmp[2].split(".")[0]
            lab_preffix = lab_tmp[0]
            lab_nohind=lab_preffix
        except:
            raise InputError('Error splitting file name. File name must match expected format for SPS3.5 DMO: [preffix]_[yyyymm]_[member].[suffix].nc')

    return(lab_tmp, lab_preffix, lab_nohind,lab_std,lab_year, lab_month, lab_mem)                                                    
