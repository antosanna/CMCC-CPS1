import os
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
