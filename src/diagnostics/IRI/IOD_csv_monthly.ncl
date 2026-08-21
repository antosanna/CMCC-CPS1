load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/cd_string.ncl"
;*****************************************************
begin

;*****************************************************
; open files and read in monthly data
;*****************************************************
M0="IOD_"+getenv("mm_string")
M1="IOD_"+getenv("mmp1_string")
M2="IOD_"+getenv("mmp2_string")
M3="IOD_"+getenv("mmp3_string")
M4="IOD_"+getenv("mmp4_string")
M5="IOD_"+getenv("mmp5_string")

tend = getenv("yyyy")
st   = getenv("st")
refperiod   = getenv("refperiod")
csvdir = getenv("csvdir")

SPSSystem="sps4" ;getenv("SPSSystem")

dir="/work/cmcc/cp1//CPS/CMCC-CPS1/forecast_anom/"+tend+st ;getenv("anomdir")

v1    = addfile (dir+"/sst_sps4_"+tend+st+"_all_ano."+refperiod+".nc","r")
sstm    = v1->tso(:,0:5,:,:)
N=dimsizes(sstm)
nens=N(0)
ntime=N(1)
time  = v1->time(0:5)
lat   = v1->lat
rad    = 4.0*atan(1.0)/180.0
re     = 6371220.0
rr     = re*rad

clatW=cos(lat({-10:10})*rad)
clatE=cos(lat({-10:0})*rad)

sstm@_FillValue=1.e+20
sstm_iod_w=wgt_areaave_Wrap(sstm(:,:,{-10:10},{50:70}),clatW,1.0,1)
sstm_iod_e=wgt_areaave_Wrap(sstm(:,:,{-10:0},{90:108}),clatE,1.0,1)
sstm_iod=sstm_iod_w-sstm_iod_e

sstm_iod!0    = "ensemble"
sstm_iod!1    = "time"
sstm_iod&time = time
iod=dim_avg_n(sstm_iod,0)


;*****************************************************
; -- WRITE CSV FILE
;*****************************************************

csv = csvdir+"/iod_monthly_"+SPSSystem+"_"+tend+st+"."+refperiod+".csv"


dq = str_get_dq()                ; double quote character

fields = (/M0,M1,M2,M3,M4,M5/)
fields = dq + fields + dq                      ; Pre/append quotes to field names
header = [/str_join(fields,",")/]              ; Header is field names separated
write_table(csv, "w", header, "%s")   ; Write header to CSV file.

alist=[/iod(0),iod(1),iod(2),iod(3),iod(4),iod(5)/]
format = "%6.2f,%6.2f,%6.2f,%6.2f,%6.2f,%6.2f"
write_table(csv, "a", alist, format)  ; Write mixed data to CSV file.
end
