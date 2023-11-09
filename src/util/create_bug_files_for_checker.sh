#!/bin/sh -l 
# TO BE MODIFIED
#BSUB -P 0490
#BSUB -q s_short
#BSUB -J create_qa_test
#BSUB -o logs/create_qa_test_%J.out
#BSUB -e logs/create_qa_test_%J.err
#BSUB -N 
#BSUB -u mariadm.chaves@cmcc.it
################################################################################################
# Create test files for controling qa_checker tests
################################################################################################

. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/load_nco
. $DIR_UTIL/load_cdo
 
set -euvx

wdir=$SCRATCHDIR/test_qa_checker
if [ -d $wdir ] ; then
   rm -rf $wdir
fi
mkdir -p $wdir
cd $wdir

#Select the yyyy and st of file (fixed for template)
templatedir=/data/csp/sp1/archive/CESM/${SPSSYS}/C3S_template
yyyy=2000
st=10
ens=01

#copy original files to $wdir
# tasmax and sic for testing spikes
ftasmax="cmcc_CMCC-CM2-v20191201_hindcast_S${yyyy}${st}0100_atmos_day_surface_tasmax_r${ens}i00p00.nc"
rsync -auv $templatedir/$ftasmax $wdir/$ftasmax
fsic="cmcc_CMCC-CM2-v20191201_hindcast_S${yyyy}${st}0100_seaIce_day_surface_sic_r${ens}i00p00.nc"
rsync -auv $templatedir/$fsic $wdir/$fsic
# Now insert errors in the test file to verify the tests:
ncap2 -O -s 'tasmax(9,170,170:175)=500' $wdir/$ftasmax $wdir/$ftasmax # 5 spikes

# Various variables to test general checks
fzg="cmcc_CMCC-CM2-v20191201_hindcast_S${yyyy}${st}0100_atmos_12hr_pressure_zg_r${ens}i00p00.nc"
rsync -auv $templatedir/$fzg $wdir/$fzg
# Insert consistency errors
ncap2 -O -s 'zg[1,10,:,:]=0' $wdir/$fzg $wdir/$fzg										# 1 time 1 level is all 0
ncap2 -O -s 'zg[1,10,:,:]=-300' $wdir/$fzg $wdir/$fzg 						# 1 time 1 level is all constant (within CMOR limit values)
ncap2 -O -s 'zg[1,1,50,50]=nan' $wdir/$fzg $wdir/$fzg 						# 1 point NaN
ncap2 -O -s 'zg[1,1,100,100]=Inf' $wdir/$fzg $wdir/$fzg 				# 1 point Inf
ncap2 -O -s 'zg[1,2,50,50]=400000' $wdir/$fzg $wdir/$fzg 			# 1 point larger than CMOR limit
ncap2 -O -s 'zg[1,2,100,100]=-8000' $wdir/$fzg $wdir/$fzg 		# 1 point smaller than CMOR limit
ncap2 -O -s 'zg[:,3,:,:]=100' $wdir/$fzg $wdir/$fzg 								# 1 level has std=0 over time

# Add other types of vars
#flwee="cmcc_CMCC-CM2-v20191201_hindcast_S${yyyy}${st}0100_land_day_surface_lwee_r${ens}i00p00.nc"
#rsync -auv $templatedir/$flwee $wdir/$flwee 
#file2append="cmcc_CMCC-CM2-v20191201_hindcast_S${yyyy}${st}0100_atmos_6hr_surface_psl_r${ens}i00p00.nc"
#file2append="cmcc_CMCC-CM2-v20191201_hindcast_S${yyyy}${st}0100_land_6hr_surface_tsl_r${ens}i00p00.nc"
#file2append="cmcc_CMCC-CM2-v20191201_hindcast_S${yyyy}${st}0100_land_day_soil_mrlsl_r${ens}i00p00.nc"
#file2append="cmcc_CMCC-CM2-v20191201_hindcast_S${yyyy}${st}0100_ocean_6hr_surface_tso_r${ens}i00p00.nc"
#fsos="cmcc_CMCC-CM2-v20191201_hindcast_S2000100100_ocean_mon_ocean2d_sos_r01i00p00.nc"
#rsync -auv $templatedir/$fsos $wdir/$fsos 

exit 0


