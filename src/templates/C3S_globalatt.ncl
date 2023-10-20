;***************************************************************
; NCL script
;***************************************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

undef ("define_att")
function define_att(domain,level,freq)
begin
       C3Satts=getenv("C3Satts")
       value = asciiread(C3Satts,-1,"string")
       natt = dimsizes(value)
       delim="="
       field=1
       att = str_get_field(value(0:), field, delim)
       field=2
       valore = str_get_field(value(0:), field, delim)
;       print(natt)
;       print(att)
       global    = True
       k=0
       global@Conventions=valore(k)
       k=1
       global@title=valore(k)
       k=2
       global@references=valore(k)
       k=3
       global@source=valore(k)
       k=4
       global@institute_id=valore(k)
       k=5
       global@institution=valore(k)
       k=6
       global@contact=valore(k)
       k=7
       global@project=valore(k)
       k=8
       global@commit=valore(k)
       k=9
       global@history=valore(k)
       k=10
       global@comment=valore(k)
       k=11
       global@summary=valore(k)
       k=12
       global@keywords=valore(k)
;       print(global)
       yyyytoday=getenv("yyyytoday")
       mmtoday=getenv("mmtoday")
       ddtoday=getenv("ddtoday")
       Htoday=getenv("Htoday")
       Mtoday=getenv("Mtoday")
       Stoday=getenv("Stoday")
       global@creation_date = yyyytoday+"-"+mmtoday+"-"+ddtoday+"T"+Htoday+":"+Mtoday+":"+Stoday+"Z"
;       print(global@creation_date)
       yyyy=getenv("yyyy")
       st=getenv("st")
       global@forecast_reference_time = yyyy+"-"+st+"-01T00:00:00Z"
       global@modeling_realm = domain
       fore_type=getenv("fore_type")
       global@forecast_type = fore_type
;       if ( varout .eq. "sftlt". or. varout .eq. "orog") then
;         frq="fix"
;      else
;          frq=getenv("frq")
;      end if
       global@frequency = freq
       global@level_type = level
       ic=getenv("ic")
       global@ic=ic 
;       print(global@ic)
       return (global)
end
