#!/bin/sh -l
###################################################################################################
## Script:  assemble_briefing.sh                                                                 ##
## Author:  Andrea Borrelli and Brandon J Fisel                                                  ##
## Summary: Executes the final plotting programs, modifies some plots via magick and executes    ##
##          the python pptx program that assembles the briefing presentation.                    ##
## Description: Adapted from prepare_briefing, this script executes the NCL program that creates ##
##          the forecast summary, executes the program for creating the esacci anomaly images,   ##
##          modifies some images for viewing within the briefing, checks all required briefing   ##
##          images exist, executes the python program that creates the briefing presentation,    ##
##          and rclones the presentation to drive with email alerts to sp1.                      ##
## Creation Date: ??/??/202?                                                                     ##
## Revision Date: 25/09/2026                                                                     ##
## Revised By: BJF                                                                               ##
###################################################################################################

. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/load_convert

conda activate ~as34319/miniconda/envs/pptx

set -euvx

read -r yyyy mm dd <<< "${1:-$(date +%Y)} ${2:-$(date +%m)} $(date +%d)"

iniy_hind=1995
endy_hind=2024
refperiod="${iniy_hind}-${endy_hind}"
dayofbriefing=19
baseline="$yyyy-$mm-01"

mmstring=$(date -d "$baseline" +%B)

yyyym1=$(date -d "$baseline -1 month" +%Y)
mm1=$(date -d "$baseline -1 month" +%m)
mm1str=$(date -d "$baseline -1 month" +%B)

yyyym2=$(date -d "$baseline -2 months" +%Y)
mm2=$(date -d "$baseline -2 months" +%m)
mm2str=$(date -d "$baseline -2 months" +%B)

sm1forey=$(date -d "$baseline -4 months" +%Y)
sm1forem=$(date -d "$baseline -4 months" +%m)
sm1foremstr=$(date -d "$baseline -4 months" +%B)

yyyym6=$(date -d "$baseline -6 months" +%Y)
mm6str=$(date -d "$baseline -6 months" +%B)

nddm1=$(date -d "$yyyym1-$mm1-01 +1 month -1 day" +%d)

m1seam1=$(date -d "$sm1forey-$sm1forem-01 +1 month" +%b | cut -c1)
m2seam1=$(date -d "$sm1forey-$sm1forem-01 +2 months" +%b | cut -c1)
m3seam1=$(date -d "$sm1forey-$sm1forem-01 +3 months" +%b | cut -c1)
seam1="${m1seam1}${m2seam1}${m3seam1}"

m1sea=$(date -d "$baseline +1 month" +%b | cut -c1)
m2sea=$(date -d "$baseline +2 months" +%b | cut -c1)
m3sea=$(date -d "$baseline +3 months" +%b | cut -c1)
sea="${m1sea}${m2sea}${m3sea}"

set +euvx
. $DIR_UTIL/descr_ensemble.sh $yyyy
set -euvx

# Image directories: current downloaded images, past downloaded images, evaluation, circulation, sie and web images
IMG_DNLD_DIR="${SCRATCHDIR}/briefing_plots_${yyyy}${mm}"
IMG_EVAL_DIR="/work/cmcc/cp1/EVALUATION/${yyyy}${mm}"
IMG_CIRC_DIR="${SCRATCHDIR}/BRIEFINGS/circulation_maps/${yyyy}${mm}"
IMG_SIE_DIR="${SCRATCHDIR}/SIE/${sm1forey}${sm1forem}/NH"
IMG_WEB_DIR="${DIR_WEB}/forecast-indexes_dev"
IMG_DIAG_DIR="${SCRATCHDIR}/diag_C3S/forecast_plots/${yyyy}${mm}/"
IMG_WAMI_DIR="${SCRATCHDIR}/WAMI/SPS4_plots_${iniy_hind}_${endy_hind}"

POST_DIR=${DIR_POST}/briefing_diags

ncl 'yyyyfore="'"$yyyy"'"' 'mmfore="'"$mm"'"' 'dirplot="'"$IMG_DNLD_DIR"'"' 'refperiod="'"$refperiod"'"' 'SS="'"$sea"'"' ${POST_DIR}/ncl/forecast_summary.ncl
${POST_DIR}/calc_daily_anom_obs_briefing.sh ${yyyy} ${mm}

# Modify image files for viewing inside the briefing pptx
# SST anomalies
magick ${IMG_DNLD_DIR}/esacci_anom_fore_${yyyy}${mm}.png -crop 100%x30%+0+57 -trim +repage ${IMG_DNLD_DIR}/sst_anomalies_top.png
magick ${IMG_DNLD_DIR}/esacci_anom_fore_${yyyy}${mm}.png -crop 100%x70%+0+360 -trim +repage ${IMG_DNLD_DIR}/sst_anomalies_bottom.png

# Month 1 global evaluations - crop into individual elements
magick ${IMG_EVAL_DIR}/t2m_ano_verification_global_${yyyym2}${mm2}_l1_monthly.png -crop 30%x100%+900%+0 -trim +repage ${IMG_EVAL_DIR}/eval_colorbar.png
magick ${IMG_EVAL_DIR}/t2m_ano_verification_global_${yyyym2}${mm2}_l1_monthly.png -crop 90%x100%+0%+0 -trim +repage ${IMG_EVAL_DIR}/t2m_ano_verification_global_${yyyym2}${mm2}_l1_monthly_nobar.png
magick ${IMG_EVAL_DIR}/precip_ano_verification_global_${yyyym2}${mm2}_l1_monthly.png -crop 90%x100%+0%+0 -trim +repage ${IMG_EVAL_DIR}/precip_ano_verification_global_${yyyym2}${mm2}_l1_monthly_nobar.png

# Month 1 Europe evaluations - crop into individual elements
magick ${IMG_EVAL_DIR}/t2m_ano_verification_europe_${yyyym2}${mm2}_l1_monthly.png -crop 90%x100%+0%+0 -trim +repage ${IMG_EVAL_DIR}/t2m_ano_verification_europe_${yyyym2}${mm2}_l1_monthly_nobar.png
magick ${IMG_EVAL_DIR}/precip_ano_verification_europe_${yyyym2}${mm2}_l1_monthly.png -crop 90%x100%+0%+0 -trim +repage ${IMG_EVAL_DIR}/precip_ano_verification_europe_${yyyym2}${mm2}_l1_monthly_nobar.png

# Lead 1 global evaluations - crop into individual elements
magick ${IMG_EVAL_DIR}/t2m_ano_verification_global_${sm1forey}${sm1forem}_l1_seasonal.png -crop 90%x100%+0%+0 -trim +repage ${IMG_EVAL_DIR}/t2m_ano_verification_global_${sm1forey}${sm1forem}_l1_seasonal_nobar.png
magick ${IMG_EVAL_DIR}/precip_ano_verification_global_${sm1forey}${sm1forem}_l1_seasonal.png -crop 90%x100%+0%+0 -trim +repage ${IMG_EVAL_DIR}/precip_ano_verification_global_${sm1forey}${sm1forem}_l1_seasonal_nobar.png

# Lead 1 Europe evaluations - crop into individual elements
magick ${IMG_EVAL_DIR}/t2m_ano_verification_europe_${sm1forey}${sm1forem}_l1_seasonal.png -crop 90%x100%+0%+0 -trim +repage ${IMG_EVAL_DIR}/t2m_ano_verification_europe_${sm1forey}${sm1forem}_l1_seasonal_nobar.png
magick ${IMG_EVAL_DIR}/precip_ano_verification_europe_${sm1forey}${sm1forem}_l1_seasonal.png -crop 90%x100%+0%+0 -trim +repage ${IMG_EVAL_DIR}/precip_ano_verification_europe_${sm1forey}${sm1forem}_l1_seasonal_nobar.png

# Check all required briefing images exist before creating the presentation
EXPECTED_IMAGES=(
    "${IMG_DNLD_DIR}/signif_events.png"
    "${IMG_DNLD_DIR}/nino_timeseries.png"
    "${IMG_DNLD_DIR}/sst_anomalies_bottom.png"
    "${IMG_DNLD_DIR}/sst_anomalies_top.png"
    "${IMG_DNLD_DIR}/map_arctic.png"
    "${IMG_DNLD_DIR}/map_antarctic.png"
    "${IMG_DNLD_DIR}/timesrs_antarctic.png"
    "${IMG_DNLD_DIR}/timesrs_arctic.png"
    "${IMG_DNLD_DIR}/t2m_c3s_climbull_eu.png"
    "${IMG_DNLD_DIR}/t2m_c3s_climbull_glo.png"
    "${IMG_DNLD_DIR}/hydro_c3s_climbull.png"
    "${IMG_CIRC_DIR}/mslp_anom_${yyyym1}${mm1}.png"
    "${IMG_CIRC_DIR}/z500_anom_${yyyym1}${mm1}.png"
    "${IMG_CIRC_DIR}/u250_anom_${yyyym1}${mm1}.png"
    "${IMG_EVAL_DIR}/eval_colorbar.png"
    "${IMG_EVAL_DIR}/precip_ano_verification_europe_${yyyym2}${mm2}_l1_monthly_nobar.png"
    "${IMG_EVAL_DIR}/t2m_ano_verification_europe_${yyyym2}${mm2}_l1_monthly_nobar.png"
    "${IMG_EVAL_DIR}/t2m_ano_verification_global_${yyyym2}${mm2}_l1_monthly_nobar.png"
    "${IMG_EVAL_DIR}/precip_ano_verification_global_${yyyym2}${mm2}_l1_monthly_nobar.png"
    "${IMG_EVAL_DIR}/Nino3.4_verification_${yyyym1}${mm1}.png"
    "${IMG_SIE_DIR}/NH_SIE_${sm1forey}${sm1forem}.png"
    "${IMG_EVAL_DIR}/precip_ano_verification_global_${sm1forey}${sm1forem}_l1_seasonal_nobar.png"
    "${IMG_EVAL_DIR}/t2m_ano_verification_global_${sm1forey}${sm1forem}_l1_seasonal_nobar.png"
    "${IMG_EVAL_DIR}/precip_ano_verification_europe_${sm1forey}${sm1forem}_l1_seasonal_nobar.png"
    "${IMG_EVAL_DIR}/t2m_ano_verification_europe_${sm1forey}${sm1forem}_l1_seasonal_nobar.png"
    "${IMG_DNLD_DIR}/c3s_mme_nino.png"
    "${IMG_DIAG_DIR}/sst_Nino3.4_strength_prob_${yyyy}_${mm}.png"
    "${IMG_DIAG_DIR}/sst_Nino3.4_mem_${yyyy}_${mm}.png"
    "${IMG_WEB_DIR}/temperature_pac_trop_ensmean_${yyyy}_${mm}.gif"
    "${IMG_DNLD_DIR}/cmcc_sst_fore_global.png"
    "${IMG_DNLD_DIR}/c3s_mm_ssto_fore_glob.png"
    "${IMG_DNLD_DIR}/cmcc_mslp_fore_global.png"
    "${IMG_DNLD_DIR}/c3s_mm_mslp_fore_glob.png"
    "${IMG_DNLD_DIR}/cmcc_hgt500_fore_global.png"
    "${IMG_DNLD_DIR}/c3s_mm_z500_fore_glob.png"
    "${IMG_DNLD_DIR}/cmcc_precip_fore_global.png"
    "${IMG_DNLD_DIR}/c3s_mm_rain_fore_glob.png"
    "${IMG_DNLD_DIR}/cmcc_t2m_fore_global.png"
    "${IMG_DNLD_DIR}/c3s_mm_2mtm_fore_glob.png"
    "${IMG_DNLD_DIR}/cmcc_hgt500_fore_Europe.png"
    "${IMG_DNLD_DIR}/cmcc_mslp_fore_Europe.png"
    "${IMG_DNLD_DIR}/cmcc_t2m_fore_Europe.png"
    "${IMG_DNLD_DIR}/cmcc_precip_fore_Europe.png"
    "${IMG_DNLD_DIR}/Europe_summary_${yyyy}_${mm}_l1.png"
    "${IMG_DNLD_DIR}/U10hPa_cmcc_fore_probs_lt0.png"
    "${IMG_DNLD_DIR}/U10hPa_fore_probs_lt0.png"
    "${IMG_WEB_DIR}/sst_IOD_mem_${yyyy}_${mm}.png"
    "${IMG_WEB_DIR}/sst_IOD_prob_${yyyy}_${mm}.png"
)
if (( 10#$mm >= 4 && 10#$mm < 10 )); then
    EXPECTED_IMAGES+=(
        "${IMG_WAMI_DIR}/WAMI_forecast_${yyyy}${mm}.png"
        "${IMG_WAMI_DIR}/WAMI_probability_${yyyy}${mm}.png"
    )
fi

missing_count=0
body_missing=""
echo "Checking required image files..."
for img in "${EXPECTED_IMAGES[@]}"; do
    if [ ! -f "$img" ]; then
        body_missing+="Missing - ${img}"
        echo "ERROR: Required ${img} image file is missing"
        ((missing_count++))
    fi
done

if [ "$missing_count" -gt 0 ]; then
    title="${CPSSYS} BRIEFING CREATION - FAILED"
    email_msg="The briefing for ${yyyy}${mm} could not be created.\n" 
    email_msg+="There are ${missing_count} required image files missing:"
    email_msg+="${body_missing}"
    ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$email_msg" -t "$title"
    echo "ERROR: Aborting briefing presentation creation. $missing_count required image files are missing."
    exit 1
fi

# Create the presentation
input="$yyyy $mm $mmstring $yyyym1 $yyyym2 $mm1 $mm2 $mm1str $yyyym2 $mm2str $sm1forey $sm1forem $sm1foremstr $seam1 $sea $dayofbriefing $nddm1 $mm6str $yyyym6"
python3 ${POST_DIR}/python/modify_template_dev.py \
    --img-dnld-dir "$IMG_DNLD_DIR" \
    --img-eval-dir "$IMG_EVAL_DIR" \
    --img-circ-dir "$IMG_CIRC_DIR" \
    --img-sie-dir "$IMG_SIE_DIR" \
    --img-web-dir "$IMG_WEB_DIR" \
    --img-diag-dir "$IMG_DIAG_DIR" \
    --img-wami-dir "$IMG_WAMI_DIR" \
    $input

# Upload presentation to drive and send mail
briefing_pres="${IMG_DNLD_DIR}/${mmstring}_${yyyy}.pptx"
if [[ "$missing_count" -eq 0 && -f "${briefing_pres}" ]]; then
    echo "Uploading presentation to drive..."
    set +euvx
    . ${DIR_UTIL}/condaactivation.sh
    condafunction deactivate
    condafunction activate $envcondarclone
    set -euvx
    rclone mkdir my_drive:briefings/${yyyy}${mm}
    rclone copy $briefing_pres my_drive:briefings/${yyyy}${mm}

    title="${CPSSYS} BRIEFING CREATION - COMPLETE"
    email_msg="The briefing for ${yyyy}${mm} has been created successfully and is on the drive at:\n"
    email_msg+="briefings/${yyyy}${mm}"
    ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$email_msg" -t "$title"
    echo "Briefing completed successfully!"
else
    title="${CPSSYS} BRIEFING CREATION - FAILED"
    email_msg="The briefing for ${yyyy}${mm} could not be created.\n"
    email_msg+="Something went wrong with the creation of the briefing ${briefing_pres}."
    ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$email_msg" -t "$title"
    echo "ERROR: Something went wrong with the creation of the briefing ${briefing_pres}."
    exit 1
fi

exit 0
