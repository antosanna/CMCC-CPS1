load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/cd_string.ncl"
;*****************************************************
begin

;*****************************************************
; open files and read in monthly data
;*****************************************************
yyyy=getenv("yyyy")
st   = getenv("st")

SPSSystem=getenv("SPSSystem")
refperiod   = getenv("refperiod")

dir=getenv("anomdir")

v1    = addfile (dir+"/sst_"+SPSSystem+"_"+yyyy+st+"_all_ano."+refperiod+".nc","r")
ts    = v1->tso(:,0:5,:,:)
time = v1->time(0:5)
lat=v1->lat
N =dimsizes(ts)
nens=N(0)
ntime=N(1)

rad    = 4.0*atan(1.0)/180.0
clat   = cos(lat*rad)
copy_VarMeta(lat,clat)

ts@_FillValue=1.e+20

ts!0    = "ensemble"
ts!1    = "time"
ts!2    = "lat"
ts!3    = "lon"

;*****************************************************   
; CALCULATE RONI Index
;*****************************************************
lat1n=getenv("lat1n")
lat2n=getenv("lat2n")
lon1n=getenv("lon1n")
lon2n=getenv("lon2n")

lat1t=getenv("lat1t")
lat2t=getenv("lat2t")
lon1t=getenv("lon1t")
lon2t=getenv("lon2t")

H0=getenv("H0")
H1=getenv("H1")
H2=getenv("H2")
H3=getenv("H3")
print(clat({lat1n:lat2n}))
nino3=wgt_areaave_Wrap(ts(:,:,{lat1n:lat2n},{lon1n:lon2n}),clat({lat1n:lat2n}),1,0)
tropicsst=wgt_areaave_Wrap(ts(:,:,{lat1t:lat2t},{lon1t:lon2t}),clat({lat1t:lat2t}),1,0)

roni_tmp=nino3-tropicsst

stdfile=getenv("stdfile")
stf=addfile(stdfile,"r")
factor=stf->roni_factor

printVarSummary(roni_tmp)
printVarSummary(factor)

roni_ens=dim_avg_n(roni_tmp,0)
nsea = 4
roni_tmp_sea=new(nsea,typeof(roni_ens))
roni_tmp_sea(0)=dim_avg(roni_ens(0:2))
roni_tmp_sea(1)=dim_avg(roni_ens(1:3))
roni_tmp_sea(2)=dim_avg(roni_ens(2:4))
roni_tmp_sea(3)=dim_avg(roni_ens(3:5))

roni_sea=roni_tmp_sea*conform(roni_tmp_sea,factor,0)


;*****************************************************
; -- WRITE CSV FILE
;*****************************************************
csvdir=getenv("csvdir")
csv = csvdir+"/rel_nino3.4_sea_"+SPSSystem+"_"+yyyy+st+"."+refperiod+".csv"

dq = str_get_dq()                ; double quote character

SS0=getenv("H0")
SS1=getenv("H1")
SS2=getenv("H2")
SS3=getenv("H3")
fields = (/SS0,SS1,SS2,SS3/)
fields = dq + fields + dq                      ; Pre/append quotes to field names
header = [/str_join(fields,",")/]              ; Header is field names separated
write_table(csv, "w", header, "%s")   ; Write header to CSV file.

alist=[/roni_sea(0),roni_sea(1),roni_sea(2),roni_sea(3)/]
format = "%6.2f,%6.2f,%6.2f,%6.2f"
write_table(csv, "a", alist, format)  ; Write mixed data to CSV file.

end

