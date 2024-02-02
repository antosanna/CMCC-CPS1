#!/bin/sh -l
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. ${DIR_UTIL}/load_cdo
set -euxv



#halons forcing file: $CESMDATAROOT/inputdata/atm/cam/tracer_cnst/tracer_cnst_halons_3D_L70_2014-2101_CMIP6-SSP5-8.5_c190307.nc
#	"O3, OH, NO3, HO2, and HALONS from WACCM case:\n",
#			"    b.e21.BWSSP585cmip6.f09_g17.CMIP6-SSP5-8.5-WACCM.001\n",
#			"Seasonal cycles every 10 years averaged over 9 years centered on date\n",
#			"Year 2014 from year 2015 output\n",
#			"Year 2101 from average of years 2096-2100" ;

# in the historical forcing history: 	"Years 2013 and 2015 averaged from 2012-2014 output."

caseid=b.e21.BWSSP585cmip6.f09_g17.CMIP6-SSP5-8.5-WACCM.001
inp_dir=$SCRATCHDIR/SCWACCM_forcing/gpfs/fs1/p/acom/acom-climate/cesm2/postprocess/$caseid/atm/proc/tseries/day_5_zm

workdir=$SCRATCHDIR/SCWACCM_forcing/workdir
if [[ -d $workdir ]] ; then
   rm -rf $workdir 
fi
mkdir -p $workdir
cd $workdir
list_var="QRS_TOT O3 O2 O NO H CO2 PS"
yeari=2015
yearf=2105
for var in $list_var ; do
  
  year=$yeari
  while [ $year -lt $yearf ] ; do
     echo $year
     ff=`ls $inp_dir/$caseid*.$var.*$year*nc`
     fname=`basename $ff` 
     if [[ $year -eq 2095 ]] ; then
        cdo -O monmean -selyear,2095/2100 $ff ${fname}_mm
        cdo -O ymonmean -seltimestep,13/72 ${fname}_mm ${fname}_clim
     else

        cdo -O monmean $ff ${fname}_mm
        cdo -O ymonmean -seltimestep,13/120 ${fname}_mm ${fname}_clim 
        if [[ $year -eq 2015 ]] ; then 
          ff2014=${fname}_mm2014
          cdo -O selyear,2015 ${fname}_mm ${ff2014}
        fi
     fi
     year=$(($year+10))
  done

  listaf=`ls $caseid*.$var.*nc_*clim` 
  cdo -O mergetime ${ff2014} $listaf ${var}_tseries.nc

done
