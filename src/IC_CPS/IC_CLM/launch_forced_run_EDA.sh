#!/bin/sh -l
#-------------------------------------------------------------------------------
#-------------------------------------------------------------
# load variables from descriptor
#-------------------------------------------------------------
#------------------------------------------------

. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. ${DIR_UTIL}/load_nco
set -euvx

dbg=${8:-0}

#------------------------------------------------
#-------------------------------------------------------------
# Set time variables
#-------------------------------------------------------------
#------------------------------------------------

yy=$1  #year month preceding start-date       
mm2d=$2  #month preceding start-date !!! this is 2 digits
member2d=$3
member=$((10#$member2d))
icclm=$4
ichydros=$5
check_incomplete=$6
errorflag=$7

backup=0
mm=$((10#$mm2d))
st=`date -d ' '$yy${mm2d}01' + 1 month' +%m`
yyyy=`date -d ' '$yy${mm2d}01' + 1 month' +%Y`

set +euvx
. ${DIR_UTIL}/descr_ensemble.sh $yyyy
set -euvx

mkdir -p $DIR_LOG/${typeofrun}/${yyyy}${st}/IC_CLM/


if [ $dbg -eq 1 ] 
then
   forcDIReda=$SCRATCHDIR/inputs/FORC4CLM
   if [ ! -d $forcDIReda ]  
   then
       echo "Missing folder $forcDIReda. Note that you are in dbg mode."
       exit 1
   fi  
fi
############
preffix="clmforc.EDA${member}.0.5d"
forcing_dir=$forcDIReda/EDA_n${member}

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

#for the previous years the atmospheric forcing must be present (it has been used in previous operational forecast)
#if the files are missing, an error message is sent and the routine is interrupted
while [ $yyf -lt $yy ]
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
         county=`ls $forcing_dir/$vartype/${preffix}.${varname}.$yyf-??.nc|wc -l`
         nreq_files=12
         if [ $county -ne $nreq_files ]
         then
            missingfiles=" "
            for actmon in {01..12}
            do  
               if [ `ls $forcing_dir/$vartype/${preffix}.${varname}.$yyf-$actmon.nc|wc -l` -eq 0 ] 
               then
                  missingfiles+=" $yyf-$actmon"
               fi  
            done
            body="CLM ICs: from $DIR_LND_IC/launch_forced_run_EDA.sh (member $member). Some CLM forcings $vartype missing in dir $forcing_dir for year $yyf job exiting now. Missing files for: $missingfiles "
            title="[CLMIC] ${CPSSYS} $typeofrun ERROR"
            ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r yes -s ${yyyy}${st}
            exit
         else
            echo 'Forcings ok '
         fi
      done
      echo ' '
   yyf=$(($yyf + 1))
done

#for the current year (months previous to the current one) the atmospheric forcing must be present (it has been used in previous operational forecast) - if the files are missing, an error message is sent and the routine is interrupted
#for the current year (months following the current one) + following years, the atmospheric forcing files must be present for CLM to run but can be replaced by an old one (the actual values are not read by the model, only the time axis need to be corrected)

yyf=$yy
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
      missingfiles=" "
      echo 'Checking vartype ' $vartype
      if [ $yyf -eq $yy ] ; then
         month=1
         while [ $month -lt $mm ]  ; do
           month2d=`printf '%.2d' $month`
           if [ `ls $forcing_dir/$vartype/${preffix}.${varname}.$yyf-$month2d.nc|wc -l` -eq 0 ] ; then
              missingfiles+=" $yyf-$month2d"
           fi
           if [[ $missingfiles != " " ]]
           then
              body="CLM ICs: from $DIR_LND_IC/launch_forced_run_EDA.sh (member $member). Some CLM forcings $vartype missing in dir $forcing_dir for year $yyf job exiting now. Missing files for: $missingfiles "
              title="[CLMIC] ${CPSSYS} ${typeofrun} ERROR"
              ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r yes -s ${yyyy}${st}
              exit
           fi
           month=$(($month  +1))
         done
         month=$mm
         while [ $month -le 12 ] ; do
           month2d=`printf '%.2d' $month`
           if [ ! -f $forcing_dir/$vartype/${preffix}.${varname}.$yyf-$month2d.nc ] ; then
               
               cp $forcing_dir/$vartype/${preffix}.${varname}.2015-${month2d}.nc $forcing_dir/$vartype/${preffix}.${varname}.$yyf-${month2d}.nc
               ncatted -a units,time,m,c,"days since ${yyf}-${month2d}-01 00:00:00" $forcing_dir/$vartype/${preffix}.${varname}.$yyf-${month2d}.nc
           fi
           month=$(($month  +1))
         done
      else
         month=1
         while [ $month -le 12 ] ; do
             month2d=`printf '%.2d' $month`
             if [ ! -f $forcing_dir/$vartype/${preffix}.${varname}.$yyf-$month2d.nc ] ; then
 
                  cp $forcing_dir/$vartype/${preffix}.${varname}.2015-${month2d}.nc $forcing_dir/$vartype/${preffix}.${varname}.$yyf-${month2d}.nc
                  ncatted -a units,time,m,c,"days since ${yyf}-${month2d}-01 00:00:00" $forcing_dir/$vartype/${preffix}.${varname}.$yyf-${month2d}.nc
          
             fi
             month=$(($month  +1))  
         done
      fi
   done
   yyf=$(($yyf + 1))
done

#------------------------------------------------
#-------------------------------------------------------------
# Create the forcings for CLM stand-alone, check, send mail
#-------------------------------------------------------------
#------------------------------------------------
# remove files for current month if they exists for safety
if [ -f $forcing_dir/Solar/${preffix}.Solr.${yy}-${mm2d}.nc ]; then
  rm $forcing_dir/Solar/${preffix}.Solr.${yy}-${mm2d}.nc
fi
if [ -f $forcing_dir/Precip/${preffix}.Prec.${yy}-${mm2d}.nc ]; then
  rm $forcing_dir/Precip/${preffix}.Prec.${yy}-${mm2d}.nc
fi
if [ -f $forcing_dir/TPHWL/${preffix}.TPQWL.${yy}-${mm2d}.nc ]; then
  rm $forcing_dir/TPHWL/${preffix}.TPQWL.${yy}-${mm2d}.nc
fi


##mv to temporary file the input for the following month (yyyy,st)
# yyyy and st refer to start-date
if [ ! -f $forcing_dir/Solar/${preffix}.Solr.${yyyy}-${st}.nc ]; then
   body="CLM ICs: Problems with EDA${member} inputs for create_edaFORC.sh. Missing Solr.${yyyy}-${st}"
   title="[CLMIC] ${CPSSYS} $typeofrun error"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r yes -s ${yyyy}${st}
   exit 1
fi

if [ ! -f $forcing_dir/Precip/${preffix}.Prec.${yyyy}-${st}.nc ]; then
   body="CLM ICs: Problems with EDA${member} inputs for create_edaFORC.sh. Missing Prec.${yyyy}-${st}"
   title="[CLMIC] ${CPSSYS} $typeofrun error"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r yes -s ${yyyy}${st}
   exit 1
fi

if [ !  -f $forcing_dir/TPHWL/${preffix}.TPQWL.${yyyy}-${st}.nc ]; then
   body="CLM ICs: Problems with EDA${member} inputs for create_edaFORC.sh Missing TPQWL.${yyyy}-${st}"
   title="[CLMIC] ${CPSSYS} $typeofrun error"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r yes -s ${yyyy}${st}
   exit 1
fi


# create files with last analysis data
checkfile=$DIR_LOG/$typeofrun/${yyyy}${st}/IC_CLM/create_edaFORC.sh_${yyyy}${st}_n${member}_ok

# here sourcing lastday from create_edaFORC.sh
. ${DIR_LND_IC}/create_edaFORC.sh $yy $mm $member $backup $checkfile $dbg
if [[ ! -f $checkfile ]]
then
   body="CLM ICs: Forcing files from EDA${member} data NOT created
      generating scripts:
      $DIR_LND_IC/create_edaFORC.sh
      "
   title="[CLMIC] ${CPSSYS} $typeofrun ERROR"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r yes -s ${yyyy}${st}

fi

check_mv=$DIR_LOG/$typeofrun/${yyyy}${st}/IC_CLM/mv_IC_EDA${member}_done

echo $lastday

refcase=cm3_lndSSP5-8.5_bgc_NoSnAg_eda${member}_op
if [[ $lastday -eq 999 ]]
then
#  FORCING SERIES COVERS ALL THE MONTH: run complete 
   ${DIR_LND_IC}/clm_forced.sh $yy $mm2d ${refcase} $icclm $ichydros $member ${check_mv} $lastday $errorflag
   #the submission of the complete case and the following mvIC2CLMdir is managed by clm_forced script through env_workflow

else
#  FORCING SERIES DOES NOT COVER ALL THE MONTH: run incomplete
   finaldir=${IC_CLM_CPS_DIR}/$st
   mkdir -p $finaldir #REDUNDANT BUT SAFER
 
   casoincomplete=incomplete_EDA${member}_SSP5-8.5_${yy}${mm2d}`printf '%.2d' ${lastday}`
   ${DIR_LND_IC}/clone_case_forced_analysis_incomplete.sh $yy $mm2d $lastday $casoincomplete $refcase ${check_mv} $icclm $ichydros $member ${errorflag} $backup
  
   #the submission of the incomplete case and the following mvIC2CLMdir is managed by clone_case script through env_workflow
   touch ${check_incomplete}
fi

