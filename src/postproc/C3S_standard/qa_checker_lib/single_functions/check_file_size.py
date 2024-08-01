import os
def check_file_size(file, min_size=0):
    """
    Check file size.
    """
    if os.stat(file).st_size <= min_size:
        raise InputError('[INPUTERROR] File Size error')
