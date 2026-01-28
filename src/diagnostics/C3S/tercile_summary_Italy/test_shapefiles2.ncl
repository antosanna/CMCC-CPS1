;************************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl" 
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "./shapefile_utils.ncl"
;************************************************
undef("add_map_tickmarks2")
function add_map_tickmarks2(wks,plot,res)
local res2, bres, vpx, vpy, vpw, vph, xndc, yndc, npts, n, j, nlat, \
nlon, delta, bot_lon, top_lon, lft_lat, rgt_lat, xblabels, xbvalues, \
xtlabels, xtvalues, yllabels, ylvalues, yrlabels, yrvalues, xfix, \
xlat, xlon, yfix, annoid, anno_str
begin
;---Make a copy of the original resource list.
  res2 = res 

;---Retrieve edges of plot in NDC space.
  getvalues plot
     "vpXF"      :  vpx 
     "vpYF"      :  vpy 
     "vpWidthF"  :  vpw 
     "vpHeightF" :  vph 
  end getvalues

;---Turn off tickmarks associated with map. We want to add our own.
  setvalues plot
    "pmTickMarkDisplayMode" : "Never"
  end setvalues

;---Initialize resources for tickmark plot. User shouldn't change these.
  bres                          = True
  bres@vpXF                     = vpx 
  bres@vpYF                     = vpy 
  bres@vpWidthF                 = vpw 
  bres@vpHeightF                = vph 
  bres@trXMinF                  = vpx 
  bres@trXMaxF                  = vpx + vpw 
  bres@trYMinF                  = vpy - vph 
  bres@trYMaxF                  = vpy 
  bres@tmEqualizeXYSizes        = True

;---This resource the user can change in main code if desired.
  bres@gsnTickMarksPointOutward = get_res_value(res2,"gsnTickMarksPointOutward",True)

;
; NDC Points to scan on X and Y axes. These arrays will be used to
; find the closest NDC pair that gets us close to the location where
; we want a tickmark.
;
  npts = 100000   ; Increase to get closer match for tickmarks
  xndc = fspan(vpx,vpx+vpw,npts)
  yndc = fspan(vpy-vph,vpy,npts)

  n    = dimsizes(yndc) 
  xfix = new(n,float)
  yfix = new(n,float)
  xlon = new(n,float)
  xlat = new(n,float)
  delta = 0.001

;---Left axis tickmarks
  if(isatt(res2,"tmYLValues")) then
    lft_lat    = get_res_value(res2,"tmYLValues",-1)
    nlat       = dimsizes(lft_lat)
    ylvalues = new(nlat,float)
    yllabels = new(nlat,string)
    xfix  = vpx + 0.0001 ; Just a smidge into the plot to make sure we don't
                         ; get missing values returned.
;
; Loop across each left latitude value that we want a tickmark for,
; and try to find the closest X,Y NDC coordinate pair along this axis.
;
    NhlNDCToData(plot,xfix,yndc,xlon,xlat)
    do j=0,dimsizes(lft_lat)-1
      NhlNDCToData(plot,xfix,yndc,xlon,xlat)
      ii = minind(fabs(xlat-lft_lat(j)))
      if(.not.any(ismissing(ii)).and.fabs(xlat(ii)-lft_lat(j)).le.delta)
        yllabels(j) = fabs(lft_lat(j)) + ""
        ylvalues(j) = yndc(ii(0))
        if(lft_lat(j).lt.0) then
          yllabels(j) = yllabels(j) + "~S~o~N~S"
        end if
        if(lft_lat(j).gt.0) then
          yllabels(j) = yllabels(j) + "~S~o~N~N"
        end if
      end if
      delete(ii)
    end do
    bres@tmYLMode   = "Explicit"
    bres@tmYLValues = ylvalues
    bres@tmYLLabels = get_res_value(res2,"tmYLLabels",yllabels)
  else
    bres@tmYLOn       = False
    bres@tmYLLabelsOn = False
  end if

;---Right axis tickmarks
  if(isatt(res2,"tmYRValues")) then
    rgt_lat    = get_res_value(res2,"tmYRValues",-1)
    nlat       = dimsizes(rgt_lat)
    yrvalues = new(nlat,float)
    yrlabels = new(nlat,string)

    xfix  = vpx + vpw - 0.0001 ; Just a smidge into the plot to make sure we don't
                               ; get missing values returned.
;
; Loop across each right latitude value that we want a tickmark for,
; and try to find the closest X,Y NDC coordinate pair along this axis.
;
    do j=0,dimsizes(rgt_lat)-1
      NhlNDCToData(plot,xfix,yndc,xlon,xlat)
      ii = minind(fabs(xlat-rgt_lat(j)))
      if(.not.any(ismissing(ii)).and.fabs(xlat(ii)-rgt_lat(j)).le.delta)
        yrlabels(j) = fabs(rgt_lat(j)) + ""
        yrvalues(j) = yndc(ii(0))
        if(rgt_lat(j).lt.0) then
          yrlabels(j) = yrlabels(j) + "~S~o~N~S"
        end if
        if(rgt_lat(j).gt.0) then
          yrlabels(j) = yrlabels(j) + "~S~o~N~N"
        end if
      end if
      delete(ii)
    end do
    bres@tmYROn       = True
    bres@tmYRLabelsOn = True
    bres@tmYUseLeft   = False
    bres@tmYRMode     = "Explicit"
    bres@tmYRValues   = yrvalues
    bres@tmYRLabels   = get_res_value(res2,"tmYRLabels",yrlabels)
  else
    bres@tmYUseLeft   = False
    bres@tmYROn       = False
    bres@tmYRLabelsOn = False
  end if

;---Top axis tickmarks
  if(isatt(res2,"tmXTValues")) then
    top_lon    = get_res_value(res2,"tmXTValues",-1)
    nlon       = dimsizes(top_lon)
    xtvalues = new(nlon,float)
    xtlabels = new(nlon,string)

    yfix  = vpy - 0.0001 ; Just a smidge into the plot to make sure we don't
                         ; get missing values returned.
;
; Loop across each top longitude value that we want a tickmark for,
; and try to find the closest X,Y NDC coordinate pair along this axis.
;
    do j=0,dimsizes(top_lon)-1
      NhlNDCToData(plot,xndc,yfix,xlon,xlat)
      ii = minind(fabs(xlon-top_lon(j)))
      if(.not.any(ismissing(ii)).and.fabs(xlon(ii)-top_lon(j)).le.delta)
        xtlabels(j) = fabs(top_lon(j)) + ""
        xtvalues(j) = xndc(ii(0))
        if(top_lon(j).lt.0) then
          xtlabels(j) = xtlabels(j) + "~S~o~N~W"
        end if
        if(top_lon(j).gt.0) then
          xtlabels(j) = xtlabels(j) + "~S~o~N~E"
        end if
      end if
      delete(ii)
    end do
    bres@gsnTickMarksOn = False
    bres@tmXBMajorLengthF = 0
    bres@tmYLMajorLengthF = 0
    bres@tmXBMinorLengthF = 0
    bres@tmYLMinorLengthF = 0
    bres@tmXTOn       = True
    bres@tmXTLabelsOn = True
    bres@tmXUseBottom = False
    bres@tmXTMode     = "Explicit"
    bres@tmXTValues   = xtvalues
    bres@tmXTLabels   = get_res_value(res2,"tmXTLabels",xtlabels)
  else
    bres@gsnTickMarksOn = False
    bres@tmXUseBottom = False
    bres@tmXTOn       = False
    bres@tmXTLabelsOn = False
  end if

;---Bottom axis tickmarks
  if(isatt(res2,"tmXBValues")) then
    bot_lon    = get_res_value(res2,"tmXBValues",-1)
    nlon       = dimsizes(bot_lon)
    xbvalues = new(nlon,float)
    xblabels = new(nlon,string)

    yfix  = vpy-vph + 0.0001 ; Just a smidge into the plot to make sure
                             ; we don't get missing values returned.
;
; Loop across each bottom longitude value that we want a tickmark for,
; and try to find the closest X,Y NDC coordinate pair along this axis.
;
do j=0,dimsizes(bot_lon)-1
      NhlNDCToData(plot,xndc,yfix,xlon,xlat)
      ii = minind(fabs(xlon-bot_lon(j)))
      if(.not.any(ismissing(ii)).and.fabs(xlon(ii)-bot_lon(j)).le.delta)
        xblabels(j) = fabs(bot_lon(j)) + ""
        xbvalues(j) = xndc(ii(0))
        if(bot_lon(j).lt.0) then
          xblabels(j) = xblabels(j) + "~S~o~N~W"
        end if
        if(bot_lon(j).gt.0) then
          xblabels(j) = xblabels(j) + "~S~o~N~E"
        end if
      end if
      delete(ii)
    end do
    bres@tmXBMode   = "Explicit"
    bres@tmXBValues = xbvalues
    bres@tmXBLabels = get_res_value(res2,"tmXBLabels",xblabels)
  else
    bres@tmXBOn       = False
    bres@tmXBLabelsOn = False
  end if

;
; Now that we are done figuring out where to put tickmarks, and
; what labels to use, get any "tm" resources that might have been
; set by the user, and create a blank plot with thes new tickmarks.
;

;---Get rest of user resources that were set with "tm".
  bres = get_res_eq(res2,"tm")

  bres = True   ; Above call will set bres to True if no "tm" resources, so
                ; make sure it is True still.

  bres@gsnDraw  = False
  bres@gsnFrame = False

;
; Create blank plot with new tickmarks (don't use gsn_csm_blank_plot,
; because it wants to scale the size of your X and Y axes.)
;
  blank  = gsn_blank_plot(wks,bres)

;
; Attach new tickmarks to original plot. This will allow resizing
; if desired. The default is to attach one plot to the center of
; the other one. These two plots are already the same size.
;
  annoid = gsn_add_annotation(plot,blank,False)

;
; Be sure to return the annotation id, otherwise the
; tickmarks will disappear.
;
  anno_str = unique_string("annoid")
  plot@$anno_str$ = annoid

  return(plot)
end
;************************************************
;  BEGIN MAIN
;************************************************
begin
;************************************************
; variable and file handling
;************************************************
  shapefdir=getenv("shapefdir")
  snameN=shapefdir+"NordI.shp"
  fN       = addfile(snameN, "r")
  shp_lonN = tofloat( fN->x )
  shp_latN = tofloat( fN->y )
  snameC = shapefdir+"CentroI.shp"
  fC       = addfile(snameC, "r")
  shp_lonC = tofloat( fC->x )
  shp_latC = tofloat( fC->y )
  snameS = shapefdir+"SudSicilia.shp"
  fS       = addfile(snameS, "r")
  shp_lonS = tofloat( fS->x )
  shp_latS = tofloat( fS->y )
  snameSS = shapefdir+"Sardegna.shp"
  fSS       = addfile(snameSS, "r")
  shp_lonSS = tofloat( fSS->x )
  shp_latSS = tofloat( fSS->y )
  snameI=shapefdir+"Italia.shp"

  check_shape=0
  if(check_shape.eq.1)then
     sname = snameS
     print_shapefile_info(sname)
     plot_shapefile(sname)
  end if

  check_limits=0
  if(check_limits.eq.1)then
      min_shp_lat = min(shp_latN) 
      print(min_shp_lat)
      min_shp_lat = min(shp_latC) 
      print(min_shp_lat)
      min_shp_lat = min(shp_latS) 
      print(min_shp_lat)
      max_shp_lat = max(shp_latN)
      print(max_shp_lat)
      max_shp_lat = max(shp_latC)
      print(max_shp_lat)
      max_shp_lat = max(shp_latS)
      print(max_shp_lat)
      min_shp_lon = min(shp_lonN)
      print(min_shp_lon)
      min_shp_lon = min(shp_lonC)
      print(min_shp_lon)
      min_shp_lon = min(shp_lonS)
      print(min_shp_lon)
      max_shp_lon = max(shp_lonN)
      print(max_shp_lon)
      max_shp_lon = max(shp_lonC)
      print(max_shp_lon)
      max_shp_lon = max(shp_lonS)
      print(max_shp_lon)
   end if

   yyyyfore=getenv("yyyyfore")
   mmfore=getenv("mmfore")
   SS=getenv("SS")
   lead="1"
   l1=toint(lead)
   varm="tas"
   varobs="t2m"
   inputmall=getenv("inputmall")
   p_inputmall=getenv("p_inputmall")
   
  in  = addfile(inputmall,"r")                            ; open netcdf file
  template  = in->$varm$(0,:,:,:)                            ; read in variabl
  lat = in->lat
  
  lon = in->lon

   rad    = 4.0*atan(1.0)/180.0
   clat   = cos(lat*rad) 
   

; tsll
   template@_FillValue=-999.
   tsllN=new(dimsizes(template(0,:,:)),typeof(template),template@_FillValue)
   copy_VarMeta(template(0,:,:),tsllN)
   tsllC=new(dimsizes(template(0,:,:)),typeof(template),template@_FillValue)
   copy_VarMeta(template(0,:,:),tsllC)
   tsllS=new(dimsizes(template(0,:,:)),typeof(template),template@_FillValue)
   copy_VarMeta(template(0,:,:),tsllS)
   dim=dimsizes(template)
   mlon=dim(2)
   nlat=dim(1)
   clatN=clat
   clatC=clat
   clatS=clat
   tsllN    = shapefile_mask_data(template(0,:,:),snameN,True)
   tsllC    = shapefile_mask_data(template(0,:,:),snameC,True)
   tsllS    = shapefile_mask_data(template(0,:,:),snameS,True)
   tsllSS    = tsllS
   tsllSS    = shapefile_mask_data(template(0,:,:),snameSS,True)
   tsllS=where(.not.ismissing(tsllSS),tsllSS,tsllS)
;   do nl=0,nlat-1
;   do ml=0,mlon-1
;      if(gc_inout(lat(nl),lon(ml),shp_latN,shp_lonN)) then
;         tsllN(nl,ml) = nl+ml
;         clatN(nl)=clat(nl)
;      end if
;      if(gc_inout(lat(nl),lon(ml),shp_latC,shp_lonC)) then
;         tsllC(nl,ml) = nl+ml
;         clatC(nl)=clat(nl)
;      end if
;      if(gc_inout(lat(nl),lon(ml),shp_latS,shp_lonS)) then
;         tsllS(nl,ml) = nl+ml
;         clatS(nl)=clat(nl)
;      end if
;      if(gc_inout(lat(nl),lon(ml),shp_latSS,shp_lonSS)) then
;         tsllS(nl,ml) = nl+ml
;         clatS(nl)=clat(nl)
;      end if
;   end do
;   end do
   res=True
   wks = gsn_open_wks("x11","ce")
   plot = new(3,graphic)  
  res@gsnDraw             = False            ; don't draw
  res@gsnFrame            = False            ; don't advance frame
  res@cnInfoLabelOn       = False            ; turn off cn info label 
   res@cnFillOn              = True     ; turn on color fill
  res@mpMinLatF                = 35
  res@mpMaxLatF                = 50
  res@mpMinLonF                = 5
  res@mpMaxLonF                = 20
   toplot=tsllN
   copy_VarMeta(template(0,:,:),toplot)
   plot(0) = gsn_csm_contour_map(wks,toplot,res)
   toplot=tsllC
   copy_VarMeta(template(0,:,:),toplot)
   plot(1) = gsn_csm_contour_map(wks,toplot,res)
   toplot=tsllS
   copy_VarMeta(template(0,:,:),toplot)
   plot(2) = gsn_csm_contour_map(wks,toplot,res)
;************************************************
; create panel
;************************************************
  resP                  = True                   ; modify the panel plot
  resP@gsnFrame         = False                  ; don't advance panel plot
  resP@gsnPanelLabelBar = False                   ; do not add common colorbar
  resP@gsnPanelMainString = "Points intecepted by the shapefiles"     ; set main title
  resP@gsnPanelBottom   = 0.05                   ; add space at bottom
  resP@gsnPanelFigureStrings= (/"Nord)","Centro)","Sud e Isole)"/) ; add strings to panel
  resP@amJust   = "TopLeft"
  gsn_panel(wks,plot,(/3,1/),resP)               ; now draw as one plot
  frame(wks)
exit
end
