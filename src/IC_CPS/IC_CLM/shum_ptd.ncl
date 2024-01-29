load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"

begin

fil1=getenv("infile1")

f = addfile(fil1,"r")
time = f->time
lati = f->lat
loni = f->lon
di = f->var168        ;dewpoint
pi = f->pres        ;slp

shum = mixhum_ptd (pi, di, 2) 
copy_VarMeta(di,shum)
printVarSummary(shum)

fileO=getenv("outfile")

system("/bin/rm -f "+fileO)
fout=addfile(fileO,"c")
fout->time=time
fout->lat=lati
fout->lon=loni
;shum!0=time
;shum!1=lat
;shum!2=lon
fout->shum=shum

end
