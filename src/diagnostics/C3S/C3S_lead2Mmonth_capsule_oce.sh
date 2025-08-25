#!/bin/sh -l

. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. $DIR_UTIL/load_cdo

set -euvx

# Inputs
export yyyy=$1
export st=$2
export ppp=$3
workdir_ens=$4
workdir=$5
export var=$6
dirlog=$7
export filetype=$8


# Create Dirs  #check!
[ -d $workdir_ens ] && rm -rf $workdir_ens
mkdir -p $workdir_ens
cd $workdir_ens

# Variables cases

fc="${yyyy}${st}"  


#CHECK if the files was already produced
export finaloutput=${var}_${CPSSYS}_sps_${yyyy}${st}
if [ ! -f $workdir/$finaloutput.nc ] ; then
  
 	 sps="${SPSSystem}_${yyyy}${st}_${ppp}"
		 export datadir=$DIR_ARCHIVE1
   nf=`ls -1 $datadir/${sps}/ocn/hist/${sps}_1d_*_*_grid_EquT_T.zip.nc | wc -l`
   if [ $nf -eq 0 ] ; then
      body="no EquT files available at $datadir/${sps}/ocn/hist/"
      title="$DIR_DIAG_C3S/C3S_lead2Mmonth_capsule_oce.sh exiting for $sps"
      ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r $typeofrun
      exit
   fi
	  tfileTEquT="$datadir/${sps}/ocn/hist/${sps}_1d_*_*_grid_EquT_T.zip.nc"
	  tfileTglobal="$datadir/${sps}/ocn/hist/${sps}_1d_*_*_grid_Tglobal.zip.nc"
	  tfileT="$datadir/${sps}/ocn/hist/${sps}_1m_*_*_grid_T.zip.nc"
	  tfileU="$datadir/${sps}/ocn/hist/${sps}_1m_*_*_grid_U.zip.nc"
	  tfileV="$datadir/${sps}/ocn/hist/${sps}_1m_*_*_grid_V.zip.nc"

	  case $var in
	    toce)  tfile=`ls -1 $tfileTEquT` ;;
	    sohtc040)  tfile=`ls -1 $tfileTglobal` ;;
	    somixhgt)  tfile=`ls -1 $tfileT` ;;
	    vozocrtx)  tfile=`ls -1 $tfileU` ;;	
   	 vomecrty)  tfile=`ls -1 $tfileV` ;;	
	  esac
	# declaring and final outputfile
  	export meshmaskfile="$CESMDATAROOT/inputdata/ocn/nemo/tn0.25v3/grid/ORCA025L75_mesh_mask.nc"
	  export finalinputfile=${tfile}
	  export filo=$workdir/${sps}_${var}.zip.nc
  	export checkfile=$workdir/${sps}_${var}_OK
  	export SPSsys=$SPSSystem
		
   ncl $DIR_DIAG_C3S/ncl/C3S_lead2Mmonth_capsule_oce.ncl
       
 	 if [ $var = "toce" -o $var = "sohtc040" ] ; then
	     cdo settaxis,$yyyy-$st-01,12:00:00,1day $filo ${filo}_tmp
  	   cdo setreftime,$yyyy-$st-01,12:00:00 ${filo}_tmp $filo
	     rm ${filo}_tmp
	  fi
fi

touch $dirlog/capsule_${yyyy}${st}_${ppp}_oce_${var}_DONE
