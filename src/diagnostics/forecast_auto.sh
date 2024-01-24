#!/bin/sh -l

. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

set -exuv

cd $HOME
todonow=0
# -------------------------------
# get the date from system
# -------------------------------
export yyyy=$1
echo $yyyy
export st=$2
export nrun=$3
export flgmnth=$4
nmf=$5
scriptdir=$6
export monthstr=$7
export var=$8
pldir=${9}
pctldir=${10}
export colormap=${11}  #prob_t2m
export units=${12}
export unitsl=${13}  #for lead season units may change (see precip)
export inputdir=${14}  #for lead season units may change (see precip)
export fact=${15}
debug=${16}

# ANTO new for automatic diagnositcs+
set +euvx
. ${DIR_UTIL}/descr_ensemble.sh $yyyy
set -euvx
# ANTO new for automatic diagnositcs-

case $flgmnth
in
# for lead season lead=$nmf - 3
   0) export lead=$(($nmf - 3)) ; export pathterc=$pctldir ;;
   1) export lead=$(($nmf - 1)) ; export pathterc=$pctldir/monthly/ ;;
esac

export pltype="png"
#if [[ $debug -eq 1 ]]
#then
#  export pltype="x11"
#fi
# -------------------------------
# go to graphic dir
# -------------------------------
cd $scriptdir/ncl
# -------------------------------
# -------------------------------
# plot current conditions wrt ${iniy_hind}-${endy_hind}
# -------------------------------

export S=( "ppp" "ppp" "ppp" "ppp" )
case $st 
in
   01) S[1]="JFM";S[2]="FMA";S[3]="MAM";S[4]="AMJ";;
   02) S[1]="FMA";S[2]="MAM";S[3]="AMJ";S[4]="MJJ";;
   03) S[1]="MAM";S[2]="AMJ";S[3]="MJJ";S[4]="JJA";;
   04) S[1]="AMJ";S[2]="MJJ";S[3]="JJA";S[4]="JAS";;
   05) S[1]="MJJ";S[2]="JJA";S[3]="JAS";S[4]="ASO";;
   06) S[1]="JJA";S[2]="JAS";S[3]="ASO";S[4]="SON";;
   07) S[1]="JAS";S[2]="ASO";S[3]="SON";S[4]="OND";;
   08) S[1]="ASO";S[2]="SON";S[3]="OND";S[4]="NDJ";;
   09) S[1]="SON";S[2]="OND";S[3]="NDJ";S[4]="DJF";;
   10) S[1]="OND";S[2]="NDJ";S[3]="DJF";S[4]="JFM";;
   11) S[1]="NDJ";S[2]="DJF";S[3]="JFM";S[4]="FMA";;
   12) S[1]="DJF";S[2]="JFM";S[3]="FMA";S[4]="MAM";;
esac

# -------------------------------
# do only one plot
# -------------------------------
l=$(($lead + 1))
export plname="${pldir}/${var}_ano_forecast_glo_${yyyy}${st}_month${l}"
export units=$units
export prob_low=$pathterc/${var}_${st}_l${lead}_33.nc
export prob_up=$pathterc/${var}_${st}_l${lead}_66.nc
if [ $flgmnth -eq 0 ] ; then
   export SS=${S[$l]}
   export plname="${pldir}/${var}_ano_forecast_glo_${yyyy}${st}_lead${lead}"
   export units=$unitsl
fi
export checkfile=$DIR_LOG/$typeofrun/$yyyy$st/`basename ${plname}`"_plot_DONE"
if [[ -f $checkfile ]]
then
   rm $checkfile
fi
#
export inputm="$inputdir/${var}_${SPSsystem}_${yyyy}${st}_ens_ano.${iniy_hind}-${endy_hind}.nc"
export inputmall="$inputdir/${var}_${SPSsystem}_${yyyy}${st}_all_ano.${iniy_hind}-${endy_hind}.nc"

export mproj="CylindricalEquidistant"
#export mproj="Robinson"
ncl season_lead_glo_2cat.ncl   # but this can perform also monthly diagnostics if $flgmnth -eq 1
if [ ! -f $checkfile ]
then
   body="$DIR_DIAG/ncl/season_lead_glo_2cat.ncl not correctly ended for $var ${yyyy}${st}"
   title="[diags] ${SPSSYS} forecast error"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "$typeofrun" -s $yyyy$st
   exit 1
fi

# -------------------------------
# ALL DONE
# -------------------------------
