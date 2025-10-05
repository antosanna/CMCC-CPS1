#!/bin/sh -l
# Download or locate each of the files and use the python script upload_2dropbox.py
# to add them to briefing_startdate folder in sp1 dropbox

####TO_BE_PORTED!
#
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

set +euvx
conda activate CDSAPI
set -euvx

# Configure env (load descriptor)
#DIR_UTIL="/users_home/cmcc/sp2/SPS/CMCC-${SPSSYS}/work/MARIA/briefing"
#DIR_LOG="/users_home/cmcc/sp2/SPS/CMCC-${SPSSYS}/work/MARIA/briefing/logs"
#SCRATCHDIR="/work/cmcc/sp2/scratch"

# Dates neccesary: current forecast, forecast evaluated, last year
fore_yyyy=`date +%Y`
fore_st=`date +%m`
today_dd=`date +%d`
eval_month_yyyy=`date --date='-1 month' +'%Y'`
eval_month_st=`date --date='-1 month' +'%m'`
eval_lead_yyyy=`date --date='-4 month' +'%Y'`
eval_lead_st=`date --date='-4 month' +'%m'`
if [[ $fore_st -ge 10 ]] ; then
#needed for MERRA reanalysis (stratosphere)
#e.g. for winter 2021/2022 - the plot will be named u60n_10_2021_merra2.pdf
   eval_year_yyyy=$fore_yyyy
else
   eval_year_yyyy=`date --date='-12 month' +'%Y'`
fi
case ${eval_month_st} in
    "01") eval_month_st_name="January";;
    "02") eval_month_st_name="February";;
    "03") eval_month_st_name="March";;
    "04") eval_month_st_name="April";;
    "05") eval_month_st_name="May";;
    "06") eval_month_st_name="June";;
    "07") eval_month_st_name="July";;
    "08") eval_month_st_name="August";;
    "09") eval_month_st_name="September";;
    "10") eval_month_st_name="October";;
    "11") eval_month_st_name="November";;
    "12") eval_mocnth_st_name="December";;
esac

# Directories
website_dir="/data/cmcc/sp1/C3S/webpage"
verification_dir="${website_dir}/verification_dev" 
verification_new_dir=/work/cmcc/sp2/EVALUATION/${fore_yyyy}${fore_st}
prob_index_dir=${website_dir}/forecast-indexes_dev
evaluation_dir="${website_dir}/evaluation"
forecast_index_dir="${website_dir}/forecast-indexes_dev" 
#dropbox_dir="Dropbox-API-Path-Root/Seasonal Forecast/${SPSSYS}/documents_staff/BRIEFINGS/briefing_plots_${fore_yyyy}${fore_st}"
dropbox_dir="/Seasonal Forecast/${SPSSYS}/documents_staff/BRIEFINGS/briefing_plots_${fore_yyyy}${fore_st}"
tmpdir="$SCRATCHDIR/briefing_plots_${fore_yyyy}${fore_st}"
logdir="$DIR_LOG/briefing_plots_${fore_yyyy}${fore_st}"

#***********************
# LIST PRODUCTS HERE !
#***********************
# Full list of files to upload. 2 types are considered: plots made by SPS, plots download from web.
# New products must be added to one of the lists

# Files produced by SPS
# Evaluation Nino3.4 and IOD
pfiles_name[1]="Nino3.4_verification_${eval_month_yyyy}${eval_month_st}.png"
pfiles_path[1]=${verification_new_dir}
pfiles_name[2]="IOD_verification_${eval_month_yyyy}${eval_month_st}.png"
pfiles_path[2]=${verification_new_dir}
# Verification on various variables for last verifiable lead (4 forecast ago) for variables: hgt500, mslp, tm, precip
pfiles_name[3]="hgt500_ano_verification_glo_${eval_lead_yyyy}${eval_lead_st}_lead1.png"
pfiles_path[3]=${verification_new_dir}
pfiles_name[4]="mslp_ano_verification_glo_${eval_lead_yyyy}${eval_lead_st}_lead1.png"
pfiles_path[4]=${verification_new_dir}
pfiles_name[5]="t2m_ano_verification_glo_${eval_lead_yyyy}${eval_lead_st}_lead1.png"
pfiles_path[5]=${verification_new_dir}
pfiles_name[6]="precip_ano_verification_glo_${eval_lead_yyyy}${eval_lead_st}_lead1.png"
pfiles_path[6]=${verification_new_dir}
pfiles_name[7]="hgt500_ano_verification_euro_${eval_lead_yyyy}${eval_lead_st}_lead1.png"
pfiles_path[7]=${verification_new_dir}
pfiles_name[8]="mslp_ano_verification_euro_${eval_lead_yyyy}${eval_lead_st}_lead1.png"
pfiles_path[8]=${verification_new_dir}
pfiles_name[9]="t2m_ano_verification_euro_${eval_lead_yyyy}${eval_lead_st}_lead1.png"
pfiles_path[9]=${verification_new_dir}
pfiles_name[10]="precip_ano_verification_euro_${eval_lead_yyyy}${eval_lead_st}_lead1.png"
pfiles_path[10]=${verification_new_dir}
# Hindcast evaluation (ACC/RMSE) for last verifiable lead (4 forecast ago) for variables: z500, mslp, tm, precip, sst
pfiles_name[11]="${SPSSYS}_ACC_global_z500_${eval_lead_st}_l1.png"
pfiles_path[11]=${verification_dir}
pfiles_name[12]="${SPSSYS}_ACC_global_mslp_${eval_lead_st}_l1.png"
pfiles_path[12]=${verification_dir}
pfiles_name[13]="${SPSSYS}_ACC_global_t2m_${eval_lead_st}_l1.png"
pfiles_path[13]=${verification_dir}
pfiles_name[14]="${SPSSYS}_ACC_global_precip_${eval_lead_st}_l1.png"
pfiles_path[14]=${verification_dir}
pfiles_name[15]="${SPSSYS}_ACC_global_sst_${eval_lead_st}_l1.png"
pfiles_path[15]=${verification_dir}
pfiles_name[16]="${SPSSYS}_RMSE_global_z500_${eval_lead_st}_l1.png"
pfiles_path[16]=${verification_dir}
pfiles_name[17]="${SPSSYS}_RMSE_global_mslp_${eval_lead_st}_l1.png"
pfiles_path[17]=${verification_dir}
pfiles_name[18]="${SPSSYS}_RMSE_global_t2m_${eval_lead_st}_l1.png"
pfiles_path[18]=${verification_dir}
pfiles_name[19]="${SPSSYS}_RMSE_global_precip_${eval_lead_st}_l1.png"
pfiles_path[19]=${verification_dir}
pfiles_name[20]="${SPSSYS}_RMSE_global_sst_${eval_lead_st}_l1.png"
pfiles_path[20]=${verification_dir}
# Tropical pacific temperature movie
pfiles_name[21]="temperature_pac_trop_ensmean_${fore_yyyy}_${fore_st}.gif"
pfiles_path[21]=${forecast_index_dir}
# IOD forecast
pfiles_name[22]="sst_IOD_mem_${fore_yyyy}_${fore_st}.png"
pfiles_path[22]=${forecast_index_dir}
pfiles_name[30]="sst_IOD_prob_${fore_yyyy}_${fore_st}.png"
pfiles_path[30]=${forecast_index_dir}
# noaa sst anomalies
pfiles_name[23]="noaa_anom_${fore_yyyy}${fore_st}.png"
pfiles_path[23]=$SCRATCHDIR/${fore_st}
# new verification plots
pfiles_name[24]="z500_ano_verification_${eval_lead_yyyy}${eval_lead_st}.pdf"
pfiles_path[24]=$verification_new_dir
pfiles_name[25]="mrlsl_ano_verification_${eval_lead_yyyy}${eval_lead_st}.pdf"
pfiles_path[25]=$verification_new_dir
pfiles_name[26]="mslp_ano_verification_${eval_lead_yyyy}${eval_lead_st}.pdf"
pfiles_path[26]=$verification_new_dir
pfiles_name[27]="t2m_ano_verification_${eval_lead_yyyy}${eval_lead_st}.pdf"
pfiles_path[27]=$verification_new_dir
pfiles_name[28]="precip_ano_verification_${eval_lead_yyyy}${eval_lead_st}.pdf"
pfiles_path[28]=$verification_new_dir
pfiles_name[29]="sst_Nino3.4_prob_${fore_yyyy}_${fore_st}.png"
pfiles_path[29]=$prob_index_dir
# Forecast Summary
pfiles_name[31]="Europe_summary_${fore_yyyy}_${fore_st}_l1.png"
pfiles_path[31]=$tmpdir

# Files download from web
# MERRA Polar vortex (stratospheric zonal wind)
dfiles_name[1]="u60n_10_${eval_year_yyyy}_merra2.pdf"
dfiles_website[1]="https://acd-ext.gsfc.nasa.gov/Data_services/met/metdata/annual/merra2/wind"
# NOOA Nino index areas
dfiles_name[2]="ninoareas_c.jpg"
dfiles_website[2]="https://www.cpc.ncep.noaa.gov/products/analysis_monitoring/ensostuff"
# NOOANino indexes timeseries
dfiles_name[3]="ssta_c.gif"
dfiles_website[3]="https://www.cpc.ncep.noaa.gov/products/analysis_monitoring/enso_update"
# NOOANino indexes map
dfiles_name[4]="sstweek_c.gif"
dfiles_website[4]="https://www.cpc.ncep.noaa.gov/products/analysis_monitoring/enso_update"
# NOOA ENSO advisory summary pdf
dfiles_name[5]="ensodisc.pdf"
dfiles_website[5]="https://www.cpc.ncep.noaa.gov/products/analysis_monitoring/enso_advisory"
# C3S UPDATE t2m map 
dfiles_name[6]="C3S_Bulletin_temp_${eval_month_yyyy}${eval_month_st}_Fig4a_map_temperature_anomalies_${eval_month_st_name}_global_Europe.png"
dfiles_website[6]="https://climate.copernicus.eu/sites/default/files/${fore_yyyy}-${fore_st}"
# C3S UPDATE t2m global and europe timeseries  
dfiles_name[7]="ts_1month_anomaly_Global_ERA5_2T_${eval_month_yyyy}${eval_month_st}_1991-2020_v01.1.png"
dfiles_website[7]="https://climate.copernicus.eu/sites/default/files/ftp-data/temperature/${eval_month_yyyy}/${eval_month_st}/ERA5_1991-2020"
# C3S UPDATE hydrological parameters europe map  
dfiles_name[8]="C3S_Bulletin_hydro_${eval_month_yyyy}${eval_month_st}_Fig1_map_anomalies_${eval_month_st_name}_Europe.png"
dfiles_website[8]="https://climate.copernicus.eu/sites/default/files/${fore_yyyy}-${fore_st}"
# C3S UPDATE Sea Ice Artic maps
dfiles_name[9]="map_1month_Arctic_ea_ci_${eval_month_yyyy}${eval_month_st}_1991-2020_v02.1.png"
dfiles_website[9]="https://climate.copernicus.eu/sites/default/files/ftp-data/seaice/${eval_month_yyyy}/${eval_month_st}/ERA5_1991-2020"
# C3S UPDATE Sea Ice Antartic maps
dfiles_name[10]="map_1month_Antarctic_ea_ci_${eval_month_yyyy}${eval_month_st}_1991-2020_v02.1.png"
dfiles_website[10]="https://climate.copernicus.eu/sites/default/files/ftp-data/seaice/${eval_month_yyyy}/${eval_month_st}/ERA5_1991-2020"
# C3S UPDATE Sea Ice Artic time series
dfiles_name[11]="ts_${eval_month_st_name}_anomaly_Arctic_ERA5_CIE_${eval_month_yyyy}${eval_month_st}_1991-2020_v01.1.png"
dfiles_website[11]="https://climate.copernicus.eu/sites/default/files/ftp-data/seaice/${eval_month_yyyy}/${eval_month_st}/ERA5_1991-2020"
# C3S UPDATE Sea Ice Antartic time series
dfiles_name[12]="ts_${eval_month_st_name}_anomaly_Antarctic_ERA5_CIE_${eval_month_yyyy}${eval_month_st}_1991-2020_v01.1.png"
dfiles_website[12]="https://climate.copernicus.eu/sites/default/files/ftp-data/seaice/${eval_month_yyyy}/${eval_month_st}/ERA5_1991-2020"
# ENSO impacts winter/summer cartoons
dfiles_name[13]="Nina_winterandsummer_620_from_climate.gov_.jpg"
dfiles_website[13]="https://www.pmel.noaa.gov/elnino/sites/default/files/thumbnails/image"
dfiles_name[14]="Nino_winterandsummer_620_from_climate.gov__0.jpg"
dfiles_website[14]="https://www.pmel.noaa.gov/elnino/sites/default/files/thumbnails/image"
# C3S UPDATE Sea Ice Extent Arctic time series
dfiles_name[15]="N_iqr_timeseries.png"
dfiles_website[15]="https://nsidc.org/data/seaice_index/images/daily_images"
# nsidc Sea Ice Extent Antarctic time series
dfiles_name[16]="S_iqr_timeseries.png"
dfiles_website[16]="https://nsidc.org/data/seaice_index/images/daily_images"
# selected extremes noaa
dfiles_name[17]="extremes-${eval_month_yyyy}${eval_month_st}.png"
dfiles_website[17]="https://www.ncdc.noaa.gov/monitoring-content/sotc/global/extremes"
# BOM IOS
#dfiles_name[17]="${fore_yyyy}${fore_st}${today_dd}.sstOutlooks_iod.png"
dfiles_name[18]="${fore_yyyy}${fore_st}${today_dd}.sstOutlooks_iod.png"
dfiles_website[18]="http://www.bom.gov.au/climate/enso/wrap-up/archive"
#NOAA ENSO - weekly report (presentation)
dfiles_name[19]="enso_evolution-status-fcsts-web.pdf"
dfiles_website[19]="https://www.cpc.ncep.noaa.gov/products/analysis_monitoring/lanina"
# ...

# other plots for briefing that we use:
# El Nino plumes for all C3S models: automatically emailed from server72 to sp1@cmcc.it
# Forecast maps from C3S: impossible to download, name not codifiable with month!

######################################################
# Normally no need to change from here...
######################################################
if [ -d $tmpdir ]; then 
     rm -rf $tmpdir
fi
mkdir -p $logdir
mkdir -p $tmpdir

cd $tmpdir

#create forecast summary
$DIR_ROOT/work/ANDREA/diag_C3S_final/launch_forecast_summary.sh

#Loop on produced files
echo 'Upload produced files'
for f in "${!pfiles_name[@]}"; do
     echo "${pfiles_path[$f]}/${pfiles_name[$f]}"

     if [ -f ${pfiles_path[$f]}/${pfiles_name[$f]} ]; then
         python $DIR_UTIL/upload_2dropbox.py "${pfiles_name[$f]}" -p "${pfiles_path[$f]}" -d "${dropbox_dir}" -l ${logdir}
     else
         echo "${pfiles_path[$f]}/${pfiles_name[$f]} does not exist" 
     fi
done

# Loop for downloaded files
echo 'Upload downloaded files'
for f in "${!dfiles_name[@]}"; do
    echo "${dfiles_website[$f]}/${dfiles_name[$f]}"
    set +e
    wget --no-check-certificate "${dfiles_website[$f]}/${dfiles_name[$f]}"
    if [ -f ${tmpdir}/enso_evolution-status-fcsts-web.pdf ] ;then
       cd ${tmpdir}
       convert -density 300 enso_evolution-status-fcsts-web.pdf -trim +repage enso_%02d.png
       listremove=`ls -1 enso_??.png | grep -v "enso_04.png"`
       rm $listremove 
    fi
    set -e
    if [ -f ${tmpdir}/${dfiles_name[$f]} ]; then
        python $DIR_UTIL/upload_2dropbox.py "${dfiles_name[$f]}" -p "${tmpdir}" -d "${dropbox_dir}" -l ${logdir}
    else
        echo "${tmpdir}/${dfiles_name[$f]} does not exist" 
    fi
done


exit 0
