load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
begin

;=============================================
; external parameters
;=============================================
yyyyfore  = getenv("yyyyfore")
mmfore    = getenv("mmfore")
diroce    = getenv("diroce")  ;"/work/csp/sp2/SPS3.5/CESM/daily/votemper/anom/"
plname=getenv("plname")
maskoce   = getenv("maskoce")  ; "mesh_mask_from2000.nc"
foce1     = "votemper_SPS3.5_sps_"+yyyyfore+mmfore+"_ens_ano.1993-2016.nc"
;==============================================
f1      = addfile (diroce+foce1 , "r")    
sstoce1 = f1 ->votemper
fm       = addfile(maskoce,"r")
tmask    = byte2flt(fm ->tmask(:,0:29,:,:))
tmask@_FillValue = 1.e+20
lon1     = fm ->nav_lon
lat1     = fm ->nav_lat
lev1     = fm ->nav_lev
time     = f1 ->time_counter
dims=dimsizes(sstoce1)
ntime=dimsizes(time)
nlev=dims(1)
nlon=dims(2)

lon11=where(lon1.lt.0,lon1+360,lon1)
sstoce1@lon1 = lon11

sstoce1@_FillValue=1.e+20

printMinMax(lat1, True)
printMinMax(lon11, True)

latS=-2.5
latN=2.5
lonW=140
lonE=280

ji=region_ind(lat1,lon11,latS,latN,lonW,lonE)
jStrt = ji(0)
jLast = ji(1)
iStrt = ji(2)
iLast = ji(3)

LAT2D = lat1(jStrt:jLast,iStrt:iLast)
LON2D = lon11(jStrt:jLast,iStrt:iLast)

tmaskprof=dim_avg_n_Wrap(tmask(:,:,jStrt:jLast,:),2)

tmaskmovie=new((/ntime,nlev,nlon/),"float")
tmaskmovie@_FillValue=1.e+20

do n=0,ntime-1
  tmaskmovie(n,:,:)=tmaskprof
end do
tmaskmovie@_FillValue=1.e+20
sstoce11=where(tmaskmovie.eq.1,sstoce1*tmaskmovie,tmaskmovie@_FillValue)

printVarSummary(sstoce11)
copy_VarMeta(sstoce1,sstoce11)
printVarSummary(sstoce11)
sstoce11@_FillValue=1.e+20

tprof11=sstoce11(time_counter|:,deptht|0:29,x|iStrt:iLast)
profile=tprof11(:,::-1,:)
;==================================================
wks  = gsn_open_wks ("png", plname )
gsn_define_colormap(wks,"BlueDarkRed18")
plot4 = new ( 1 , graphic)

; Set up resources.
  res                     = True  
  res@gsnMaximize         = True        ; Maximize plot in frame

;---This resource not needed in NCL V6.1.0
  res@gsnSpreadColors     = True        ; Span full color map

;---This resource defaults to True in NCL V6.1.0
  res@lbLabelAutoStride   = True        ; Control labelbar spacing 

  res@cnFillOn            = True        ; Turn on contour fill
  res@cnLinesOn           = False       ; Turn off contour lines
  ;res@trGridType          = "TriangularMesh"    ; Define the mesh type.


  res@gsnYAxisIrregular2Linear = True

  res@cnLevelSelectionMode     = "ExplicitLevels" 
  res@cnLevels                 = (/-4,-3.5,-3,-2.5,-2,-1.5,-1,-0.5,0,0.5,1,1.5,2,2.5,3,3.5,4/)
  res@lbTitleString    = "[~S~o~N~C]"                ; title string
  res@lbTitlePosition  = "Right"              ; title position
  res@lbTitleDirection = "Across"
  res@tiYAxisString = "Depth (m)"
  res@cnMissingValFillPattern = "SolidFill"
  res@cnMissingValFillColor = "grey"
  
  month_abbr = (/"","Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep", \
                    "Oct","Nov","Dec"/)

 do n=0,ntime-1
    nn=n+1

    profile!1="lev"
    profile!2="lon"

    tmp=-lev1(0:29)
    profile&lev=tmp(::-1)
    profile&lon=lon11(0,iStrt:iLast)

    time@units = "days since "+yyyyfore+"-"+mmfore+"-01 12:00:0.0"
    utc_date = tostring(cd_calendar(time(n), -2))

    year   = tointeger(str_get_cols(utc_date,0,3))    ; Convert to integer for
    month  = tointeger(str_get_cols(utc_date,4,5))    ; use sprinti 
    day    = tointeger(str_get_cols(utc_date,6,7))
    date_str = "12Z " + sprinti("%0.2i ", day) + \
               month_abbr(month) + " "  + sprinti("%0.4i", year)

    res@tiMainString        = "Forecast issued on "+yyyyfore+mmfore
    
    res@gsnRightString  = date_str
    ;res@gsnRightString  = "time: " +  nn

    res@tmXBMode        = "Explicit"  
    res@tmXBValues      = (/140,160,180,200,220,240,260,280/)
    res@tmXBLabels      = (/"140E","160E","180E","200E","220E","240E","260E","280E"/)
    res@tmXBTickSpacingF      = 20.

    plot = gsn_csm_contour(wks,profile(n,:,:),res)  ; Create filled contours

    geom_value="80x80+930+830" 

end do

delete(wks)   ; Make sure PS file is closed

dirlogo=getenv("dirlogo") 
do n=0,ntime-1
    nn=n+1
    nnstr=sprinti("%0.6i", nn)
;    system( "composite -geometry "+geom_value+" "+dirlogo+"cmcc_logo_bw.jpg "+plname+"."+nnstr+".png "+plname+"."+nnstr+".png")
 
end do

;cmd = "magick convert -delay 25 "+plname+"*png "+plname+".gif"
;system(cmd)
;cmd = "rm "+plname+"*png"
;system(cmd)


;frame(wks)

end
