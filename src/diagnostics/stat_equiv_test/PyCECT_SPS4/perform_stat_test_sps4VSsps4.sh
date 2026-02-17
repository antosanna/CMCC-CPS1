#!/bin/sh -l
#BSUB -J stat_test_sps4
#BSUB -q p_medium
#BSUB -n 144
#BSUB -x
#BSUB -o /work/cmcc/cp1/CPS/CMCC-CPS1/logs/stat_test/stat_test_sps4.%J.out
#BSUB -e /work/cmcc/cp1/CPS/CMCC-CPS1/logs/stat_test/stat_test_sps4.%J.err
#BSUB -P 0784
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
. $HOME/.bashrc
. $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/load_cdo
. $DIR_UTIL/load_nco
module load impi-2021.6.0/2021.6.0
module load intel-2021.6.0/impi-2021.6.0/parallel-netcdf/1.12.3-eshb5
. ~/load_miniconda
conda activate /users_home/cmcc/cp2/miniconda/envs/cmcc_pycect
set -euvx

set -euvx

# ********************************************
# Input
# ********************************************

here=$PWD
pysrcdir=/users_home/cmcc/mb16318/CPS/PyCECT

ARCHIVE=$DIR_ARCHIVE1

# !WARNING HERE !WARNING HERE !WARNING HERE
compute_test=1 # activate ensamble cat

set +euvx
. $DIR_UTIL/descr_ensemble.sh 1993
set -uevx


# ***************
# Input - General
# ***************

members=300   #number of members in the reference ens

npc=30        # number of Pricnipal components. Must be < variables ( as a rule of thumb the 33% of total number of used vars)

sig=-1      #value of sigma_mul (if 0 - use default sigMul=2.23)
cam_vars=115          #total number of vars in h0 (monthly) SPS4 output
cam_vars=105          #total number of vars in h0 (monthly) SPS4 output
#members=120   #number of members in the reference ens MUST BE > $cam_vars
#members=170   #number of members in the reference ens MUST BE > $cam_vars
#npc=50        # number of Pricnipal components. Must be < variables ( as a rule of thumb the 33% of total number of used vars)

# we are going to process monthly files (1 is monthly/ 0 is not)
ismonthly=1
tag=sps4VSsps4
resolution="f05_n0253"
esize=$members   #esize = number of members in $wkdir. must be > vars
etslice=1
ttslice=1
numfiletocheck=11 # among files in testdir folder analyze only numfiletocheck
nmax=10 # here we take the first 10 members for each year (1993-2009)
num_newruns=$nmax
minPC=3      #this is a parameter to define standard 3
runfail=2    #this is a parameter to define standard 2 must be <= num_newruns

nmonmax=$nmonfore


iniy=$iniy_hind
endy=$endy_hind

# tslice must be 0 in case of monthly files
if [ $ismonthly -eq 1 ]; then etslice=0 ; fi   #???????
if [ $ismonthly -eq 1 ]; then ttslice=0 ; fi

#for st in {01..12}
for st in {01..01}
do

   testname=${SPSSystem}_${st}_sps4VSsps4_pop${members}_nrun${num_newruns}_minPC${minPC}_nfail${runfail}
   logtestfile=${testname}.log


   if [[ $sig -gt 0 ]] ; then
      outdirlog=$WORK/pyCECT/${testname}/outlog_sigmul${sig}_npc$npc
   else
      outdirlog=$WORK/pyCECT/${testname}/outlog_sigmul2.23_npc$npc
   fi

   mkdir -p $outdirlog


# **********************
# Input - Ref Ensemble
# **********************


   sumdir=$WORK/pyCECT/${testname}/summary/    #directory for summary file
   mkdir -p $sumdir
   summary_file=$sumdir/ens.summary

   exclude_vars_file=excluded_varlist.json_min  #only exclude constant fields 




# **********************
# Input - Test members
# **********************

# ********************************************

# ********************************************
# merge REF ENSEMBLES (juno)
# ********************************************
  gatheroutput_dir=$SCRATCHDIR/pyCECT/sps4/$st/ensemble       #directory for ncatted DMO (reference)
  mkdir -p $gatheroutput_dir
  wkdir=$SCRATCHDIR/pyCECT/${testname}/ensemble       #directory for ncatted DMO (reference)
  mkdir -p ${wkdir}
  cd $wkdir
  # loop over members
  # to check members completed for each year we have used the script $DIR_UTIL/count_members.py     
  

  pop=""
  for yyyy in $(seq -w $iniy $endy)  ; do
	 
       count=0
       for pp in $(seq -w 001 030); do 
           
           caso=${SPSSystem}_${yyyy}${st}_${pp}
       	   filelisttomerge=()
           if [ ! -f $gatheroutput_dir/${caso}.cam.h0.nc ]; then
	      # loop over monthly h0
       	      for month in `seq 0 $(( $nmonmax -1 )) `; do
              		  startdate=$yyyy$st
               	  monthdate=`date +%Y-%m -d "${startdate}01 + ${month} month"`
                  file=$ARCHIVE/$caso/atm/hist/${caso}.cam.h0.${monthdate}.zip.nc
                  if [[ ! -f $file ]] ; then
                     file=$ARCHIVE/$caso/atm/hist/${caso}.cam.h0.${monthdate}.nc
                  fi
                  filelisttomerge+="${file} "
       	      done
	      
	      #use nco instead of cdo to manage file dimension
              ncrcat -O $filelisttomerge $gatheroutput_dir/${caso}.cam.h0.nc
           else
              ln -sf $gatheroutput_dir/${caso}.cam.h0.nc $wkdir
       	   fi
           pop+=" $caso"
       	   count=$(($count + 1))
       	   if [[ $count -ge $nmax ]] ; then
	             break
           fi
        done
   done   #loop on hindcast years

# ********************************************
# merge TESTS ENSEMBLE (leonardo)
# ********************************************
# the following operations are necessary is testing against another experiment, not here where the test is done against the same pop

#   if [ $compute_test -eq 1 ]; then
#      mkdir -p ${test_indir}
#      TESTARCHIVE=$SCRATCHDIR/cmcc/cp1/scratch/check_equivalence_remapping/$testname/$st
#      mkdir -p $TESTARCHIVE
#      TESTARCHIVE=$DIR_ARCHIVE
   
   
   # loop over members
# define a listofcases in number equal or greater than the needed $numfiletocheck
#         for pp in $listofcases; do 
#
#             caso=${SPSSystem}_${startdate2}_0${pp}
#          if [[ ! -d $TESTARCHIVE/$caso ]]
#          then
#              continue
#          fi

#             ic=$(($ic + 1))
#             if [[ ! -f $test_indir/${caso}.cam.h0.nc ]]
#             then
#                filelisttomerge=()
	  # loop over monthly h0
#                for month in `seq 0 $(( $nmonmax -1 )) `; do
#              	     monthdate=`date +%Y-%m -d "${startdate2}01 + ${month} month"`
#                    file=$TESTARCHIVE/$caso/${caso}.cam.h0.${monthdate}.zip.nc
#                if [[ ! -f $file ]] ; then
#                   file=$TESTARCHIVE/$caso/${caso}.cam.h0.${monthdate}.nc
#                fi    
#                filelisttomerge+="${file} "
#       	     done
          
	         # use nco instead of cdo to manage file dimension
#             ncrcat -O $filelisttomerge $test_indir/${caso}.cam.h0.nc 
#          fi
#          if [[ $ic -eq $numfiletocheck ]]
#          then
#             break
#          fi
#        done
#     done
#   fi
# ********************************************
# 0) PRELIMINARY CHECKS
# ********************************************

#   cntesize=`ls -1 $wkdir/*.nc | wc -l`
#   if [ $esize -lt $cntesize ]; then 
#        echo "the test will use only the first $esize"
#   fi

   cntexclvars=`cat $here/$exclude_vars_file | cut -d '[' -f2 | cut -d ']' -f1 | cut -d '{' -f2  | cut -d '}' -f2 | grep -v -e '^$' | wc -l`
   if [ $esize -lt $(( $cam_vars - $cntexclvars )) ]; then 
      echo "Number of analyzed vars must be <= of members number. Increase number list in ${exclude_vars_file}. Stop." && exit 1
   fi


# ********************************************
# 1) ENSEMBLE SUMMARY
# ********************************************
   echo "ENSEMBLE SUMMARY"


   cd $here

   for month in `seq 0 $(( $nmonmax -1 )) `; do
      etslice=$month
      ttslice=$etslice
      if [  -f ${summary_file}_${month}.nc ]; then
         rm -f ${summary_file}_${month}.nc
      fi   
  
      mpiexec.hydra -n 144 -ppn 72 python $pysrcdir/pyEnsSum.py --indir $wkdir --tag $tag --sumfile ${summary_file}_${month}.nc --mach $machine --res $resolution --tslice $etslice --esize $esize --jsonfile $exclude_vars_file --verbose
   #mpiexec.hydra -n 144 -ppn 72 python $pysrcdir/pyEnsSum.py --indir $wkdir --tag $tag --sumfile ${summary_file}_${month}.nc --mach $machine --res $resolution --tslice $etslice --esize $esize --jsonfile $exclude_vars_file --verbose --mpi_disable True
   #python $pysrcdir/pyEnsSum.py --indir $wkdir --tag $tag --sumfile ${summary_file}_${month} --mach $machine --res $resolution --tslice $etslice --esize $esize --jsonfile $exclude_vars_file --verbose --mpi_disable True

   done

# *******************************************
# 2) COMPARE TEST vs ENSEMBLE
# ********************************************

   cd $here
   if [ $compute_test -eq 1 ]; then
   
   # loop over members
      npert=1
      for ic in `seq 1 $npert`
      do  
         test_indir=$SCRATCHDIR/pyCECT/$testname/testdir/$iniy-$endy/$ic
         mkdir -p ${test_indir}
         filecheck=$outdirlog/chunk_${iniy}-${endy}_${ic}times_DONE
         if [[ -f $filecheck ]]
         then
               continue
         fi  
         shuffled=( $(shuf -e `echo $pop|cut -d '.' -f1`) ) 
         listofcases=`echo ${shuffled[*]:0:$num_newruns}`
         for caso in $listofcases
         do
            rsync -auv $wkdir/${caso}.cam.h0.nc $test_indir
         done
# count number of test, test must consist of at least 3 cases
         if [ `ls -1 $test_indir/*.nc | wc -l` -lt 3 ]; then
            echo "test members in $test_indir must be ge 3. Stop." && exit 1
         fi

         for month in `seq 0 $(( $nmonmax -1 )) `; do
           	echo "TEST FOR MONTH * $month * **************************"
           	etslice=$month
           	ttslice=$etslice

           	echo "COMPARE TEST vs ENSEMBLE"
           	python3 $pysrcdir/pyCECT.py --sumfile ${summary_file}_${month}.nc --indir $test_indir --tslice $ttslice --nPC ${npc} --sigMul $sig --numRunFile $numfiletocheck > $outdirlog/${logtestfile}_${month}_${numfiletocheck}_mem # --verbose --saveResults # --printStdMean --printVars


         done   #loop on months
      done   #loop on perturbations
   fi  #compute_test
done   #loop on $st

# ********************************************
# Done
# ********************************************
echo "$0 Done"
exit 0 
