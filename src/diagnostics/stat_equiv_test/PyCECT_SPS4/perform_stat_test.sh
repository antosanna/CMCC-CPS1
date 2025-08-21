#!/bin/bash -l
#BSUB -J stat_test
#BSUB -q s_long
#BSUB -o logs/stat_test.%J.out
#BSUB -e logs/stat_test.%J.err
#BSUB -P 0490
#BSUB -M 5000


# ********************************************
# Perform a statistical test to asses portability of CAM simulation
# over a new machine. 
# ********************************************
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. ${DIR_UTIL}/load_cdo
. ${DIR_UTIL}/load_nco

set -euvx

# ********************************************
# Input
# ********************************************
here=$PWD
pysrcdir=$PWD/../src

ARCHIVE=$DIR_ARCHIVE1
TESTARCHIVE=$SCRATCHDIR/pyCECT/sample_for_pyCECT
mkdir -p $TESTARCHIVE


# !WARNING HERE !WARNING HERE !WARNING HERE
retrieve_ens=0 # activate ensemble retrievment

# !WARNING HERE !WARNING HERE !WARNING HERE
retrieve_test=0 # activate ensamble retrievment

yyyy=1993
set +euvx
. $DIR_UTIL/descr_ensemble.sh $yyyy
set -uevx
st="05"
startdate=$yyyy$st
members=$nrunmax

testname_ens="${SPSSystem}_${startdate}_test_c0"
#testname_test="${SPSSystem}_${startdate}_test_c5"
st2=11
startdate2=$yyyy$st2
testname_test="${SPSSystem}_${startdate2}_st05VSst11"

# ***************
# Input - General
# ***************
wkdir=$SCRATCHDIR/pyCECT/${testname_ens}/ensemble
test_indir=$SCRATCHDIR/pyCECT/${testname_test}/testdir 

mkdir -p ${wkdir}
mkdir -p ${test_indir}
# we are going to process monthly files (1 is monthly/ 0 is not)
ismonthly=1

# ***************
# Input - Ensamble
# ***************
cam_vars=115
#summary_file=$wkdir/ens.summary.nc
summary_file=ens.summary.nc

exclude_vars_file=$here/excluded_varlist.json
tag="${SPSSystem}_${machine}"
resolution="f05_n0253"
esize=30 #esize = number of members in $wkdir. must be > vars
etslice=1
listofcases=$(seq -w 1 15)

# ***************
# Input - Test
# ***************
ttslice=1
#testname="patch_${startdate}"
testname=$tag
numfiletocheck=5 # among files in testdir folder analyze only numfiletocheck
npc=14 # number of Pricnipal components. Must be < variables ( as a rule of thumb the 33% of total number of used vars)
logtestfile=$here/${testname_test}.log
# ********************************************

# ********************************************
# RETRIEVE ENSAMBLES
# ********************************************
if [ $retrieve_ens -eq 1 ]; then
  	cd $wkdir
	# loop over members
	  for pp in $(seq -w 001 0${members}); do 

		    caso=${SPSSystem}_${startdate}_${pp}
		    filelisttomerge=()
    		if [ ! -f $wkdir/${caso}.cam.h0.nc ]; then
			# loop over monthly h0
		   	   for month in `seq 0 $(( $nmonfore -1 )) `; do
        				monthdate=`date +%Y-%m -d "${startdate}01 + ${month} month"`
				        file=$DIR_ARCHIVE1/$caso/atm/hist/${caso}.cam.h0.${monthdate}.zip.nc
     			   	filelisttomerge+="${file} "
		    	  done
			  # merge them (using nco to keep the file structure - needed lev dimension)
			     ncrcat -O $filelisttomerge $wkdir/${caso}.cam.h0.nc
		 	#     cdo -O mergetime $filelisttomerge $wkdir/${caso}.cam.h0.nc 
		   fi
  done
fi

# ********************************************
# RETRIEVE TESTS
# ********************************************
if [ $retrieve_test -eq 1 ]; then
   ic=0
	# loop over members
  	for pp in $listofcases; do 

	    caso=${SPSSystem}_${startdate2}_0${pp}
     if [[ ! -d $DIR_ARCHIVE1/$caso ]]
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
			        file=$DIR_ARCHIVE1/$caso/atm/hist/${caso}.cam.h0.${monthdate}.zip.nc
			        filelisttomerge+="${file} "
       	done
		# merge them
		#      cdo -O mergetime $filelisttomerge $test_indir/${caso}.cam.h0.nc 
		   ncrcat -O $filelisttomerge $test_indir/${caso}.cam.h0.nc 
		# remove merged files
		   fi
     if [[ $ic -eq 5 ]]
     then
        break
     fi
  	done
fi
# ********************************************
# 0) PRELIMINARY CHECKS
# ********************************************
# ENSAMBLE
# tslice must be 0 in case of monthly files
if [ $ismonthly -eq 1 ]; then etslice=0 ; fi
cntesize=`ls -1 $wkdir/*.nc | wc -l`
if [ $esize -lt $cntesize ]; then 
	esize=$cntesize 
fi

cntexclvars=`cat $exclude_vars_file | cut -d '[' -f2 | cut -d ']' -f1 | cut -d '{' -f2  | cut -d '}' -f2 | grep -v -e '^$' | wc -l`
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
#set +uvx
#. $DIR_UTIL/condaactivation.sh 
#set -uvx
#condafunction activate CECT_stattest
set +euvx
. $DIR_UTIL/load_miniconda
set -euvx
conda activate CECT_stattest
#nmonfore=1 # just for test purposes

echo $CONDA_PREFIX
cd $here
for month in `seq 0 $(( $nmonfore -1 )) `; do
  	etslice=$month
        ttslice=$etslice
        exclude_vars_file=excluded_varlist.json 
	 if [ ! -f ${summary_file}_${month} ]; then
		    python3 $pysrcdir/pyEnsSum.py --indir $wkdir --tag $tag --sumfile ${summary_file}_${month} --mach $machine --res $resolution --tslice $etslice --esize $esize --jsonfile $exclude_vars_file

		    if [ $? -ne 0 ]; then
      			echo "Test cannot be completed due to error on ensamble summary phase. Stop." && exit 1
		    fi
	 fi
done
# pyEnsSum.py*******************************************
# 2) COMPARE TEST vs ENSAMBLE
# ********************************************
#nmonfore=1 # just for test purposes

for month in `seq 0 $(( $nmonfore -1 )) `; do
	echo "TEST FOR MONTH * $month * **************************"
	etslice=$month
	ttslice=$etslice

	echo "COMPARE TEST vs ENSAMBLE"
	python3 $pysrcdir/pyCECT.py --sumfile ${summary_file}_${month} --indir $test_indir --tslice $ttslice --nPC ${npc}  --numRunFile $numfiletocheck > ${logtestfile}_${month}_${numfiletocheck}_mem # --verbose --saveResults # --printStdMean --printVars

	if [ $? -ne 0 ]; then
		echo "Test error. Stop." && exit 1
	fi

done

# ********************************************
# Done
# ********************************************
echo "$0 Done"
exit 0 




