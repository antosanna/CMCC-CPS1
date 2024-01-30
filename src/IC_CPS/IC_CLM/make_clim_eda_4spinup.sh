#!/bin/sh -l

#BSUB  -J make_clim_eda_4spinup
#BSUB  -q s_long
#BSUB  -o logs/make_clim_eda_4spinup.out.%J  
#BSUB  -e logs/make_clim_eda_4spinup.err.%J  
#BSUB  -P 0490


set +euxv     
# MANDATORY!! if not set the script exits because if sourced 
# does not recognize $PROMPT 
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. ${DIR_UTIL}/load_cdo
. ${DIR_UTIL}/load_nco
. ${DIR_UTIL}/load_ncl
set -euxv

member=$1  #eda member tag
WORKDIR_LAND=$SCRATCHDIR/WORK_LAND_IC
script_dir=${DIR_LND_IC}
mkdir -p $WORKDIR_LAND

#################################
# CREATE CLIMATOLOGY OF FORCING
#################################
forcDIReda=$SCRATCHDIR/EDA_n$member
OUTDIR=$forcDIReda/clim_1960-1969
mkdir -p $OUTDIR
mkdir -p $OUTDIR/Precip
mkdir -p $OUTDIR/Solar
mkdir -p $OUTDIR/TPHWL
prefix=clmforc.EDA${member}.0.5d
prefix_clim=clmforc.EDA${member}.0.5d.clim1960-1969

wkdir=$WORKDIR_LAND/workdir_eda${member}_clim
if [[ -d $wkdir ]] ; then
   rm -r $wkdir
fi

mkdir -p $wkdir
cd $wkdir
		
# link neccesary scripts 
ln -sf ${script_dir}/setVar_Prec.ncl .
ln -sf ${script_dir}/setVar_Solr.ncl .
ln -sf ${script_dir}/setVar_TPQW.ncl .
#------------------------------------------------
for mo in 01 02 03 04 05 06 07 08 09 10 11 12 ; do

   # get number of time steps in the month
   case "$mo" in
              01|03|05|07|08|10|12)
               nts=248
                       ;;	
              02)
               nts=224
                       ;;	
              04|06|09|11)
               nts=240
                       ;;	
   esac	
			
   for ts in `seq 1 $nts`; do
       tsp=`printf "%03d" ${ts}`

       #------------------------------------------------
       # select each timestep
       #------------------------------------------------
       for yr in `seq 1960 1969`; do
           cdo seltimestep,${ts} $forcDIReda/Precip/${prefix}.Prec.${yr}-${mo}.nc PREC_${yr}.nc
           cdo seltimestep,${ts} $forcDIReda/Solar/${prefix}.Solr.${yr}-${mo}.nc SOLR_${yr}.nc
           cdo seltimestep,${ts} $forcDIReda/TPHWL/${prefix}.TPQWL.${yr}-${mo}.nc TPQW_${yr}.nc
       done

       #------------------------------------------------
       # concatenate all years
       #------------------------------------------------
        cdo cat PREC_*.nc  PREC_1960-1969-${mo}.nc
        cdo cat SOLR_*.nc  SOLR_1960-1969-${mo}.nc
        cdo cat TPQW_*.nc  TPQW_1960-1969-${mo}.nc
				  
       #------------------------------------------------
       # calculate mean of each time step
       #------------------------------------------------
        cdo timmean PREC_1960-1969-${mo}.nc timmean_PREC_${tsp}.nc
        cdo timmean SOLR_1960-1969-${mo}.nc timmean_SOLR_${tsp}.nc
        cdo timmean TPQW_1960-1969-${mo}.nc timmean_TPQW_${tsp}.nc

        #clean
        rm PREC_*nc SOLR_*nc TPQW_*nc

   done # end ts loop

  #------------------------------------------------
  # merge all timesteps in the month
  #------------------------------------------------
  cdo mergetime timmean_PREC_*nc CLIM_PREC_${mo}.nc
  cdo mergetime timmean_SOLR_*nc CLIM_SOLR_${mo}.nc
  cdo mergetime timmean_TPQW_*nc CLIM_TPQW_${mo}.nc
  #clean
  rm timmean_*

  #------------------------------------------------
  # format as template
  #------------------------------------------------
  cat setVar_Prec.ncl | sed -e "s/MESE/${mo}/" > svPREC.ncl
  ncl svPREC.ncl

  cat setVar_Solr.ncl | sed -e "s/MESE/${mo}/" > svSOLR.ncl
  ncl svSOLR.ncl

  cat setVar_TPQW.ncl | sed -e "s/MESE/${mo}/" > svTPQW.ncl
  ncl svTPQW.ncl

  #clean
  rm sv*

  #------------------------------------------------
  # nc2 to final file
  #------------------------------------------------
  cdo -f nc2 copy CLIM_PREC_${mo}_time.nc $OUTDIR/Precip/${prefix_clim}.Prec.1960-1969.${mo}.nc
  cdo -f nc2 copy CLIM_SOLR_${mo}_time.nc $OUTDIR/Solar/${prefix_clim}.Solr.1960-1969.${mo}.nc
  cdo -f nc2 copy CLIM_TPQW_${mo}_time.nc $OUTDIR/TPHWL/${prefix_clim}.TPQWL.1960-1969.${mo}.nc
			
  #clean
  rm CLIM_PREC_*nc 
  rm CLIM_SOLR_*nc
  rm CLIM_TPQW_*nc

done # end mo loop
