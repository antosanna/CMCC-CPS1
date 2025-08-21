#!/bin/sh -l
#BSUB -J stat_test_sps4
#BSUB -q p_short
#BSUB -n 144
#BSUB -x
#BSUB -o /work/cmcc/cp2/CPS/CMCC-CPS1/logs/stat_test/stat_test.%J.out
#BSUB -e /work/cmcc/cp2/CPS/CMCC-CPS1/logs/stat_test/stat_test.%J.err
#BSUB -P 0490
#BSUB -M 70000


####################################################################################
# This script has been designed to launch pyCECT test
# to check the statistical equivalence of SPS4 hindcast members 
# run on CMCC machines (juno) and CINECA one (leonardo)
#
# pyCECT has been defined a statistical test to asses portability
# of CAM simulation over a new machine. 
#
# This procedure is set to RUN on JUNO with the conda env
#
#    conda activate /work/cmcc/cp2/miniforge/envs/env_pycect      
#
# For running the python routines (for summary definition and check)
# we need to upload also mpi & parallel-netcdf modules

#    module load impi-2021.6.0/2021.6.0
#    module load intel-2021.6.0/impi-2021.6.0/parallel-netcdf/1.12.3-eshb5
#   
# With the current setup it runs on 2 juno nodes (144 cores) with 50Gb of MemReq
#
# For SPS4 (June 2024) we have used the following commit of pyCECT suite:
#     commit 2964079eb3cd3c460622cf0dcc5faba64650987c
#
#####################################################################################
. /users_home/cmcc/mb16318/.bashrc
. /users_home/cmcc/mb16318/CPS/CMCC-CPS1/src/util/descr_CPS.sh
. /users_home/cmcc/mb16318/CPS/CMCC-CPS1/src/util/load_cdo
. /users_home/cmcc/mb16318/CPS/CMCC-CPS1/src/util/load_nco

set -euvx

# ********************************************
# Input
# ********************************************

here=$DIR_DIAG/stat_equiv_test/PyCECT_SPS4
pysrcdir=/users_home/cmcc/$USER/CPS/CMCC-SPS-PyCECT

ARCHIVE=/work/csp/cp1//CMCC-CM//archive/     #DMO dir for reference ens (juno - $DIR_ARCHIVE1)
TESTARCHIVE=/work/csp/cp1/scratch/stat_equiv_test_leonardo   #DMO dir for members to be checked (leonardo)
mkdir -p $TESTARCHIVE


# !WARNING HERE !WARNING HERE !WARNING HERE
retrieve_ens=0 # activate ensemble retrievment

# !WARNING HERE !WARNING HERE !WARNING HERE
retrieve_test=0 # activate ensamble retrievment

set +euvx
. /users_home/cmcc/mb16318/CPS/CMCC-CPS1/src/util/descr_ensemble.sh 1993
set -uevx


# ***************
# Input - General
# ***************

st="05"       #climatological startdate to perform the test
members=170   #number of members in the reference ens

npc=30        # number of Pricnipal components. Must be < variables ( as a rule of thumb the 33% of total number of used vars)

testname="${SPSSystem}_${st}_test${members}ens_junoVleo"
sig=0      #value of sigma_mul (if 0 - use default sigMul=2.23)


wkdir=/work/cmcc/$USER/scratch/pyCECT/${testname}/ensemble       #directory for ncatted DMO (reference)
test_indir=/work/cmcc/$USER/scratch/pyCECT/${testname}/testdir   #directory for ncatted DMO (test)

mkdir -p $here/OUTPUT_${CPSSYS}/${testname}

if [[ $sig -ne 0 ]] ; then
   outdirlog=$here/OUTPUT_${CPSSYS}/${testname}/outlog_sigmul${sig}_npc$npc
else
   outdirlog=$here/OUTPUT_${CPSSYS}/${testname}/outlog_sigmul2.23_npc$npc
fi

mkdir -p $outdirlog
mkdir -p ${wkdir}
mkdir -p ${test_indir}

# we are going to process monthly files (1 is monthly/ 0 is not)
ismonthly=1

# **********************
# Input - Ref Ensemble
# **********************

cam_vars=115          #total number of vars in h0 (monthly) SPS4 output

sumdir=$here/OUTPUT_${CPSSYS}/${testname}/summary/    #directory for summary file
mkdir -p $sumdir
summary_file=$sumdir/ens.summary

exclude_vars_file=excluded_varlist.json_min  #only exclude constant fields 
#exclude_vars_file=excluded_varlist.json_may

tag="${SPSSystem}_${machine}"  #for attribute of netcdf summary files
resolution="f05_n0253"
esize=$members   #esize = number of members in $wkdir. must be > vars
etslice=1


startdate2=199605
listofcases="04 14 16"


# **********************
# Input - Test members
# **********************
ttslice=1
numfiletocheck=3 # among files in testdir folder analyze only numfiletocheck
logtestfile=${testname}.log

# ********************************************

# ********************************************
# RETRIEVE REF ENSEMBLES (juno)
# ********************************************
if [ $retrieve_ens -eq 1 ]; then
  cd $wkdir
  # loop over members
  # to check members completed for each year we have used the script $DIR_UTIL/count_members.py     
  
  nmax=10 # here we take the first 10 members for each year (1993-2009)

  for yyyy in $(seq -w 1993 2009)  ; do
	 
       count=0
       for pp in $(seq -w 001 030); do 
           
           caso=${SPSSystem}_${yyyy}${st}_${pp}
           if [[ ! -f /work/csp/cp1//CPS/CMCC-CPS1/cases/$caso/logs/${caso}_6months_done ]] ; then
		    continue
           fi
	   filelisttomerge=()
           if [ ! -f $wkdir/${caso}.cam.h0.nc ]; then
	      # loop over monthly h0
	      for month in `seq 0 $(( $nmonfore -1 )) `; do
		  startdate=$yyyy$st
        	  monthdate=`date +%Y-%m -d "${startdate}01 + ${month} month"`
                  file=$ARCHIVE/$caso/atm/hist/${caso}.cam.h0.${monthdate}.zip.nc
                  if [[ ! -f $file ]] ; then
                     file=$ARCHIVE/$caso/atm/hist/${caso}.cam.h0.${monthdate}.nc
                  fi
                  filelisttomerge+="${file} "
	      done
	      
	      #use nco instead of cdo to manage file dimension
              ncrcat -O $filelisttomerge $wkdir/${caso}.cam.h0.nc
	   fi
	   count=$(($count + 1))
	   if [[ $count -ge $nmax ]] ; then
	      break
           fi
        done
   done
fi

# ********************************************
# RETRIEVE TESTS ENSEMBLE (leonardo)
# ********************************************

if [ $retrieve_test -eq 1 ]; then
   ic=0
   
   # loop over members
   for pp in $listofcases; do 

       caso=${SPSSystem}_${startdate2}_0${pp}
       if [[ ! -d $TESTARCHIVE/$caso ]]
       then
           continue
       fi

       ic=$(($ic + 1))
       if [[ ! -f $test_indir/${caso}.cam.h0.nc ]]
       then
          filelisttomerge=()
	  # loop over monthly h0
          for month in `seq 0 $(( $nmonfore -1 )) `; do
	     monthdate=`date +%Y-%m -d "${startdate2}01 + ${month} month"`
             file=$TESTARCHIVE/$caso/atm/hist/${caso}.cam.h0.${monthdate}.zip.nc
             if [[ ! -f $file ]] ; then
                file=$TESTARCHIVE/$caso/atm/hist/${caso}.cam.h0.${monthdate}.nc
             fi    
             filelisttomerge+="${file} "
       	  done
          
	         # use nco instead of cdo to manage file dimension
          ncrcat -O $filelisttomerge $test_indir/${caso}.cam.h0.nc 
       fi
       if [[ $ic -eq $numfiletocheck ]]
       then
          break
       fi
  done
fi
# ********************************************
# 0) PRELIMINARY CHECKS
# ********************************************

# REF ENSEMBLE
# tslice must be 0 in case of monthly files

if [ $ismonthly -eq 1 ]; then etslice=0 ; fi

cntesize=`ls -1 $wkdir/*.nc | wc -l`
if [ $esize -lt $cntesize ]; then 
#	esize=$cntesize 
     echo "the test will use only the first $esize"
fi

cntexclvars=`cat $here/$exclude_vars_file | cut -d '[' -f2 | cut -d ']' -f1 | cut -d '{' -f2  | cut -d '}' -f2 | grep -v -e '^$' | wc -l`
if [ $esize -lt $(( $cam_vars - $cntexclvars )) ]; then 
   echo "Number of analyzed vars must be <= of members number. Increase number list in ${exclude_vars_file}. Stop." && exit 1
fi


#TEST
# tslice must be 0 in case of monthly files
if [ $ismonthly -eq 1 ]; then ttslice=0 ; fi

# count number of test, test must consist of at least 3 cases
if [ `ls -1 $test_indir/*.nc | wc -l` -lt 3 ]; then
   echo "test members in $test_indir must be ge 3. Stop." && exit 1
fi

# ********************************************
# 1) ENSEMBLE SUMMARY
# ********************************************
echo "ENSEMBLE SUMMARY"

module load impi-2021.6.0/2021.6.0
module load intel-2021.6.0/impi-2021.6.0/parallel-netcdf/1.12.3-eshb5

set +euvx
. /users_home/cmcc/mb16318/load_miniconda
conda activate /work/cmcc/cp2/miniforge/envs/env_pycect
set -euvx

cd $here

echo $CONDA_PREFIX
for month in `seq 0 $(( $nmonfore -1 )) `; do
   etslice=$month
   ttslice=$etslice
   if [  -f ${summary_file}_${month}.nc ]; then
      rm -f ${summary_file}_${month}.nc
   fi   
  
   mpiexec.hydra -n 144 -ppn 72 python $pysrcdir/pyEnsSum.py --indir $wkdir --tag $tag --sumfile ${summary_file}_${month}.nc --mach $machine --res $resolution --tslice $etslice --esize $esize --jsonfile $exclude_vars_file --verbose
   #mpiexec.hydra -n 144 -ppn 72 python $pysrcdir/pyEnsSum.py --indir $wkdir --tag $tag --sumfile ${summary_file}_${month}.nc --mach $machine --res $resolution --tslice $etslice --esize $esize --jsonfile $exclude_vars_file --verbose --mpi_disable True
   #python $pysrcdir/pyEnsSum.py --indir $wkdir --tag $tag --sumfile ${summary_file}_${month} --mach $machine --res $resolution --tslice $etslice --esize $esize --jsonfile $exclude_vars_file --verbose --mpi_disable True

   if [ $? -ne 0 ]; then
      echo "Test cannot be completed due to error on ensamble summary phase. Stop." && exit 1
   fi
done

# *******************************************
# 2) COMPARE TEST vs ENSEMBLE
# ********************************************

for month in `seq 0 $(( $nmonfore -1 )) `; do
	echo "TEST FOR MONTH * $month * **************************"
	etslice=$month
	ttslice=$etslice

	echo "COMPARE TEST vs ENSEMBLE"
	python3 $pysrcdir/pyCECT.py --sumfile ${summary_file}_${month}.nc --indir $test_indir --tslice $ttslice --nPC ${npc} --sigMul $sig --numRunFile $numfiletocheck > $outdirlog/${logtestfile}_${month}_${numfiletocheck}_mem # --verbose --saveResults # --printStdMean --printVars

	if [ $? -ne 0 ]; then
		echo "Test error. Stop." && exit 1
	fi

done

# ********************************************
# Done
# ********************************************
echo "$0 Done"
exit 0 




