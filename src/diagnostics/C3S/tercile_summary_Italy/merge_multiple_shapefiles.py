import pandas as pd
import geopandas as gpd

files = ["/work/cmcc/cp1/shape_files/Italy/NordI.kml", "/work/cmcc/cp1/shape_files/Italy/CentroI.kml", "/work/cmcc/cp1/shape_files/Italy/SudSicilia.kml", "/work/cmcc/cp1/shape_files/Italy/Sardegna.kml"]

gdfs = [gpd.read_file(f, driver="KML") for f in files]
merged = gpd.GeoDataFrame(pd.concat(gdfs, ignore_index=True))

merged.to_file("/work/cmcc/cp1/shape_files/Italy/Italia.shp")
