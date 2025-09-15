#!/bin/sh -l

. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh

set -euvx

#test 10/09/2025
#export AWS_MAX_ATTEMPTS=10
#export AWS_RETRY_MODE=adaptive
#test 11/09/2025
#aws configure set default.s3.max_concurrent_requests 5
#aws configure set default.s3.max_bandwidth 100MB/s
#aws configure set default.s3.multipart_threshold 64MB
#aws configure set default.s3.multipart_chunksize 16MB

#original
$HOME/.local/bin/aws s3 sync $DIR_WEB  s3://sps-files.cmcc.it/ --delete
#test 10/09/2025
#$HOME/.local/bin/aws s3 sync $DIR_WEB  s3://sps-files.cmcc.it/ --delete --exact-timestamps
#test 11/09/2025
#$HOME/.local/bin/aws s3 sync $DIR_WEB  s3://sps-files.cmcc.it/ --delete --cli-read-timeout 0 --cli-connect-timeout 60
exit 0
