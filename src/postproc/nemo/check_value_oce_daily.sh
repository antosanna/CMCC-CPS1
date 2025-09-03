#!/bin/sh -l

set -x

input=$1
scriptdir=$2

caso=`echo $input | cut -d '/' -f6`
filetype=`echo $input | cut -d '.' -f3`
yyst=`echo $input | cut -d '_' -f2 | cut -c1-4`
st=`echo $input | cut -d '_' -f2 | cut -c5-6`
pp=`echo $input | cut -d '_' -f3 | cut -c1-3`
year=`echo $input | cut -d '.' -f4 | cut -d '-' -f1`
mm=`echo $input | cut -d '.' -f4 | cut -d '-' -f2`

case $filetype
    in
    U) varlist="vozocrtx" ;;
    V) varlist="vomecrty" ;;
    Tglobal) varlist="ssh sss" ;;
esac

for var in $varlist ; do

    case $var
     in
     vozocrtx|vomecrty) vmin=-5 ; vminw=-1.5  ; vmax=5 ; vmaxw=1.5  ;;
     ssh) vmin=-5  ; vmax=5 ; vminw=-3 ; vmaxw=3   ;;
     sss) vmin=0 ; vminw=0 ; vmaxw=42 ; vmax=55 ;;
    esac

    cdo timmin -fldmin -timmean -selname,$var $input $scriptdir/min_$caso.nc 
    cdo -ltc,$vmin $scriptdir/min_$caso.nc $scriptdir/min_flag_$caso.nc
    min=`cdo infov $scriptdir/min_$caso.nc | grep $var | awk {'print $9'}`
    min_flag=`cdo infov $scriptdir/min_flag_$caso.nc | grep $var | awk {'print $9'} | cut -c1-1`
    cdo -ltc,$vminw $scriptdir/min_$caso.nc $scriptdir/minw_flag_$caso.nc
    minw_flag=`cdo infov $scriptdir/minw_flag_$caso.nc | grep $var | awk {'print $9'} | cut -c1-1`
    rm $scriptdir/min*_$caso.nc
    cdo timmax -fldmax -timmean -selname,$var $input $scriptdir/max_$caso.nc 
    cdo -gtc,$vmax $scriptdir/max_$caso.nc $scriptdir/max_flag_$caso.nc
    max=`cdo infov $scriptdir/max_$caso.nc | grep $var | awk {'print $9'}`
    max_flag=`cdo infov $scriptdir/max_flag_$caso.nc | grep $var | awk {'print $9'} | cut -c1-1`
    cdo -gtc,$vmax $scriptdir/max_$caso.nc $scriptdir/maxw_flag_$caso.nc
    maxw_flag=`cdo infov $scriptdir/maxw_flag_$caso.nc | grep $var | awk {'print $9'} | cut -c1-1`
    rm $scriptdir/max*_$caso.nc


    if [[ $min_flag -eq 1 ]] || [[ $max_flag -eq 1 ]] ; then
        echo "$var: min value= $min, cmor_min= $vmin" >> $HOME/CESM/CESM1.2/GIT/cesm/cases/$caso/QC/ocn/check_oce_daily_${yyst}${st}_${pp}_${year}${mm}.txt
        echo "$var: max value= $max, cmor_max= $vmax" >> $HOME/CESM/CESM1.2/GIT/cesm/cases/$caso/QC/ocn/check_oce_daily_${yyst}${st}_${pp}_${year}${mm}.txt
        echo "$input WRONG VALUES" >> $HOME/CESM/CESM1.2/GIT/cesm/cases/$caso/QC/ocn/check_oce_daily_${yyst}${st}_${pp}_${year}${mm}.txt
        echo " "
    elif [[ $minw_flag -eq 1 ]] || [[ $maxw_flag -eq 1 ]] ; then
        echo "$var: min value= $min, warn_min= $vminw" >> $HOME/CESM/CESM1.2/GIT/cesm/cases/$caso/QC/ocn/check_oce_daily_${yyst}${st}_${pp}_${year}${mm}.txt
        echo "$var: max value= $max, warn_max= $vmaxw" >> $HOME/CESM/CESM1.2/GIT/cesm/cases/$caso/QC/ocn/check_oce_daily_${yyst}${st}_${pp}_${year}${mm}.txt
        echo "$input WARNING" >> $HOME/CESM/CESM1.2/GIT/cesm/cases/$caso/QC/ocn/check_oce_daily_${yyst}${st}_${pp}_${year}${mm}.txt
        echo " "
    #else
    #    echo "$var: min value= $min, cmor_min= $vmin" >> $HOME/CESM/CESM1.2/GIT/cesm/cases/$caso/QC/ocn/check_oce_daily_${yyst}${st}_${pp}_${year}${mm}.txt
    #    echo "$var: max value= $max, cmor_max= $vmax" >> $HOME/CESM/CESM1.2/GIT/cesm/cases/$caso/QC/ocn/check_oce_daily_${yyst}${st}_${pp}_${year}${mm}.txt
    #    echo "$input CORRECT" >> $HOME/CESM/CESM1.2/GIT/cesm/cases/$caso/QC/ocn/check_oce_daily_${yyst}${st}_${pp}_${year}${mm}.txt
    #    echo " "
    fi
done
