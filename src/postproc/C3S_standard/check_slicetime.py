"""
Esamina tutti i file NetCDF in una directory e stampa, per ciascuno,
il primo e l'ultimo valore (grezzo, non decodificato) della variabile time.
"""

import os
import sys
import glob
import re
import argparse
import xarray as xr

# ------------------------------------------------------------------
# PARAMETRI DA RIGA DI COMANDO
# ------------------------------------------------------------------
parser = argparse.ArgumentParser(
    description="Esamina i file NetCDF di una directory e stampa primo/ultimo valore della variabile time"
)
parser.add_argument(
    "-d", "--directory", default=".",
    help="Cartella da esaminare (default: cartella corrente)"
)
parser.add_argument(
    "-p", "--pattern", default="cmcc*.nc",
    help="Pattern dei file da cercare (default: '*.nc')"
)
parser.add_argument(
    "-t", "--time_var", default="time",
    help="Nome della variabile tempo nel NetCDF (default: 'time')"
)
args = parser.parse_args()
 
DIRECTORY = args.directory
PATTERN   = args.pattern
TIME_VAR  = args.time_var
#DIRECTORY = "/work/cmcc/cp2/CMCC-CM/archive/C3Sext/199511/"          # cartella da esaminare
#PATTERN   = "cmcc*.nc"       # pattern dei file da cercare
#TIME_VAR  = "time"       # nome della variabile tempo

# ------------------------------------------------------------------
# SCANSIONE FILE
# ------------------------------------------------------------------
files = sorted(glob.glob(os.path.join(DIRECTORY, PATTERN)))
errors_found = False
files_with_errors_primo = []
files_with_errors_ultimo = []

if not files:
    print(f"Nessun file trovato in '{DIRECTORY}' con pattern '{PATTERN}'")

for f in files:
    try:
        ds = xr.open_dataset(f, decode_times=False)
    except Exception as e:
        print(f"{os.path.basename(f)}: ERRORE apertura file -> {e}")
        continue

    if TIME_VAR not in ds.variables:
        print(f"{os.path.basename(f)}: variabile '{TIME_VAR}' non trovata")
        ds.close()
        continue

    time_vals = ds[TIME_VAR].values
    primo = time_vals[0]
    ultimo = time_vals[-1]

    # Estrazione dei numeri "sliceNtimeMtoP" dal nome file, se presenti
    match = re.search(r"slicetime(\d+)to(\d+)", os.path.basename(f))
    if match:
        primo_nome, ultimo_nome = int(match.group(1)), int(match.group(2))
        match_ok = (primo*24 == primo_nome) and (ultimo*24 == ultimo_nome)
#        print(f"{os.path.basename(f)}: primo={primo} (nome={primo_nome})  "
#              f"ultimo={ultimo} (nome={ultimo_nome})  match={match_ok}")
        if primo*24 != primo_nome:
            print(f"  ATTENZIONE: il primo valore di time ({primo*24}) nel file {f}"
                  f"non corrisponde al numero nel nome file ({primo_nome})!")
            errors_found = True
            files_with_errors_primo.append(os.path.basename(f))

        if ultimo*24 != ultimo_nome:
            print(f"  ATTENZIONE: l'ultimo valore di time ({ultimo*24}) nel file {f}"
                  f"non corrisponde al numero nel nome file ({ultimo_nome})!")
            errors_found = True
            files_with_errors_ultimo.append(os.path.basename(f))
    else:
        print(f"{os.path.basename(f)}: primo={primo}  ultimo={ultimo}  "
              f"(nessun pattern slicetime nel nome)")
#    print(f"{os.path.basename(f)}: primo={primo*24}  ultimo={ultimo*24}")

    ds.close()
# ------------------------------------------------------------------
# EXIT CODE FINALE
# ------------------------------------------------------------------
if errors_found:
    print("\nControllo completato: TROVATE discrepanze tra nome file e valori time.")
    print(f"File con errori nel primo istante ({len(files_with_errors_primo)}):")
    for fname in files_with_errors_primo:
        print(f"  - {fname}")
    print(f"File con errori nell'ultimo istante ({len(files_with_errors_ultimo)}):")
    for fname in files_with_errors_ultimo:
        print(f"  - {fname}")
    sys.exit(1)
else:
    print("\nControllo completato: tutti i file corrispondono correttamente.")
    sys.exit(0)
