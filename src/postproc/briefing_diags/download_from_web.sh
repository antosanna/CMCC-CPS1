#!/bin/sh -l
###################################################################################################
## Script:  download_from_web.sh                                                                 ##
## Author:  Brandon J Fisel                                                                      ##
## Summary: Downloads required and optional image files from the web, Copernicus and server73.   ##
## Description: This script first downloads images from the web, then downloads Copernius C3S    ##
##          charts and finally downloads the ENSO plume for all models from server73. Seasonal-  ##
##          specific (summer/winter) plots are always downloaded regardless of season.           ##
## Creation Date: 18/05/2026                                                                     ##
## Revision Date: 28/09/2026                                                                     ##
## Revised By: BJF                                                                               ##
###################################################################################################

. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. ${DIR_UTIL}/load_convert

set +evxu
. ${DIR_UTIL}/load_miniconda
conda activate env_json
set -evxu

# Dates neccesary: current forecast, forecast evaluated and last year
read -r yyyy mm dd <<< "${1:-$(date +%Y)} ${2:-$(date +%m)} $(date +%d)"

baseline="$yyyy-$mm-01"

fore_yyyy="$yyyy"
fore_st="$mm"
today_dd="$dd"

mm1str=$(date -d "$baseline -1 month" +%B)

eval_month_yyyy=$(date -d "$baseline -1 month" +%Y)
eval_month_st=$(date -d "$baseline -1 month" +%m)
eval_lead_yyyy=$(date -d "$baseline -4 months" +%Y)
eval_lead_st=$(date -d "$baseline -4 months" +%m)

if [[ $((10#$fore_st)) -ge 10 ]] ; then
    # Needed for MERRA stratospheric zonal wind reanalysis (e.g., winter 2021/2022: u60n_10_2021_merra2.pdf)
    eval_year_yyyy=$fore_yyyy
else
    eval_year_yyyy=$(date -d "$baseline -12 months" +%Y)
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
    "12") eval_month_st_name="December";;
esac

tmpdir="$SCRATCHDIR/briefing_plots_${fore_yyyy}${fore_st}"
logdir="$DIR_LOG/briefing_plots_${fore_yyyy}${fore_st}/logs"

# Check for existence of flag and exit if all files have already been downloaded
flag_done=${logdir}/download_from_web_DONE
if [ -f $flag_done ]; then
    exit 0
fi

# Use a key-value dict to group figures to download as filename_tosave, stored in array as:
# Direct download: ["filename_tosave"]="base_url/imagename"
# Scrape download: ["filename_tosave"]="SCRAPE:base_url|keyword|file_extension"

# Use web scraping for image downloads from the Copernicus Bulletin (image names vary by month). Follow the above
# Scrape download comment to change or add images for download (more info below). The Scrape download expands the
# image name string using |, similar to a * wildcard.

# To modify or add Copernicus Bulletin images for download:
# 1) Go to the base_url in a web browser
# 2a) For a static image: right click, and open in another tab
# 2b) For a dynamic image (timeseries): click the download arrow button and download the file
# 3a) Determine a common image name (keyword) for that image in the web browser
# 3b) Similar to 3a, but from the image file name downloaded to your computer
# 4) Modify or add to the web_downloads array: the filename_tosave, base_url, keyword and file extension

# Lowercase month name from the bulletin page URL
eval_month_name="${mm1str,,}"
declare -A web_downloads=(
  ################################################################################
  # Standard figures to download
  # 1 MERRA2 polar vortex (stratospheric zonal wind)
  ["u60n_10_${eval_year_yyyy}_merra2.pdf"]="https://ozonewatch.gsfc.nasa.gov/meteorology/figures/merra2/wind/u60n_10_${eval_year_yyyy}_merra2.pdf"
  # 2 NOAA Nino index areas
  ["ninoareas_c.jpg"]="https://www.cpc.ncep.noaa.gov/products/analysis_monitoring/ensostuff/ninoareas_c.jpg"
  # 3 NOAA ENSO advisory summary pdf
  ["ensodisc.pdf"]="https://www.cpc.ncep.noaa.gov/products/analysis_monitoring/enso_advisory/ensodisc.pdf"
  # Scrape the two below sea ice figures
  # 4 C3S arctic sea ice map
  ["map_arctic.png"]="SCRAPE:https://climate.copernicus.eu/sea-ice-cover-${eval_month_name}-${eval_month_yyyy}|concentration_anomalies_arctic|.png.jpg"
  # 5 C3S antarctic sea ice map
  ["map_antarctic.png"]="SCRAPE:https://climate.copernicus.eu/sea-ice-cover-${eval_month_name}-${eval_month_yyyy}|concentration_anomalies_antarctic|.png.jpg"
  # 6 NSIDC arctic sea ice extent time series
  ["timesrs_arctic.png"]="https://nsidc.org/data/seaice_index/images/daily_images/N_iqr_timeseries.png"
  # 7 NSIDC antarctic sea ice extent time series
  ["timesrs_antarctic.png"]="https://nsidc.org/data/seaice_index/images/daily_images/S_iqr_timeseries.png"
  # 8 NOAA selected extremes
  ["signif_events.png"]="https://www.ncei.noaa.gov/monitoring-content/sotc/global/extremes/extremes-${eval_month_yyyy}${eval_month_st}.png"
  # 9 NOAA ENSO weekly report (presentation)
  ["enso_evolution-status-fcsts-web.pdf"]="https://www.cpc.ncep.noaa.gov/products/analysis_monitoring/lanina/enso_evolution-status-fcsts-web.pdf"
  # Scrape the three below t2m and hydro figures
  # 10 C3S global t2m map
  ["t2m_c3s_climbull_glo.png"]="SCRAPE:https://climate.copernicus.eu/surface-air-temperature-${eval_month_name}-${eval_month_yyyy}|map_temperature_anomalies_${eval_month_st_name}_global|.png.jpg"
  # 11 C3S europe t2m map
  ["t2m_c3s_climbull_eu.png"]="SCRAPE:https://climate.copernicus.eu/surface-air-temperature-${eval_month_name}-${eval_month_yyyy}|map_temperature_anomalies_${eval_month_st_name}_europe|.png.jpg"
  # 12 C3S europe hydrological parameters map
  ["hydro_c3s_climbull.png"]="SCRAPE:https://climate.copernicus.eu/precipitation-relative-humidity-soil-moisture-and-river-flow-${eval_month_name}-${eval_month_yyyy}|map_anomalies_${eval_month_st_name}_europe|.png.jpg"
  ################################################################################
  # Temporary or non-standard figures to download
  # Scrape the two below t2m time series figures
  # C3S global and europe t2m time series
  #["timeseries_era5_monthly_2t_anomaly_ref19912020_glo.png"]="SCRAPE:https://climate.copernicus.eu/surface-air-temperature-${eval_month_name}-${eval_month_yyyy}|timeseries_era5_monthly_2t_anomaly_ref19912020_global_month|.png"
  #["timeseries_era5_monthly_2t_anomaly_ref19912020_eu.png"]="SCRAPE:https://climate.copernicus.eu/surface-air-temperature-${eval_month_name}-${eval_month_yyyy}|timeseries_era5_monthly_2t_anomaly_ref19912020_europe_month|.png"
  ################################################################################
)

mkdir -p $logdir
mkdir -p $tmpdir

cd $tmpdir

# Accumulated error arrays for summarizing at bottom of log
web_errors=()
C3S_errors=()

# Download the web_downloads array list first
max_attempts=10
for output_name in "${!web_downloads[@]}"; do
    if [[ -f "$output_name" ]]; then
        echo "$output_name image file exists, skipping..."
        continue
    fi

    url="${web_downloads[$output_name]}"

    if [[ "$url" == SCRAPE:* ]]; then
        # Remove SCRAPE: prefix
        label="${url#SCRAPE:}"

        # Extract the array components
        IFS='|' read -r base_url keyword ext_pattern <<< "$label"

        echo "Fetching bulletin page for: $output_name..."
        html=""
        attempt=1
        while [[ -z "$html" && $attempt -le $max_attempts ]]; do
            if (( attempt > 1 )); then
                echo "Attempt $attempt: retrying in a few seconds..."
                sleep $((10 + RANDOM % (20 - 10)))
            fi
            set +x
            html=$(curl -k -sS -f -L --connect-timeout 10 --max-time 30 "$base_url")
            set -x
            ((attempt++))
        done

        # Check for valid bulletin page
        if [[ -z "$html" ]]; then
            web_errors+=("CRITICAL: Failed to load bulletin page at $base_url for target '$output_name' after $max_attempts attempts")
            continue
        fi

        # Fetch HTML link and extract matching imagename using this regex:
        # ${base_url} : the https url path
        # [^"'> ]* : strings that change
        # ${keyword} : partial imagename that should not change
        # ${ext_pattern} : as defined in the array path (web_downloads)

        set +x
        remote_file=$(echo "$html" | grep -oE "[^\"'> ]*${keyword}[^\"'> ]*\\${ext_pattern}" | head -n 1)
        set -x

        # Check for existence of imagefile and download
        if [[ -n "$remote_file" ]]; then
            # Handle relative urls
            [[ "$remote_file" != http* ]] && remote_file="https://climate.copernicus.eu${remote_file}"

            # For .png.jpg files, download and convert to .png
            if [[ "$ext_pattern" == *".png.jpg"* ]] && [[ "$output_name" == *.png ]]; then
                tmp_file="${output_name}.tmp.jpg"
                attempt=1
                download_success=false
                while [[ "$download_success" == false && $attempt -le $max_attempts ]]; do
                    if (( attempt > 1 )); then
                        echo "Attempt $attempt: retrying in a few seconds..."
                        sleep $((10 + RANDOM % (20 - 10)))
                    fi

                    rm -f "$tmp_file"
                    curl -k -sS -f -L --connect-timeout 10 --max-time 60 "$remote_file" -o "$tmp_file"

                    if [[ -s "$tmp_file" ]]; then
                        download_success=true
                    fi
                    ((attempt++))
                done

                # Validate downloaded temp file
                if [[ "$download_success" == false ]]; then
                    web_errors+=("DOWNLOAD_FAILED: Could not download '$output_name' from $remote_file after $max_attempts attempts")
                    rm -f "$tmp_file"
                    continue
                fi

                convert "$tmp_file" "$output_name" && rm -f "$tmp_file"
            else
                echo "Downloading $output_name..."
                attempt=1
                while [[ "$download_success" == false && $attempt -le $max_attempts ]]; do
                    if (( attempt > 1 )); then
                        echo "Attempt $attempt: retrying in a few seconds..."
                        sleep $((10 + RANDOM % (20 - 10)))
                    fi

                    rm -f "$output_name"
                    curl -k -sS -f -L --connect-timeout 10 --max-time 60 "$remote_file" -o "$output_name"

                    if [[ -s "$output_name" ]]; then
                        download_success=true
                    fi
                    ((attempt++))
                done

                if [[ "$download_success" == false ]]; then
                    web_errors+=("DOWNLOAD_FAILED: Could not download '$output_name' from $remote_file after $max_attempts attempts")
                fi
            fi
            # Final output file check
            if [[ -s "$output_name" ]]; then
                echo "Saved: $output_name"
            elif [[ "$download_success" == true ]]; then
                web_errors+=("FILE_EMPTY: Output image '$output_name' exists but is empty")
            fi
        else
            web_errors+=("NOT_FOUND: Could not locate keyword '$keyword' on '$base_url' for target '$output_name'")
        fi
    else
        # Direct file downloads
        echo "Downloading image: $output_name...."
        attempt=1
        download_success=false
        while [[ "$download_success" == false && $attempt -le $max_attempts ]]; do
            if (( attempt > 1 )); then
                echo "Attempt $attempt: retrying in a few seconds..."
                sleep $((10 + RANDOM % (20 - 10)))
            fi

            rm -f "$output_name"
            curl -k -sS -f -L --connect-timeout 10 --max-time 60 "$url" -o "$output_name"

            if [[ -s "$output_name" ]]; then
                download_success=true
            fi
            ((attempt++))
        done

        if [[ "$download_success" == false ]]; then
            web_errors+=("DOWNLOAD_FAILED: Output file '$output_name' is missing or is empty")
        else
            echo "Saved: $output_name"
        fi
    fi
    sleep $((5 + RANDOM % (20 - 5)))
done

# Download forecast maps from Copernicus Climate Data Store: C3S MM/CMCC and U10hPa

# Define parameters
var_cen=("edzw" "ecmf" "rjtd" "egrr" "lfpw" "cmcc" "mm") #centres
var_C3S=("mslp" "ssto" "2mtm" "z500" "rain") #C3S vars
base_C3S_key=("base_time") #base time
base_C3S=("${fore_yyyy}-${fore_st}-01T00:00:00Z")
valid_C3S_key=("valid_time") #3mo valid time
valid_C3S_3mo_yyyy=$(date --date="+ 1 month" +'%Y')
valid_C3S_3mo_st=$(date --date="+ 1 month" +'%m')
valid_C3S_3mo=("${valid_C3S_3mo_yyyy}-${valid_C3S_3mo_st}-01T00:00:00Z")
map_C3S_key=("type") #C3S plot types ("" = terc_su or tercile summary, and ensm or ensemble mean anomoly)
map_C3S=("" "ensm")
mapU_C3S=("probs_lt0")
area_C3S_key=("area") #C3S areas ("" = Global, "area01" = Europe)
area_C3S=("" "area01")

FAILNUM=0

# Curl helper functions to build parameter strings locally for missing ""
param_query() {
    local q="$base_C3S_key=$1&$valid_C3S_key=$2"
    [[ -n "$3" ]] && q+="&$map_C3S_key=$3"
    [[ -n "$4" ]] && q+="&$area_C3S_key=$4"
    echo "$q"
}

param_query_ts() {
    local q="$base_C3S_key=$1&$map_C3S_key=$2"
    echo "$q"
}

# Generate parameter and filename combinations
combinations=()
filenames=()
for v3mo in "${valid_C3S_3mo[@]}"; do
    for vmap in "${map_C3S[@]}"; do
        for vare in "${area_C3S[@]}"; do
            combinations+=("$(param_query "$base_C3S" "$v3mo" "$vmap" "$vare")")
            # File names to build with substitutions for missing ""
            f1="${vmap:-terc_su}"
            f2="${vare:-glob}"
            # Remove suffix after last hyphen for file name
            filenames+=("${f2}_${f1}")
        done
    done
done

# Replace area01=euro in filenames
filenames=("${filenames[@]/area01/euro}")

# Generate parameter combinations for U10hPa consistent with MM
combinations_ts=()
combinations_ts+=("$(param_query_ts "$base_C3S" "$mapU_C3S")")

#echo "Total requests to process: $(( ${#combinations[@]} * ${#var_C3S[@]} )) C3SMM and ${#combinations_ts[@]} U10hPa timeseries"

# Process parameter combinations for download
# 3 Month C3SMM & CMCC
for vcen in "${var_cen[@]:5:6}"; do
    for vvar in "${var_C3S[@]}"; do
        BASE_URL="https://charts.ecmwf.int/opencharts-api/v1/products/c3s_seasonal_spatial_${vcen}_${vvar}_3m/"
        for i in "${!combinations[@]}"; do
            params="${combinations[$i]}"
            fname="c3s_${vcen}_${vvar}_fore_${filenames[$i]}"
            if [[ -f "$fname.png" ]]; then
                echo "$fname.png already exists, skipping..."
                continue
            fi
            echo "Requesting: $params"

            img_url=""
            attempt=1
            max_attempts=10

            # First curl to obtain json file, then parse the img link stored to img_url
            while [[ -z "$img_url" && $attempt -le $max_attempts ]]; do
                if (( attempt > 1 )); then
                    echo "Attempt $attempt: retrying in a few seconds..."
                    sleep $((10+RANDOM % (20-10)))
                fi
                img_url=$(curl -s -f -G -d "$params" --connect-timeout 10 --max-time 30 "${BASE_URL}" | jq -r '.. | .link? | .href? // empty')

                ((attempt++))
            done

            # Second curl to obtain img
            if [[ -n "$img_url" ]]; then
                curl -s -f -L -o "${fname}.png" --connect-timeout 10 --max-time 60 "$img_url"
                file "${fname}.png" | grep -q "PNG image data" || C3S_errors+=("Not a PNG: '${fname}'.png")
                echo "Saved: ${fname}.png"
            else
                C3S_errors+=("FAILED: Could not retrieve img_url for '$params' after '$max_attempts' attempts")
                ((FAILNUM++))
            fi
            sleep $((5+RANDOM % (20-5)))
        done
    done
done

echo "C3SMM download failures: $FAILNUM"
FAILNUM=0 #reset for U10hPa

# U10hPa timeseries
for vcen in "${var_cen[@]:0:6}"; do
    BASE_URL="https://charts.ecmwf.int/opencharts-api/v1/products/c3s_seasonal_stratots_${vcen}/"
    for i in "${!combinations_ts[@]}"; do
        params="${combinations_ts[$i]}"
        fname="U10hPa_${vcen}_fore_probs_lt0"
        if [[ -f "$fname.png" ]]; then
            echo "$fname.png already exists, skipping..."
            continue
        fi
        echo "Requesting $params"

        img_url=""
        attempt=1
        max_attempts=10

        while [[ -z "$img_url" && $attempt -le $max_attempts ]]; do
            if (( attempt > 1 )); then
                echo "Attempt $attempt: retrying in a few seconds..."
                sleep $((10+RANDOM % (20-10)))
            fi  
            img_url=$(curl -s -f -G -d "$params" --connect-timeout 10 --max-time 30 "${BASE_URL}" | jq -r '.. | .link? | .href? // empty')

            ((attempt++))
        done

        if [[ -n "$img_url" ]]; then
            curl -s -f -L -o "${fname}.png" --connect-timeout 10 --max-time 60 "$img_url"
            file "${fname}.png" | grep -q "PNG image data" || C3S_errors+=("Not a PNG: '${fname}'.png")
            echo "Saved: ${fname}.png"
        else
            C3S_errors+=("FAILED: Could not retrieve img_url for '$params' after '$max_attempts' attempts")
            ((FAILNUM++))
        fi  
        sleep $((5+RANDOM % (20-5)))
    done
done

echo "U10hPa download failures: $FAILNUM"

# Process C3S MM/CMCC into montages
# Note: the resulting resolution of these montages yields a final pptx file size ~2x the original size (~25Mb to ~53Mb)
for f in U10hPa_*.png; do magick "$f" -gravity South -chop 0x250 -trim +repage "$(basename "$f")"; done
montage -mode concatenate -tile 3x2 U10hPa_{cmcc,ecmf,edzw,rjtd,egrr,lfpw}_*.png U10hPa_fore_probs_lt0.png

for f in c3s_*.png; do magick "$f" -gravity South -chop 0x250 -trim +repage "$(basename "$f")"; done

declare -a var=("mslp" "2mtm" "rain" "ssto" "z500")
for v in "${var[@]}"; do
    montage -mode concatenate -tile 1x2 c3s_cmcc_${v}_fore_glob_*.png c3s_cmcc_${v}_fore_glob.png
    montage -mode concatenate -tile 1x2 c3s_mm_${v}_fore_glob_*.png c3s_mm_${v}_fore_glob.png
    montage -mode concatenate -tile 1x2 c3s_cmcc_${v}_fore_euro_*.png c3s_cmcc_${v}_fore_euro.png
done

if [ -f ${tmpdir}/enso_evolution-status-fcsts-web.pdf ] ;then
    cd ${tmpdir}
    convert -density 300 enso_evolution-status-fcsts-web.pdf[4] -trim +repage nino_timeseries.png
fi

# Retrieve C3S MME NINO
rsync -rav server73:/work3/chaves/SPS/C3S_${yyyy}${mm}_ENSO_34_all_models.pdf .
if [ -f C3S_${yyyy}${mm}_ENSO_34_all_models.pdf ]; then
    convert C3S_${yyyy}${mm}_ENSO_34_all_models.pdf -trim +repage c3s_mme_nino.png
else
    C3S_errors+=("FAILED: Could not retrieve C3S MME NINO from server73")
fi

# Execution summary
echo ""
echo "################################################################################"
echo "                         WEB DOWNLOAD EXECUTION SUMMARY                         "
echo "################################################################################"
if [[ ${#web_errors[@]} -eq 0 ]]; then
    echo "STATUS: SUCCESS - All web downloads completed"
else
    echo "STATUS: FAILED - Encountered ${#web_errors[@]} web download errors:"
    echo ""
    for err in "${web_errors[@]}"; do
        echo "  [!] $err"
    done
    exit 1
fi

echo ""
echo "################################################################################"
echo "                         C3S DOWNLOAD EXECUTION SUMMARY                         "
echo "################################################################################"
if [[ ${#C3S_errors[@]} -eq 0 ]]; then
    echo "STATUS: SUCCESS - All C3S downloads completed"
else
    echo "STATUS: FAILED - Encountered ${#C3S_errors[@]} C3S download errors:"
    echo ""
    for err in "${C3S_errors[@]}"; do
        echo "  [!] $err"
    done
    exit 1
fi

touch $flag_done
echo "Web download has completed"

exit 0
