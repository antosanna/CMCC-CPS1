import os
def check_path_exists(path):
    """
    Check if path exists.
    """
    if not (os.path.exists(path)):
        raise InputError('[INPUTERROR] Unknown file or path '+path)

