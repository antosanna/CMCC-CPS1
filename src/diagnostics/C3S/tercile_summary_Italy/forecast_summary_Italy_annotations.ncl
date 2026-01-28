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
;************************************************
; plot parameters
;************************************************
 
   p_threshold=0.39
   wks_type=getenv("pltype")
   region="Italy"
   proj="LambertConformal"
   bnd="National"
   minlat=32.
   maxlat=48.
   minlon=4.
   maxlon=20.
   lon0="0"
   lat0="90"
   lbx=0.16
   lby=0.06
   plname="pino"
   wks  = gsn_open_wks(wks_type,plname)
   gsn_merge_colormaps(wks,"prob_t2m_new","prob_prec")
;****************here probability data ********************
;   
   prob_low=getenv("prob_low")
   print("******** reading t2m prob_low "+prob_low)
   prec_prob_low=getenv("prec_prob_low")
   print("******** reading prec_prob_low "+prec_prob_low)
   fnl1 = addfile(prob_low,"r")
   pfnl1 = addfile(prec_prob_low,"r")
   lowtmp = fnl1->low33
   p_lowtmp = pfnl1->low33
   low=lowtmp
   plow=p_lowtmp
   copy_VarMeta(lowtmp,low)
   copy_VarMeta(p_lowtmp,plow)
   low@_FillValue=1.e+20
   plow@_FillValue=1.e+20

   prob_up=getenv("prob_up")
   print("******** reading t2m prob_up "+prob_up)
   prec_prob_up=getenv("prec_prob_up")
   print("******** reading prec_prob_up "+prec_prob_up)
   fnl2 = addfile(prob_up,"r")
   pfnl2 = addfile(prec_prob_up,"r")
   uptmp = fnl2->up66
   p_uptmp = pfnl2->up66
   up=uptmp
   pup=p_uptmp
   copy_VarMeta(uptmp,up)
   copy_VarMeta(p_uptmp,pup)
   up@_FillValue=1.e+20
   pup@_FillValue=1.e+20

;  
b=addfile(inputmall,"r")
bp=addfile(p_inputmall,"r")
ssttmp=b->$varm$ 
sst=dim_avg_n_Wrap(ssttmp(:,0+l1:2+l1,:,:),1)
prp=dim_avg_n_Wrap(bp->lwepr(:,0+l1:2+l1,:,:),1)

tsl=sst
tsn=sst
tsu=sst
psl=prp
psn=prp
psu=prp
countl=0
do k=0,49
   tsl(k,:,:)=where (sst(k,:,:).lt.low,1.,0.)
   tsu(k,:,:)=where(sst(k,:,:).gt.up,1.,0.)
   psl(k,:,:)=where (prp(k,:,:).lt.plow,1.,0.)
   psu(k,:,:)=where(prp(k,:,:).gt.pup,1.,0.)
end do


   tsll=dim_avg_n_Wrap(tsl,0)
   tsuu=dim_avg_n_Wrap(tsu,0)
   tsuu@_FillValue=-9999.
   tsll@_FillValue=-9999.
   tsll_summary=where(tsll .gt. p_threshold ,1.,0)
   tsuu_summary=where(tsuu .gt. p_threshold ,10.,0)

; ---- Now precip
   psll=dim_avg_n_Wrap(psl,0)
   psuu=dim_avg_n_Wrap(psu,0)
   psuu@_FillValue=-9999.
   psll@_FillValue=-9999.
   psll_summary=where(psll .gt. p_threshold ,100.,0)
   psuu_summary=where(psuu .gt. p_threshold ,1000.,0)
;************************************************
; plot parameters
;************************************************
  res2                      = True                ; make plot mods

  res2@gsnDraw                 = False               ; don't draw
  res2@gsnFrame                = False        ; don't advance frame
  res2@cnLinesOn               = False
  res2@gsnSpreadColors         = False               ; use full colormap
  res2@gsnMaximize             = True
  res2@mpGeophysicalLineThicknessF = 2
  res2@mpFillOn                = False
  res2@gsnAddCyclic            = True
  res2@cnConstFLabelOn         = False
  res2@cnConstFEnableFill      = True
  if ( region .eq. "global" ) then
     res2@gsnDraw             = False
     res2@gsnFrame            = False
     res2@gsnMaximize         = True
     res2@mpCenterLonF        = 0
     res2@tiMainOffsetYF      = -0.02
     res2@mpGridLineColor      = "transparent"
     res2@mpGridAndLimbDrawOrder = "PreDraw"
     res2@mpFillOn             = False
     res2@mpPerimOn            = False
     res2@mpShapeMode          = "FreeAspect"
     res2@vpWidthF             = 0.5
     res2@vpHeightF            = 0.25
     res2@mpLimitMode         = "LatLon"
     res2@mpGridAndLimbOn     = True
     ;res2@mpGridSpacingF      = 30.
     res2@tmXBLabelFontHeightF = 0.008
     res2@tmYLLabelFontHeightF = 0.008
     res2@pmTickMarkDisplayMode = "Always"
     res2@mpGridLatSpacingF        = 30
     res2@mpGridLonSpacingF        = 60
  else if ( region .eq. "NH" ) then
     res2@gsnMaximize          = False
     res2@gsnPolar             = "NH"
     res2@tiMainOffsetYF      = 0.05
  else if ( region .eq. "SH" ) then
     res2@gsnMaximize          = False
     res2@gsnPolar             = "SH"
     res2@tiMainOffsetYF      = 0.05
  else if ( region .eq. "Europe" .or. region .eq. "Italy")
     res2@mpProjection = proj
     res2@mpDataBaseVersion = "MediumRes"
     res2@mpGridAndLimbOn        = True
     res2@mpGridAndLimbDrawOrder = "PostDraw"
     res2@mpOutlineBoundarySets = "National"
     res2@mpGridLineDashPattern  = 2
     res2@mpFillOn             = False
     res2@mpLimitMode           = "Corners"
     res2@mpLeftCornerLatF      = 34 ;22.5 
     res2@mpLeftCornerLonF      = 6  ;-15
     res2@mpRightCornerLatF     = 50 ;57.5
     res2@mpRightCornerLonF     = 22 ;80

     res2@mpLambertMeridianF   = 15
     res2@mpLambertParallel1F    = 30
     res2@mpLambertParallel2F    = 80

     ;res2@gsnPaperOrientation  = "landscape"
     res2@gsnPaperOrientation = "auto"
     res2@gsnMaximize          = True
     res2@tmXBLabelFontHeightF = 0.005
     res2@tmYLLabelFontHeightF = 0.005
     res2@pmLabelBarWidthF     = 0.6               ; default is shorter
     res2@pmLabelBarHeightF    = 0.07               ; default is taller
     res2@pmLabelBarOrthogonalPosF = .40
     res2@pmTickMarkDisplayMode = "Always"
     res2@mpShapeMode          = "FreeAspect"
     res2@vpWidthF             = 0.3
     res2@vpHeightF            = 0.2
     res2@mpGridLatSpacingF    = 15
     res2@mpGridLonSpacingF    = 15
     res2@tiMainOffsetYF       = 0.05
  else
     res2@mpFillOn             = False
     res2@mpCenterLonF=0.  ;tofloat(getenv("lon0"))
     res2@mpCenterLatF=0.  ;tofloat(getenv("lat0"))
     res2@mpLimitMode          = "LatLon"
     res2@gsnPaperOrientation  = "landscape"
     res2@gsnMaximize          = True
     res2@tmXBLabelFontHeightF = 0.008
     res2@tmYLLabelFontHeightF = 0.008
     res2@pmLabelBarWidthF     = 0.6               ; default is shorter
     res2@pmLabelBarHeightF    = 0.07               ; default is taller
     res2@pmLabelBarOrthogonalPosF = .40
     res2@pmTickMarkDisplayMode = "Always"
     res2@mpShapeMode          = "FreeAspect"
     res2@vpWidthF             = 0.5
     res2@vpHeightF            = 0.06
     res2@tiMainOffsetYF       = 0.0001
  end if
  end if
  end if
  end if
  res2@cnLabelMasking           = True
  res2@mpPerimOn                = True

  res2@mpMinLatF                = minlat
  res2@mpMaxLatF                = maxlat
  res2@mpMinLonF                = minlon
  res2@mpMaxLonF                = maxlon
 
  res2@cnMissingValFillColor   = -1
  res2@gsnLeftString           = ""                  ; left title, remove default
  res2@gsnRightString          = ""
  res2@gsnCenterString         = ""

  diseqn="~F18~[~F10~prob ~F18~L 40%~F18~]"
  res2@tiMainString = "Start-date "+mmfore+"-"+yyyyfore+" Lead season "+lead+" ("+SS+")~C~ ~Z75~                 Outlook summary "+diseqn

  if ( region .eq. "global" ) then
     res2@gsnCenterStringFontHeightF  = 0.014
  else if ( region .eq. "NH" .or. region .eq. "SH" ) then
     res2@gsnCenterStringFontHeightF  = 0.02
  else if ( region .eq. "Europe" .or. region .eq. "Italy") then
     res2@gsnCenterStringFontHeightF  = 0.01
     res2@gsnCenterStringOrthogonalPosF = 0.02
  else
     res2@gsnCenterStringFontHeightF  = 0.0102
     res2@gsnCenterStringOrthogonalPosF = 0.3
  end if
  end if
  end if

  res2@cnSmoothingOn = True 
  res2@cnSmoothingTensionF = 5.
  res2@cnSmoothingDistanceF = 2
  res2@gsnStringFont = "helvetica-bold"

;************************************************
  res2@cnFillOpacityF          = 0.4
  res2@cnLevelSelectionMode    = "ExplicitLevels"                        ; set explicit contour levels
  res2@cnLevels                = (/1,10,100,1000/)
  res2@cnFillColors            = (/-1,3,9,17,22/)
  res2@cnLineLabelsOn          = False
  res2@lbLabelBarOn            = False
  res2@cnFillOn                = True                                            ; turn on color fill
  ;res2@cnFillMode              = "RasterFill"
  res2@cnInfoLabelOn           = False                      ; turn off contour label
  res2@cnLabelMasking          = True
;************************************************

   res2@cnMissingValFillColor   = -1
   ;if ( region.eq."Italy") then
      res2@tiMainFontHeightF = .01
      ;res2@tiDeltaF = 1.45
      res2@tiMainOffsetYF = .035
      res2@lbBottomMarginF =-.7
   ;end if

   res2@cnFillOpacityF          = 0.4
   tsuu_plot=where(tsuu_summary.eq.0. ,-9999.,tsuu_summary)
   copy_VarMeta(template(0,:,:),tsuu_summary)
   copy_VarMeta(template(0,:,:),tsuu_plot)
   tsuu_plot@_FillValue=-9999.
   res2@cnFillOpacityF          = 0.4
   tsll_plot=where(tsll_summary.eq.0. ,-9999.,tsll_summary)
   copy_VarMeta(template(0,:,:),tsll_plot)
   copy_VarMeta(template(0,:,:),tsll_summary)
   tsll_plot@_FillValue=-9999.
   res2@cnFillOpacityF          = 0.4
   prpuu_plot=where(psuu_summary.eq.0. ,-9999.,psuu_summary)
   copy_VarMeta(template(0,:,:),prpuu_plot)
   copy_VarMeta(template(0,:,:),psuu_summary)
   prpuu_plot@_FillValue=-9999.
   res2@cnFillOpacityF          = 0.4
   prpll_plot=where(psll_summary.eq.0. ,-9999.,psll_summary)
   copy_VarMeta(template(0,:,:),prpll_plot)
   copy_VarMeta(template(0,:,:),psll_summary)
   prpll_plot@_FillValue=-9999.
;   print(tsll_plot+"   "+tsuu_plot+"   "+prpll_plot+"   "+prpuu_plot)

   res2@cnMissingValFillColor   = -1
   plot=gsn_csm_contour_map(wks,tsuu_plot,res2)
   plot2=gsn_csm_contour(wks,tsll_plot,res2)
   plot3=gsn_csm_contour(wks,prpuu_plot,res2)
   plot4=gsn_csm_contour(wks,prpll_plot,res2) ; plot3


   dataprob=new((/3,4/),typeof(tsuu_plot))


;************************************************
; add the shapefile
;************************************************
  resp                  = True                      ; polyline mods desired
  resp@gsLineColor      = "red"                     ; color of lines
  resp@gsLineThicknessF = 2.0                       ; thickness of lines
  resp@gsLineLabelString= ""                    ; adds a line label string

; create array of dummy graphic variables. This is required, b/c each line
; must be associated with a unique dummy variable.
;---Add shapefile outlines from indian_met_zones shapefile
  lnres = True
  lnres@gsLineColor = "Red"
  lnres@gsLineThicknessF = 3.0

  id = gsn_add_shapefile_polylines(wks,plot4,snameI,lnres)

;************************************************

   rad    = 4.0*atan(1.0)/180.0
   clat   = cos(lat*rad) 
   

; tsll
   tsllN=new(dimsizes(tsll_summary),typeof(tsll_summary),tsll_summary@_FillValue)
   copy_VarMeta(tsll_summary,tsllN)
   tsllC=new(dimsizes(tsll_summary),typeof(tsll_summary),tsll_summary@_FillValue)
   copy_VarMeta(tsll_summary,tsllC)
   tsllS=new(dimsizes(tsll_summary),typeof(tsll_summary),tsll_summary@_FillValue)
   copy_VarMeta(tsll_summary,tsllS)
   dim=dimsizes(tsll_summary)
   mlon=dim(1)
   nlat=dim(0)
   tsllN    = shapefile_mask_data(tsll_summary,snameN,True)
   tsllC    = shapefile_mask_data(tsll_summary,snameC,True)
   tsllS    = shapefile_mask_data(tsll_summary,snameS,True)
   tsllSS    = tsllS
   tsllSS    = shapefile_mask_data(tsll_summary,snameSS,True)
   tsllS=where(.not.ismissing(tsllSS),tsllSS,tsllS)
   dataprob(0,0)=wgt_areaave_Wrap(tsllN,clat,1,0)
   dataprob(1,0)=wgt_areaave_Wrap(tsllC,clat,1,0)
   dataprob(2,0)=wgt_areaave_Wrap(tsllS,clat,1,0)

; tsuu
   tsuuN=new(dimsizes(tsuu_summary),typeof(tsuu_summary),tsuu_summary@_FillValue)
   copy_VarMeta(tsuu_summary,tsuuN)
   tsuuC=new(dimsizes(tsuu_summary),typeof(tsuu_summary),tsuu_summary@_FillValue)
   copy_VarMeta(tsuu_summary,tsuuC)
   tsuuS=new(dimsizes(tsuu_summary),typeof(tsuu_summary),tsuu_summary@_FillValue)
   copy_VarMeta(tsuu_summary,tsuuS)
   tsuuN    = shapefile_mask_data(tsuu_summary,snameN,True)
   tsuuC    = shapefile_mask_data(tsuu_summary,snameC,True)
   tsuuS    = shapefile_mask_data(tsuu_summary,snameS,True)
   tsuuSS    = tsllS
   tsuuSS    = shapefile_mask_data(tsuu_summary,snameSS,True)
   tsuuS=where(.not.ismissing(tsuuSS),tsuuSS,tsuuS)
   dataprob(0,1)=wgt_areaave_Wrap(tsuuN,clat,1,0)/10.
   dataprob(1,1)=wgt_areaave_Wrap(tsuuC,clat,1,0)/10.
   dataprob(2,1)=wgt_areaave_Wrap(tsuuS,clat,1,0)/10.
; prpll
   prpllN=new(dimsizes(psll_summary),typeof(psll_summary),psll_summary@_FillValue)
   copy_VarMeta(psll_summary,prpllN)
   prpllC=new(dimsizes(psll_summary),typeof(psll_summary),psll_summary@_FillValue)
   copy_VarMeta(psll_summary,prpllC)
   prpllS=new(dimsizes(psll_summary),typeof(psll_summary),psll_summary@_FillValue)
   copy_VarMeta(psll_summary,prpllS)
   prpllN    = shapefile_mask_data(psll_summary,snameN,True)
   prpllC    = shapefile_mask_data(psll_summary,snameC,True)
   prpllS    = shapefile_mask_data(psll_summary,snameS,True)
   prpllSS    = tsllS
   prpllSS    = shapefile_mask_data(psll_summary,snameSS,True)
   prpllS=where(.not.ismissing(prpllSS),prpllSS,prpllS)
   dataprob(0,2)=wgt_areaave_Wrap(prpllN,clat,1,0)/100.
   dataprob(1,2)=wgt_areaave_Wrap(prpllC,clat,1,0)/100.
   dataprob(2,2)=wgt_areaave_Wrap(prpllS,clat,1,0)/100.
;prpuu
   prpuuN=new(dimsizes(psuu_summary),typeof(psuu_summary),psuu_summary@_FillValue)
   copy_VarMeta(psuu_summary,prpuuN)
   prpuuC=new(dimsizes(psuu_summary),typeof(psuu_summary),psuu_summary@_FillValue)
   copy_VarMeta(psuu_summary,prpuuC)
   prpuuS=new(dimsizes(psuu_summary),typeof(psuu_summary),psuu_summary@_FillValue)
   copy_VarMeta(psuu_summary,prpuuS)
   prpuuN    = shapefile_mask_data(psuu_summary,snameN,True)
   prpuuC    = shapefile_mask_data(psuu_summary,snameC,True)
   prpuuS    = shapefile_mask_data(psuu_summary,snameS,True)
   prpuuSS    = tsuuS
   prpuuSS    = shapefile_mask_data(psuu_summary,snameSS,True)
   prpuuS=where(.not.ismissing(prpuuSS),prpuuSS,prpuuS)
   dataprob(0,3)=wgt_areaave_Wrap(prpuuN,clat,1,0)/1000.
   dataprob(1,3)=wgt_areaave_Wrap(prpuuC,clat,1,0)/1000.
   dataprob(2,3)=wgt_areaave_Wrap(prpuuS,clat,1,0)/1000.

   dataprob=dataprob*100.

   print("lower  T")
   print(dataprob(:,0))
   print("upper T")
   print(dataprob(:,1))
   print("lower P")
   print(dataprob(:,2))
   print("upper P")
   print(dataprob(:,3))

       
   overlay(plot,plot2)
   overlay(plot,plot3)
   overlay(plot,plot4)
;**********************************************************
; add labelbar to second plot
;********************************************************** 
  tmres    = True

;---Set the values you want for the map tickmarks.
  tmres@tmXBLabelFontHeightF = 0.009         ; Default is a bit large
  if (region .eq. "global") then

;---We're putting tickmarks on all four axes.
      tmres@tmYLValues = ispan(-90,90,30)
      tmres@tmYRValues = ispan(-90,90,30)
      tmres@tmXBValues = ispan(-180,180,30)
      tmres@tmXTValues = ispan(-180,180,30)
      map = add_map_tickmarks2(wks,plot,tmres)
  else if (region .eq. "Europe" .or. region .eq. "Italy") then

;---We're putting tickmarks on all four axes.
      tmres@tmYLValues = ispan(-90,90,5)
      tmres@tmYRValues = ispan(-90,90,5)
      tmres@tmXBValues = ispan(-180,180,5)
      tmres@tmXTValues = ispan(-180,180,5)
      map = add_map_tickmarks2(wks,plot,tmres)
  else if ( region .eq. "Tropics" ) then

;---We're putting tickmarks on all four axes.
      tmres@tmYLValues = ispan(-20,20,10)
      tmres@tmYRValues = ispan(-20,20,10)
      tmres@tmXBValues = ispan(-180,180,30)
      tmres@tmXTValues = ispan(-180,180,30)
      map = add_map_tickmarks2(wks,plot,tmres)

  end if
  end if
  end if

  getvalues plot@contour
   
  "vpXF"      : vpx
  "vpYF"      : vpy
  "vpHeightF" : vph
  "vpWidthF"  : vpw
  end getvalues
  
  if ( region .eq. "NH" .or. region .eq. "SH" ) then
     scalefactor=0.6
  else
     scalefactor=0.5
  end if
  lbw    = scalefactor * vpw           ; Make labelbar size a fraction of the plot.
  lbh    = scalefactor * vph

  lbres                    = True
  lbres@vpWidthF           = 0.1  ;scalefactor * vpw     ; labelbar width
  lbres@vpHeightF          = .05 ;scalefactor * vph     ; labelbar height
  lbres@lbBoxMajorExtentF  = 0.5         ; puts space between color boxes
  lbres@lbFillOpacityF          = 0.4
  lbres@lbOrientation      = "Horizontal"    ; orientation
  lbres@lbAutoManage       = False         ; we control label bar
  lbres@lbFillPattern      = "SolidFill"
  lbres@lbLabelFontHeightF = 0.012

;  delete(lbres@lbFillColors)
  lbres@lbPerimOn             = False         ; Turn off labelbar perimeter.
  lbres@lbMonoFillPattern     = True          ; one pattern, all solid
  lbres@lbTitleOffsetF        = 0.5
  lbres@lbTitleOn               = True
  lbres@lbTitlePosition         = "Bottom"
  lbres@lbTitleFontHeightF      = 0.012               ; label font height
  lbres@lbTitleString           = "Colder-than-average"

  lbres@lbFillPatterns        = (/1/)
  lbres@lbFillColors          =  (/3/)
  labels = " "


  gsn_labelbar_ndc(wks,1,labels,lbx-0.05,vpy-vph-0.0725,lbres)

  delete(lbres@lbFillColors)
  delete(lbres@lbFillPatterns)

  lbres@lbLabelFontHeightF      = 0.012
  lbres@lbTitleOn               = True
  lbres@lbTitlePosition         = "Bottom"
  lbres@lbTitleFontHeightF      = 0.012               ; label font height

  lbres@lbFillPatterns        = (/10/)
  lbres@lbFillColors          = (/9/)
  lbres@lbTitleString           = "Warmer-than-average"

  gsn_labelbar_ndc(wks,1,labels,lbx+0.15,vpy-vph-0.0725,lbres)

;---- Labels for precip
  delete(lbres@lbFillColors)
  delete(lbres@lbFillPatterns)
  
  lbres@lbPerimOn             = False         ; Turn off labelbar perimeter.
  lbres@lbMonoFillPattern     = True          ; one pattern, all solid
  lbres@lbTitleOffsetF        = 0.5 
  lbres@lbTitleOn               = True
  lbres@lbTitlePosition         = "Bottom"
  lbres@lbTitleFontHeightF      = 0.012               ; label font height

  lbres@lbFillColors          =  (/17/)
  lbres@lbFillPatterns        = (/100/)
  lbres@lbTitleString           = "Drier-than-average"



  gsn_labelbar_ndc(wks,1,labels,lbx+0.35,vpy-vph-0.0725,lbres)

  delete(lbres@lbFillColors)
  delete(lbres@lbFillPatterns)

  lbres@lbLabelFontHeightF      = 0.012
  lbres@lbTitleOn               = True
  lbres@lbTitlePosition         = "Bottom"
  lbres@lbTitleFontHeightF      = 0.012               ; label font height

  lbres@lbFillColors            =  (/22/)
  lbres@lbFillPatterns          = (/1000/)
  lbres@lbTitleString           = "Wetter-than-average"

  gsn_labelbar_ndc(wks,1,labels,lbx+0.55,vpy-vph-0.0725,lbres)

;---------------
; Now annotate bar charts
;---------------
 nobs=3
 x=ispan(1,nobs+1,1)
 xrange = max(x) - min(x)
 deltax = xrange/10.

 xpos = (/0.14, 0.40, 0.67/) 
 ypos = (/0.95, 0.95, 0.95/) 

;---Markers on bar charts
  xndc_beg = (/0.22, 0.40, 0.62/) 
  yndc_beg = (/0.79, 0.84, 0.81/) 

;---Set resources common to both bar and XY plot
  bres                       = True
  bres@gsnFrame              = False     ; Turn off individual draw

  bres@vpWidthF              = 0.20      ; Make plots small,
  bres@vpHeightF             = 0.10      ; and non-square.

;---Turn off bottom tickmarks, and all minor tickmarks
  bres@tmXBOn                = False
  bres@tmXTOn                = False
  bres@tmYLMinorOn           = False
  bres@tmXTMinorOn           = False

;---Set X axis limits, and y minimum to same for all plots
  bres@trXMinF               = min(x) - deltax
  bres@trXMaxF               = max(x) + deltax
  bres@trYMinF               = 0.0    ; set to same for both plots
                                     ; we'll let ncl set the max Y

;---Bar chart resources
  bbres                      = bres  

  bbres@gsnXYBarChart         = True                 ; turn on bar chart
  bbres@gsnXYBarChartBarWidth = 0.75                 ; change bar widths
  bbres@gsnXYBarChartFillOpacityF          = 0.3
  bbres@gsnXYBarChartColors2            = (/3,9,17,22/)
;  bbres@gsnXYBarChartColors2 = (/"cornflowerblue","coral1","darkgoldenrod","darkolivegreen2"/)

  ;---Turn off right tickmarks
  bbres@tmYROn                = False

  bbres@tiYAxisString         = "%"

  ;---Create arrays to hold plot ids
  bar_plot = new(nobs,graphic)
  anno_id  = new(nobs,graphic)

  string_title=(/"Northern Italy","Central Italy","Southern Italy"/)
  do i=0,nobs-1
    bbres@vpXF         = xpos(i)
    bbres@vpYF         = ypos(i)
    
   
    bbres@tiMainString =  string_title(i)

;---Create bar plot
    bar_plot(i) = gsn_csm_xy (wks,x,dataprob(i,:),bbres)
  end do
;---------------
  draw(plot)
  frame(wks)
;************************************************
   delete(wks)
;***********************************************
logo=getenv("cmcc_logo")
if ( region .eq. "global" ) then
   geom_value="80x80+930+830" 
else if ( region .eq. "NH" .or. region .eq. "SH" ) then
  geom_value=" 80x80+930+880" 
else if ( region .eq. "Europe" ) then
  geom_value=" 80x80+930+900" 
else
   geom_value="80x80+930+660"
end if
end if
end if
system( "composite -geometry "+geom_value+logo+ plname+".png "+plname+".png")
end
