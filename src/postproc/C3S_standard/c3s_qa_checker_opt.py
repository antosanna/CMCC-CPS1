#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Perform a series of quality checks on SPS3.5 data. Input data can be:
    raw model output
    model output for C3S

@author: Maria del Mar Chaves Montero @ CMCC, CSP division Nov 2019
"""
# ==========================================================================
# Preamble
# ==========================================================================
import os
import sys
import json
import time
import traceback
import tracemalloc
import warnings

import xarray as xr
from tabulate import tabulate

from qa_checker_lib.argParser import argParser

from qa_checker_lib.general_tools import (
    check_emails,
    check_path_exists,
    find_files,
    check_file_size,
    print_error,
    write_log,
    get_labels_from_filename,
)

from qa_checker_lib.var_tools import (
    get_var_name,
    get_time_name,
    get_lev_name,
    var_in_list,
    sel_field_slice,
)

from qa_checker_lib.checker_tools import (
    check_minmax,
    check_tsd_34dfield,
    check_consistency_all_field_not_encoded,
    check_2d_field,
    check_field,
)
from qa_checker_lib.checker_tools_onlyspike import (
    check_temp_spike,
    check_temp_spike_new,
    find_coord_dmo,
)

from qa_checker_lib.clim_checker_tools import (
    check_minmax_interval,
    check_climatological_ranges,
    check_interquantile_interval,
    check_interquantile_interval_prec,
    check_climatology_minmax,
    check_climatology_minmax_vect,
    check_monthly_minmax,
    make_clim_error_table,
    make_clim_error_table_tol,
    change_value,
)

from qa_checker_lib.errors import *

# Help message shown when a pair of climatological files cannot be located.
_CLIM_FILES_HELP = (
    "[INFO] Files for climatological range must follow some rules:",
    "   Two files are expected: one with the mean and one with the standard deviation",
    "   All climatological files contain a variable with same name and dimensions than the checked variable",
    "   Files must be named as follows: ",
    "        [preffix]_[startdate].[hindcast-period]_[shortname]_min.nc",
    "        [preffix]_[startdate].[hindcast-period]_[shortname]_max.nc",
    "        [preffix]_[startdate].[hindcast-period]_[shortname]_emean_highfreq.nc",
    "        i.e cmcc_CMCC-CM3-v20231101_hindcast_11.1995-2024_hus_min.nc",
)

_QUANTILE_FILES_HELP = (
    "[INFO] Files for quantile check range are selected according to the quantile value input,",
    "   which expresses the lower quantile value.",
    "   Files must be named as follows: ",
    "        [preffix]_[startdate].[hindcast-period]_[shortname]_[quantile value]quantile.nc",
    "        [preffix]_[startdate].[hindcast-period]_[shortname]_[1 - quantile value]quantile.nc",
    "        i.e cmcc_CMCC-CM3-v20231101_hindcast_11.1995-2024_hus_0.10quantile.nc",
)


def open_clim_pair(path_clim, lab_month, shortname, file_max, file_min,
                    verbose, very_verbose, decode_times=True, help_msg=_CLIM_FILES_HELP):
    """
    Locate and open a pair of climatological reference files (max/min).

    Centralizes the "check existence -> open" pattern that used to be
    duplicated (with the same error message copy-pasted) for the yearly
    climatology, the monthly climatology and the quantile files.

    Returns (ds_max, ds_min, path_max, path_min).
    Raises InputError if either file is missing.
    """
    dir_path = os.path.join(path_clim, lab_month, shortname)
    path_max = os.path.join(dir_path, file_max)
    path_min = os.path.join(dir_path, file_min)

    try:
        if very_verbose:
            print(f"....Looking for climatological files at {dir_path}")
        check_path_exists(path_min)
        check_path_exists(path_max)
    except Exception:
        if verbose:
            for line in help_msg:
                print(line)
        raise InputError(
            f"Cannot open one or more climatological files in {dir_path} \n"
            f"{file_min}, \n{file_max}"
        )

    ds_max = xr.open_dataset(path_max, decode_times=decode_times)
    ds_min = xr.open_dataset(path_min, decode_times=decode_times)
    return ds_max, ds_min, path_max, path_min


# ==========================================================================
# Main function
# ==========================================================================

def main():
    # Ignore warnings
    warnings.filterwarnings("ignore")

    # Read arguments
    args = argParser()

    # Trace program timing
    start_time = time.process_time()

    # Trace program memory allocation
    if args.trace_mem:
        tracemalloc.start()

    # Read json table with external arguments
    check_path_exists(args.json)

    print("[INFO] Reading json table: ", args.json)
    try:
        with open(args.json, "r") as read_file:
            json_table = json.load(read_file)
        hindcast_period    = json_table["hindcast_period"]
        system             = json_table["system"]
        C3Svars            = json_table["checks"]["C3S_variables"]
        DMOvars            = json_table["checks"]["DMO_variables"]
        masked_vars        = json_table["checks"]["masked_vars"]
        excluded_vars      = json_table["checks"]["excluded_vars"]
        min_checked_vars   = json_table["checks"]["min_checked_vars"]
        max_checked_vars   = json_table["checks"]["max_checked_vars"]
        tsd_checked_vars   = json_table["checks"]["tsd_checked_vars"]
        spike_checked_vars = json_table["checks"]["spike_checked_vars"]
        clim_checked_vars  = json_table["checks"]["clim_checked_vars"]
    except Exception:
        if args.verbose:
            traceback.print_exc()
        raise InputError("Cannot read json file or its content")

    # Read file(s) to check
    check_path_exists(args.path)
    files = find_files(args.file, args.path)

    # Print list of file(s)
    print("[INFO] Processing file:" if len(files) <= 1 else "[INFO] List of files:")
    print(files)
    print("")

    # Fix suffix variables for output naming
    # Add underscore to suffix and prefix if present
    # TODO maybe exp, real can be taken from file name instead of external argument?
    exp = f"_{args.log_exp_suffix}" if args.log_exp_suffix else args.log_exp_suffix
    real = f"_{args.log_real_suffix}" if args.log_real_suffix else args.log_real_suffix
    # If there is more than 1 file the output needs a suffix, otherwise it will be overwritten!
    file_suffix = "_f" if len(files) > 1 else ""

    # Loop on file(s)
    for f in range(len(files)):

        if len(files) > 1 and args.verbose:
            print("[INFO] Processing file:")
            print(files[f])

        # Check file size > 0
        try:
            check_file_size(os.path.join(args.path, files[f]))
        except InputError as e:
            print("[INPUTERROR] >>", str(e))

        # Initialize error list for file
        file_output_list = []

        # Quality checks on file
        try:
            # Read the file
            DS = xr.open_dataset(os.path.join(args.path, files[f]), decode_times=False)

            # Get the list of variables to check: selected variable OR all
            # variables in the file (except coordinates/bounds)
            varlist = [args.var, None] if args.var is not None else list(DS.data_vars.keys())

            print("varlist:")
            print(varlist)

            # Loop on variable(s)
            for v in varlist:
                if v is None or v in excluded_vars or (v not in C3Svars and v not in DMOvars):
                    continue

                # Initialize error list variables for each variable in file
                error_in_var = False
                ice_spike_list = []
                spike_error_list = []
                spikemin_list = []
                spikeright_list = []
                spikeleft_list = []
                dropT_list = []
                coord_list = []
                consistency_list = []
                generallist = []
                climlist = []
                table_values = []
                table_header = []
                # TODO REMOVE ALL climlist2
                climlist2 = []
                table_values2 = []
                table_header2 = []

                # Get some info about the variable
                varname = get_var_name(DS[v])
                shortname = DS[v].name
                timename = None
                levname = None
                if shortname not in ("orog", "sftlf"):
                    timename = get_time_name(DS[v])
                if "plev" in DS.dims or "depth" in DS.dims:
                    levname = get_lev_name(DS[v])
                print("[INFO] Variable ", shortname, DS[v].dims)
                print("[INFO] Variable ", shortname, " shape", DS[v].shape, "\n")

                # Get label information from file name.
                # This is a critical point that limits the application of this
                # program to files that follow a specific naming convention
                # (CMCC SPS3.5 DMO/C3S data). For adding new filename types,
                # see get_labels_from_filename().
                lab_tmp, lab_preffix, lab_nohind, lab_std, lab_year, lab_month, lab_mem = \
                    get_labels_from_filename(files[f], v, [C3Svars, DMOvars])
                print("tmp:");   print(lab_tmp)
                print("std:");   print(lab_std)
                print("year:");  print(lab_year)
                print("month:"); print(lab_month)
                print("mem:");   print(lab_mem)

                # Set flags for var min/max/time sd that must be checked
                check_min   = var_in_list(v, min_checked_vars)
                check_max   = var_in_list(v, max_checked_vars)
                check_tsd   = var_in_list(v, tsd_checked_vars)
                check_spike = var_in_list(v, spike_checked_vars)
                print(spike_checked_vars)
                check_clim  = var_in_list(v, clim_checked_vars)

                # Get min/max limits for var
                minlim = min_checked_vars[shortname] if check_min else None
                maxlim = max_checked_vars[shortname] if check_max else None
                min4spike = 180  # min limit from json in the next future
                # Get level for climatological check
                lev4check = clim_checked_vars[shortname][0] if check_clim else None
                tolerance  = clim_checked_vars[shortname][1] if check_clim else None

                if args.only_spike:
                    check_min = False
                    check_max = False
                    check_tsd = False
                    check_clim = False

                # Get fill_value or default
                if var_in_list(v, masked_vars):
                    fill_value = DS[v].encoding["_FillValue"]
                else:
                    fill_value = 1e+20

                # Consistency check on all fields on NON-DECODED DATA, to avoid
                # _FillValue being turned into nan by xarray's encoding (which
                # would make it indistinguishable from actual nans).
                with xr.open_dataset(os.path.join(args.path, files[f]),
                                      decode_times=False, decode_cf=False) as DSnotdecoded:
                    consistency_list = check_consistency_all_field_not_encoded(
                        DSnotdecoded[v], varname, shortname,
                        verbose=args.verbose, very_verbose=args.very_verbose)

                print("consistencylist:")
                print(consistency_list)

                # General checks
                generallist = check_field(
                    DS[v], varname, shortname, timename, levname,
                    filling_value=fill_value, constant_limit=1e-9,
                    check_min=check_min, min_limit=minlim,
                    check_max=check_max, max_limit=maxlim,
                    check_tsd=check_tsd, tsd_limit=0,
                    verbose=args.verbose, very_verbose=args.very_verbose)
                print("generallist:")
                print(generallist)

                # Spike check
                if check_spike:
                    if args.verbose:
                        print(f"[INFO] Performing spike diagnostic with threshold "
                              f"d1={args.delta1} and d2={args.delta2}")
                    if shortname in ("TREFMNAV", "tasmin"):
                        (ice_spike_list, spikemin_list, spikeright_list, spikeleft_list,
                         dropT_list, spike_error_list) = check_temp_spike_new(
                            varname, shortname, timename, files[f], spike_error_list,
                            field1=DS[v], min_limit1=min4spike,
                            delta_limit1=float(args.delta1), delta_limit2=float(args.delta2),
                            verbose=args.verbose, very_verbose=args.very_verbose)
                    else:
                        raise InputError("Spike check in this variable has not been implemented")

                # Climatology range check
                if check_clim and args.path_clim and args.quantile_value:
                    print("[INFO] Performing quantile interval check")
                    low_quantile = float(args.quantile_value)
                    high_quantile = round(1. - low_quantile, 2)
                    str_high_quantile = f"{high_quantile:.2f}"
                    str_low_quantile = f"{low_quantile:.2f}"

                    # Build quantile file names
                    if lev4check == 0:
                        file_quant_max = f"{lab_preffix}_{lab_month}.{hindcast_period}_{shortname}_{str_high_quantile}quantile_max.monthly.C3S.nc"
                        file_quant_min = f"{lab_preffix}_{lab_month}.{hindcast_period}_{shortname}_{str_low_quantile}quantile_min.monthly.C3S.nc"
                    else:
                        file_quant_max = f"{lab_preffix}_{lab_month}.{hindcast_period}_{shortname}_{lev4check}hPa_{str_high_quantile}quantile_max.monthly.C3S.nc"
                        file_quant_min = f"{lab_preffix}_{lab_month}.{hindcast_period}_{shortname}_{lev4check}hPa_{str_low_quantile}quantile_min.monthly.C3S.nc"

                    if args.very_verbose:
                        print(f"....Looking for quantile files quantile value "
                              f"{args.quantile_value} at "
                              f"{os.path.join(args.path_clim, lab_month, shortname)}")

                    DSupperq, DSlowerq, _, _ = open_clim_pair(
                        args.path_clim, lab_month, shortname,
                        file_quant_max, file_quant_min,
                        args.verbose, args.very_verbose,
                        help_msg=_QUANTILE_FILES_HELP)

                    # Read min/max from yearly hindcast climatology
                    file_clim_max = f"{lab_preffix}_{lab_month}.{hindcast_period}_{shortname}_max.nc"
                    file_clim_min = f"{lab_preffix}_{lab_month}.{hindcast_period}_{shortname}_min.nc"
                    DSmax, DSmin, _, _ = open_clim_pair(
                        args.path_clim, lab_month, shortname,
                        file_clim_max, file_clim_min,
                        args.verbose, args.very_verbose, decode_times=False)

                    # Read min/max from monthly hindcast climatology
                    # e.g. cmcc_CMCC-CM2-v20191201_hindcast_02.1993-2016_psl_max.monthly.C3S.nc
                    file_clim_monmax = f"{lab_preffix}_{lab_month}.{hindcast_period}_{shortname}_max.monthly.C3S.nc"
                    file_clim_monmin = f"{lab_preffix}_{lab_month}.{hindcast_period}_{shortname}_min.monthly.C3S.nc"
                    DSmonmax, DSmonmin, _, _ = open_clim_pair(
                        args.path_clim, lab_month, shortname,
                        file_clim_monmax, file_clim_monmin,
                        args.verbose, args.very_verbose, decode_times=False)

                    climlist, table_values, table_header = check_interquantile_interval(
                        DS[v], DSmax[v], DSmonmax[v], DSupperq[v], DSmin[v], DSmonmin[v],
                        DSlowerq[v], lev4check, args.mult_fact, args.logdir,
                        verbose=args.verbose, very_verbose=args.very_verbose, warning=True)

                elif check_clim and args.path_clim:
                    print("[INFO] Performing climatological max/min check on monthly records")

                    # Read monthly min/max from hindcast climatology
                    # e.g. cmcc_CMCC-CM2-v20191201_hindcast_02.1993-2016_psl_max.monthly.C3S.nc
                    if args.updateclim:
                        file_clim_monmax = f"{lab_nohind}_{lab_month}_{shortname}_max.monthly.C3S.nc"
                        file_clim_monmin = f"{lab_nohind}_{lab_month}_{shortname}_min.monthly.C3S.nc"
                    else:
                        file_clim_monmax = f"{lab_preffix}_{lab_month}.{hindcast_period}_{shortname}_max.monthly.C3S.nc"
                        file_clim_monmin = f"{lab_preffix}_{lab_month}.{hindcast_period}_{shortname}_min.monthly.C3S.nc"

                    DSmonmax, DSmonmin, _, _ = open_clim_pair(
                        args.path_clim, lab_month, shortname,
                        file_clim_monmax, file_clim_monmin,
                        args.verbose, args.very_verbose, decode_times=False)

                    climlist, table_values, table_header = check_minmax_interval(
                        DS[v], DSmonmax[v], DSmonmin[v], tolerance, args.logdir,
                        verbose=args.verbose, very_verbose=args.very_verbose, warning=True)

                # Merge all error lists, for all variables
                # TODO REMOVE climlist2
                for fulllist in (consistency_list, generallist, climlist, spike_error_list, climlist2):
                    if fulllist:
                        error_in_var = True
                        file_output_list += fulllist

                # Print logs/summary for variable:
                # Print table of clim errors for variable if test failed
                if table_values:
                    logname = os.path.join(
                        args.logdir, f"clim_error_list_{shortname}{exp}{real}{file_suffix}.outlier")
                    with open(logname, "w") as fh:
                        fh.write(tabulate(table_values, headers=table_header))
                    if args.verbose:
                        print("[INFO] Log file written: " + logname)

                # TO REMOVE (this operates only on last variable but for testing is ok)
                if table_values2:
                    logname = os.path.join(
                        args.logdir, f"hf_clim_error_list_{shortname}{exp}{real}{file_suffix}.outlier")
                    with open(logname, "w") as fh:
                        fh.write(tabulate(table_values2, headers=table_header2))
                    if args.verbose:
                        print("[INFO] Log file written: " + logname)

                # Print summary report for variable if summary_report flag is present
                # TODO You can improve this condition adding other options, i.e, when
                # any error is found (error_in_var is True), or for certain variables
                # (define summary_vars in json)
                if args.summary_report:
                    create_summary(DS, DS[v], table_values, args.logdir, lab_std, lab_mem,
                                    files[f], args.verbose, args.very_verbose)
                    if args.verbose:
                        print("[INFO] Summary report file written in " +
                              os.path.join(args.logdir, "summary"))

        # Exit in case of InputError
        except InputError as e:
            print("[INPUTERROR] ", files[f], ">>", str(e), "for variable", shortname)

        except Exception:
            print("[SYSERROR] Unexpected error:", sys.exc_info()[0], "on ", sys.exc_info()[2])
            if args.verbose:
                traceback.print_exc()

        finally:
            if args.write_log and file_output_list:
                logname = os.path.join(args.logdir, f"qa_checker_error_list{exp}{real}{file_suffix}.txt")
                write_log(logname, files[f], file_output_list, args.verbose, args.very_verbose)
                if args.verbose:
                    print("[INFO] Log file written: " + logname)

            if args.minlist and any(spikemin_list):
                write_log(args.minlist, files[f], spikemin_list, args.verbose, args.very_verbose)

            if args.leftlist and any(spikeleft_list):
                write_log(args.leftlist, files[f], spikeleft_list, args.verbose, args.very_verbose)

            if args.rightlist and any(spikeright_list):
                write_log(args.rightlist, files[f], spikeright_list, args.verbose, args.very_verbose)

            if args.dropTlist and any(dropT_list):
                write_log(args.dropTlist, files[f], dropT_list, args.verbose, args.very_verbose)

            if ice_spike_list:
                logname = args.spikelist
                write_log(logname, files[f], ice_spike_list, args.verbose, args.very_verbose)
                if shortname == "tasmin" and args.dmoFile:
                    logname = args.spikelistdmo
                    DS_DMO = xr.open_dataset(args.dmoFile, decode_times=False)
                    coord_list = find_coord_dmo(ice_spike_list, DS_DMO, DS)
                    write_log(logname, files[f], coord_list, args.verbose, args.very_verbose)
                if args.verbose:
                    print("[INFO] Log file written: " + logname)

            print("[INFO] Finished diagnose")

    # Print program execution information
    if args.trace_mem:
        current, peak = tracemalloc.get_traced_memory()
        print(f"[INFO] Current memory usage is {current / 10**6}MB; Peak was {peak / 10**6}MB")
        tracemalloc.stop()

    print("[INFO] Execution time was", time.process_time() - start_time, "seconds")


# ==========================================================================
# Main sentinel
# ==========================================================================
if __name__ == "__main__":
    main()
