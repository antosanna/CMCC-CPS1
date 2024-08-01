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
        except:
            raise InputError('Error splitting file name. File name must match expected format for SPS3.5 DMO: [preffix]_[yyyymm]_[member].[suffix].nc')

    return(lab_tmp, lab_preffix, lab_std,lab_year, lab_month, lab_mem)
