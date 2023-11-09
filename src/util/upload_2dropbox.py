#!/usr/bin/env python
# -*- coding: utf-8 -*-
#"""
# Upload given file to an existing directory on dropbox
# 
# In order to load over Dropbox sp1 account, an APP was created (see Dropbox dev guide) and a token was generated.
#
# Input(s):    - file
#              - file path
#              - path on Dropbox
#              - logdir
#
#@author: MdM Chaves @ CMCC May 2021
#"""
import dropbox
import os
import time
import argparse
import logging
from datetime import datetime

# Main function
def main():

    args = argParser()

    # Logging
    if not (os.path.exists(args.logdir)):
        os.mkdir(args.logdir)
    dt_string =  datetime.now().strftime("%Y%m%d_%s")

    LOG = os.path.join(args.logdir, "upload_2dropbox_"+dt_string+".log")                                                  
    logging.basicConfig(filename=LOG, filemode='a',
                        format='%(asctime)s,%(msecs)d %(name)s %(levelname)s %(message)s',
                        datefmt='%H:%M:%S',
                        level=logging.DEBUG)

    logging.info("** Starting new session **")

    # Dropbox token (use with caution)
    access_token = '_msokiMK1dcAAAAAAAAAAdfOYyHmKCpBaufSXrouSPCnkcRqgcRwkNEv4Zv51KDR'

    # File path
    file_from = os.path.join(args.path, args.fname)
    check_path_exists(file_from)

    # Load access tokend
    transferData = TransferData(access_token)

    # Dropbox path
    file_to = os.path.join(args.dropbox, args.fname)

    # API v2 Dropbox - upload file
    logging.info("Transfer to dropbox") 
    transferData.upload_file(file_from, file_to)

# Functions
def argParser():
    """
    Argument parser
    """
    parser = argparse.ArgumentParser(prog='upload_2dropbox',description='Upload file to dropbox.')
    parser.add_argument("fname", help="File to upload ")
    parser.add_argument("-p", "--path", default=".",
            help='file path (default current directory)')
    parser.add_argument("-d", "--dropbox", default="/Seasonal Forecast/SPS3.5/documents_staff/",
            help='dropbox path (default /Seasonal Forecast/SPS3.5/documents_staff/ )')
    parser.add_argument("-l", "--logdir", default=".",
            help='log file path (default current directory)')
    args = parser.parse_args()
    return(args)

def check_path_exists(path):
    """
    Check if path exists
    """
    if not (os.path.exists(path)):
        raise InputError('[INPUTERROR] Unknown path')

class TransferData:
	def __init__(self, access_token):
		self.access_token = access_token

	def upload_file(self, file_from, file_to):
		"""upload a file to Dropbox using API v2"""
		dbx = dropbox.Dropbox(self.access_token)
		stats = dbx.users_get_current_account()
		print(stats)

		# files_upload() must have overwrite mode
		with open(file_from, 'rb') as f:
			dbx.files_upload(f.read(), file_to, mode=dropbox.files.WriteMode.overwrite)

		logging.info("Transfer to dropbox completed")	


if __name__ == '__main__':
    main()
