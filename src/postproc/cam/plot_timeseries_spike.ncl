; ***********************************************
;************************************************
begin
;************************************************
; read in data
;************************************************
  caso   = getenv("caso")
  var2plot   = getenv("var2plot")
  healed_dir   = getenv("HEALED_DIR")
  srcFileName   = getenv("inputFV")
  print("source file "+srcFileName)
  pltname_root   = getenv("pltname_root")
  inputascii=getenv("inputascii")
  data = readAsciiTable(inputascii,1,"string",3)

;  it_spike    = tointeger(str_get_field(data,1,";"))
  j_spike = stringtointeger(str_get_field(data,2,";"))
  i_spike = stringtointeger(str_get_field(data,3,";"))
  nn=dimsizes(i_spike)
  nplots=nn(0)
  delete(nn)
  
  fC5=addfile(srcFileName,"r")
  addc=-273.15

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

  C3S=toint(getenv("C3S"))
  if(C3S.eq.0)then
     res@xyMarkerColors := "blue"
     do k=1,nplots
        wks   = gsn_open_wks ("png",pltname_root+"."+k+".png")

        toplot=tofloat(fC5->$var2plot$(:,j_spike(k-1,0),i_spike(k-1,0)))+addc
        lon=tofloat(fC5->lon(i_spike(k-1,0)))
        lat=tofloat(fC5->lat(j_spike(k-1,0)))

;************************************************
; to plot multiple lines, you must put them into
; a multidimensional array
;************************************************

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
  else if(C3S.eq.1)then
     plot=new(2,graphic)
;************************************************
; set-up the panel
;************************************************
     resP                     = True                ; modify the panel plot

     resP@gsnPanelLabelBar    = True                ; add common colorbar
     resP@lbLabelFontHeightF  = 0.007               ; make labels smaller
     srcFileNameDMO=getenv("inputDMO")
     print("DMO source file "+srcFileNameDMO)
     fDMO=addfile(srcFileNameDMO,"r")
     lonDMO=tofloat(fDMO->lon)
     latDMO=tofloat(fDMO->lat)
     do k=1,nplots
        wks   = gsn_open_wks ("png",pltname_root+"."+tostring(k))
        res@gsnDraw   = False
        res@gsnFrame          = False

        toplot=tofloat(fC5->$var2plot$(:,j_spike(k-1,0),i_spike(k-1,0)))+addc
        lon=tofloat(fC5->lon(i_spike(k-1,0)))
        lat=tofloat(fC5->lat(j_spike(k-1,0)))

        res@xyMarkerColors := "blue"
        lonplt=sprintf("%5.1f",lon)
        latplt=sprintf("%5.1f",lat)
        res@tiMainString         = caso+" C3S ~C~ lon "+lonplt+" lat "+latplt
        res@tiYAxisString =""
        res@tmXTOn=False

        label=new(1,"string")
        label(0)="Tmin"
        res@xyExplicitLegendLabels =label
        plot(0)  = gsn_csm_y (wks,toplot,res)

; now plot corresponding DMO
        ind_latDMO= closest_val(lat,latDMO)
        ind_lonDMO= closest_val(lon,lonDMO)
        toplot=tofloat(fDMO->TREFMNAV(:,ind_latDMO,ind_lonDMO))+addc
        res@xyMarkerColors := "red"
        lonplt=sprintf("%5.1f",lonDMO(ind_lonDMO))
        latplt=sprintf("%5.1f",latDMO(ind_latDMO))
        res@tiMainString         = "DMO ~C~ lon "+lonplt+" lat "+latplt
        plot(1)  = gsn_csm_y (wks,toplot,res)

        gsn_panel(wks,plot,(/2,1/),resP)               ; now draw as one plot
   
     end do
  end if
  end if

end

