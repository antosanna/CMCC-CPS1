load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/cd_string.ncl"
;*****************************************************
begin

;*****************************************************
; open files and read in monthly data
;*****************************************************
SS0=getenv("H0")
SS1=getenv("H1")
SS2=getenv("H2")
SS3=getenv("H3")
st   = getenv("st")
yyyy   = getenv("yyyy")
SPSSystem="sps4" ;getenv("SPSSystem")
refperiod   = getenv("refperiod")
outdir=getenv("csvdir")


dir="/work/cmcc/cp1//CPS/CMCC-CPS1/forecast_anom/"+yyyy+st ;getenv("anomdir")

v1    = addfile (dir+"/sst_"+SPSSystem+"_"+yyyy+st+"_all_ano."+refperiod+".nc","r")
ts    = v1->tso(:,0:5,:,:)
lon    = v1->lon
lat    = v1->lat
ens_ts    = dim_avg_n(ts,0)
time  = v1->time(0:5)
N=dimsizes(ts)
ntime = N(1)
nens  = N(0)

ens_ts!0    = "time"
ens_ts!1    = "lat"
ens_ts!2    = "lon"
ens_ts&lon=lon
ens_ts&lat=lat

;*****************************************************   
; CALCULATE Nino3 Index
;*****************************************************
lt1=getenv("lat1n")
lt2=getenv("lat2n")
lg1=getenv("lon1n")
lg2=getenv("lon2n")

rad    = 4.0*atan(1.0)/180.0
clat   = cos(lat*rad)
copy_VarMeta(lat,clat)

nino3=wgt_areaave_Wrap(ens_ts(:,{lt1:lt2},{lg1:lg2}),clat({lt1:lt2}),1,0)
nino3!0    = "time"
nino3&time = time

nsea = 4
nino34_sea=new(nsea,typeof(nino3))
nino34_sea(0)=dim_avg(nino3(0:2))
nino34_sea(1)=dim_avg(nino3(1:3))
nino34_sea(2)=dim_avg(nino3(2:4))
nino34_sea(3)=dim_avg(nino3(3:5))

;*****************************************************
; -- WRITE CSV FILE
;*****************************************************

csv = outdir+"/nino3.4_sea_"+SPSSystem+"_"+yyyy+st+"."+refperiod+".csv"


  dq = str_get_dq()                ; double quote character

  fields = (/SS0,SS1,SS2,SS3/)
  fields = dq + fields + dq                      ; Pre/append quotes to field names
  header = [/str_join(fields,",")/]              ; Header is field names separated
  write_table(csv, "w", header, "%s")   ; Write header to CSV file.

alist=[/nino34_sea(0),nino34_sea(1),nino34_sea(2),nino34_sea(3)/]
format = "%6.2f,%6.2f,%6.2f,%6.2f"
write_table(csv, "a", alist, format)  ; Write mixed data to CSV file.


end
