#!/bin/sh -l
#BSUB -q s_long
#BSUB -J fix_timesteps_C3S_1member
#BSUB -e logs/fix_timesteps_C3S_1member_%J.err
#BSUB -o logs/fix_timesteps_C3S_1member_%J.out

. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/load_nco
. $DIR_UTIL/load_cdo
set -euvx

echo "enter fix_timesteps_C3S.sh"
startdate=$1
member=$2
outdirC3S=$3

#
cd $outdirC3S
out=6hr
lista6h=`ls *6hr*_r${member}i00p00.nc`
nout=`expr $fixsimdays \* 4`
for file in $lista6h
do
      nstep=`cdo -ntime $file`
      if [ $nstep -gt $nout ]
      then
         mkdir -p $outdirC3S/wrong_${out}
         echo "FIX THIS FILE " $file
         nstepm1=$(($nstep - 1))
         ncks -Oh -F -d leadtime,1,$nstepm1 $file tmp.$file
         mv $file $outdirC3S/wrong_${out}/
         mv tmp.$file $file
      fi
done
out=12hr
lista12h=`ls *12hr*_r${member}i00p00.nc`
nout=`expr $fixsimdays \* 2`
for file in $lista12h
do
      nstep=`cdo -ntime $file`
      if [ $nstep -gt $nout ]
      then
         mkdir -p $outdirC3S/wrong_${out}
         echo "FIX THIS FILE " $file
         nstepm1=$(($nstep - 1))
         ncks -Oh -F -d leadtime,1,$nstepm1 $file tmp.$file
         mv $file $outdirC3S/wrong_${out}/
         mv tmp.$file $file
      fi
done
# daily cam files are 20 = 18 (atmos) + lwee (surface) + sic (seaIce)
out=day
listaday=`ls *atmos*day*_r${member}i00p00.nc *day*lwee*_r${member}i00p00.nc *seaIce_day*sic*_r${member}i00p00.nc`
nout=$fixsimdays
for file in $listaday
do
      nstep=`cdo -ntime $file`
      if [ $nstep -gt $nout ]
      then
         mkdir -p $outdirC3S/wrong_${out}
         echo "FIX THIS FILE " $file
         ncks -Oh -F -d leadtime,2, $file tmp.$file
         mv $file $outdirC3S/wrong_${out}/
         mv tmp.$file $file
      fi
done

echo "succesfully completed fix_timesteps_C3S.sh"
#get checkfix_timesteps from dictionary
set +euvx
. $dictionary
set -euvx
touch $checkfix_timesteps
