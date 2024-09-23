#!/bin/sh -l

# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. ${DIR_POST}/APEC/descr_SPS4_APEC.sh
. $DIR_UTIL/load_cdo
. $DIR_UTIL/load_nco

#module load intel-2021.6.0/netcdf-c-threadsafe/4.9.0-25h5k  
#module load intel-2021.6.0/netcdf-fortran-threadsafe/4.6.0-2dmem

set -evx

yyyy=$1
st="$2"
ppp="$3"  #must be 3 digits
DATA=$4
workdir=$5
pushdir=$6
typeofrun=$7

#varlisttot="$8"  #("${!8}")  
#MB 6/10/2021: As documented in the logbook, there are some problems in passing an array as input in bash. Waiting for a smarter solution, the var list is redefined here explicitely
varlisttot=("rlt lwesnw sic tso psl tas uas vas lwepr zg ta ua va")

echo $typeofrun
echo ${varlisttot[@]} 

varlist2d=""
varlist3d=""

for var in ${varlisttot[*]} ;do
  case $var
     in
     rlt|lwesnw|sic|tas|uas|vas|tso|lwepr|psl) varlist2d+="$var " ;;
     *) varlist3d+="$var " ;;
	 esac
done

# APEC function definition ---------------------------------------------------------------------------------------------

# function to setaxis and to setreftime
fixtimedd() {
  local yyyy=$1
  local mm=$2
  local dd=$3
  local hh=$4
  local incr=$5
  local infile=$6
  incr2=1
  outfile=${infile}

  cdo settaxis,${yyyy}-${mm}-${dd},${hh}:00,${incr} ${infile} temp_${yyyy}${mm}
  cdo setreftime,${yyyy}-${mm}-${dd},${hh}:00 temp_${yyyy}${mm} ${outfile}
  rm temp_${yyyy}${mm}
}

# APEC env creation ----------------------------------------------------------------------------------------------------

caso=${yyyy}${st}_${ppp}

if [[ $typeofrun = "forecast" ]] ; then
	datadd=$WORK_SPS4/APEC/$caso/daily
	mkdir -p $datadd
fi
datamm=$WORK_SPS4/APEC/$caso/monthly

# normalize pushdir, extra check for pushdir format (remove final slash .. if they exist)
#normalized_pushdir="`cd "${pushdirapec}";pwd`"
pushdirapec_yyyyst="${pushdirapec}/$typeofrun/$yyyy$st"
pushdirapec_monthly=$pushdirapec_yyyyst/monthly
if [[ $typeofrun = "forecast" ]] ; then
   pushdirapec_daily=$pushdirapec_yyyyst/daily
   mkdir -p $pushdirapec_daily
fi

# create directories
mkdir -p $pushdirapec_monthly
mkdir -p $datamm
 
mkdir -p $workdir/$ppp
cd $workdir/$ppp

mm=`echo ${st} | bc`
nm=1
year=${yyyy}
pp=`echo $ppp | cut -c2-3`

# APEC retrieve surface and pressusre level fields ---------------------------------------------------------------------

varlist="$varlist2d"
if [[ "$varlist" != "" ]] ; then
   for var in $varlist ; do

     case $var
      in
      rlt)   type="atmos" ; freqout="day" ; varnew=olr    ;;
      tas)   type="atmos" ; freqout="day" ; varnew=t2m    ;;
      uas)   type="atmos" ; freqout="day" ; varnew=u10    ;;
      vas)   type="atmos" ; freqout="day" ; varnew=v10    ;;
      psl)   type="atmos" ; freqout="day" ; varnew=mslp   ;;
      tso)   type="ocean" ; freqout="day" ; varnew=sst    ;;
      lwepr) type="atmos" ; freqout="day" ; varnew=precip ;;
      lwesnw) type="land" ; freqout="day" ; varnew=swe ;;
      sic)  type="seaIce" ; freqout="day" ; varnew=sic ;;
     esac
     hh=12 ; incr="1day"

     if [[ $typeofrun = "forecast" ]] ; then
	       if [[ $var = "lwepr" || $var = "rlt" || $var = "lwesnw" || $var = "sic" ]] ; then
		         ncks -Oh -6 ../cmcc_CMCC-CM3-v${version}_${typeofrun}_S${yyyy}${st}0100_${type}_${freqout}_surface_${var}_r${pp}i00p00.nc CMCC_${caso}_${var}_tmp.nc
		         fixtimedd ${yyyy} ${st} 01 12 1day CMCC_${caso}_${var}_tmp.nc
	       else
		         mv ../cmcc_CMCC-CM3-v${version}_${typeofrun}_S${yyyy}${st}0100_${type}_${freqout}_surface_${var}_r${pp}i00p00.nc CMCC_${caso}_${var}_tmp.nc
	       fi
     else	
	       if [[ $var = "lwepr" ||  $var = "rlt" || $var = "lwesnw" || $var = "sic" ]] ; then
     		    ncks -Oh -6 ../cmcc_CMCC-CM3-v${version}_${typeofrun}_S${yyyy}${st}0100_${type}_${freqout}_surface_${var}_r${pp}i00p00.nc CMCC_${caso}_${var}_tmp.nc
     		    fixtimedd ${yyyy} ${st} 01 12 1day CMCC_${caso}_${var}_tmp.nc
	       else
		         rsync -auv ../cmcc_CMCC-CM3-v${version}_${typeofrun}_S${yyyy}${st}0100_${type}_${freqout}_surface_${var}_r${pp}i00p00.nc CMCC_${caso}_${var}_tmp.nc
       	fi
   		
     fi 

     #cdo daymean cmcc_CMCC-CM3-v${version}_${typeofrun}_S${yyyy}${st}0100_${type}_${freqout}_surface_${var}_r${pp}i00p00.nc CMCC_${caso}_${var}_tmp.nc
     cp CMCC_${caso}_${var}_tmp.nc CMCC_${caso}_${var}.nc
     cdo monmean CMCC_${caso}_${var}.nc CMCC_${caso}_monthly_${var}.nc 

     rm CMCC_${caso}_${var}_tmp.nc

   done

fi  #end if on varlist2d

# COPY PRESSURE LEVEL FIELDS AND PREPARE FOR POST-PROCESSING
pp=`echo $ppp | cut -c2-3`

ppnum=${pp#0}
case $typeofrun
   in
   forecast)  ppmax=25 ; ppmax2=50 ;;
   hindcast)  ppmax=15 ; ppmax2=30 ;;
esac
ppmaxp1=$(($ppmax + 1))

vartr="n1-n${ppmax}"
# only if number of first tranche members ar lt 26 set $vartr to "n26-n50" to treat $pp > $nmaxjob
if [[ $nmaxjob -le ${ppmaxp1} ]] ; then
  	if [[ $ppnum -gt $nmaxjob ]] ; then  
  		vartr="n${ppmaxp1}-n${ppmax2}"
  	fi
fi

varlist="$varlist3d"
if [[ "$varlist" != "" ]] ; then
   for var in $varlist ; do
	
      #fixtimedd2 $yyyy $st 01 00 12hour cmcc_CMCC-CM3-v${version}_${typeofrun}_S${yyyy}${st}0100_atmos_12hr_pressure_${var}_r${pp}i00p00.nc 
      if [[ $typeofrun = "forecast" ]] ; then
          mv ../cmcc_CMCC-CM3-v${version}_${typeofrun}_S${yyyy}${st}0100_atmos_day_pressure_${var}_r${pp}i00p00.nc CMCC_${caso}_${var}_tmp.nc
      else
          rsync -auv ../cmcc_CMCC-CM3-v${version}_${typeofrun}_S${yyyy}${st}0100_atmos_day_pressure_${var}_r${pp}i00p00.nc CMCC_${caso}_${var}_tmp.nc
      fi

      cp CMCC_${caso}_${var}_tmp.nc CMCC_${caso}_${var}.nc
      cdo monmean CMCC_${caso}_${var}.nc CMCC_${caso}_${var}_monthly.nc
      
      rm CMCC_${caso}_${var}_tmp.nc
   done

fi  # end if on varlist3d

# APEC files transformation --------------------------------------------------------------------------------------------
while [ $nm -le 6 ] ; do   
  [ $mm -gt 12 ] && { mm="1" ; year=$(($year + 1)) ; }
  
  mm2=`printf "%.02d" $((10#$mm))`

  if [[ $typeofrun = "forecast" ]] ; then
    	varlist="$varlist2d"  # tas tso psl lwepr"
     if [[ "$varlist" != "" ]] ; then 
 	      for var in $varlist ; do

	          case $var
 	          in
            rlt)   varnew=olr    ;;
    	       tas)   varnew=t2m    ;;
    	       uas)   varnew=u10    ;;
    	       vas)   varnew=v10    ;;
    	       psl)   varnew=mslp   ;;
    	       tso)   varnew=sst    ;;
    	       lwepr) varnew=precip ;;
    	       lwesnw) varnew=swe    ;;
    	       sic)   varnew=sic    ;;
   	       esac

   	       if [[ $var = "psl" ]] ; then 

      		      cdo selyear,${year} CMCC_${caso}_${var}.nc CMCC_SPS_${caso}_${year}_${var}.nc
      	      	cdo selmon,${mm2} CMCC_SPS_${caso}_${year}_${var}.nc CMCC_SPS_${caso}_${year}${mm2}_${var}.nc
      		      cdo divc,100 CMCC_SPS_${caso}_${year}${mm2}_${var}.nc CMCC_SPS_${caso}_${year}${mm2}_${var}_hPa.nc
      		      cdo chname,psl,mslp CMCC_SPS_${caso}_${year}${mm2}_${var}_hPa.nc CMCC_SPS_${caso}_${year}${mm2}_${varnew}.nc
		            ncatted -Oh -a units,mslp,m,c,"hPa" CMCC_SPS_${caso}_${year}${mm2}_${varnew}.nc
      	   	   rm CMCC_SPS_${caso}_${year}${mm2}_${var}_hPa.nc
	          elif [[ $var = "lwepr" ]]  ; then
	        	
         	   	cdo selyear,${year} CMCC_${caso}_${var}.nc CMCC_SPS_${caso}_${year}_${var}.nc
         	   	cdo selmon,${mm2} CMCC_SPS_${caso}_${year}_${var}.nc CMCC_SPS_${caso}_${year}${mm2}_${var}.nc
         	   	cdo mulc,1000 CMCC_SPS_${caso}_${year}${mm2}_${var}.nc CMCC_SPS_${caso}_${year}${mm2}_${var}_kgm2.nc
      	      	cdo chname,lwepr,precip CMCC_SPS_${caso}_${year}${mm2}_${var}_kgm2.nc CMCC_SPS_${caso}_${year}${mm2}_${varnew}.nc
		            ncatted -Oh -a units,precip,m,c,"kg/m^2" CMCC_SPS_${caso}_${year}${mm2}_${varnew}.nc
      	 	     rm CMCC_SPS_${caso}_${year}${mm2}_${var}_kgm2.nc
   	       else
         	 	  cdo selyear,${year} CMCC_${caso}_${var}.nc CMCC_SPS_${caso}_${year}_${var}.nc
         	 	  cdo selmon,${mm2} CMCC_SPS_${caso}_${year}_${var}.nc CMCC_SPS_${caso}_${year}${mm2}_${var}.nc
         	 	  cdo chname,${var},${varnew} CMCC_SPS_${caso}_${year}${mm2}_${var}.nc CMCC_SPS_${caso}_${year}${mm2}_${varnew}.nc
   	       fi
           if [[ $var != "sic" ]] ; then
   	          rm CMCC_SPS_${caso}_${year}${mm2}_${var}.nc
           fi
     	done   

  	# Zip and move on data output directory 
     	gzip -f CMCC_SPS_${caso}_${year}${mm2}_*.nc 
     	mv CMCC_SPS_${caso}_${year}${mm2}_*.nc.gz $datadd
   fi #end if on varlist2d existence

  fi
  # monthly mean data 
  varlist="$varlist2d" # rlt tas tso psl lwepr"
  if [[ "$varlist" != "" ]] ; then
     for var in $varlist ; do

      case $var
       in  
       rlt)   varnew=olr    ;;  
       tas)   varnew=t2m    ;;  
    	  uas)   varnew=u10    ;;
    	  vas)   varnew=v10    ;;
       psl)   varnew=mslp   ;;  
       tso)   varnew=sst    ;;  
       lwepr) varnew=precip ;;
    	  lwesnw) varnew=swe    ;;
    	  sic)   varnew=sic    ;;
      esac

      if [[ $var = "psl" ]] ; then 

         cdo selyear,${year} CMCC_${caso}_monthly_${var}.nc CMCC_SPS_${caso}_${year}_monthly_${var}.nc
         cdo selmon,${mm2} CMCC_SPS_${caso}_${year}_monthly_${var}.nc CMCC_SPS_${caso}_${year}${mm2}_monthly_${var}.nc
         cdo divc,100 CMCC_SPS_${caso}_${year}${mm2}_monthly_${var}.nc CMCC_SPS_${caso}_${year}${mm2}_monthly_${var}_hPa.nc
         cdo chname,psl,mslp CMCC_SPS_${caso}_${year}${mm2}_monthly_${var}_hPa.nc CMCC_SPS_${caso}_${year}${mm2}_monthly_${varnew}.nc
         ncatted -Oh -a units,mslp,m,c,"hPa" CMCC_SPS_${caso}_${year}${mm2}_monthly_${varnew}.nc	
         rm CMCC_SPS_${caso}_${year}${mm2}_monthly_${var}_hPa.nc
      elif [[ $var = "lwepr" ]] ; then
         cdo selyear,${year} CMCC_${caso}_monthly_${var}.nc CMCC_SPS_${caso}_${year}_monthly_${var}.nc
         cdo selmon,${mm2} CMCC_SPS_${caso}_${year}_monthly_${var}.nc CMCC_SPS_${caso}_${year}${mm2}_monthly_${var}.nc
         cdo mulc,1000 CMCC_SPS_${caso}_${year}${mm2}_monthly_${var}.nc CMCC_SPS_${caso}_${year}${mm2}_monthly_${var}_kgm2.nc
         cdo chname,lwepr,precip CMCC_SPS_${caso}_${year}${mm2}_monthly_${var}_kgm2.nc CMCC_SPS_${caso}_${year}${mm2}_monthly_${varnew}.nc
         ncatted -Oh -a units,precip,m,c,"Kg/m^2" CMCC_SPS_${caso}_${year}${mm2}_monthly_${varnew}.nc	
         rm CMCC_SPS_${caso}_${year}${mm2}_monthly_${var}_kgm2.nc
      else
         cdo selyear,${year} CMCC_${caso}_monthly_${var}.nc CMCC_SPS_${caso}_${year}_monthly_${var}.nc
         cdo selmon,${mm2} CMCC_SPS_${caso}_${year}_monthly_${var}.nc CMCC_SPS_${caso}_${year}${mm2}_monthly_${var}.nc
         cdo chname,${var},${varnew} CMCC_SPS_${caso}_${year}${mm2}_monthly_${var}.nc CMCC_SPS_${caso}_${year}${mm2}_monthly_${varnew}.nc
      fi  
      if [[ $var != "sic" ]] ; then
         rm CMCC_SPS_${caso}_${year}${mm2}_monthly_${var}.nc
      fi  
    done

    list=`ls -1 CMCC_SPS_${caso}_${year}${mm2}_monthly*.nc`
    for ll in $list ; do 
      fixtimedd ${year} ${mm2} 15 12 1mon $ll
    done
  # Zip and move on data output directory 
    gzip -f CMCC_SPS_${caso}_${year}${mm2}_monthly_*.nc 
    mv CMCC_SPS_${caso}_${year}${mm2}_monthly_*.nc.gz $datamm
  fi  #end if on varlist existence

  #NOW PRESSURE LEVEL FIELDS...
  varlist=$varlist3d
  if [[ "$varlist" != "" ]] ; then
     for var in $varlist ; do
       case $var
        in
        zg) varnew=Z ;;
        ta) varnew=T ;;
        ua) varnew=U ;;
        va) varnew=V ;;
       esac
       for lev in 85000 50000 20000 ; do
          levnew=`echo $lev | cut -c1-3`
       # monthly pressure level fields
          cdo chname,${var},${varnew} CMCC_${caso}_${var}_monthly.nc CMCC_SPS_${caso}_${year}${mm2}_monthly_${varnew}${levnew}_tmp.nc
          cdo selmon,${mm2} CMCC_SPS_${caso}_${year}${mm2}_monthly_${varnew}${levnew}_tmp.nc CMCC_SPS_${caso}_${year}${mm2}_monthly_${varnew}${levnew}_tmp2.nc
          cdo sellevel,${lev} CMCC_SPS_${caso}_${year}${mm2}_monthly_${varnew}${levnew}_tmp2.nc CMCC_SPS_${caso}_${year}${mm2}_monthly_${varnew}${levnew}.nc
          ncap2 -Oh -s "plev=plev/100" CMCC_SPS_${caso}_${year}${mm2}_monthly_${varnew}${levnew}.nc CMCC_SPS_${caso}_${year}${mm2}_monthly_${varnew}${levnew}_tmp.nc
          ncdump CMCC_SPS_${caso}_${year}${mm2}_monthly_${varnew}${levnew}_tmp.nc > CMCC_SPS_${caso}_${year}${mm2}_monthly_${varnew}${levnew}_tmp.txt
          sed -e s/plev/lev/g CMCC_SPS_${caso}_${year}${mm2}_monthly_${varnew}${levnew}_tmp.txt > CMCC_SPS_${caso}_${year}${mm2}_monthly_${varnew}${levnew}_tmp2.txt
          ncgen -o CMCC_SPS_${caso}_${year}${mm2}_monthly_${varnew}${levnew}.nc CMCC_SPS_${caso}_${year}${mm2}_monthly_${varnew}${levnew}_tmp2.txt
          ncatted -Oh -a units,lev,m,c,"hPa" CMCC_SPS_${caso}_${year}${mm2}_monthly_${varnew}${levnew}.nc
          ncatted -Oh -a ,global,d,, CMCC_SPS_${caso}_${year}${mm2}_monthly_${varnew}${levnew}.nc
          rm CMCC_SPS_${caso}_${year}${mm2}_monthly_${varnew}${levnew}_*txt
          rm CMCC_SPS_${caso}_${year}${mm2}_monthly_${varnew}${levnew}_tmp*.nc

       # daily pressure level fields

          if [[ $typeofrun = "forecast" ]] ; then	
		           cdo chname,${var},${varnew} CMCC_${caso}_${var}.nc CMCC_SPS_${caso}_${year}${mm2}_${varnew}${levnew}_tmp.nc
	            cdo selmon,${mm2} CMCC_SPS_${caso}_${year}${mm2}_${varnew}${levnew}_tmp.nc CMCC_SPS_${caso}_${year}${mm2}_${varnew}${levnew}_tmp2.nc
       		    cdo sellevel,${lev} CMCC_SPS_${caso}_${year}${mm2}_${varnew}${levnew}_tmp2.nc CMCC_SPS_${caso}_${year}${mm2}_${varnew}${levnew}.nc
       	    	ncap2 -Oh -s "plev=plev/100" CMCC_SPS_${caso}_${year}${mm2}_${varnew}${levnew}.nc CMCC_SPS_${caso}_${year}${mm2}_${varnew}${levnew}_tmp.nc
       		    ncdump CMCC_SPS_${caso}_${year}${mm2}_${varnew}${levnew}_tmp.nc > CMCC_SPS_${caso}_${year}${mm2}_${varnew}${levnew}_tmp.txt
       		    sed -e s/plev/lev/g CMCC_SPS_${caso}_${year}${mm2}_${varnew}${levnew}_tmp.txt > CMCC_SPS_${caso}_${year}${mm2}_${varnew}${levnew}_tmp2.txt
       		    ncgen -o CMCC_SPS_${caso}_${year}${mm2}_${varnew}${levnew}.nc CMCC_SPS_${caso}_${year}${mm2}_${varnew}${levnew}_tmp2.txt
       		    ncatted -Oh -a units,lev,m,c,"hPa" CMCC_SPS_${caso}_${year}${mm2}_${varnew}${levnew}.nc
       		    ncatted -Oh -a ,global,d,, CMCC_SPS_${caso}_${year}${mm2}_${varnew}${levnew}.nc
       		    rm CMCC_SPS_${caso}_${year}${mm2}_${varnew}${levnew}_*txt
       		    rm CMCC_SPS_${caso}_${year}${mm2}_${varnew}${levnew}_tmp*.nc
          fi
       # Zip and move on data output directory 
          if [[ $typeofrun = "forecast" ]] ; then
           		gzip -f CMCC_SPS_${caso}_${year}${mm2}_${varnew}${levnew}.nc 
       	    	mv CMCC_SPS_${caso}_${year}${mm2}_${varnew}${levnew}.nc.gz $datadd
          fi

          gzip -f CMCC_SPS_${caso}_${year}${mm2}_monthly_${varnew}${levnew}.nc
          mv CMCC_SPS_${caso}_${year}${mm2}_monthly_${varnew}${levnew}.nc.gz $datamm
       done
    done
  fi #end if on varlist existence

  mm=$(($mm + 1))
  nm=$(($nm + 1))
done

# APEC clean and rsync -------------------------------------------------------------------------------------------------
rm *.nc
if [[ $typeofrun = "forecast" ]] ; then 
  	rsync -auv --remove-source-files $datadd/*.nc.gz $pushdirapec_daily
fi
rsync -auv --remove-source-files $datamm/*.nc.gz $pushdirapec_monthly
touch ${DIR_LOG}/${typeofrun}/${yyyy}${st}/${caso}_APEC_DONE 

exit
