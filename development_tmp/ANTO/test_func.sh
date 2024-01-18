#!/bin/sh -l 

# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh


set -eu

function Count_files()
{
       counter=$1
       ret=1
       echo $ret
   
}
ic=2
res=$( Count_files $ic )
echo "res = " $res
