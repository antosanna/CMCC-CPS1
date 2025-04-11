import os
import argparse
def argParser():
    """
    Argument parser.
    """
    parser = argparse.ArgumentParser(prog='C3SDataChecker',
        description=""" CMCC Checker for SPS3.5 data.
                        This program needs a configuration table named qa_checker_table.json.
                        Files names must follow the convention of SPS3.5 data (either C3S or DMO).
                        Variable names and dimensions must conform C3S standard.
                        Checks are specific for SPS3.5 data in C3S format. Some of the checks accept also SPS3.5 DMO files.
                    """)
    parser.add_argument("file", help="file to process. If a math pattern is indicated, then double quotes are needed")
    parser.add_argument("-v","--var", 
            help="name of the variable to process. (default:reads all vars in file)")
    parser.add_argument("-p", "--path", default=os.getcwd(),
            help="file path (default current directory)")
    parser.add_argument("-j","--json", default=os.path.join(os.getcwd(),"qa_checker_table.json"),
            help="Json file with limits for range checks (default: qa_checker_table.json in current directory)")
    parser.add_argument("-l", "--logdir", default=os.getcwd(),
            help="log file path (default current directory)")
    parser.add_argument("-d1", "--delta1", default=-30.,
            help="default value for spike check d1")
    parser.add_argument("-d2", "--delta2", default=5.,
            help="default value for spike check d2")
    parser.add_argument("-spike", "--only_spike", default=False, 
            help="default value to activate/disactivate only_spike mode")
    parser.add_argument("-sl","--spikelist", default=False, 
            help="realpath of txt containing the list of spikes")
    parser.add_argument("-dT","--dropTlist", default=False, 
            help="realpath of txt containing the list of temperature drops (greater than 30)")
    parser.add_argument("-std", "--std_thresh", default=2.,
            help="default value for spike check std_dev")
    parser.add_argument("-exp","--log_exp_suffix", default="",
            help="suffix for naming log files indicating experiment, i.e., sps3.5")
    parser.add_argument("-real","--log_real_suffix", default="",
            help="suffix for naming log files indicating realization, i.e, 202010_001") 
    parser.add_argument("-w", "--write_log", action='store_true',
            help="enable writing of error log file on logdir (default=False). Note that the logs for spike check always written.")    
    parser.add_argument("-pclim","--path_clim",
            help="""enable climatological check by indicating clim folder path which must contain the files 
                    under the following tree: startdate/varname.
                    Files must follow the naming convention:
                    [preffix]_[startdate].[hindcastperiod]_[varname]_min.nc
                    [preffix]_[startdate].[hindcastperiod]_[varname]_max.nc
                    (i.e. cmcc_CMCC-CM2-v20191201_hindcast_11.1993-2016_hus_min.nc)
                    Each of the cimatological files must contain a variable named as the variable to check.
                """)
    parser.add_argument("-pqval","--quantile_value",
            help="""lower quantile (the upper will be defined in the code symmetrically)
            """)
    parser.add_argument("-mf","--mult_fact",default=1.5,
            help="""multiplicative factor for the interquantile interval (default according to Tukey 1977)
            """)
    parser.add_argument("--summary_report", action='store_true',
            help="enable creation of a report with a small set of plots (default=False) on the logdir.")    
    parser.add_argument("--trace_mem", action='store_true', 
            help="enable memory tracing (default=False)")          
    parser.add_argument("--verbose", action='store_true',
            help="enable verbose messages (default=False)")
    parser.add_argument("--very_verbose", action='store_true',
            help="enable very verbose messages (default=False)"),
    parser.add_argument("-scd","--scratchdir",help="""Scratch dir to store temporary max/min file updated """)
    parser.add_argument("-up","--updateclim",action='store_true',help="""Activate climatology files updated with forecast values """)
    args = parser.parse_args()

    if args.very_verbose:
        args.verbose=True

    return(args)
