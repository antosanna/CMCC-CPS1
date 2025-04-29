; ***********************************************
;************************************************
begin
;************************************************
; read in data
;************************************************
  caso   = getenv("caso")
  srcFileName   = getenv("inputC3S")
  pltname_root   = getenv("pltname_root")
  inputascii=getenv("inputascii")
  data = readAsciiTable(inputascii,1,"string",3)

  j_spike = stringtointeger(str_get_field(data,2,";"))
  i_spike = stringtointeger(str_get_field(data,3,";"))
  nn=dimsizes(i_spike)
  nplots=nn(0)
  delete(nn)
  
  do k=1,nplots
     wks   = gsn_open_wks ("png",pltname_root+"."+k+".png")
     fC5=addfile(srcFileName,"r")

     addc=-273.15
     toplot=tofloat(fC5->tasmin(:,j_spike(k-1,0),i_spike(k-1,0)))+addc
     lon=tofloat(fC5->lon(i_spike(k-1,0)))
     lat=tofloat(fC5->lat(j_spike(k-1,0)))

;************************************************
; to plot multiple lines, you must put them into
; a multidimensional array
;************************************************
;************************************************
; create plot
;************************************************

     res                   = True                       ; plot mods desired
     res@pmLegendDisplayMode    = "Always"
     res@pmLegendSide           = "Top"                 ; Change location of
     res@pmLegendParallelPosF   = 1.15                   ; move units right
     res@pmLegendOrthogonalPosF = -1.                  ; more neg = down
     res@lgLabelFontHeightF=0.015

     res@pmLegendWidthF         = 0.07                  ; Change width and
     res@pmLegendHeightF        = 0.1 
     res@xyDashPattern  = 0                         ; Make curves all solid
     res@xyMarkLineMode = "MarkLines"               ; Markers *and* lines
     res@xyMarker      = 1
     res@xyMarkerSizeF=0.03
     res@xyMarkerColors := "blue"
     lonplt=sprintf("%5.1f",lon)
     latplt=sprintf("%5.1f",lat)
     res@tiMainString         = caso+" ~C~ lon "+lonplt+" lat "+latplt
     res@tiYAxisString =""
     res@tmXTOn=False

     label=new(1,"string")
     label(0)="Tmin"
     res@xyExplicitLegendLabels =label
     plot  = gsn_csm_y (wks,toplot,res)
  end do

end

