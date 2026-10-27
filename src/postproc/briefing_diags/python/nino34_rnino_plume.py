###################################################################################################
## Script:  nino34_rnino_plume.py                                                                ##
## Author:  Andrea Borrelli and Brandon J Fisel                                                  ##
## Summary: Plots Nino3.4 and Relative Nino3.4 overlay plots.                                    ##
## Description: Adopted from ENSO_plot.ncl and RONI_plot.ncl, this script uses the downloaded    ##
##          Nino3.4 indices and Relative Nino3.4 anomalies and plots them as overlayed plume     ##
##          timeseries.                                                                          ##
## Creation Date: ??/??/202?                                                                     ##
## Revision Date: 22/10/2026                                                                     ##
## Revised By: BJF                                                                               ##
###################################################################################################
import argparse
import os
import sys
import datetime
import logging
import calendar
import numpy as np
import xarray as xr
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from typing import Any, Dict
from matplotlib.lines import Line2D
from matplotlib.ticker import MultipleLocator
from PIL import Image
from matplotlib.image import BboxImage
from matplotlib.transforms import Bbox, TransformedBbox

# Logging configuration
logging.basicConfig(
    level=logging.INFO,
    format="[%(asctime)s] [%(levelname)s] [%(filename)s:%(lineno)d] - %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
    handlers=[
        logging.StreamHandler(sys.stdout)
    ]
)
LOG = logging.getLogger("calc_nino34_plotter")

# Configuration
# NT=15 (7 observed months, 6 forecast months, and 2 empty)
NT = 15
IOBS = slice(0, 7)
IFC = slice(7, 13)
X = np.arange(NT) + 0.5

VAR_CONFIGS: Dict[str, Dict[str, Any]] = {
    "nino": {
        "lat1": -5.0,
        "lat2": 5.0,
        "lon1": 190.0,
        "lon2": 240.0,
        "obs": "black",
        "mem": "red",
        "em": "limegreen",
        "obs_lab": "NCEP Nino3.4"
    },
    "rnino": {
        "lat1": -20.0,
        "lat2": 20.0,
        "lon1": 0.0,
        "lon2": 360.0,
        "obs": "dimgray",
        "mem": "blue",
        "em": "orange",
        "obs_lab": "NOAA Relative Nino3.4"
    }
}

def read_forecast(fname):
    # Read var(ens, 6, lat, lon) : NaN = missing
    LOG.info("Reading forecast variable tso")
    with xr.open_dataset(fname, decode_times=False) as ds:
        tso = ds["tso"].isel({ds["tso"].dims[1]: slice(0, 6)}).values.astype("f8")
        lat = ds["lat"].values.astype("f8")
        lon = ds["lon"].values.astype("f8")
    tso[np.abs(tso) >= 1.e19] = np.nan
    return tso, lat, lon

def read_roni_factor(fname):
    # Read factor file
    LOG.info("Reading factor file")
    with xr.open_dataset(fname, decode_times=False) as ds:
        return np.asarray(ds["roni_factor"].values, dtype="f8").ravel()[:6]

def read_ascii_last7(fname, field):
    # Read text indices (field, 1-based)
    # last 7 values of the column
    LOG.info("Reading text indices")
    vals = []
    with open(fname) as f:
        for line in f:
            p = line.split()
            if len(p) < field:
                continue
            try:
                vals.append(float(p[field - 1]))
            except ValueError as e:
                LOG.error(f"ValueError: An error occurred in read_ascii_last7 when reading {fname}: {e}", exc_info=True)
                continue
    return np.array(vals[-7:], dtype="f8")

def box_mean(ts, lat, lon, la1, la2, lo1, lo2):
    # Weighted average cos(lat) as wgt_areaave(...,clat,1,0) : ts(..., lat, lon)
    jl = (lat >= min(la1, la2)) & (lat <= max(la1, la2))
    il = (lon >= min(lo1, lo2)) & (lon <= max(lo1, lo2))
    sub = ts[..., jl, :][..., il]
    w_2d = np.broadcast_to(np.cos(np.deg2rad(lat[jl]))[:, None], (len(lat[jl]), len(lon[il])))
    w = np.broadcast_to(w_2d, sub.shape).copy()
    w[np.isnan(sub)] = 0.0
    with np.errstate(invalid="ignore"):
        return np.nansum(sub * w, axis=(-2, -1)) / w.sum(axis=(-2, -1))

def build_series(fc6, obs7):
    # Create the timeseries, NaN where missing
    nens = fc6.shape[0]
    mem = np.full((nens, NT), np.nan)
    mem[:, IFC] = fc6
    em = np.full(NT, np.nan)
    em[IFC] = np.nanmean(fc6, axis=0)
    obs = np.full(NT, np.nan)
    obs[IOBS] = obs7
    # Allocation for observed, first month ens mean
    rac = np.full(NT, np.nan)
    rac[6], rac[7] = obs[6], em[7]
    return dict(mem=mem, em=em, obs=obs, rac=rac)

def month_labels(year, month):
    labs = []
    for i in range(NT):
        m = month - 1 + i
        y, m = year + m // 12, m % 12 + 1
        labs.append(f"{calendar.month_abbr[m]}\n{y}")
    labs = [("" if i % 2 == 0 else l) for i, l in enumerate(labs)]
    return labs

def plot_series(ax, s, style, alpha=0.6):
    ax.plot(X, s["mem"].T, color=style["mem"], ls="--", lw=1, marker="o", ms=2,
            alpha=alpha, zorder=2)
    ax.plot(X, s["obs"], color=style["obs"], lw=2.5, zorder=4)
    ax.plot(X, s["rac"], color="grey", lw=1.5, zorder=3)
    ax.plot(X, s["em"], color=style["em"], lw=3, marker="o", ms=5, zorder=5)

def add_logo(fig, logo):
    # Open the CMCC logo
    logo_path = (logo)
    logo_img = Image.open(logo_path).convert("RGBA")

    # Original aspect ratio of the logo
    logo_aspect = logo_img.width / logo_img.height

    # Original logo dimensions
    fig_w = fig.get_figwidth()
    fig_h = fig.get_figheight()

    # Set the desired logo width
    logo_width = 0.08
    
    # Logo height as a proportion of the dimensions and aspect ratio
    logo_height = logo_width * fig_w / fig_h / logo_aspect

    # Logo margins
    margin_x = 0.02
    margin_y = 0.02

    # Set the logo bounding box (x0, y0, width, height)
    logo_bbox = Bbox.from_bounds(
        1.0 - margin_x - logo_width,
        margin_y,
        logo_width,
        logo_height
    )

    logo_artist = BboxImage(
        TransformedBbox(logo_bbox, fig.transFigure),
        interpolation="lanczos",
        zorder=10
    )
    logo_artist.set_data(logo_img)
    fig.add_artist(logo_artist)

def make_plot(nino, roni, labels, title, sps, outfile, logo):
    fig, ax = plt.subplots(figsize=(10, 6))

    plot_series(ax, nino, VAR_CONFIGS["nino"])
    plot_series(ax, roni, VAR_CONFIGS["rnino"])
    ax.axhline(0.0, color="black", lw=1, zorder=1)

    # Dynamic Y axis: min/max on both indices (members, averages, observed)
    allv = np.concatenate([np.ravel(v) for d in (nino, roni) for v in d.values()])
    ymin = np.floor(np.nanmin(allv) - 1)
    ymax = np.ceil(np.nanmax(allv) + 1)
    ax.set_ylim(ymin, ymax)
    ax.set_yticks(np.arange(ymin, ymax + 0.5, 1.0))
    ax.set_yticklabels([f"{v:3.1f}" for v in ax.get_yticks()])
    # tmYLMinorPerMajor = 4
    ax.yaxis.set_minor_locator(MultipleLocator(0.2))
    ax.set_ylabel("°C", fontsize=16)

    ax.set_xlim(X[0], X[-1])
    ax.set_xticks(X)
    ax.set_xticklabels(labels)
    ax.set_xticks(np.arange(NT), minor=True)
    ax.tick_params(axis="x", which="major", length=0)
    ax.tick_params(axis="y", right=False)
    ax.set_title(title, fontsize=18)

    sn, sr = VAR_CONFIGS["nino"], VAR_CONFIGS["rnino"]
    handles = [
        Line2D([], [], color=sn["obs"], lw=2.5, label=sn["obs_lab"]),
        Line2D([], [], color=sn["em"], lw=3, marker="o", label=f"{sps} Nino3.4 ens. mean"),
        Line2D([], [], color=sn["mem"], lw=1, ls="--", marker="o", ms=3, label=f"{sps} Nino3.4"),
        Line2D([], [], color=sr["obs"], lw=2.5, label=sr["obs_lab"]),
        Line2D([], [], color=sr["em"], lw=3, marker="o", label=f"{sps} Rel. Nino3.4 ens. mean"),
        Line2D([], [], color=sr["mem"], lw=1, ls="--", marker="o", ms=3, label=f"{sps} Rel. Nino3.4"),
    ]
    ax.legend(handles=handles, loc="upper left", ncol=2, frameon=False, fontsize=9)

    # Allocate space for the logo
    fig.subplots_adjust(bottom=0.22)
    
    # Add the logo
    add_logo(fig, logo)

    # Save the figure
    fig.savefig(outfile, dpi=150)
    plt.close(fig)

def main(args):
    LOG.info("Initializing plotting Nino34 and RNino34...")

    yyyym7 = args.yyyym7
    mm7 = args.mm7
    yyyy = args.yyyy
    mm = args.mm
    nens = args.nens
    sps = args.sps
    refperiod = args.refperiod
    anomdir = args.anomdir
    dirplots = args.dirplots
    region = args.region
    stdfile = args.factor
    nino_obs = args.nino_obs
    rnino_obs = args.rnino_obs
    logo = args.cmcc_logo

    bn = [float(VAR_CONFIGS["nino"][k]) for k in ("lat1", "lat2", "lon1", "lon2")]
    bt = [float(VAR_CONFIGS["rnino"][k]) for k in ("lat1", "lat2", "lon1", "lon2")]

    fname = f"{anomdir}/sst_{sps}_{yyyy}{mm}_all_ano.{refperiod}.nc"
    tso, lat, lon = read_forecast(fname)
    tso = tso[:nens]

    nino_fc = box_mean(tso, lat, lon, *bn)
    trop_fc = box_mean(tso, lat, lon, *bt)
    factor = read_roni_factor(stdfile)
    roni_fc = (nino_fc - trop_fc) * factor[None, :]

    nino_obs = read_ascii_last7(nino_obs, 10)
    roni_obs = read_ascii_last7(rnino_obs, 3)

    nino = build_series(nino_fc, nino_obs)
    roni = build_series(roni_fc, roni_obs)

    labels = month_labels(yyyym7, mm7)
    title = f"{region} and Relative {region} Index issued {yyyy}{mm}"
    plname = f"{dirplots}/sst_{region}_RONI_{yyyy}_{mm}"
    make_plot(nino, roni, labels, title, sps, f"{plname}.png", logo)
    LOG.info(f"Plot saved to {plname}.png")
    
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Plot Nino34 and RNino34.")
    parser.add_argument("--yyyy", help="Forecast init year")
    parser.add_argument("--mm", help="Forecast init month")
    parser.add_argument("--yyyym7", type=int, help="Init year - 7 months")
    parser.add_argument("--mm7", type=int, help="Init month - 7 months")
    parser.add_argument("--nens", type=int, default=50, help="Number of ensemble membeers")
    parser.add_argument("--sps", help="SPS model version")
    parser.add_argument("--refperiod", help="Reference period")
    parser.add_argument("--anomdir", help="Anomaly directory")
    parser.add_argument("--dirplots", help="Plot directory")
    parser.add_argument("--region", default="Nino3.4", help="Region")
    parser.add_argument("--factor", help="NetCDF monthly factor file")
    parser.add_argument("--nino-obs", help="Nino3.4 text data file")
    parser.add_argument("--rnino-obs", help="RNino3.4 text data file")
    parser.add_argument("--cmcc-logo", help="CMCC logo")

    args = parser.parse_args()

    main(args)
