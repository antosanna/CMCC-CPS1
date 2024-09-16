#!/bin/sh -l

. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. $DIR_UTIL/load_cdo
. $DIR_UTIL/load_nco

set -evxu


yyyy=$1
st=$2
refperiod=$3
var=$4
nrun=$5
datamm=$6
flgmnth=$7
monthstr=$8
nmf=$9
climdir=${10}/${var}/C3S/clim
#climdir=$climdir/${var}/C3S/clim"
pctldir=${11}
pctlvar=${12}
colormap=${13}
units=${14}
unitsl=${15}
fact=${16}
pldir=${17}
dbg=${18}

set +euvx
. ${DIR_UTIL}/descr_ensemble.sh $yyyy
set -euvx
outputgrid=reg1x1
if [[ ! -d $datamm/anom ]] 
then
   mkdir -p $datamm/anom
fi

ensalllist=""
ensanomfile=$datamm/anom/${var}_${SPSSystem}_${yyyy}${st}_ens_ano.$refperiod.nc
if [[ -f $ensanomfile ]]
then
   rm $ensanomfile
fi 
ic=0
cd $datamm
# this is a different plist wrt the one in plot_forecast_all_vars.sh and in assembler_${SPSSYS}_runtime.sh
plist=`ls |grep ${SPSSystem}_${yyyy}${st}|grep "\.${nmf}.${outputgrid}"|grep $var`
for f in $plist
do
   ens=`echo $f|cut -d '_' -f3|cut -d '.' -f1`
   mergefile=$datamm/${SPSSystem}_${yyyy}${st}_${ens}.${outputgrid}.$var.nc
   if [[ -f $mergefile ]]
   then
      rm $mergefile
   fi
   if [[ `ls $datamm/${SPSSystem}_${yyyy}${st}_${ens}.?.${outputgrid}.$var.nc|wc -l` -gt 1 ]]
   then
      cdo -mergetime $datamm/${SPSSystem}_${yyyy}${st}_${ens}.?.${outputgrid}.$var.nc $mergefile
# if there is only one month
   else
      cp $datamm/${SPSSystem}_${yyyy}${st}_${ens}.?.${outputgrid}.$var.nc $mergefile
   fi
   filein=${SPSSystem}_${yyyy}${st}_${ens}.${outputgrid}.$var.nc
   if [[ -f $datamm/anom/${var}_${SPSSystem}_${yyyy}${st}_${ens}_ano.$refperiod.nc ]]
   then
      rm $datamm/anom/${var}_${SPSSystem}_${yyyy}${st}_${ens}_ano.$refperiod.nc
   fi
   cdo sub -seltimestep,1/$nmf $datamm/${filein} -seltimestep,1/$nmf $climdir/${var}_${SPSSYS}_clim_$refperiod.${st}.nc $datamm/anom/${var}_${SPSSystem}_${yyyy}${st}_${ens}_ano.$refperiod.nc
   ic=`expr $ic + 1`
   ensalllist="$ensalllist $datamm/anom/${var}_${SPSSystem}_${yyyy}${st}_${ens}_ano.$refperiod.nc"
   if [ $ic -gt $nrun ]
   then
       break
   fi 
done #while on $plist
allanomfile=$datamm/anom/${var}_${SPSSystem}_${yyyy}${st}_all_ano.$refperiod.nc
if [[ -f $allanomfile ]]
then
   rm $allanomfile
fi
cdo -O ensmean $ensalllist $ensanomfile
tmpfile=$datamm/anom/tmp.${var}_${SPSSystem}_${yyyy}${st}.nc
cdo settaxis,$yyyy-$st-15,12:00,1mon $ensanomfile $tmpfile
cdo setreftime,$yyyy-$st-15,12:00 $tmpfile $ensanomfile
rm $tmpfile
ncecat -O  $ensalllist $allanomfile
  
# NOW DO THE PLOT
$DIR_DIAG/forecast_auto.sh $yyyy $st $nrun $flgmnth $nmf $DIR_DIAG ${monthstr} ${var} $pldir $pctldir $colormap $units $unitsl $datamm/anom $fact $dbg
