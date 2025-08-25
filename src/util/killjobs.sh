#!/bin/sh -l
. ~/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

usage() { echo "Usage: $0 [-m <machine string >] [-i <input string >] " 1>&2; exit 1; }

while getopts ":m:i:" o; do
    case "${o}" in
        m)
            machine=${OPTARG}
            ;;
        i)
            input=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done

if [ $# -eq 0 ]
then
   usage
fi
if [ -z $machine ]
then
   usage
fi
if [ -z $input ]
then
    echo 'Job already terminated'
    exit 0  
    #usage
fi
# MACHINE DEPENDENT PART ----------------------------
if [[  "$machine" == "zeus" ]] || [[  "$machine" == "juno" ]] || [[  "$machine" == "cassandra" ]]
then
#  set -evx
  isjobup=0
  isjobup=`bjobs -w | grep ${input} | wc -l`
   command="bkill "

elif [[ "${machine}" == "leonardo" ]] 
then
  set -evx
  isjobup=0
  isjobup=`squeue | grep ${input} | wc -l`
  command="scancel "
fi
#
if [[ $isjobup -ne 0 ]] ; then
  echo $command $input
  eval $command ${input}
  set +evx
fi
