#!/bin/sh -l

. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. ${DIR_UTIL}/load_cdo
set -euvx

# Inputs
yyyy=$1
st=$2
workdir=$3
anomdir=$4
var=$5
dbg=$6        #NOT USED!!!!
logdir=$7

set +euvx
. $DIR_UTIL/descr_ensemble.sh $yyyy
set -euvx
outputfile="output.1.nc"  	#python_fst_output
intoutput="output.2.nc"		#cdo intermediate output


# Create Dirs
if [ -d $workdir ] ; then 
   	rm -rf $workdir
fi
mkdir -p $workdir
cd $workdir

# Variables cases
case $var
in
  	t2m)     varC3S=tas ; option="-subc,273.15"       ; hour="00:00:00" ; incr="6hour";;
	  sst)     varC3S=tso ; option=""                   ; hour="00:00:00" ; incr="6hour";;
  	precip)  varC3S=lwepr ; option="-mulc,1000"          ; hour="12:00:00" ; incr="1day";;
	  mslp)    varC3S=psl ; option="-divc,100"          ; hour="00:00:00" ; incr="6hour";;
  	z500)    varC3S=zg ; option="-sellevel,50000"   ; hour="00:00:00" ; incr="12hour";;
	  t850)    varC3S=ta ; option="-sellevel,85000"   ; hour="00:00:00" ; incr="12hour";;
   u200)    varC3S=ua    ; option="-sellevel,20000"  ; hour="00:00:00" ; incr="12hour";;
   v200)    varC3S=va    ; option="-sellevel,20000"  ; hour="00:00:00" ; incr="12hour";;
   sic)    varC3S=sic    ; option=""  ; hour="12:00:00" ; incr="1day";;
esac


#forecast dir
fc="${yyyy}${st}"  

datadir="${WORK_C3S1}/${fc}"
#CHECK if the files was already produced
flist=`ls -1 $datadir/*${varC3S}_*.nc | head -n $nrunC3Sfore`
for ff in $flist ; do
  
    pp=`basename $ff | cut -d '_' -f9 | cut -d '.' -f1 | cut -c2-3`
  	 ppp=`printf "%03d" $(( 10#${pp} ))`
	   caso="${SPSSystem}_${yyyy}${st}_${ppp}"
    finaloutput=${var}_${caso}.nc

  	 if [ ! -f ${logdir}/capsule_${yyyy}${st}_${ppp}_${var}_DONE ] ; then
		# GET Data
		#rsync -auv $datadir/*${varC3S}_*r${pp}i00p00.nc .
   		  cd $datadir 
		     tfile=`ls -1 cmcc_${GCM_name}-v*_*_S${yyyy}${st}0100_*_${varC3S}_r${pp}i00p00.nc`
	     	cd $workdir
	     	ppp=`printf "%03d" $(( 10#${pp} ))` 
		     caso="${SPSSystem}_${yyyy}${st}_${ppp}"

		# declaring and final outputfile
  		   finalinputfile=${tfile}
	  	   finaloutput=${var}_${caso}.nc
  #convert NetCDF4 to NetCDF3 to speed up the elaborations on timeaxis
		     ncks -O -6 ${datadir}/${finalinputfile} ${finalinputfile}_tmp
  #redefine the timeaxis to be cdo compliant
		     cdo settaxis,$yyyy-$st-01,$hour,$incr ${finalinputfile}_tmp ${finalinputfile}_tmp2
		     cdo setreftime,$yyyy-$st-01,$hour ${finalinputfile}_tmp2 ${finalinputfile}_tmp3
		   #make monthly mean
		     cdo monmean $option ${finalinputfile}_tmp3 ${outputfile}
		   # set output of python in months
  		   cdo settunits,months ${outputfile} ${intoutput} 
		   # set calendar to C3S standard
	  	   cdo setcalendar,365_day ${intoutput} ${finaloutput} 
		   # clean intermediate files
		     rm ${outputfile} && rm ${intoutput} 
		     rm ${finalinputfile}_tmp*
	
		   #here for operational  purposes we leave  everything on scratch
       touch ${logdir}/capsule_${yyyy}${st}_${ppp}_${var}_DONE

	  else
		     continue	
	  fi
	
done  #end loop on plist
