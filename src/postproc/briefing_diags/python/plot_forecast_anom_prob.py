###################################################################################################
## Script:  plot_forecast_anom_prob.py                                                           ##
## Author:  Brandon J Fisel                                                                      ##
## Summary: Plots Global and Europe domain diagnostic briefing plots as one column and two rows: ##
##          top row: anomaly plot and bottom row: probability plot.                              ##
## Description: Computes anomalies, probabilities and Mann Whitney U significance from input     ##
##          data, adopted from Andrea's NCL scripts. Variables are plotted for two domains       ##
##          global and Europe), with the global domain using PlateCarree and the Europe domain   ##
##          using LambertConformal projections. The global plots are assembled from two plots:   ##
##          the first being the 30 degree expanded domain and the second being the default 360   ##
##          degree global plot. The two plots are merged together, and axis labels and plot      ##
##          bounding lines are customized for each and seamlessly placed as one plot. The Europe ##
##          plot domain is computed using a quasi-corners NCL method but otherwise the plot uses ##
##          normal LambertConformal projection and plotting techniques. However, these plots use ##
##          highly customized axis labels. Titles and legends are treated as containers to       ##
##          handle separate formatting between the container and plots.                          ##
## Creation Date: 21/08/2026                                                                     ##
## Revision Date: 24/09/2026                                                                     ##
## Revised By: BJF                                                                               ##
###################################################################################################
import argparse
import os
import sys
import datetime
import logging
from typing import Tuple, Dict, Any
import numpy as np
import xarray as xr
from scipy import stats
import matplotlib.pyplot as plt
import matplotlib.colors as mcolors
import matplotlib.patches as mpatches
import matplotlib.lines as mlines
from matplotlib.gridspec import GridSpec, GridSpecFromSubplotSpec
import cartopy.crs as ccrs
import cartopy.feature as cfeature
from cartopy.util import add_cyclic_point
from PIL import Image

# Logging configuration
logging.basicConfig(
    level=logging.INFO,
    format="[%(asctime)s] [%(levelname)s] [%(filename)s:%(lineno)d] - %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
    handlers=[
        logging.StreamHandler(sys.stdout)
    ]
)
LOG = logging.getLogger("briefing_diag_plotter")

def parse_args():
    parser = argparse.ArgumentParser(description="Briefing Diagnostic Plotter")

    # Directory Arguments
    parser.add_argument("--anom_dir", type=str, required=True, help="Directory containing anomalies")
    parser.add_argument("--clim_dir", type=str, required=True, help="Directory containing climatology")
    parser.add_argument("--plot_dir", type=str, required=True, help="Directory to save plots")

    # Case Arguments
    parser.add_argument("--yyyyfore", type=str, required=True, help="Forecast year")
    parser.add_argument("--mmfore", type=str, required=True, help="Forecast month")
    parser.add_argument("--iniy_hind", type=str, default="1995", help="Hindcast start year")
    parser.add_argument("--endy_hind", type=str, default="2024", help="Hindcast end year")
    parser.add_argument("--varm", type=str, required=True, help="Variable to plot")
    parser.add_argument("--reglist", nargs='+', type=str, required=True, help="Regions to plot")
    parser.add_argument("--flgmnth", type=int, default=0, help="Climate data to use")
    parser.add_argument("--flgmnth_fname", type=str, default="seasonal", help="Seasonal or monthly")
    parser.add_argument("--leadlist", nargs='+', type=int, default=1, help="Lead month")
    parser.add_argument("--model", type=str, default="CMCC", help="Model string")
    parser.add_argument("--climate_size", type=str, default="900", help="Model times")
    parser.add_argument("--nens", type=str, default="50", help="Ensemble size")
    parser.add_argument("--blue_color", type=str, default="#1A36E8", help="Title color")

    return parser.parse_args()

# Configuration and variable mapping
VAR_MAPPING: Dict[str, str] = {
    "t2m": "tas",
    "sst": "tso",
    "precip": "lwepr",
    "z500": "zg",
    "hgt500": "zg",
    "mslp": "psl"
}

VAR_CONFIGS: Dict[str, Dict[str, Any]] = {
    "t2m": {
        "name": "2m temperature",
        "scale": 1.0,
        "levels": [-2.0, -1.0, -0.5, -0.2, 0.2, 0.5, 1.0, 2.0],
        "labels": ["<-2.0 °C", "-2.0..-1.0", "-1.0..-0.5", "-0.5..-0.2", "-0.2..0.2", "0.2..0.5", "0.5..1.0", "1.0..2.0", ">2.0 °C"],
        "a_colors": ['#050095', '#3753F9', '#69A8FB', '#7CFDFE', '#FFFFFF', '#FEEF51', '#FDAD32', '#FD5123', '#CA212B'],
        "p_colors": ['#FFFFFF', '#050095', '#3753F9', '#69A8FB', '#7CFDFE', '#FEEF51', '#FDAD32', '#FD5123', '#CA212B'],
        "unit": "°C"
    },
    "sst": {
        "name": "SST",
        "scale": 1.0,
        "levels": [-2.0, -1.0, -0.5, -0.2, 0.2, 0.5, 1.0, 2.0],
        "labels": ["<-2.0 °C", "-2.0..-1.0", "-1.0..-0.5", "-0.5..-0.2", "-0.2..0.2", "0.2..0.5", "0.5..1.0", "1.0..2.0", ">2.0 °C"],
        "a_colors": ['#050095', '#3753F9', '#69A8FB', '#7CFDFE', '#FFFFFF', '#FEEF51', '#FDAD32', '#FD5123', '#CA212B'],
        "p_colors": ['#FFFFFF', '#050095', '#3753F9', '#69A8FB', '#7CFDFE', '#FEEF51', '#FDAD32', '#FD5123', '#CA212B'],
        "unit": "°C"
    },
    "z500": {
        "name": "Z500",
        "scale": 1.0,
        "levels": [-40, -20, -10, -5, 5, 10, 20, 40],
        "labels": ["<-40m", "-40..-20", "-20..-10", "-10..-5", "-5..5", "5..10", "10..20", "20..40", ">40m"],
        "a_colors": ['#050095', '#3753F9', '#69A8FB', '#7CFDFE', '#FFFFFF', '#FEEF51', '#FDAD32', '#FD5123', '#CA212B'],
        "p_colors": ['#FFFFFF', '#050095', '#3753F9', '#69A8FB', '#7CFDFE', '#FEEF51', '#FDAD32', '#FD5123', '#CA212B'],
        "unit": "m"
    },
    "hgt500": {
        "name": "Z500",
        "scale": 1.0,
        "levels": [-40, -20, -10, -5, 5, 10, 20, 40],
        "labels": ["<-40m", "-40..-20", "-20..-10", "-10..-5", "-5..5", "5..10", "10..20", "20..40", ">40m"],
        "a_colors": ['#050095', '#3753F9', '#69A8FB', '#7CFDFE', '#FFFFFF', '#FEEF51', '#FDAD32', '#FD5123', '#CA212B'],
        "p_colors": ['#FFFFFF', '#050095', '#3753F9', '#69A8FB', '#7CFDFE', '#FEEF51', '#FDAD32', '#FD5123', '#CA212B'],
        "unit": "m"
    },
    "precip": {
        "name": "precipitation",
        "scale": 90.0,
        "levels": [-200, -100, -50, -10, 10, 50, 100, 200],
        "labels": ["<-200mm", "-200..-100", "-100..-50", "-50..10", "-10..10", "10..50", "50..100", "100..200", ">200mm"],
        "a_colors": ['#973912', '#CA8A26', '#FECE38', '#FEEFA0', '#FFFFFF', '#CDFE75', '#33FD3A', '#11973C', '#0A6565'],
        "p_colors": ['#FFFFFF', '#973912', '#CA8A26', '#FECE38', '#FEEFA0', '#CDFE75', '#33FD3A', '#11973C', '#0A6565'],
        "unit": "mm"
    },
    "mslp": {
        "name": "MSLP",
        "scale": 1.0,
        "levels": [-4.0, -2.0, -1.0, -0.5, 0.5, 1.0, 2.0, 4.0],
        "labels": ["<-4 hPa", "-4..-2", "-2..-1", "-1..-0.5", "-0.5..0.5", "0.5..1", "1..2", "2..4", ">4 hPa"],
        "a_colors": ['#050095', '#3753F9', '#69A8FB', '#7CFDFE', '#FFFFFF', '#FEEF51', '#FDAD32', '#FD5123', '#CA212B'],
        "p_colors": ['#FFFFFF', '#050095', '#3753F9', '#69A8FB', '#7CFDFE', '#FEEF51', '#FDAD32', '#FD5123', '#CA212B'],
        "unit": "hPa"
    }
}

DIAG4PRES_VARS = ["mslp", "sst", "hgt500", "z500", "precip", "t2m"]
DIAG4PRES_REGIONS = ["global", "Europe"]

# Spatial map projections setup
# Europe Lambert Conformal projection defined via lower-left and upper-right bounding coordinates
eu_proj = ccrs.LambertConformal(central_longitude=15.0, central_latitude=38.5, standard_parallels=(30.0, 80.0))
left_lon, left_lat = -16.0, 22.75
right_lon, right_lat = 83.5, 54.25
x_left, y_bottom = eu_proj.transform_point(left_lon, left_lat, ccrs.PlateCarree())
x_right, y_top = eu_proj.transform_point(right_lon, right_lat, ccrs.PlateCarree())

REGION_CONFIGS = {
    "Europe": {
        "x_bounds": (x_left, x_right),
        "y_bounds": (y_bottom, y_top),
        "x_grid": np.arange(-30, 75, 15),
        "y_grid": [30, 45, 60],
        "x_top_labels": {-30: "30°W", 0: "0°W", 30: "30°E", 60: "60°E"},
        "x_bot_labels": {0: "0°E", 30: "30°E"},
        "left_label": "30°W",
        "right_label": "60°E",
        "proj": eu_proj
    },
    "global": {
        "flocatx_left": [150, 180],
        "flocatx_right": [-150, -120, -90, -60, -30, 0, 30, 60, 90, 120, 150, 180],
        "flocaty": [-60, -30, 0, 30, 60],
        "proj": ccrs.PlateCarree(central_longitude=0)
    }
}

SEASON_MAP = {
    "01": ["JFM", "FMA", "MAM", "AMJ"], "02": ["FMA", "MAM", "AMJ", "MJJ"],
    "03": ["MAM", "AMJ", "MJJ", "JJA"], "04": ["AMJ", "MJJ", "JJA", "JAS"],
    "05": ["MJJ", "JJA", "JAS", "ASO"], "06": ["JJA", "JAS", "ASO", "SON"],
    "07": ["JAS", "ASO", "SON", "OND"], "08": ["ASO", "SON", "OND", "NDJ"],
    "09": ["SON", "OND", "NDJ", "DJF"], "10": ["OND", "NDJ", "DJF", "JFM"],
    "11": ["NDJ", "DJF", "JFM", "FMA"], "12": ["DJF", "JFM", "FMA", "MAM"]
}

def get_season_name(mmfore: str, lead: int, flgmnth: int, yyyyfore: str) -> str:
    # Derives 3-month season labels
    if flgmnth == 0:
        return SEASON_MAP[mmfore][lead]
    month_idx = (int(mmfore) - 1 + lead) % 12 + 1
    return datetime.date(int(yyyyfore), month_idx, 1).strftime("%B")

def compute_significance(inputmall: str, inputmall_hc: str, lead: int, varm: str) -> np.ndarray:
    # Computes grid-point significance contours using a two-sided Mann-Whitney U test
    missing_files = [f for f in (inputmall, inputmall_hc) if not os.path.exists(f)]
    if missing_files:
        msg = f"Missing required input dataset(s) for significance calculation: {', '.join(missing_files)}"
        LOG.error(msg)
        raise FileNotFoundError(msg)

    LOG.info(f"Computing Mann-Whitney U significance between forecast and hindcast files...")
    with xr.open_dataset(inputmall, decode_times=False) as ds_fore, \
         xr.open_dataset(inputmall_hc, decode_times=False) as ds_hc:

        varname = VAR_MAPPING.get(varm, varm)
        f_data = ds_fore[varname]
        h_data = ds_hc[varname]

        if "level" in f_data.dims or "plev" in f_data.dims:
            f_data = f_data.isel(level=0) if "level" in f_data.dims else f_data.isel(plev=0)
            h_data = h_data.isel(level=0) if "level" in h_data.dims else h_data.isel(plev=0)

        if "time" in f_data.dims and f_data.sizes["time"] >= (lead + 3):
            f_data = f_data.isel(time=slice(lead, lead + 3)).mean(dim="time")
        elif "time" in f_data.dims:
            f_data = f_data.mean(dim="time")

        if "time" in h_data.dims and h_data.sizes["time"] >= (lead + 3):
            h_data = h_data.isel(time=slice(lead, lead + 3)).mean(dim="time")
        elif "time" in h_data.dims:
            h_data = h_data.mean(dim="time")

        f_vals = f_data.values
        h_vals = h_data.values

        # Flatten non-spatial dimensions into a 1D vector per spatial grid cell
        nlat, nlon = f_data.sizes["lat"], f_data.sizes["lon"]
        f_vals = f_vals.reshape(-1, nlat, nlon)
        h_vals = h_vals.reshape(-1, nlat, nlon)

        # Mask invalid fill values
        f_vals = np.where((f_vals >= 1e19) | np.isnan(f_vals), np.nan, f_vals)
        h_vals = np.where((h_vals >= 1e19) | np.isnan(h_vals), np.nan, h_vals)

        # Compute the Mann-Whitney U test across 0th axis (ensemble/time dimension)
        res = stats.mannwhitneyu(f_vals, h_vals, alternative="two-sided", method="asymptotic", axis=0)
        pval = np.where(np.isnan(res.pvalue), 1.0, res.pvalue)

        return pval

def compute_probs(inputmall: str, problowfile: str, probupfile: str, lead: int, varm: str) -> np.ndarray:
    # Computes 8-category tercile probability distributions (Lower tercile 1-4, Upper tercile 5-8).
    missing_files = [f for f in (problowfile, probupfile) if not os.path.exists(f)]
    if missing_files:
        msg = f"Missing required input dataset(s) for probability calculation: {', '.join(missing_files)}"
        LOG.error(msg)
        raise FileNotFoundError(msg)

    LOG.info("Calculating category tercile probabilities...")
    with xr.open_dataset(inputmall, decode_times=False) as ds_all, \
         xr.open_dataset(problowfile, decode_times=False) as ds_low, \
         xr.open_dataset(probupfile, decode_times=False) as ds_up:

        varname = VAR_MAPPING.get(varm, varm)
        data = ds_all[varname]

        if "level" in data.dims or "plev" in data.dims:
            data = data.isel(level=0) if "level" in data.dims else data.isel(plev=0)

        if "time" in data.dims and data.sizes["time"] >= (lead + 3):
            sst = data.isel(time=slice(lead, lead + 3)).mean(dim="time")
        elif "time" in data.dims:
            sst = data.mean(dim="time")
        else:
            sst = data

        low_vals = ds_low["low33"].squeeze().values
        up_vals = ds_up["up66"].squeeze().values
        sst_vals = sst.values

        if varm.upper() in ["prec", "precip"]:
            if np.nanmax(low_vals) < 1.0:
                low_vals *= 86400.0
                up_vals *= 86400.0
            if np.nanmax(sst_vals) < 1.0:
                sst_vals *= 86400.0
        elif varm.lower() == "mslp":
            if np.nanmax(low_vals) > 10000:
                low_vals /= 100.0
                up_vals /= 100.0
                sst_vals /= 100.0

        sst_vals = np.where(sst_vals >= 1e19, np.nan, sst_vals)
        low_vals = np.where(low_vals >= 1e19, np.nan, low_vals)
        up_vals = np.where(up_vals >= 1e19, np.nan, up_vals)

        tsl = np.where(sst_vals < low_vals, 1.0, 0.0)
        tsu = np.where(sst_vals > up_vals, 1.0, 0.0)

        tsll = np.nanmean(tsl, axis=0) if tsl.ndim == 3 else tsl
        tsuu = np.nanmean(tsu, axis=0) if tsu.ndim == 3 else tsu

        prob_category = np.zeros_like(tsll, dtype=int)
        eps = 1e-4

        below_dom = (tsll >= 0.40 - eps) & (tsll >= tsuu)
        above_dom = (tsuu >= 0.40 - eps) & (tsuu > tsll)

        # Categorize dominant signals into 10% bins
        prob_category = np.where(below_dom & (tsll >= 0.70 - eps), 1, prob_category)
        prob_category = np.where(below_dom & (tsll >= 0.60 - eps) & (tsll < 0.70 - eps), 2, prob_category)
        prob_category = np.where(below_dom & (tsll >= 0.50 - eps) & (tsll < 0.60 - eps), 3, prob_category)
        prob_category = np.where(below_dom & (tsll >= 0.40 - eps) & (tsll < 0.50 - eps), 4, prob_category)

        prob_category = np.where(above_dom & (tsuu >= 0.40 - eps) & (tsuu < 0.50 - eps), 5, prob_category)
        prob_category = np.where(above_dom & (tsuu >= 0.50 - eps) & (tsuu < 0.60 - eps), 6, prob_category)
        prob_category = np.where(above_dom & (tsuu >= 0.60 - eps) & (tsuu < 0.70 - eps), 7, prob_category)
        prob_category = np.where(above_dom & (tsuu >= 0.70 - eps), 8, prob_category)

        return prob_category

def compute_anomaly(inputm: str, pval: np.ndarray, lead: int, varm: str) -> Tuple[np.ndarray, np.ndarray, np.ndarray]:
    # Computes spatial ensemble mean anomaly
    if not os.path.exists(inputm):
        LOG.error(f"Missing required anomaly dataset: {inputm}. Cannot calculate anomaly for {varm}.")
        raise FileNotFoundError(f"Anomaly file not found: {inputm}")

    LOG.info("Processing ensemble mean anomaly...")
    with xr.open_dataset(inputm, decode_times=False) as ds_m:
        varname = VAR_MAPPING.get(varm, varm)
        data = ds_m[varname]

        if "level" in data.dims or "plev" in data.dims:
            data = data.isel(level=0) if "level" in data.dims else data.isel(plev=0)

        if "time" in data.dims and data.sizes["time"] >= (lead + 3):
            anom = data.isel(time=slice(lead, lead + 3)).mean(dim="time")
        else:
            anom = data.mean(dim="time") if "time" in data.dims else data

        scale_factor = VAR_CONFIGS.get(varm, {}).get("scale", 1.0)
        anom_vals = np.squeeze(anom.values) * scale_factor

        # Mask non-significant anomalies for specific variables
        if varm in ["t2m", "precip"]:
            anom_vals = np.where(pval < 0.10, anom_vals, np.nan)

        return anom_vals, ds_m["lat"].values, ds_m["lon"].values

def format_lon_label(val: float) -> str:
    # Build custom global longitude axis labels
    val_mod = np.mod(val, 360.0)
    if val_mod in (0, 360):
        return "0°E"
    elif val_mod == 180:
        return "180°E" if val <= 180 else "180°W"
    elif val_mod < 180:
        return f"{int(val_mod)}°E"
    else:
        return f"{int(360 - val_mod)}°W"

def format_lat_label(val: float) -> str:
    # Build custom global latitude axis labels
    if val == 0:
        return "0°"
    return f"{int(val)}°N" if val > 0 else f"{int(abs(val))}°S"

def overlay_logo(img_path: str, logo_filename: str = "cmcc_logo_bw.jpg", placements: list = None) -> None:
    if placements is None:
        placements = [{"position": "lower_left"}]

    # Overlays logo image onto final plot
    script_dir = os.path.dirname(os.path.abspath(__file__))
    logo_path = logo_filename if os.path.exists(logo_filename) else os.path.join(script_dir, logo_filename)

    if os.path.exists(logo_path) and os.path.exists(img_path):
        LOG.info(f"Applying logo to {img_path}")
        base_img = Image.open(img_path).convert("RGBA")
        logo = Image.open(logo_path).convert("RGBA")

        r, g, b, a = logo.split()
        mask = Image.eval(r, lambda p: 0 if p > 240 else 255)
        mask = Image.eval(g, lambda p: 0 if p > 240 else 255).convert("1")
        logo.putalpha(mask)

        logo_width = 140
        wpercent = logo_width / float(logo.size[0])
        logo_height = int((float(logo.size[1]) * float(wpercent)))
        logo = logo.resize((logo_width, logo_height), Image.Resampling.LANCZOS)

        for cfg in placements:
            pos = cfg.get("position", "lower_left")
            target_y_px = cfg.get("target_y_px", None)

            if pos == "top_plot_lower_left" and target_y_px is not None:
                # Top plot logo
                y_loc = target_y_px + 5
                y_loc = max(10, min(y_loc, base_img.height - logo_height - 10))
                loc = (10, int(y_loc))
            elif pos == "lower_left":
                # Bottom plot logo
                loc = (10, base_img.height - logo_height - 10)
            else:
                loc = (base_img.width - logo_width - 10, base_img.height - logo_height - 10)

            base_img.paste(logo, loc, logo)

        if img_path.lower().endswith(('.jpg', '.jpeg')):
            base_img.convert("RGB").save(img_path, quality=90)
        else:
            base_img.save(img_path)
    else:
        LOG.warning(f"Logo image not found at {logo_path}. Skipping logo placement.")
        return

def build_legend_container(fig: plt.Figure, bbox_bounds: list) -> plt.Axes:
    # Builds a non-axis bounding box container for holding legend patches and custom text headers
    container = fig.add_axes(bbox_bounds)
    container.axis('off')
    container.set_xlim(0, 1)
    container.set_ylim(0, 1)
    return container

def setup_subaxes_styling(ax_left: plt.Axes, ax_right: plt.Axes, lakes: cfeature.Feature, RES: str, varm: str) -> None:
    # Create custom cartographic framing lines across global split-panel maps for seamless visual joining
    # along the 180 meridian between sub-axes
    for ax in (ax_left, ax_right):
        if varm == "sst":
            ax.add_feature(cfeature.LAND.with_scale(RES), linewidth=0.0, facecolor='#FFDDAA', edgecolor='None')
        ax.add_feature(lakes, linewidth=0.8, facecolor="none", edgecolor='black')
        ax.add_feature(cfeature.COASTLINE.with_scale(RES), linewidth=1.1, edgecolor='black')
        ax.add_feature(cfeature.BORDERS.with_scale(RES), linewidth=0.7, edgecolor='gray')
        if hasattr(ax, 'outline_patch'):
            ax.outline_patch.set_visible(False)
        for spine in ax.spines.values():
            spine.set_visible(False)

        # Top and bottom lines
        ax.add_line(mlines.Line2D([ax.get_xlim()[0], ax.get_xlim()[1]], [90, 90], transform=ccrs.PlateCarree(), color='black', linewidth=2.4, zorder=10))
        ax.add_line(mlines.Line2D([ax.get_xlim()[0], ax.get_xlim()[1]], [-90, -90], transform=ccrs.PlateCarree(), color='black', linewidth=2.4, zorder=10))

    # Outer left and right lines
    ax_left.add_line(mlines.Line2D([150, 150], [-90, 90], transform=ccrs.PlateCarree(), color='black', linewidth=2.4, zorder=10))
    ax_right.add_line(mlines.Line2D([180, 180], [-90, 90], transform=ccrs.PlateCarree(), color='black', linewidth=2.4, zorder=10))

def annotate_global_axis_labels(ax_left: plt.Axes, ax_right: plt.Axes, flocatx_left: list, flocatx_right: list, flocaty: list) -> None:
    # Create longitude/latitude text labels on global split sub-panels
    # Top and bottom lon labels for the left sub-plot (30-degree expansion)
    for x in flocatx_left:
        lbl = format_lon_label(x)
        ax_left.text(x, 92.5, lbl, transform=ccrs.PlateCarree(), ha='center', va='bottom', fontsize=5, fontweight='bold', clip_on=False)
        ax_left.text(x, -92.5, lbl, transform=ccrs.PlateCarree(), ha='center', va='top', fontsize=5, fontweight='bold', clip_on=False)

    # Top and bottom lon labels for the right sub-plot (global)
    for x in flocatx_right:
        lbl = format_lon_label(x)
        ax_right.text(x, 92.5, lbl, transform=ccrs.PlateCarree(), ha='center', va='bottom', fontsize=5, fontweight='bold')
        ax_right.text(x, -92.5, lbl, transform=ccrs.PlateCarree(), ha='center', va='top', fontsize=5, fontweight='bold')

    # Leftmost lat labels
    for y in flocaty:
        lbl = format_lat_label(y)
        ax_left.text(148.5, y, lbl, transform=ccrs.PlateCarree(), ha='right', va='center', fontsize=5, fontweight='bold', clip_on=False)

    # Rightmost lat labels
    y1, y2 = ax_right.get_ylim()
    for y in flocaty:
        lbl = format_lat_label(y)
        y_axes = (y - y1) / (y2 - y1)
        ax_right.text(1.01, y_axes, lbl, transform=ax_right.transAxes, ha='left', va='center', fontsize=5, fontweight='bold', clip_on=False)

def main():
    LOG.info("Initializing plotting briefing diagnostics...")

    # Retrieve parameters passed from shell
    args = parse_args()

    anomdir = args.anom_dir
    clim_dir = args.clim_dir
    dirplots = args.plot_dir
    yyyyfore = args.yyyyfore
    mmfore = args.mmfore
    iniy_hind = args.iniy_hind
    endy_hind = args.endy_hind
    varm = args.varm
    reglist = args.reglist
    flgmnth = args.flgmnth
    flgmnth_fname = args.flgmnth_fname
    leadlist = args.leadlist
    model = args.model
    climate_size = args.climate_size
    nens = args.nens
    blue_color = args.blue_color

    # Custom parameters
    refperiod = f"{iniy_hind}-{endy_hind}"
    RES = "110m" # Cartopy feature resolution

    vconfig = VAR_CONFIGS.get(varm, VAR_CONFIGS["z500"])

    for l in leadlist:
        lead = l - 1
        ss = get_season_name(mmfore, lead, flgmnth, yyyyfore)
        LOG.info(f"Processing lead {l} ({ss} {yyyyfore}) for variable: {varm}")

        probupfile = f"{clim_dir}/pctl/{'monthly/' if flgmnth==1 else ''}{mmfore}/{varm}_{mmfore}_l{lead}_66.{refperiod}.nc"
        problowfile = f"{clim_dir}/pctl/{'monthly/' if flgmnth==1 else ''}{mmfore}/{varm}_{mmfore}_l{lead}_33.{refperiod}.nc"
        inputm = f"{anomdir}/{varm}_sps4_{yyyyfore}{mmfore}_ens_ano.{refperiod}.nc"
        inputmall = f"{anomdir}/{varm}_sps4_{yyyyfore}{mmfore}_all_ano.{refperiod}.nc"
        inputmall_hc = f"{clim_dir}/monthly/{varm}/C3S/anom/{varm}_sps4_{mmfore}_all_ano.{refperiod}.nc"

        try:
            pval = compute_significance(inputmall, inputmall_hc, lead, varm)
            anom_data, lats, lons = compute_anomaly(inputm, pval, lead, varm)
            prob_data = compute_probs(inputmall, problowfile, probupfile, lead, varm)
        except Exception as e:
            LOG.error(f"Skipping variable '{varm}' at lead {l} due to missing input or processing error: {e}", exc_info=True)
            continue

        for region in reglist:
            LOG.info(f"Generating figure for region: {region}")
            rconfig = REGION_CONFIGS.get(region, REGION_CONFIGS["global"])
            varfile = "hgt500" if varm == "z500" else varm

            lakes = cfeature.NaturalEarthFeature(category="physical", name="lakes", scale=RES)

            anom_plot, lons_plot = add_cyclic_point(anom_data, coord=lons)
            pval_plot, _ = add_cyclic_point(pval, coord=lons)
            prob_plot, _ = add_cyclic_point(prob_data, coord=lons)
            transform_crs = ccrs.PlateCarree()

            if varm in DIAG4PRES_VARS and region in DIAG4PRES_REGIONS:
                fig_width, fig_height = 6.5167, 8.8533
                fig = plt.figure(figsize=(fig_width, fig_height))
                plt.rcParams['font.family'] = 'sans-serif'
                plt.rcParams['font.sans-serif'] = ['Arial', 'Helvetica', 'DejaVu Sans']

                if region == "global":
                    gs_outer = GridSpec(2, 1, figure=fig, hspace=0.56, top=0.88, bottom=0.04, left=0.08, right=0.92)

                    gs_top = GridSpecFromSubplotSpec(1, 2, subplot_spec=gs_outer[0, 0], width_ratios=[30, 360], wspace=0.0)
                    ax1_left = fig.add_subplot(gs_top[0, 0], projection=rconfig["proj"])
                    ax1_right = fig.add_subplot(gs_top[0, 1], projection=rconfig["proj"])

                    gs_bot = GridSpecFromSubplotSpec(1, 2, subplot_spec=gs_outer[1, 0], width_ratios=[30, 360], wspace=0.0)
                    ax2_left = fig.add_subplot(gs_bot[0, 0], projection=rconfig["proj"])
                    ax2_right = fig.add_subplot(gs_bot[0, 1], projection=rconfig["proj"])

                    ax1_left.set_extent([150, 180, -90, 90], crs=transform_crs)
                    ax1_right.set_extent([-180, 180, -90, 90], crs=transform_crs)
                    ax2_left.set_extent([150, 180, -90, 90], crs=transform_crs)
                    ax2_right.set_extent([-180, 180, -90, 90], crs=transform_crs)

                    setup_subaxes_styling(ax1_left, ax1_right, lakes, RES, varm)
                    setup_subaxes_styling(ax2_left, ax2_right, lakes, RES, varm)

                    annotate_global_axis_labels(ax1_left, ax1_right, rconfig["flocatx_left"], rconfig["flocatx_right"], rconfig["flocaty"])
                    annotate_global_axis_labels(ax2_left, ax2_right, rconfig["flocatx_left"], rconfig["flocatx_right"], rconfig["flocaty"])
                else:
                    gs = GridSpec(2, 1, figure=fig, hspace=0.46, top=0.88, bottom=0.04, left=0.08, right=0.92)
                    ax1_right = fig.add_subplot(gs[0, 0], projection=rconfig["proj"])
                    ax2_right = fig.add_subplot(gs[1, 0], projection=rconfig["proj"])
                    ax1_left, ax2_left = None, None

                    for ax in (ax1_right, ax2_right):
                        ax.set_aspect('auto')
                        ax.set_xlim(rconfig["x_bounds"])
                        ax.set_ylim(rconfig["y_bounds"])
                        if varm == "sst":
                            ax.add_feature(cfeature.LAND.with_scale(RES), linewidth=0.0, facecolor='#FFDDAA', edgecolor='None')
                        ax.add_feature(lakes, linewidth=0.8, facecolor="none", edgecolor='black')
                        ax.add_feature(cfeature.COASTLINE.with_scale(RES), linewidth=1.1, edgecolor='black')
                        ax.add_feature(cfeature.BORDERS.with_scale(RES), linewidth=0.7, edgecolor='gray')
                        for spine in ax.spines.values():
                            spine.set_visible(True)
                            spine.set_linestyle('-')
                            spine.set_linewidth(1.2)
                            spine.set_edgecolor('black')

                        gl = ax.gridlines(draw_labels=False, crs=ccrs.PlateCarree(), color='gray', linestyle=(0, (1, 3)), linewidth=0.8)
                        gl.xlines, gl.ylines = True, True
                        gl.xlocator = plt.FixedLocator(rconfig["x_grid"])
                        gl.ylocator = plt.FixedLocator(rconfig["y_grid"])

                        # Plot framing line offsets
                        x0, x1 = rconfig["x_bounds"]
                        y0, y1 = rconfig["y_bounds"]
                        y_offset = (y1 - y0) * 0.020
                        x_offset = (x1 - x0) * 0.020

                        # For top axis label positioning, approximate the top framing line latitude
                        lat_top = ax.get_extent(crs=ccrs.PlateCarree())[3]
                        for lon_val, label in rconfig["x_top_labels"].items():
                            x_p, _ = eu_proj.transform_point(lon_val, lat_top - 2.0, ccrs.PlateCarree()) # subtract by 2.0 for nicer outer label placement
                            if x0 <= x_p <= x1:
                                ax.text(x_p, y1 + y_offset, label, transform=ax.transData, ha='center', va='bottom', fontsize=5, fontweight='bold', clip_on=False)

                        # For bottom axis label positioning
                        for lon_val, label in rconfig["x_bot_labels"].items():
                            x_p, _ = eu_proj.transform_point(lon_val, 30.0, ccrs.PlateCarree())
                            if x0 <= x_p <= x1:
                                ax.text(x_p, y0 - y_offset, label, transform=ax.transData, ha='center', va='top', fontsize=5, fontweight='bold', clip_on=False)

                        # Left and right label positioning, approximate using a midpoint
                        y_mid = (y0 + y1) / 2.0
                        ax.text(x0 - x_offset, y_mid, rconfig["left_label"], transform=ax.transData, ha='right', va='center', fontsize=5, fontweight='bold', clip_on=False)
                        ax.text(x1 + x_offset, y_mid, rconfig["right_label"], transform=ax.transData, ha='left', va='center', fontsize=5, fontweight='bold', clip_on=False)

                # Top plot: Ensemble mean anomaly
                anom_colors = vconfig["a_colors"]
                anom_cmap = mcolors.ListedColormap(anom_colors)
                anom_norm = mcolors.BoundaryNorm([-999] + vconfig["levels"] + [999], anom_cmap.N)

                if region == "global":
                    # The 30-degree expansion
                    ax1_left.contourf(lons_plot, lats, anom_plot, levels=100, transform=transform_crs, cmap=anom_cmap, norm=anom_norm)
                    if varm != "sst":
                        # Draw the significance line as a fill
                        cs_left = ax1_left.contourf(lons_plot, lats, pval_plot, levels=[0.0099, 0.01], colors=['#228B22'], transform=transform_crs)
                        cs_left.set_facecolor('none')
                        cs_left.set_edgecolor('#228B22')
                        cs_left.set_linewidth(0.6)

                # The default domain
                ax1_right.contourf(lons_plot, lats, anom_plot, levels=100, transform=transform_crs, cmap=anom_cmap, norm=anom_norm)

                if varm != "sst":
                    # Draw the significance line as a fill
                    cs_right = ax1_right.contourf(lons_plot, lats, pval_plot, levels=[0.0099, 0.01], colors=['#228B22'], transform=transform_crs)
                    cs_right.set_facecolor('none')
                    cs_right.set_edgecolor('#228B22')
                    cs_right.set_linewidth(0.6)

                # Legend / Title (Top Panel)
                if region == "global":
                    # Both left and right global sub-plots
                    pos_l, pos_r = ax1_left.get_position(), ax1_right.get_position()
                    top_bbox = [pos_l.x0, pos_l.y1 + 0.02, pos_r.x1 - pos_l.x0, 0.08]
                else:
                    pos1 = ax1_right.get_position()
                    top_bbox = [pos1.x0, pos1.y1 + 0.02, pos1.width, 0.08]

                top_container = build_legend_container(fig, top_bbox)
                top_container.text(0.0, 0.98, f"C3S: {model} contribution", color=blue_color, fontsize=10, fontweight=500)
                top_container.text(0.0, 0.75, f"Mean {vconfig['name']} anomaly", color=blue_color, fontsize=10, fontweight=500)
                top_container.text(0.0, 0.54, f"Nominal forecast start: 01/{mmfore}/{yyyyfore[-2:]}", color=blue_color, fontsize=7)
                top_container.text(0.0, 0.38, f"Ensemble size = {nens}, hindcast climate size = {climate_size}", color=blue_color, fontsize=7)

                top_container.text(1.0, 0.98, f"{ss} {yyyyfore}", color=blue_color, fontsize=10, fontweight=500, ha='right')
                top_container.text(1.0, 0.75, f"Reference period: {iniy_hind}-{endy_hind}", color=blue_color, fontsize=10, fontweight=500, ha='right')
                top_container.text(1.0, 0.54, "Solid contour at 1% significance level", color=blue_color, fontsize=7, ha='right')

                num_anom = len(anom_colors)
                dx_a = 0.88 / num_anom
                sq_h = 0.18
                sq_w_top = sq_h * (top_bbox[3] * fig_height) / (top_bbox[2] * fig_width)
                start_x_a = (1.0 - ((num_anom - 1) * dx_a + sq_w_top)) / 2.0

                for i, (col, lbl) in enumerate(zip(anom_colors, vconfig["labels"])):
                    x_pos = start_x_a + i * dx_a
                    rect = mpatches.Rectangle((x_pos, 0.01), sq_w_top, sq_h, facecolor=col, edgecolor='black', linewidth=0.5)
                    top_container.add_patch(rect)
                    top_container.text(x_pos + sq_w_top + 0.005, 0.01 + (sq_h/2), lbl, fontsize=5, fontweight=500, va='center')

                # Bottom plot: Probability summary
                prob_colors = vconfig["p_colors"]
                prob_cmap = mcolors.ListedColormap(prob_colors)
                prob_norm = mcolors.BoundaryNorm(np.arange(-0.5, 9.5, 1), prob_cmap.N)

                if region == "global":
                    # The 30-degree expansion
                    ax2_left.pcolormesh(lons_plot, lats, prob_plot, transform=transform_crs, cmap=prob_cmap, norm=prob_norm, edgecolor='none', shading='nearest', antialiased=True)
                    if varm == "sst":
                        ax2_left.add_feature(cfeature.LAND.with_scale(RES), facecolor='#FFDDAA', zorder=2)
                        ax2_left.add_feature(lakes, linewidth=0.8, facecolor="none", edgecolor='black', zorder=3)
                        ax2_left.add_feature(cfeature.COASTLINE.with_scale(RES), linewidth=1.1, edgecolor='black', zorder=4)
                        ax2_left.add_feature(cfeature.BORDERS.with_scale(RES), linewidth=0.7, edgecolor='gray', zorder=5)

                # The default domain
                ax2_right.pcolormesh(lons_plot, lats, prob_plot, transform=transform_crs, cmap=prob_cmap, norm=prob_norm, edgecolor='none', shading='nearest', antialiased=True)
                if varm == "sst":
                    ax2_right.add_feature(cfeature.LAND.with_scale(RES), facecolor='#FFDDAA', zorder=2)
                    ax2_right.add_feature(lakes, linewidth=0.8, facecolor="none", edgecolor='black', zorder=3)
                    ax2_right.add_feature(cfeature.COASTLINE.with_scale(RES), linewidth=1.1, edgecolor='black', zorder=4)
                    ax2_right.add_feature(cfeature.BORDERS.with_scale(RES), linewidth=0.7, edgecolor='gray', zorder=5)

                # Legend / Title (Bottom Panel)
                if region == "global":
                    pos_bl, pos_br = ax2_left.get_position(), ax2_right.get_position()
                    bot_bbox = [pos_bl.x0, pos_bl.y1 + 0.025, pos_br.x1 - pos_bl.x0, 0.08]
                else:
                    pos2 = ax2_right.get_position()
                    bot_bbox = [pos2.x0, pos2.y1 + 0.025, pos2.width, 0.08]

                sq_w_bot = sq_h * (bot_bbox[3] * fig_height) / (bot_bbox[2] * fig_width)

                bot_container = build_legend_container(fig, bot_bbox)
                bot_container.text(0.0, 0.98, f"C3S: {model} contribution", color=blue_color, fontsize=10, fontweight=500)
                bot_container.text(0.0, 0.75, f"Prob(most likely category of {vconfig['name']})", color=blue_color, fontsize=10, fontweight=500)
                bot_container.text(0.0, 0.54, f"Nominal forecast start: 01/{mmfore}/{yyyyfore[-2:]}", color=blue_color, fontsize=7)
                bot_container.text(0.0, 0.38, f"Ensemble size = {nens}, hindcast climate size = {climate_size}", color=blue_color, fontsize=7)
                bot_container.text(1.0, 0.98, f"{ss} {yyyyfore}", color=blue_color, fontsize=10, fontweight=500, ha='right')

                bot_container.text(start_x_a + 2.4 * dx_a + (sq_w_bot/2), 0.25, "<--- below lower tercile", fontsize=5, ha='center')
                bot_container.text(start_x_a + 5.6 * dx_a + (sq_w_bot/2), 0.25, "above upper tercile --->", fontsize=5, ha='center')

                # This legend will be composed of three pieces (left: below, mid: other and right: upper)
                below_colors = prob_colors[1:5]
                below_labels = ["70..100%", "60..70%", "50..60%", "40..50%"]

                for i, (col, lbl) in enumerate(zip(below_colors, below_labels)):
                    x_pos = start_x_a + i * dx_a
                    rect = mpatches.Rectangle((x_pos, 0.02), sq_w_bot, sq_h, facecolor=col, edgecolor='black', linewidth=0.5)
                    bot_container.add_patch(rect)
                    bot_container.text(x_pos + sq_w_bot + 0.005, 0.02 + (sq_h/2), lbl, fontsize=5, fontweight=500, va='center')

                x_pos_other = start_x_a + 4 * dx_a
                rect_other = mpatches.Rectangle((x_pos_other, 0.02), sq_w_bot, sq_h, facecolor='#FFFFFF', edgecolor='black', linewidth=0.5)
                bot_container.add_patch(rect_other)
                bot_container.text(x_pos_other + sq_w_bot + 0.005, 0.02 + (sq_h/2), "other", fontsize=5, va='center')

                above_colors = prob_colors[5:9]
                above_labels = ["40..50%", "50..60%", "60..70%", "70..100%"]

                for i, (col, lbl) in enumerate(zip(above_colors, above_labels)):
                    x_pos = start_x_a + (5 + i) * dx_a
                    rect = mpatches.Rectangle((x_pos, 0.02), sq_w_bot, sq_h, facecolor=col, edgecolor='black', linewidth=0.5)
                    bot_container.add_patch(rect)
                    bot_container.text(x_pos + sq_w_bot + 0.005, 0.02 + (sq_h/2), lbl, fontsize=5, fontweight=500, va='center')

                fig.canvas.draw()

                # Calculate top plot bottom-left corner for logo
                top_plot_ax = ax1_left if region == "global" else ax1_right
                pos_top = top_plot_ax.get_position()
                total_height_px = int(fig_height * 300)
                top_plot_bottom_px = int((1.0 - pos_top.y0) * total_height_px)

                # Save figure
                diag4pres_path = f"{dirplots}/cmcc_{varfile}_fore_{region}.png"
                fig.subplots_adjust(top=0.98, bottom=0.08, left=0.08, right=0.92)
                plt.savefig(diag4pres_path, dpi=300, bbox_inches=None)
                plt.close(fig)
                
                LOG.info(f"Figure successfully created: {diag4pres_path}")
                overlay_logo(diag4pres_path, placements=[{"position": "top_plot_lower_left", "target_y_px": top_plot_bottom_px}, {"position": "lower_left"}])

if __name__ == "__main__":
    main()
