#!/bin/sh -l
. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
set +evxu
if [[ $machine == "zeus" ]] || [[ $machine == "juno" ]]; then	
condafunction() {
   local comm=$1
   local env=$2	
   if [[ $env != "$envcondacm3" ]] && [[ $env != "$envcondanemo" ]]
   then
       . $DIR_UTIL/load_miniconda
   fi
   if [  $comm == "activate"  ]; then
	conda $comm $env
   elif [  $comm == "deactivate"  ]; then
	conda $comm
   fi
}
elif [[ "${machine}" == "marconi" ]] ; then 
# get conda version
condafunction() {
   local comm=$1
   local env=$2	
   if [[ $env != "$envcondacm3" ]] && [[ $env != "$envcondanemo" ]]
   then
       . $DIR_UTIL/load_miniconda
   fi
   condaver=$(conda -V | awk '{print $2}' )
   condaver1=$(echo $condaver | cut -d '.'  -f 1)
   condaver2=$(echo $condaver | cut -d '.'  -f 2)
   condavergt44=0
	# if version gt 4.4 condavergt44=1
   if [ $condaver1 -eq 4 -a $condaver2 -gt 4 ]; then
	condavergt44=1
   fi
   if [ $condaver1 -gt 4 ]; then
	condavergt44=1
   fi
   if [ $comm == "activate" ] ; then
	   echo "conda activate"
                if [  $condavergt44 -eq 1 ] ; then
			conda $comm $env
		else
			source $comm $env
		fi
   elif [ $comm == "deactivate" ] ; then
      if [  $condavergt44 -eq 1 ] ; then
	conda $comm
      else
	source $comm
      fi		
   fi		
}
fi
