#!/usr/bin/env python
# -*- coding: utf-8 -*-
#"""
# Create a C3S status from csv summary files, convert them in xls and finally load over Dropbox
# 
# In order to load over Dropbox sp1 account, an APP was created (see Dropbox dev guide) and a token was generated
#
#@author: Antonio Cantelli @ CMCC Sept 2020
#"""
import dropbox
from pandas import ExcelWriter
import os
import time
import pandas as pd
import argparse
import logging


def argParser():
    """
    Argument parser
    """
    parser = argparse.ArgumentParser(prog='create_C3S_status_and_upload',description='Create C3S summary file starting form csv files. See launcher: launch_C3S_status.sh')
    parser.add_argument("fname", help="File for excelfname (usually SPS35_HC_C3S_status.xlsx) ")

    parser.add_argument("-p", "--path", default=".",
            help='file path: Usually $DIR_SCRA/C3S_HC_status (default current directory)')
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

def create_xlsfile(path,excelfname):			
	# open excel file
	writer = pd.ExcelWriter(path+excelfname,engine='xlsxwriter')

	# load csv files
	startdatelist = ["10","11","12","01","02","03","04","05","06","07","08","09"]
	#startdatelist = ["10"]

	for i in startdatelist:
		df = pd.read_csv(path+'C3S_status_'+i+'.csv',sep=";")
		df.to_excel(writer,i)

		# Get the xlsxwriter workbook and worksheet objects.
		workbook  = writer.book
		worksheet = writer.sheets[i]

		# Add a format. Light red fill with dark red text.
		format1 = workbook.add_format({'bg_color': '#FFC7CE','font_color': '#9C0006'})

		# Set the conditional format range.
		start_row = 1
		start_col = 10 # column OK
		end_row = len(df)
		end_cold = start_col

		# Apply a conditional format to the cell range.
		worksheet.conditional_format(start_row, start_col, end_row, end_cold,
			{'type':     'cell',
			'criteria': '==',
			'value':    0,
			'format':   format1})

		#set the column width as per your requirement
		worksheet.set_column('B:J', 15)

	writer.save()


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

def main():

	args = argParser()

	excelfname = args.fname
	path = args.path	
	# Check existence 
	check_path_exists(path)

	# logging  
	LOG = path+"C3S_status.log"                                                     
	logging.basicConfig(filename=LOG, filemode='a',
						format='%(asctime)s,%(msecs)d %(name)s %(levelname)s %(message)s',
						datefmt='%H:%M:%S',
						level=logging.DEBUG)

	logging.info("** Starting new session **")

	# Dropbox token (use with caution)
	access_token = '_msokiMK1dcAAAAAAAAAAdfOYyHmKCpBaufSXrouSPCnkcRqgcRwkNEv4Zv51KDR'

	file_from = path+excelfname

	logging.info("Creating Excel file")
	# Create local xls file
	create_xlsfile(path,excelfname)

	# Load access tokend
	transferData = TransferData(access_token)

	# Dropbox path
	file_to='/Seasonal Forecast/SPS3.5/documents_staff/'+excelfname

	# API v2 Dropbox - upload file
	logging.info("Transfer to dropbox")	
	transferData.upload_file(file_from, file_to)


if __name__ == '__main__':
    main()

