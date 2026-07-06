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

nsea = 4 
iod_sea=new(nsea,typeof(iod))
iod_sea(0)=dim_avg(iod(0:2))
iod_sea(1)=dim_avg(iod(1:3))
iod_sea(2)=dim_avg(iod(2:4))
iod_sea(3)=dim_avg(iod(3:5))



;*****************************************************
; -- WRITE CSV FILE
;*****************************************************

csv = csvdir+"/iod_sea_"+SPSSystem+"_"+tend+st+"."+refperiod+".csv"


  dq = str_get_dq()                ; double quote character

  fields = (/SS0,SS1,SS2,SS3/)
  fields = dq + fields + dq                      ; Pre/append quotes to field names
  header = [/str_join(fields,",")/]              ; Header is field names separated
  write_table(csv, "w", header, "%s")   ; Write header to CSV file.

alist=[/iod_sea(0),iod_sea(1),iod_sea(2),iod_sea(3)/]
format = "%6.2f,%6.2f,%6.2f,%6.2f"
write_table(csv, "a", alist, format)  ; Write mixed data to CSV file.
end
