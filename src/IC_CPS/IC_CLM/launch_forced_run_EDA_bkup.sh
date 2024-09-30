#!/bin/sh -l
#-------------------------------------------------------------------------------
#-------------------------------------------------------------
# load variables from descriptor
#-------------------------------------------------------------
#------------------------------------------------

. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
set -euvx

dbg=${6:-0}

#------------------------------------------------
#-------------------------------------------------------------
# Set time variables
#-------------------------------------------------------------
#------------------------------------------------

yy=$1  #year month preceding start-date       
mm2d=$2  #month preceding start-date !!! this is 2 digits
member2d=$3
icclm=$4
ichydros=$5

bkup=1
mm=$((10#$mm2d))
member=$((10#$member2d))
st=`date -d ' '$yy${mm2d}01' + 1 month' +%m`
yyyy=`date -d ' '$yy${mm2d}01' + 1 month' +%Y`

set +euvx
. ${DIR_UTIL}/descr_ensemble.sh $yyyy
set -euvx

if [ $dbg -eq 1 ] 
then
   forcDIReda=$SCRATCHDIR/inputs/FORC4CLM
   if [ ! -d $forcDIReda ]  
   then
       echo "Missing folder $forcDIReda. Note that you are in dbg mode."
       exit 1
   fi  
fi
if  [[ -f $icclm ]] && [[ -f $ichydros ]] 
then
    echo "backup IC $icclm and $ichydros already computed" 
    exit
fi

############
preffixtempl="clmforc.EDA${member}.0.5d"
preffix="clmforc.EDA${member}.backup.0.5d"
templdir=$forcDIReda/EDA_n${member}
forcing_dir=$forcDIReda/EDA_n${member}_backup
mkdir -p ${forcing_dir}
#------------------------------------------------
#-------------------------------------------------------------
# Check CLM forcing
#-------------------------------------------------------------
#------------------------------------------------

# got to the working dir
mkdir -p $WORKDIR_LAND
cd $WORKDIR_LAND

# first check if all the required forcing files are present: CLM is not conceived to work as forecast model and requires always all the forcings for the entire designed period (for instance in our set-up from 2015 to 2030) 
echo ' '
echo 'Checking CLM forcing files for period 2015-2030 '
echo '-----------------------------------------'

y00=2015
yend=2030
yyf=$y00
while [ $yyf -le $yend ]
do
   echo ' '
   echo 'Checking CLM forcing files for year ' $yyf
   echo '-----------------------------------------'
   echo 'Checking perturbation dir ' $forcing_dir
   for vartype in Precip Solar TPHWL
   do

	 case $vartype in
              Precip) varname=Prec ;;
              Solar)  varname=Solr ;;
              TPHWL)  varname=TPQWL ;;
         esac

         echo 'Checking vartype ' $vartype
         mkdir -p ${forcing_dir}/$vartype
         missingfiles=" "
         for actmon in {01..12}
         do
            file2check=${forcing_dir}/$vartype/${preffix}.${varname}.$yyf-$actmon.nc
            if [[ -f  $file2check ]] ; then
               rm $file2check
            fi
            if [[ ! -f $file2check ]] || [[ ! -L $file2check ]] ; then
                if [ -f $templdir/$vartype/${preffixtempl}.${varname}.$yyf-$actmon.nc ]
                then
                    ln -sf $templdir/$vartype/${preffixtempl}.${varname}.$yyf-$actmon.nc $forcing_dir/$vartype/${preffix}.${varname}.$yyf-$actmon.nc
                else
                    missingfiles+=" $yyf-$actmon"
                fi
            elif [[ -L $file2check ]] ; then
                  echo "OK $file2check is already a link!"
            fi
         done
            if [[ $missingfiles != " " ]]
            then
               body="CLM ICs: from $DIR_LND_IC/launch_forced_run_EDA_bkup.sh. Some CLM forcings $vartype missing in dir $templdir for year $yyf. It is impossible to make the link in $forcing_dir. Job exiting now. Missing files for: $missingfiles "
               title="[CLMIC-backup] ${CPSSYS} forecast ERROR"
               ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r yes -s ${yyyy}${st}
               exit 1
            fi
      done
      echo ' '
   yyf=$(($yyf + 1))
done

#------------------------------------------------
#-------------------------------------------------------------
# Create the forcings for CLM stand-alone, check, send mail
#-------------------------------------------------------------
#------------------------------------------------

if [[ -f $forcing_dir/Solar/${preffix}.Solr.${yy}-${mm2d}.nc ]]; then
    rm $forcing_dir/Solar/${preffix}.Solr.${yy}-${mm2d}.nc
elif [[ -L $forcing_dir/Solar/${preffix}.Solr.${yy}-${mm2d}.nc ]]; then
    unlink $forcing_dir/Solar/${preffix}.Solr.${yy}-${mm2d}.nc
fi
if [[ -f $forcing_dir/Precip/${preffix}.Prec.${yy}-${mm2d}.nc ]]; then
    rm $forcing_dir/Precip/${preffix}.Prec.${yy}-${mm2d}.nc
elif [[ -L $forcing_dir/Precip/${preffix}.Prec.${yy}-${mm2d}.nc ]] ; then    
    unlink $forcing_dir/Precip/${preffix}.Prec.${yy}-${mm2d}.nc
fi
if [[ -f $forcing_dir/TPHWL/${preffix}.TPQWL.${yy}-${mm2d}.nc ]]; then
    rm $forcing_dir/TPHWL/${preffix}.TPQWL.${yy}-${mm2d}.nc
elif [[ -L $forcing_dir/TPHWL/${preffix}.TPQWL.${yy}-${mm2d}.nc ]] ;then
   unlink $forcing_dir/TPHWL/${preffix}.TPQWL.${yy}-${mm2d}.nc
fi

##mv to temporary file the input for the following month (yyyy,st)
filesolar_mp1=$forcing_dir/Solar/${preffix}.Solr.${yyyy}-${st}.nc
if [ ! -f ${filesolar_mp1} ] || [ ! -L ${filesolar_mp1} ] ; then
   body="CLM ICs: Problems with EDA${member} inputs for create_edaFORC.sh. Missing Solr.${yyyy}-${st}"
   title="[CLMIC-backup] ${CPSSYS} forecast error"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r yes -s ${yyyy}${st}
   exit 1
fi

fileprec_mp1=$forcing_dir/Precip/${preffix}.Prec.${yyyy}-${st}.nc
if [ ! -f ${fileprec_mp1} ] || [ ! -L ${fileprec_mp1} ] ; then
  body="CLM ICs: Problems with EDA${member} inputs for create_edaFORC.sh. Missing Prec.${yyyy}-${st}"
  title="[CLMIC-backup] ${CPSSYS} forecast error"
  ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r yes -s ${yyyy}${st}
  exit 1
fi

fileTP_mp1=$forcing_dir/TPHWL/${preffix}.TPQWL.${yyyy}-${st}.nc
if [ ! -f ${fileTP_mp1} ] || [ ! -L ${fileTP_mp1} ] ; then
  body="CLM ICs: Problems with EDA${member} inputs for create_edaFORC.sh. Missing TPQWL.${yyyy}-${st}"
  title="[CLMIC-backup] ${CPSSYS} forecast error"
  ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r yes -s ${yyyy}${st}
  exit 1
fi



# create files with last analysis data
mkdir -p $DIR_LOG/$typeofrun/${yyyy}${st}/IC_CLM
checkfile=$DIR_LOG/$typeofrun/${yyyy}${st}/IC_CLM/create_edaFORC.sh_${yyyy}${st}_n${member}_bkup_ok
# here sourcing lastday from create_era5FORC.sh
. ${DIR_LND_IC}/create_edaFORC.sh $yy $mm $member $bkup $checkfile $dbg
if [[ ! -f $checkfile ]]
then
   body="CLM ICs: Forcing files from EDA${member} data NOT created
      generating scripts:
      $DIR_LND_IC/create_era5FORC.sh
      "
   title="[CLMIC-backup] ${CPSSYS} $typeofrun ERROR"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r yes -s ${yyyy}${st}

fi



if [ ${dbg} -eq 1 ]
then
   exit 0
fi

check_mv=$DIR_LOG/$typeofrun/${yyyy}${st}/IC_CLM/mv_IC_EDA${member}_bkup_done
finaldir=${IC_CPS_guess}/CLM/$st
mkdir -p $finaldir     #REDUNDANT BUT SAFER  

errorflag=${DIR_LOG}/$typeofrun/${yyyy}${st}/IC_CLM/clm_run_error_touch_EDA${member}.bkup.${yyyy}${st}
refcase=cm3_lndSSP5-8.5_bgc_NoSnAg_eda${member}_op
casoincomplete=incomplete_EDA${member}.bkup_SSP5-8.5_${yy}${mm2d}`printf '%.2d' ${lastday}`

${DIR_LND_IC}/clone_case_forced_analysis_incomplete.sh $yy $mm2d $lastday $casoincomplete $refcase ${check_mv} $icclm $ichydros $member ${errorflag} $bkup

exit 0
