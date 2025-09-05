#!/bin/sh -l
# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

set -euvx

yyyy=$1                    # year start-date
set +euvx
. ${DIR_UTIL}/descr_ensemble.sh $yyyy
set -uevx
st=$2                    # start-date 2 figures

check_done=$DIR_LOG/$typeofrun/$yyyy$st/ICs/set_forecast_ICs_${yyyy}${st}_done
if [[ -f $check_done ]]
then
   echo "already run"
   exit
fi
for ic in `seq -w 01 $n_ic_cam`
do
    bkupf=$IC_CAM_CPS_DIR/$st/${CPSSYS}.cam.i.$yyyy-$st-01-00000.$ic.bkup.nc
    if [[ ! -f $IC_CAM_CPS_DIR/$st/${CPSSYS}.cam.i.$yyyy-$st-01-00000.$ic.nc ]]
    then
        if [[ ! -f $bkupf ]]
        then
           body="CAM: CAM IC $ic was not correctly produced and  the back-up is missing too"
           title="[CAMIC] ${CPSSYS} forecast ERROR"
           ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"  -r $typeofrun -s $yyyy$st
           exit 1
        else
        
           mv $bkupf $IC_CAM_CPS_DIR/$st/${CPSSYS}.cam.i.$yyyy-$st-01-00000.$ic.nc
           body="CAM: CAM IC $ic was not correctly produced. You are going to use the back-up"
           title="[CAMIC] ${CPSSYS} forecast notification"
           ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"  -r $typeofrun -s $yyyy$st
        fi
     else
        if [[ -f $bkupf ]]
        then
           rm $bkupf
        fi
        body="CAM IC $ic correctly produced and back-up removed"
        ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -r "only" -s $yyyy$st
    fi
done
#
# replace missing CLM ICs with backup
for ic in `seq -w 01 $n_ic_clm`
do
    bkupf_clm=$IC_CLM_CPS_DIR/$st/${CPSSYS}.clm2.r.$yyyy-$st-01-00000.$ic.bkup.nc
    bkupf_rof=$IC_CLM_CPS_DIR/$st/${CPSSYS}.hydros.r.$yyyy-$st-01-00000.$ic.bkup.nc
    if [[ ! -f $IC_CLM_CPS_DIR/$st/${CPSSYS}.clm2.r.$yyyy-$st-01-00000.$ic.nc ]]
    then
        if [[ ! -f $bkupf_clm ]] || [[ ! -f $bkupf_rof ]]
        then
           body="CLM: CLM IC $ic was not correctly produced and  the back-up is missing too"
           title="[CLMIC] ${CPSSYS} forecast ERROR"
           ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"  -r $typeofrun -s $yyyy$st
           exit 1
        else
           mv $bkupf_clm $IC_CLM_CPS_DIR/$st/${CPSSYS}.clm2.r.$yyyy-$st-01-00000.$ic.nc
           mv $bkupf_rof $IC_CLM_CPS_DIR/$st/${CPSSYS}.hydros.r.$yyyy-$st-01-00000.$ic.nc
           body="CLM: CLM IC $ic was not correctly produced. You are going to use the back-up"
           title="[CLMIC] ${CPSSYS} forecast notification"
           ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"  -r $typeofrun -s $yyyy$st
        fi
     else
        if [[ -f $bkupf_clm ]]
        then
           rm $bkupf_clm
        fi
        if [[ -f $bkupf_rof ]]
        then
           rm $bkupf_rof
        fi
        body="CLM and HYDROS ICs $ic correctly produced and back-up removed"
        ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -r "only" -s $yyyy$st
    fi
done
# replace missing NEMO ICs with backup
for ic in 01 02 03 08 09
do
    bkupf_nemo=$IC_NEMO_CPS_DIR/$st/${CPSSYS}.nemo.r.$yyyy-$st-01-00000.$ic.bkup.nc
    bkupf_cice=$IC_CICE_CPS_DIR/$st/${CPSSYS}.cice.r.$yyyy-$st-01-00000.$ic.bkup.nc
    if [[ ! -f $IC_NEMO_CPS_DIR/$st/${CPSSYS}.nemo.r.$yyyy-$st-01-00000.$ic.nc ]]
    then
        if [[ ! -f $bkupf_cice ]] || [[ ! -f $bkupf_nemo ]]
        then
           body="NEMO/CICE: NEMO/CICE IC $ic was not correctly produced and  the back-up is missing too"
           title="[NEMO/CICEIC] ${CPSSYS} forecast ERROR"
           ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"  -r $typeofrun -s $yyyy$st
           exit 1
        else
           mv $bkupf_nemo $IC_NEMO_CPS_DIR/$st/${CPSSYS}.nemo.r.$yyyy-$st-01-00000.$ic.nc
           mv $bkupf_cice $IC_CICE_CPS_DIR/$st/${CPSSYS}.cice.r.$yyyy-$st-01-00000.$ic.nc
           body="NEMO: NEMO IC $ic was not correctly produced. You are going to use the back-up both for NEMO and CICE"
           title="[NEMOIC] ${CPSSYS} forecast notification"
           ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"  -r $typeofrun -s $yyyy$st
        fi
    elif [[ ! -f $IC_CICE_CPS_DIR/$st/${CPSSYS}.cice.r.$yyyy-$st-01-00000.$ic.nc ]]
    then
        if [[ ! -f $bkupf_cice ]] || [[ ! -f $bkupf_nemo ]]
        then
           body="NEMO/CICE: NEMO/CICE IC $ic was not correctly produced and  the back-up is missing too"
           title="[NEMO/CICEIC] ${CPSSYS} forecast ERROR"
           ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"  -r $typeofrun -s $yyyy$st
           exit 1
        else
           mv $bkupf_nemo $IC_NEMO_CPS_DIR/$st/${CPSSYS}.nemo.r.$yyyy-$st-01-00000.$ic.nc
           mv $bkupf_cice $IC_CICE_CPS_DIR/$st/${CPSSYS}.cice.r.$yyyy-$st-01-00000.$ic.nc
           body="CICE: CICE IC $ic was not correctly produced. You are going to use the back-up both for NEMO and CICE"
           title="[CICEIC] ${CPSSYS} forecast notification"
        fi
     else
        if [[ -f $bkupf_cice ]]
        then
           rm $bkupf_cice
        fi
        if [[ -f $bkupf_nemo ]]
        then
           rm $bkupf_nemo
        fi
        body="NEMO and CICE ICs $ic correctly produced and back-up removed"
        ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -r "only" -s $yyyy$st
    fi
done
mkdir -p $DIR_LOG/$typeofrun/$yyyy$st/ICs
touch $check_done
