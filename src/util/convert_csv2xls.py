import openpyxl
import pandas as pd
import argparse
import os

def argParser():
    """
    Argument parser
    """
    parser = argparse.ArgumentParser(prog='convert_csv2xls',description='Convert file from csv to xls.')
    parser.add_argument("fname", help="File to convert ")
    parser.add_argument("fnameout", help="Destination File ")
    parser.add_argument("-p", "--path", default=".",
            help='file path (default current directory)')
#    parser.add_argument("-l", "--logdir", default=".",
#            help='log file path (default current directory)')
    args = parser.parse_args()
    return(args)

def check_path_exists(path):
    """
    Check if path exists
    """
    if not (os.path.exists(path)):
        raise InputError('[INPUTERROR] Unknown path')

def myconvert():
    # File path
   file_from = os.path.join(args.path, args.fname)
   file_out = os.path.join(args.path, args.fnameout)
   check_path_exists(file_from)
   read_file = pd.read_csv (file_from)
   read_file.to_excel (file_out, index = None, header=True)

if __name__ == '__main__':
   args = argParser()
   myconvert()
