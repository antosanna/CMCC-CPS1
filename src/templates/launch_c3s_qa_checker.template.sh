#!/bin/sh -l
#-------------------------------------------------------------------------------
# Script to check produced forecast
#-------------------------------------------------------------------------------
#--------------------------------
. $HOME/.bashrc

set -evxu

namespace=$1
startdate=$2
member=$3
jsonf=$4
reduced=$5
wdir=$6

echo "activate env *********************"

set +euvx
  . $DIR_UTIL/condaactivation.sh 
  condafunction activate qachecker 
set -euvx


echo "retrieve fields ******************"
output=$wdir/output
mkdir -p $output

cd $wdir
if [[ -d $wdir/tempdir_${namespace} ]] ; then
    rm -rf $wdir/tempdir_${namespace}
fi 

mkdir -p $wdir/tempdir_${namespace}

netcdf2check=`ls -1 *$namespace*.nc`

for ncfile in $netcdf2check ; do

    # get variable name
    logname=`echo $ncfile  | cut -d _ -f5-15 | cut -d . -f1`
    varname=`echo $logname  | cut -d _ -f4`

    if [[  -f $output/$logname.txt ]] ; then 
        rm $output/$logname.txt
    fi

    # copy to tempdir
    rsync -auv $ncfile $wdir/tempdir_${namespace}
    if [[  $varname == "tasmin" ]] ; then 
       netcdfaux_sic=`ls -1 $outdirC3S/*seaIce_day_surface_sic*r${member}*.nc`
       rsync -auv $netcdfaux_sic $wdir/tempdir_${namespace}

       netcdfaux_mask=`ls -1 $outdirC3S/*atmos_fix_surface_sftlf*r${member}*.nc`
       rsync -auv $netcdfaux_mask $wdir/tempdir_${namespace} 
    fi
    

    scratch4outl=$SCRATCHDIR/checker_${startdate}/$member/$namespace/
    if [[ -d $scratch4outl ]] ; then
        rm -r $scratch4outl
    fi
    mkdir -p $scratch4outl
    if [[ $reduced -eq 1 ]] ; then
      # launch python (checking files in tempdir_\$namespace)
      # adding -pclim input activates the climatological check on monthly min/max, while -pqval activates the interquantile one 
         python c3s_qa_checker.py $ncfile -sld ${spike_list_dmo} -dmo $REPOSITORY/lsm_sps4.nc -sl $spike_list -p $wdir/tempdir_${namespace} -j $jsonf -exp $startdate -real $member --logdir $output/ --verbose >> $output/$logname.txt
    else
       # WILL BE THE ABOVE ONCE THE HINDCAST CLIMATOLOGIES WILL BE COMPUTED
       python c3s_qa_checker.py $ncfile -p $wdir/tempdir_${namespace} -pclim $OUTDIR_DIAG/C3S_statistics -u -scd $scratch4outl -j $jsonf -exp $startdate -real $member --logdir $output/ --verbose >> $output/$logname.txt
    fi
    # remove files
    if [[ $? -eq 0 ]] ; then
        echo Once finished, clean file...
        rm $wdir/$ncfile   
    else
        exit 1
    fi

done

cd $ACTDIR

# remove and touch done file
if [[ -f NSDONE_${namespace} ]] ; then
    rm -r NSDONE_${namespace}
fi 
touch NSDONE_${namespace}

# remove temporary dir
if [[ -f NSDONE_${namespace} ]] ; then
    rm -rf $wdir/tempdir_${namespace}
fi

exit 0
