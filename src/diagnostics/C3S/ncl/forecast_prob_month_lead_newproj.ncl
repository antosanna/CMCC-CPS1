;************************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl" 
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
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
  write= "FALSE"     ; flag for writing field netcdf files
  yyyyfore=getenv("yyyyfore")
  mmfore=getenv("mmfore")
  SS=getenv("SS")
  terc=getenv("tercile")
  varm=getenv("varname")
  varobs=getenv("varobs")
  inputm=getenv("inputm")
  inputmall=getenv("inputmall")
  landmask=getenv("landmask")
  region=getenv("region")
  minlat=tofloat(getenv("minlat"))
  maxlat=tofloat(getenv("maxlat"))
  minlon=tofloat(getenv("minlon"))
  maxlon=tofloat(getenv("maxlon"))
  strvar=getenv("strvar")
  proj=getenv("proj")
  bnd=getenv("bnd")
  dirplots=getenv("dirplots") 
  nens=tointeger(getenv("nens"))
  ;if ( region .eq. "global" )
  ;   write = "TRUE"
  ;end if
   
  in  = addfile(inputm,"r")                            ; open netcdf file
  lead=getenv("lead")
  l1=toint(lead)
  if ( varm .eq. "zg" ) .or. ( varm .eq. "ta" ) .or. ( varm .eq. "ua" ) .or. ( varm .eq. "va" ) then
  	template  = in->$varm$(:,0,:,:)                            ; read in variabl
  else	
  	template  = in->$varm$(:,:,:)                            ; read in variabl
  end if
  if (varm .eq. "tso") then
   
     fmsk=addfile(landmask,"r")
     masklndtmp=fmsk->LANDFRAC(0,:,:)
     masklndtmp@_FillValue=1.e+20
     masklnd=where(masklndtmp.gt.0.,template@_FillValue,1)
     copy_VarMeta(masklndtmp,masklnd)
     
     masklnd@_FillValue=1.e+20
  
  end if
  lat = in->lat
  lon = in->lon

; ************************************************
; plot parameters
;************************************************
 
  wks_type=getenv("wks_type")
  plname=dirplots+"/"+varobs+"_"+region+"_prob_"+terc+"_tercile_"+yyyyfore+"_"+mmfore+"_monthly_l"+lead
  wks  = gsn_open_wks(wks_type,plname)
  gsn_define_colormap(wks,"prob_t2m_new")
;****************here probability data ********************
;   
  prob_low=getenv("problowfile")
  fnl1 = addfile(prob_low,"r")
  lowtmp = fnl1->low33
  if ( varm .eq. "lwepr" ) then
     low=lowtmp  ;*86400
  else if (varm .eq. "psl" ) then
     low=lowtmp   ;/100
  else if (varm .eq. "tso" ) ; then
     ;lowtmp@_FillValue=1.e+20
     low = where(masklnd.eq.masklnd@_FillValue,1.e+20,lowtmp)
  else
     low=lowtmp
  end if
  end if
  end if
  copy_VarMeta(lowtmp,low)

  prob_up=getenv("probupfile")
  fnl2 = addfile(prob_up,"r")
  uptmp = fnl2->up66
  if ( varm .eq. "lwepr" ) then
     up=uptmp ;*86400
  else if (varm .eq. "psl" ) then
     up=uptmp  ;/100
  else if (varm .eq. "tso" ) ; then
     ;uptmp@_FillValue=1.e+20
     up = where(masklnd.eq.masklnd@_FillValue,1.e+20,uptmp)
  else
     up=uptmp
  end if
  end if
  end if
  copy_VarMeta(uptmp,up)

;  
b=addfile(inputmall,"r")
if ( varm .eq. "zg" ) .or. ( varm .eq. "ta" ) .or. ( varm .eq. "ua" ) .or. ( varm .eq. "va" ) then
	sst=b->$varm$(:,l1,0,:,:)
else if ( varm .eq. "tso" ) then
	ssttmp=b->$varm$(:,l1,:,:)
	sst=ssttmp
        Ndim=dimsizes(ssttmp)
        nmem=Ndim(0)
        do i=0,nmem-1
	    sst(i,:,:)=where(masklnd.eq.masklnd@_FillValue,1.000000020040877e+20,ssttmp(i,:,:))
	end do
        sst@_FillValue=1.000000020040877e+20
        ;print(sst(0,:,:))
        ;print(sst(0,:,:)+"     "+low+"     "+up)
else
	sst=b->$varm$(:,l1,:,:)
end if
end if

tsl=sst
tsn=sst
tsu=sst
tmp=sst(0,:,:)
countl=0
do k=0,nens-1

   tsl(k,:,:)=where (sst(k,:,:).lt.low,1.,0.)
   tsu(k,:,:)=where(sst(k,:,:).gt.up,1.,0.)
   tmp=tsl(k,:,:)+tsu(k,:,:)
   tsn(k,:,:)=where(tmp.eq.0.,1.,0.)
   delete(tmp)
end do


   tsnn=dim_avg_n(tsn,0)*100
   tsuu=dim_avg_n(tsu,0)*100
   tsll=dim_avg_n(tsl,0)*100
   tsnn@_FillValue=-9999.
   tsuu@_FillValue=-9999.
   tsll@_FillValue=-9999.
   copy_VarMeta(template(0,:,:),tsnn)
   copy_VarMeta(template(0,:,:),tsuu)
   copy_VarMeta(template(0,:,:),tsll)

if ( terc .eq. "low") then
   varname="problow"
   prob=tsll
   tsplot=tsll
   tercstr="prob ("+varobs+" < lower tercile)"
   tercstr2="below lower tercile"
else if (terc .eq. "mid") then
   varname="probmid"
   prob=tsnn
   tsplot=tsnn
   tercstr="prob (lower tercile < "+varobs+" < upper tercile)"
   tercstr2="near normal"
else
   varname="probup"
   prob=tsuu
   tsplot=tsuu
   tercstr="prob ("+varobs+" > upper tercile)"
   tercstr2="above upper tercile"
end if
end if

;************************************************
; plot parameters
;************************************************
  res2                      = True                ; make plot mods
  ;if ((region .ne. "NH") .and. (region .ne. "SH")) then
  ;   res2@mpProjection         = proj
  ;end if
  res2@gsnDraw                 = False               ; don't draw
  res2@gsnFrame                = False        ; don't advance frame
  res2@cnLinesOn               = False
  res2@gsnSpreadColors         = False               ; use full colormap
  res2@gsnMaximize          = True
  res2@mpGeophysicalLineThicknessF = 2
  if ( region .eq. "global" ) then
     res2@gsnDraw             = False
     res2@gsnFrame            = False
     res2@gsnMaximize         = True
     res2@mpCenterLonF        = 0
     res2@tiMainOffsetYF      = -0.02
     res2@gsnAddCyclic         = True
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
  else if ( region .eq. "Europe" )
     res2@mpProjection = proj
     res2@mpDataBaseVersion = "MediumRes"
     res2@mpGridAndLimbOn        = True
     res2@mpGridAndLimbDrawOrder = "PostDraw"
     res2@mpGridLineDashPattern  = 2 
     res2@mpFillOn             = False
     res2@mpLimitMode           = "Corners"
     res2@mpLeftCornerLatF      = 22.5 ;25 
     res2@mpLeftCornerLonF      = -15 
     res2@mpRightCornerLatF     = 57.5
     res2@mpRightCornerLonF     = 80
  
     res2@mpLambertMeridianF   = 15
     res2@mpLambertParallel1F    = 30
     res2@mpLambertParallel2F    = 80
     
     res2@gsnPaperOrientation  = "landscape"
     res2@gsnMaximize          = True
     res2@tmXBLabelFontHeightF = 0.008
     res2@tmYLLabelFontHeightF = 0.008
     res2@pmLabelBarWidthF     = 0.6               ; default is shorter
     res2@pmLabelBarHeightF    = 0.07               ; default is taller
     res2@pmLabelBarOrthogonalPosF = .40 
     res2@pmTickMarkDisplayMode = "Always"
     res2@mpShapeMode          = "FreeAspect"
     res2@vpWidthF             = 0.35
     res2@vpHeightF            = 0.25
     res2@mpGridLatSpacingF    = 15
     res2@mpGridLonSpacingF    = 15
     res2@tiMainOffsetYF       = 0.05
  else
     res2@mpFillOn             = False
     res2@mpCenterLonF=0.  ;getenv("lon0")
     res2@mpCenterLatF=0.  ;getenv("lat0")
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
  ;res2@mpGridLineColor          = "Black"
  ;res2@mpGridAndLimbDrawOrder   = "PostDraw"
  ;res2@mpFillOn                 = False
  ;if (region .eq. "Tropics") then
  ;    res2@mpGridAndLimbOn          = True                ; turn on lat/lon lines
  ;end if 
  res2@mpPerimOn                = False

  res2@mpMinLatF                = minlat
  res2@mpMaxLatF                = maxlat
  res2@mpMinLonF                = minlon
  res2@mpMaxLonF                = maxlon


res2@cnMissingValFillColor   = -1
res2@gsnLeftString           = ""                  ; left title, remove default
res2@gsnRightString          = ""
res2@gsnCenterString         = "" 
if ( terc .eq. "low" .or. terc .eq. "up" ) then
   res2@tiMainString            = "Start-date "+mmfore+"-"+yyyyfore+" forecast month "+lead+" ("+SS+")~C~ ~Z75~                      "+tercstr
else
   res2@tiMainString            = "Start-date "+mmfore+"-"+yyyyfore+" forecast month "+lead+" ("+SS+")~C~ ~Z75~          "+tercstr
end if
res2@gsnCenterStringOrthogonalPosF = 0.1

if ( region .eq. "global" ) then
   res2@gsnCenterStringFontHeightF  = 0.014
else if ( region .eq. "NH" .or. region .eq. "SH" ) then
   res2@gsnCenterStringFontHeightF  = 0.02
else if ( region .eq. "Europe") then
   res2@gsnCenterStringFontHeightF  = 0.0102
   res2@gsnCenterStringOrthogonalPosF = 0.1
else
   res2@gsnCenterStringFontHeightF  = 0.0102
   res2@gsnCenterStringOrthogonalPosF = 0.3
end if
end if
end if

  res2@gsnStringFont = "helvetica-bold"
  
  res2@cnLevelSelectionMode    = "ExplicitLevels"                        ; set explicit contour levels
  res2@cnLevels                = (/10,20,40,50,60,70,100/)
;  res2@cnFillColors            = (/5,4,3,2,6,7,8/)
  res2@cnFillColors            = (/4,2,15,6,7,8,9/)

  res2@cnLineLabelsOn          = False
  res2@lbLabelBarOn            = False
  res2@cnFillOn                = True                                            ; turn on color fill
  res2@cnFillMode              = "RasterFill"
  res2@cnInfoLabelOn           = False                      ; turn off contour label
  res2@cnLabelMasking          = True
;************************************************

   res2@cnMissingValFillColor   = -1
   if ( region.eq."Tropics") then
      res2@tiMainFontHeightF = .014
      res2@lbBottomMarginF =-.7
   end if
   res2@cnInfoLabelOn = False
   res2@cnLineLabelsOn          = False
   if ((region .eq. "NH") .or. (region .eq. "SH") ) then
      plot = gsn_csm_contour_map_polar(wks,tsplot,res2)
   else
      plot = gsn_csm_contour_map(wks,tsplot,res2)
   end if
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
   else if (region .eq. "Europe") then

;---We're putting tickmarks on all four axes.
      tmres@tmYLValues = ispan(-90,90,15)
      tmres@tmYRValues = ispan(-90,90,15)
      tmres@tmXBValues = ispan(-180,180,15)
      tmres@tmXTValues = ispan(-180,180,15)
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

  scalefactor=0.7
  lbw    = scalefactor * vpw           ; Make labelbar size a fraction of the plot.
  lbh    = scalefactor * vph

  lbres  = True
  lbres@vpWidthF           = lbw     ; labelbar width
  lbres@vpHeightF          = .05     ; labelbar height
  lbres@lbBoxMajorExtentF  = 0.6         ; puts space between color boxes
  lbres@lbOrientation         = "Horizontal"    ; orientation
  lbres@lbAutoManage          = False         ; we control label bar
  lbres@lbFillPattern         = "SolidFill"
  lbres@lbLabelFontHeightF    = 0.012
  lbres@lbFillColors          = res2@cnFillColors
  lbres@lbPerimOn             = False         ; Turn off labelbar perimeter.
  lbres@lbMonoFillPattern     = True          ; one pattern, all solid


  labels = (/"0-10","10-20","20-40","40-50","50-60","60-70","70-100"/)

  nboxes=7
  lbx=tofloat(getenv("lbx"))
  gsn_labelbar_ndc(wks,nboxes,labels,lbx,vpy-vph-0.05,lbres)
  draw(plot)
  frame(wks)
;*******************************************************************
  if ( write .eq. "TRUE" ) then
    
    nlat  = dimsizes(lat)
    nlon  = dimsizes(lon)

    diro = "./files/"                     ; Output directory
    filo = "SPS3.5_"+varname+"_"+varobs+"_"+yyyyfore+mmfore+"_l"+lead+".nc"  ; Output file  
    system("/bin/rm -f " + diro + filo)    ; remove if exists
    fout  = addfile (diro + filo, "c")  ; open output file

    setfileoption(fout,"DefineMode",True)

    fAtt               = True            ; assign file attributes
    fAtt@title         = "Probabilistic forecast"
    fAtt@Conventions   = "CF compliant"
    fAtt@creation_date = systemfunc ("date")
    fileattdef( fout, fAtt )            ; copy file attributes  ; MODIFY

    dimNames = (/"lat", "lon"/)
    dimSizes = (/ nlat,  nlon/)
    dimUnlim = (/False, False/)
    filedimdef(fout,dimNames,dimSizes,dimUnlim)

    filevardef(fout, "lat"  ,typeof(lat),getvardims(lat))  ; MODIFY
    filevardef(fout, "lon"  ,typeof(lon),getvardims(lon))  ; MODIFY
    filevardef(fout, "prob"  ,typeof(prob),getvardims(prob))  ; MODIFY
 

   filevarattdef(fout,"lat"  ,lat)
   filevarattdef(fout,"lon"  ,lon)
   probAtt           = 0
   probAtt@units     = "%"
   probAtt@long_name = "probability forecast "+varobs+" "+tercstr2
   filevarattdef( fout, "prob" , probAtt )

   fout->lat    = (/lat/)
   fout->lon    = (/lon/)
   fout->prob   = (/prob/) 

  end if
;************************************************
   delete(wks)
;***********************************************
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
system( "composite -geometry "+geom_value+" cmcc_logo_bw.jpg "+ plname+".png "+plname+".png")
system( "touch "+plname+"_DONE")

end
