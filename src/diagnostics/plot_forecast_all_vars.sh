#!/bin/sh -l
#BSUB -q s_medium
#BSUB -J plot_test
#BSUB -e logs/plot_test_%J.err
#BSUB -o logs/plot_test_%J.out
#BSUB -P 0490

. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

set -evxu

#****************************** 
#WARNING!!!
#****************************** 
# Before performing this analysis make sure you have precomputed the climatologies for the reference period (/users_home/sp2/CESM/CESM1.2/GIT/cesm/postproc/SPS35/SKILL_SCORES/ANOM)

yyyy=$1          #`date +%Y`
st=$2          #`date +%m`
nrun=$3        #50
nmf=$4
flgmnth=$5 #1  # this is to decide the timescale plot: 0 for seasonal, 1 for monthly
monthstr=$6
checkfile=$7
inputfile=$8
debug=${9:-0}

set +euvx
. ${DIR_UTIL}/descr_ensemble.sh $yyyy
set -euvx
logdir=$DIR_LOG/$typeofrun/$yyyy$st
WKDIR=$SCRATCHDIR/runtimediag/$yyyy$st
mkdir -p $WKDIR
if [[ $debug -eq 1 ]]
then
   mymail=sp1@cmcc.it #antonella.sanna@cmcc.it
   ccmail=sp1@cmcc.it #antonella.sanna@cmcc.it
fi


#****************************** 
#****************************** 

refperiod=${iniy_hind}-${endy_hind}

case $flgmnth
in
  0) tplot=seasonal ;;
  1) tplot=monthly ;;
esac

echo "Starting procedures for computing anomalies and plotting ${tplot} forecast for stardate ${yyyy}${st} up to month ${nmf}"

scriptdir=$DIR_DIAG
climdir=$CLIM_DIR_DIAG
pctldir=$PCTL_DIR_DIAG

#****************************** 
# Main var loop
#****************************** 
varlist="t2m sst precip mslp z500 u200 v200 t850"
# now postprocess files 
if [ $flgmnth -eq 1 ] ; then
#      checkdiagfile=$logdir/${nmf}_diag_DONE
      pldir=${WKDIR}/month/
else
      #l=$(($nmf - 2))     #lead season from nmf
# ANDREA-ZHIQI 20220303 to have the correct relationship between months and lead season
      l=$(($nmf - 3))     #lead season from nmf
#      checkdiagfile=$logdir/lead${l}_diag_DONE
      pldir=${WKDIR}/lead/
fi
mkdir -p $pldir

set -evx

# all vars at once
$DIR_DIAG/assembler_${CPSSYS}_runtime.sh $yyyy $st $nrun $scriptdir $nmf $WKDIR $inputfile $debug
cd $WKDIR
for var in $varlist
do
   case $var
   in
       t2m) pctlvar="TREFHT";colormap="prob_t2m";units="[~S~o~N~C]";unitsl="[~S~o~N~C]";fact=1;;
       sst) pctlvar="SST";colormap="prob_t2m";units="[K]";unitsl="[K]";fact=1     ;;
       precip) pctlvar="PREC";colormap="prob_prec";units="[mm/month]" ;unitsl="[mm/season]";fact=30  ;;
       mslp) pctlvar="MSLP";colormap="prob_t2m";units="[hPa]" ;unitsl="[hPa]"  ;fact=1  ;;
       z500) pctlvar="z500";colormap="prob_t2m";units="[m]";unitsl="[m]"    ;fact=1 ;;
       t850) pctlvar="t850";colormap="prob_t2m";units="[K]";unitsl="[K]"    ;fact=1 ;;
       u200) pctlvar="u200";colormap="prob_t2m";units="[m/s]";unitsl="[m/s]"    ;fact=1 ;;
       v200) pctlvar="v200";colormap="prob_t2m";units="[m/s]";unitsl="[m/s]"    ;fact=1 ;;
   esac
   if [ $flgmnth -eq 1 ] ; then
      count=`ls $pctldir/monthly/${var}_${st}_l?_??.nc|wc -l`
      nmaxcount=12
      export checkfilevar=$DIR_LOG/$typeofrun/$yyyy$st/${var}_month_plot_ok 
   else
      l=$(($nmf - 3))     #lead season from nmf
      export checkfilevar=$DIR_LOG/$typeofrun/$yyyy$st/${var}_l${l}_plot_ok 
      count=`ls $pctldir/${var}_${st}_l?_??.nc|wc -l`
      nmaxcount=8
   fi
   if [ $count -lt $nmaxcount ]
   then
      echo "You do not have terciles for this start-date $st and $var"
      exit 1
   fi
   set +e
#   rm -rf $WKDIR/*_${yyyy}${st}_*
   input="$yyyy $st $refperiod $var $nrun $WKDIR $flgmnth $monthstr $nmf $climdir $pctldir $pctlvar $colormap $units $unitsl $fact $pldir $debug"
   ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_m -s anom_${CPSSYS}_runtime.sh -j anom_${CPSSYS}_runtime.$var.${yyyy}${st} -d ${DIR_DIAG} -l ${logdir} -i "$input"
done

while `true` ; do

   nproc=`${DIR_UTIL}/findjobs.sh -m $machine -n anom_${CPSSYS}_runtime -c yes`
   if [ $nproc -eq 0 ] ; then
      break
   fi
   sleep 30

done

#****************************** 
# Send email 
#****************************** 

case $flgmnth
in
 1) textflag="first month" ; pdfflag="month1" ;;
 0) case $nmf
     in
     3) textflag="Lead season 0" ; pdfflag="Lead0" ;;
     4) textflag="Lead season 0 and 1" pdfflag="Lead0_1" ;;
     *) textflag="Lead season 0, 1 and 2" ; pdfflag="Lead0_1_2" ;;
    esac ;;
esac


n_var=`echo $varlist|wc -w`
if [ ${nmf} -eq 1 ] 
then
   nfiles=`ls $logdir/*_month${nmf}*_DONE|wc -l`
   if [ $nfiles -lt $n_var ] 
   then
      title="${CPSSYS} forecast ERROR"
      body="not all diagnostics ok for nmf ${nmf} $yyyy$st. Exiting $DIR_DIAG//plot_forecast_all_vars.sh"

      ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" 
      exit 1
   fi
else
   nfiles=`ls $logdir/*_lead?*_DONE|wc -l`
   if [ $nfiles -lt $(($n_var * $l )) ] 
   then
      title="${CPSSYS} forecast ERROR"
      body="not all diagnostics ok for lead ${l} $yyyy$st. Exiting $DIR_DIAG/plot_forecast_all_vars.sh"
      ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" 

      exit 1
   fi
fi
if [[ -f ${checkfile} ]]
then
   rm ${checkfile}
fi
convert ${pldir}/*${yyyy}${st}*.png ${pldir}/${yyyy}${st}_${pdfflag}.pdf
touch ${checkfile}

if [[ $? -ne 0 ]]
then
   title="${CPSSYS} forecast ERROR"
   body="pdf file not produced by script $0"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" 
   exit 1
fi

title="${CPSSYS} FORECAST $yyyy$st Diagnostics "${textflag}
body="Dear Silvio e Stefano, \n you will find attached the diagnostics for $nrun members relative to "${textflag}".\n Thank you \n"

app="${pldir}/${yyyy}${st}_${pdfflag}.pdf"

${DIR_UTIL}/sendmail.sh -m $machine -e $ccmail -M "$body" -t "$title" -c $mymail -a $app

