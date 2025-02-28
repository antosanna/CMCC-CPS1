#!/bin/sh -l

# create masks for vertinterpZT that will recompute the field where the mask is set to 0
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. ${DIR_UTIL}/load_cdo
set -evxu
yyyy=$1
st=$2
dirout=$REPOSITORY/masksPS/$yyyy
dirwork=$SCRATCHDIR/extrapTZ/monthly_PS/
outdirmin=$REPOSITORY/monthly_PS/ensminPS/$yyyy
outdirmax=$REPOSITORY/monthly_PS/ensmaxPS/$yyyy
outdirmean=$REPOSITORY/monthly_PS/ensmeanPS/$yyyy
mkdir -p $dirwork $outdirmin $outdirmax $outdirmean $dirout
echo 'extract STARTS ' `date`
#------------------------------------
if [[ ! -f $outdirmin/PS.sps4_${yyyy}${st}.min.C3S.nc.gz ]]
then
   cdo -O -ensmin $dirwork/sps4_${yyyy}${st}_0??/PS.sps4_${yyyy}${st}_0??.C3S.nc $outdirmin/PS.sps4_${yyyy}${st}.min.C3S.nc
   gzip -f $outdirmin/PS.sps4_${yyyy}${st}.min.C3S.nc
fi
if [[ ! -f $outdirmax/PS.sps4_${yyyy}${st}.max.C3S.nc.gz ]]
then
if [[ ! -f $outdirmax/PS.sps4_${yyyy}${st}.max.C3S.nc ]]
then
   cdo -O -ensmax $dirwork/sps4_${yyyy}${st}_0??/PS.sps4_${yyyy}${st}_0??.C3S.nc $outdirmax/PS.sps4_${yyyy}${st}.max.C3S.nc
fi
fi
if [[ ! -f $outdirmean/PS.sps4_${yyyy}${st}.mean.C3S.nc ]]
then
   cdo -O -ensmean $dirwork/sps4_${yyyy}${st}_0??/PS.sps4_${yyyy}${st}_0??.C3S.nc $outdirmean/PS.sps4_${yyyy}${st}.mean.C3S.nc
   rm -rf $dirwork/sps4_${yyyy}${st}_0??/
fi
#
cd $dirout
if [[ ! -f $dirout/mask.$yyyy$st.925hPa.nc ]]
then
   cdo -setrtoc2,0,95500,0,1 $outdirmax/PS.sps4_${yyyy}${st}.max.C3S.nc $dirout/mask.$yyyy$st.925hPa.nc
fi
if [[ ! -f $dirout/mask.$yyyy$st.1000hPa.nc ]]
then
   cdo -setrtoc2,0,105000,0,1 $outdirmax/PS.sps4_${yyyy}${st}.max.C3S.nc $dirout/mask.$yyyy$st.1000hPa.nc
fi
if [[ -f $outdirmax/PS.sps4_${yyyy}${st}.max.C3S.nc ]]
then
   gzip $outdirmax/PS.sps4_${yyyy}${st}.max.C3S.nc
fi
