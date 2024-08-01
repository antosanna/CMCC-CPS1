import os
import fnmatch
def find_files(file, path='.'):
    """
    Find files in a path matching a string.
    """
    files = fnmatch.filter(os.listdir(path), file)
    if len(files) == 0:
        raise InputError('[INPUTERROR] 0 Files found in the path matching file name')
    return(files)
