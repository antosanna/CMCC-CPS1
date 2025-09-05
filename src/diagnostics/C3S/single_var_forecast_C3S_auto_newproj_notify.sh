#!/bin/sh -l
. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
. ${DIR_UTIL}/load_ncl

set -evxu

export yyyyfore=$1
echo $yyyyfore
export mmfore=$2
mfore=$((10#$mmfore))

set +euvx
. ${DIR_UTIL}/descr_ensemble.sh $yyyyfore
set -evxu
export nens=$nrunC3Sfore
export varm=$3
terclist="low mid up"
reglist="$4"
export anomdir=$5
export dirplots=$6
export flgmnth=$7
flgmnth_fname=$8
leadlist="$9"
export varobs=$varm
export varname=$varm
case $varm
in
   t2m)   export varname=tas;;
   sst)   export varname=tso;;
   precip) export varname=lwepr;;
   z500)    export varname=zg;;
   t850)    export varname=ta;;
   mslp)   export varname=psl;;
   u200)   export varname=ua;;
   v200)   export varname=va;;
esac
case $varobs
in
   t2m|sst|t850|z500|u200|v200|mslp|sic) export ensmColormap="prob_t2m_new" ;;
   precip) export ensmColormap="prob_prec" ;;
esac

export spreadColormap="spread_15lev"

# -------------------------------
# go to graphic dir
# -------------------------------
export S=( "ppp" "ppp" "ppp" "ppp" )
case $mmfore 
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

cd $DIR_DIAG_C3S/ncl

# -------------------------------
#lead-time0
# -------------------------------
for l in $leadlist
do
  if [[ $flgmnth -eq 0 ]]
  then
       export lead=$(($l - 1))
       export SS=${S[$l]}
       export probupfile="${DIR_CLIM}/pctl/${mmfore}/${varm}_${mmfore}_l${lead}_66.$iniy_hind-$endy_hind.nc"
       export problowfile="${DIR_CLIM}/pctl/${mmfore}/${varm}_${mmfore}_l${lead}_33.$iniy_hind-$endy_hind.nc"
       frequency="season"
  else
       export lead=$(($l  - 1))
       #MB 20230204 - forced tag to be in english
       export SS=`LANG=en_us_88591 date -d "$yyyyfore${mmfore}01 + ${lead} month" +%B`
       export probupfile="${DIR_CLIM}/pctl/monthly/${mmfore}/${varm}_${mmfore}_l${lead}_66.$iniy_hind-$endy_hind.nc"
       export problowfile="${DIR_CLIM}/pctl/monthly/${mmfore}/${varm}_${mmfore}_l${lead}_33.$iniy_hind-$endy_hind.nc"
       frequency="month"
  fi
  export inputm="$anomdir/${varm}_${SPSSystem}_${yyyyfore}${mmfore}_ens_ano.1993-${endy_hind}.nc"
  export inputmall="$anomdir/${varm}_${SPSSystem}_${yyyyfore}${mmfore}_all_ano.1993-${endy_hind}.nc"
  export landmask="$MYCESMDATAROOT/CMCC-${CPSSYS}/files4${CPSSYS}/lsm_C3S.nc"
  export inputclim_mm="${DIR_CLIM}/monthly/${varm}/C3S/clim/${varm}_${SPSSystem}_clim_1993-$endy_hind.${mmfore}.nc"

  export wks_type=png
  for region in $reglist 
  do
      export region=$region
      case $region 
      in
         Europe) export minlat=20
                 export maxlat=65
                 export minlon=-40
                 export maxlon=50
                 export proj="LambertConformal"
                 export bnd="National"
                 export lon0="10"
                 export lat0="40"
                 export lbx=0.16
                 export lby=0.06
         ;;
         SH)     export minlat=-90
                 export maxlat=-20
                 export minlon=-180
                 export maxlon=180
                 export proj="Satellite"
                 export bnd="National"
                 export lon0="0"
                 export lat0="-90"
                 export lbx=0.28
         ;;
         NH)     export minlat=20
                 export maxlat=90
                 export minlon=-180
                 export maxlon=180
                 export proj="Satellite"
                 export bnd="National"
                 export lon0="0"
                 export lat0="90"
                 export lbx=0.28
         ;;
         Tropics)export minlat=-20
                 export maxlat=20
                 export minlon=-180
                 export maxlon=180
                 export proj="CylindricalEquidistant"
                 export bnd=""
                 export lon0="0"
                 export lat0="0"
                 export lbx=0.19
         ;;
         global) export minlat=-90
                 export maxlat=90
                 export minlon=-180
                 export maxlon=180
                 export proj="Robinson"
                 export bnd=""
                 export lon0="0"
                 export lbx=0.16
         ;;
      esac

      for diag in ensmean spread ; do
 
         case $diag
         in
            ensmean) case $varobs
                     in
                     sic)  export ensmeanLevels="-2,-1,-.5,-.2,.2,.5,1,2"
                           export ensmeanColors="5,4,3,2,0,6,7,8,9"
                           export ensmeanlabel='"<-2","-2:-1","-1:-0.5","-0.5:-0.2","-0.2:0.2","0.2:0.5","0.5:1","1:2",">2"'
                          export strvar="SIC anomalies [frac]" ;;
                     t2m) export ensmeanLevels="-2,-1,-.5,0.,.5,1,2"
                          export ensmeanColors="5,4,3,2,6,7,8,9"
                          export ensmeanlabel='"<-2","-2:-1","-1:-0.5","-0.5:0","0:0.5","0.5:1","1:2",">2"' 
                          export strvar="T2m anomalies [~S~o~N~C]" ;;
                     sst) export ensmeanLevels="-2,-1,-.5,0.,.5,1,2"
                          export ensmeanColors="5,4,3,2,6,7,8,9"
 			                      export ensmeanlabel='"<-2","-2:-1","-1:-0.5","-0.5:0","0:0.5","0.5:1","1:2",">2"' 
                          export strvar="SST anomalies [~S~o~N~C]" ;;
                    t850) export ensmeanLevels="-2,-1,-.5,0,.5,1,2"
                          export ensmeanColors="5,4,3,2,6,7,8,9"
			                       export ensmeanlabel='"<-2","-2:-1","-1:-0.5","-0.5:0","0:0.5","0.5:1","1:2",">2"' 
                          export strvar="T850 anomalies [~S~o~N~C]" ;;
                    mslp) export ensmeanLevels="-4,-2,-1,-0.5,0.5,1,2,4"
                          export ensmeanColors="5,4,3,2,6,7,8,9"
		                      	 export ensmeanlabel='"<-4","-4:-2","-2:-1","-1:-0.5","-0.5:0","0:0.5","0.5:1","1:2","2:4",">4"' 
                          export strvar="mslp anomalies [hPa]" ;;
                  precip) export ensmeanLevels="-200,-100,-50,0,50,100,200"
                          export ensmeanColors="5,4,3,2,6,7,8,9"
		                    	   export ensmeanlabel='"<-200","-200:-100","-100:-50","-50:0","0:50","50:100","100:200",">200"' 
  		                      export strvar="precipitation anomalies [mm/${frequency}]" ;;
                    z500) export ensmeanLevels="-40,-20,-10,-5,5,10,20,40"
                          export ensmeanColors="5,4,3,2,6,7,8,9"
			                       export ensmeanlabel='"<-40,"-40:-20","-20:-10","-10:-5","-5:0","0:5","5:10","10:20","20:40",">40"'
			                       export strvar="Z500 anomalies [m]" ;;
                    u200) export strvar="Zonal wind component at 200 hPa" ;;
                    v200) export strvar="Meridional wind component at 200 hPa" ;; 
                     esac ;;
            spread)  case $varobs
                     in
                     sic) export spreadLevels="0.25,0.75,1.25,1.85,2.25,2.75,3.25"
                          export spreadColors="2,16,13,12,11,10,8,6,4"
                          export spreadlabel='"0-0.5","0.5-1","1-1.5","1.5-2","2-2.5","2.5-3","3-3.5",">3.5"'
                       			export strvar="SIC spread [frac]" ;;

                      t2m) export spreadLevels="0.25,0.75,1.25,1.85,2.25,2.75,3.25"
                       			export spreadColors="2,16,13,12,11,10,8,6,4"
                       			export spreadlabel='"0-0.5","0.5-1","1-1.5","1.5-2","2-2.5","2.5-3","3-3.5",">3.5"' 
                       			export strvar="T2m spread [~S~o~N~C]" ;;
                     sst) export spreadLevels="0.25,0.75,1.25,1.85,2.25,2.75,3.25"
                       			export spreadColors="2,16,13,12,11,10,8,6,4"
                       			export spreadlabel='"0-0.5","0.5-1","1-1.5","1.5-2","2-2.5","2.5-3","3-3.5",">3.5"' 
                       			export strvar="SST spread [~S~o~N~C]" ;;
                    t850) export spreadLevels="0.25,0.75,1.25,1.75,2.25,2.75,3.25"
                          export spreadColors="2,16,13,12,11,10,8,6"
	                      		 export spreadlabel='"0-0.5","0.5-1","1-1.5","1.5-2","2-2.5","2.5-3","3-3.5",">3.5"' 
                      			 export strvar="T850 spread [~S~o~N~C]" ;;
                    mslp) export spreadLevels="0.5,1.5,2.5,3.5,4.5,5.5,6.5"
                          export spreadColors="2,16,13,12,11,10,8,6"
                      			 export spreadlabel='"0-1","1-2","2-3","3-4","4-5","5-6","6-7",">7"' 
		                      	 export strvar="mslp spread [hPa]" ;;
                  precip) export spreadLevels="12.5,37.5,62.5,87.5,112.5,137.5,162.5,187.5"
                          export spreadColors="2,16,13,12,11,10,8,6,4"
			                       export spreadlabel='"0-25","25-50","50-75","75-100","100-125","125-150","150-175","175-200",">200"' 
                          export strvar="precipitation spread [mm/${frequency}]" ;;
                    z500) export spreadLevels="5,15,25,35,45,55,65"
                          export spreadColors="2,16,13,12,11,10,8,6"
                    			   export spreadlabel='"0-10","10-20","20-30","30-40","40-50","50-60","60-70",">70"' 
			                       export strvar="Z500 spread [m]" ;;
                   u200) export strvar="U200 spread [m/s]" ;;
                   v200) export strvar="V200 spread [m/s]" ;
                     esac ;;
         esac             
         export diagtype=$diag
         if [[ $flgmnth -eq 0 ]]
         then
             ncl forecast_deterministic_season_lead_newproj.ncl
         else
             ncl forecast_deterministic_month_lead_newproj.ncl
         fi

      done ##end for diag
    

      for terc in $terclist ; do
          export tercile=$terc
          if [[ $flgmnth -eq 0 ]]
          then
               ncl forecast_prob_season_lead_newproj.ncl 
          else
               ncl forecast_prob_month_lead_newproj.ncl 
          fi
      done
      if [[ $flgmnth -eq 0 ]]
      then
          export tercile=terc_summ
          ncl forecast_prob_season_terc_summary_lead_newproj.ncl
      else
          export tercile=terc_summ
          ncl forecast_prob_month_terc_summary_lead_newproj.ncl
      fi
    
 

  done #end for region
done #end for leadlist
#
. $DIR_UTIL/load_convert
# this is to trim the picture
#convert_opt="-geometry 1000x1000 -rotate -90 -density 300 -trim +repage"
convert_opt="-trim +repage"
case $varobs
in
   z500) varfile=hgt500 ;;
   *)    varfile=$varobs ;;
esac
for l in $leadlist
do
  export lead=$(($l - 1))
  for region in $reglist 
  do
      if [[ $region == "global" ]] 
      then
         geom_value="80x80+930+830" 
      elif [[ $region == "NH" ]] || [[ $region == "SH" ]]
      then
         geom_value=" 80x80+930+880" 
      elif [[ $region == "Europe" ]] 
      then
         geom_value=" 80x80+930+900" 
      else
         geom_value="80x80+930+660"
      fi
      composite -geometry ${geom_value} cmcc_logo_bw.jpg $dirplots/${varobs}_${region}_ens_anom_${yyyyfore}_${mmfore}_${flgmnth_fname}_l${lead}.${wks_type} $dirplots/${varobs}_${region}_ens_anom_${yyyyfore}_${mmfore}_${flgmnth_fname}_l${lead}.${wks_type}
      magick convert ${convert_opt} $dirplots/${varobs}_${region}_ens_anom_${yyyyfore}_${mmfore}_${flgmnth_fname}_l${lead}.${wks_type} $dirplots/${varfile}_${region}_ens_anom_${yyyyfore}_${mmfore}_${flgmnth_fname}_l${lead}.png
      composite -geometry ${geom_value} cmcc_logo_bw.jpg $dirplots/${varobs}_${region}_spread_${yyyyfore}_${mmfore}_${flgmnth_fname}_l${lead}.${wks_type} $dirplots/${varobs}_${region}_spread_${yyyyfore}_${mmfore}_${flgmnth_fname}_l${lead}.${wks_type}
      magick convert ${convert_opt} $dirplots/${varobs}_${region}_spread_${yyyyfore}_${mmfore}_${flgmnth_fname}_l${lead}.${wks_type} $dirplots/${varfile}_${region}_spread_${yyyyfore}_${mmfore}_${flgmnth_fname}_l${lead}.png
     
      composite -geometry ${geom_value} cmcc_logo_bw.jpg $dirplots/${varobs}_${region}_tercile_summary_${yyyyfore}_${mmfore}_${flgmnth_fname}_l${lead}.${wks_type} $dirplots/${varobs}_${region}_tercile_summary_${yyyyfore}_${mmfore}_${flgmnth_fname}_l${lead}.${wks_type}
      magick convert ${convert_opt} $dirplots/${varobs}_${region}_tercile_summary_${yyyyfore}_${mmfore}_${flgmnth_fname}_l${lead}.${wks_type} $dirplots/${varfile}_${region}_tercile_summary_${yyyyfore}_${mmfore}_${flgmnth_fname}_l${lead}.png

      composite -geometry ${geom_value} cmcc_logo_bw.jpg $dirplots/${varobs}_${region}_prob_up_tercile_${yyyyfore}_${mmfore}_${flgmnth_fname}_l${lead}.${wks_type} $dirplots/${varobs}_${region}_prob_up_tercile_${yyyyfore}_${mmfore}_${flgmnth_fname}_l${lead}.${wks_type}
      magick convert ${convert_opt} $dirplots/${varobs}_${region}_prob_up_tercile_${yyyyfore}_${mmfore}_${flgmnth_fname}_l${lead}.${wks_type} $dirplots/${varfile}_${region}_prob_up_tercile_${yyyyfore}_${mmfore}_${flgmnth_fname}_l${lead}.png
      composite -geometry ${geom_value} cmcc_logo_bw.jpg $dirplots/${varobs}_${region}_prob_low_tercile_${yyyyfore}_${mmfore}_${flgmnth_fname}_l${lead}.${wks_type} $dirplots/${varobs}_${region}_prob_low_tercile_${yyyyfore}_${mmfore}_${flgmnth_fname}_l${lead}.${wks_type}
      magick convert ${convert_opt} $dirplots/${varobs}_${region}_prob_low_tercile_${yyyyfore}_${mmfore}_${flgmnth_fname}_l${lead}.${wks_type} $dirplots/${varfile}_${region}_prob_low_tercile_${yyyyfore}_${mmfore}_${flgmnth_fname}_l${lead}.png
      composite -geometry ${geom_value} cmcc_logo_bw.jpg $dirplots/${varobs}_${region}_prob_mid_tercile_${yyyyfore}_${mmfore}_${flgmnth_fname}_l${lead}.${wks_type} $dirplots/${varobs}_${region}_prob_mid_tercile_${yyyyfore}_${mmfore}_${flgmnth_fname}_l${lead}.${wks_type}
      magick convert ${convert_opt} $dirplots/${varobs}_${region}_prob_mid_tercile_${yyyyfore}_${mmfore}_${flgmnth_fname}_l${lead}.${wks_type} $dirplots/${varfile}_${region}_prob_mid_tercile_${yyyyfore}_${mmfore}_${flgmnth_fname}_l${lead}.png
      if [[ $varfile == "hgt500" ]]
      then
          rm $dirplots/${varobs}_${region}_ens_anom_${yyyyfore}_${mmfore}_${flgmnth_fname}_l${lead}.${wks_type}
          rm $dirplots/${varobs}_${region}_spread_${yyyyfore}_${mmfore}_${flgmnth_fname}_l${lead}.${wks_type}
          rm $dirplots/${varobs}_${region}_tercile_summary_${yyyyfore}_${mmfore}_${flgmnth_fname}_l${lead}.${wks_type}
          rm $dirplots/${varobs}_${region}_prob_up_tercile_${yyyyfore}_${mmfore}_${flgmnth_fname}_l${lead}.${wks_type}
          rm $dirplots/${varobs}_${region}_prob_low_tercile_${yyyyfore}_${mmfore}_${flgmnth_fname}_l${lead}.${wks_type}
          rm $dirplots/${varobs}_${region}_prob_mid_tercile_${yyyyfore}_${mmfore}_${flgmnth_fname}_l${lead}.${wks_type}
      fi
  done #end for region
done #end for leadlist
# -------------------------------
# ALL DONE
# -------------------------------
#set +euvx
#. $DIR_UTIL/condaactivation.sh
#condafunction activate $envcondarclone
#listafig=`ls ${dirplots}/*${yyyyfore}_${mmfore}*png`
#rclone mkdir my_drive:SPS4_webpage_plots/$yyyyfore$mmfore
##for fig in $listafig
#do
#   rclone copy $fig my_drive:SPS4_webpage_plots
#done
