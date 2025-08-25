#!/bin/sh -l
. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
set +evxu
if [[ $machine == "zeus" ]] || [[ $machine == "juno" ]] || [[ $machine == "cassandra" ]]; then	
condafunction() {
   local comm=$1
   local env=$2	
   if [[ $env != "$envcondacm3" ]] 
   then
       . $DIR_UTIL/load_miniconda
       if [[ $env == "$envcondanemo" ]] 
       then
          if [[ $machine == "zeus" ]]
          then
             module load intel20.1
          fi
          module load $mpilib4py_nemo_rebuild
       fi
   else
       . $HOME/load_conda
   fi
   if [  $comm == "activate"  ]; then
      	conda $comm $env
   elif [  $comm == "deactivate"  ]; then
      	conda $comm
   fi
}
elif [[ "${machine}" == "leonardo" ]] ; then 
   module load $mpilib4py_nemo_rebuild
# get conda version
condafunction() {
   local comm=$1
   local env=$2	
   if [  $comm == "activate"  ]; then
      	conda $comm $env
   elif [  $comm == "deactivate"  ]; then
      	conda $comm
   fi
}
fi
