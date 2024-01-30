#!/bin/sh -
# USE sftp for the first attempt
# THEN sftp -a to complete an interrupted or incomplete push
sftp user@ftpsite < count_remote_files.sh |grep -v sftp
