import os
import argparse
def argParser():
    """
    Argument parser.
    """
    parser = argparse.ArgumentParser(prog='read_csv',
        description=""" reads csv files and create list of cases to be run
                    """)
    parser.add_argument("csvfile", 
            help="input file in format csv")
    parser.add_argument("-y","--year",
            help="year to parse for")
    parser.add_argument("-st", "--startdate",
            help="climatological start date")
    parser.add_argument("-m", "--mode",
            help="if 0 computes missing cases; if 1 completed ones")
    args=parser.parse_args()
    return(args)
