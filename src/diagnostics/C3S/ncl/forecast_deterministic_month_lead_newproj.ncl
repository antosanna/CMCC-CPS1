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
write="FALSE"
yyyyfore=getenv("yyyyfore")
mmfore=getenv("mmfore")
SS=getenv("SS")
inputm=getenv("inputm")
inputmall=getenv("inputmall")
in  = addfile(inputm,"r")                            ; open netcdf file
lead=getenv("lead")
diagtype=getenv("diagtype")
varm=getenv("varname")
varobs=getenv("varobs")

inputmclim=getenv("inputclim_mm") ;"/work/csp/sp2/SPS3.5/CESM/monthly/"+varobs+"/C3S/clim/"+varobs+"_SPS3.5_clim_1993-2016."+mmfore+".nc"
inclim = addfile(inputmclim,"r")

strvar=getenv("strvar")
;---------
dirplots=getenv("dirplots")

ensmColormap=getenv("ensmColormap")
spreadColormap=getenv("spreadColormap")
minlat=tofloat(getenv("minlat"))
maxlat=tofloat(getenv("maxlat"))
minlon=tofloat(getenv("minlon"))
maxlon=tofloat(getenv("maxlon"))
proj=getenv("proj")
bnd=getenv("bnd")
region=getenv("region")

; AA +
; if ( region .eq. "global" ) then
;    write="TRUE"
; end if
; AA -

l1=toint(lead)
if ( varm .eq. "zg" ) .or. ( varm .eq. "ta" ) .or. ( varobs .eq. "u200" ) .or. ( varobs .eq. "v200" ) then
	  template  = in->$varm$(:,0,:,:)                            ; read in variabl
else if (varm .eq. "mrlsl" ) then
   templateclim=inclim->$varm$
   tmp  = in->$varm$
   template = tmp/templateclim*100
   copy_VarMeta(tmp,template)
   delete(tmp)
else
	  template  = in->$varm$(:,:,:)                            ; read in variabl
end if
end if
tstmp=template(l1,:,:)
lat=in->lat
lon=in->lon
tstmp@_FillValue = -999.
b=addfile(inputmall,"r")
;#######
if ( varobs .eq. "sst" ) then 
   tstmp@_FillValue = 1.e+20
   tmp=where(template.gt.10 .or. template.lt.-10 ,template@_FillValue,template)
   copy_VarMeta(template,tmp)
   ts=tmp(l1,:,:)
   ts@_FillValue = 1.e+20
   copy_VarMeta(template(0,:,:),ts)
   sstorig=b->$varm$(:,0,:,:)
   ssttmp=b->$varm$(:,l1,:,:)
   ssttmp@_FillValue=1.e+20
   sst=where(ssttmp.gt.20 .or. ssttmp.lt.-20,1.e+20,ssttmp)
   sstspread=dim_stddev_n(sst,0)
   sstspread@_FillValue=1.e+20
   copy_VarMeta(sstorig(0,:,:),sstspread)
else if ( varobs .eq. "z500" ) .or. ( varobs .eq. "t850" ) .or. ( varobs .eq. "u200" ) .or. ( varobs .eq. "v200" ) then
     ts=tstmp
     copy_VarMeta(tstmp,ts)
     sst=b->$varm$(:,l1,0,:,:)
     sstspread=dim_stddev_n(sst,0)
     sstspread@_FillValue=-9999.
     copy_VarMeta(template(0,:,:),sstspread)
else
   if (varobs .eq. "precip") then
      ts=tstmp*30
      copy_VarMeta(tstmp,ts)
      sst=b->$varm$(:,l1,:,:)*30
   else if (varobs .eq. "mrlsl") then
      ts=tstmp
      tmp=b->$varm$
      N=dimsizes(tmp)
      nmem=N(0)
      ntim=N(1)
      nlat=N(2)
      nlon=N(3)
      delete(tmp)
      ;ssttmp=new((/nmem,nlat,nlon/),float)
      sst=new((/nmem,nlat,nlon/),float)
      ssttmp=b->$varm$(:,l1,:,:)
      sstclim=templateclim(l1,:,:)
      do e=0,nmem-1
         sst(e,:,:)=ssttmp(e,:,:)/sstclim*100
      end do
   else
      ts=tstmp
      copy_VarMeta(tstmp,ts)
      sst=b->$varm$(:,l1,:,:)
   end if
   end if
   sstspread=dim_stddev_n(sst,0)
   sstspread@_FillValue=-9999.
   copy_VarMeta(template(0,:,:),sstspread)
end if
end if
;***********************************************************
; set units for netCDF files
;***********************************************************
if ( varobs.eq."sst" .or. varobs.eq."t2m" .or. varobs.eq."t850") then
   units="degC"
else if ( varobs.eq."mrlsl") then
   units="[%]"   ;"[mm~S~3~N~"+"/"+"mm~S~3~N~]"
else if ( varobs.eq."precip") then
   units=""
else if (varobs.eq."mslp") then
   units=""
else if (varobs.eq."u200" .or. varobs.eq."v200") then
   units="m/s"
else
   units=""
end if
end if
end if
end if
end if
   
wks_type=getenv("wks_type")
;************************************************
; plot parameters
;************************************************
if (diagtype .eq. "ensmean") then
   pltype="ens_anom"
   vardiag=ts
else
   pltype="spread"
   vardiag=sstspread
end if

plname=dirplots+"/"+varobs+"_"+region+"_"+pltype+"_"+yyyyfore+"_"+mmfore+"_monthly_l"+lead
wks  = gsn_open_wks(wks_type,plname)

if (diagtype .eq. "ensmean") then
   gsn_define_colormap(wks,ensmColormap)
else
   gsn_define_colormap(wks,spreadColormap)
end if

res2                      = True                ; make plot mods

res2@gsnDraw                 = False               ; don't draw
res2@gsnFrame                = False        ; don't advance frame
res2@cnLinesOn               = False
res2@gsnSpreadColors         = False               ; use full colormap
res2@gsnMaximize             = True
res2@mpGeophysicalLineThicknessF = 2

if ( region .eq. "global" ) then
   res2@gsnDraw             = False
   res2@gsnFrame            = False
   res2@gsnMaximize         = True
   res2@mpCenterLonF         = 0

   res2@tiMainOffsetYF      = -0.02   ;05
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
   res2@mpFillOn             = False
   res2@gsnMaximize          = False
   res2@gsnPolar             = "NH"
   res2@tiMainOffsetYF      = 0.05
else if ( region .eq. "SH" ) then
   res2@mpFillOn             = False
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
   
   res2@tiMainOffsetYF      = 0.05
   res2@gsnPaperOrientation  = "landscape"
   res2@gsnMaximize          = True
   res2@tmXBLabelFontHeightF = 0.008
   res2@tmYLLabelFontHeightF = 0.008
   res2@pmLabelBarWidthF     = 0.3               ; default is shorter
   res2@pmLabelBarHeightF    = 0.05               ; default is taller
   res2@pmLabelBarOrthogonalPosF = .03 
   res2@lbLabelFontHeightF   = 0.01
   res2@pmTickMarkDisplayMode = "Always"
   res2@mpShapeMode          = "FreeAspect"
   res2@vpWidthF             = 0.35
   res2@vpHeightF            = 0.25
   res2@mpGridLatSpacingF        = 15
   res2@mpGridLonSpacingF        = 15
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
   res2@tiMainOffsetYF      = 0.001
end if
end if
end if
end if
res2@cnLabelMasking           = True

if (region .eq. "Tropics") then
    res2@mpGridAndLimbOn          = False                ; turn on lat/lon lines   
end if

res2@mpMinLatF                = minlat
res2@mpMaxLatF                = maxlat
res2@mpMinLonF                = minlon
res2@mpMaxLonF                = maxlon


res2@cnMissingValFillColor   = -1
res2@gsnLeftString           = ""
res2@gsnRightString          = ""
res2@gsnCenterString         = "" 
res2@tiMainString            = "Start-date "+mmfore+"-"+yyyyfore+" forecast month "+lead+" ("+SS+")~C~ ~Z75~                          "+strvar

if ( region .eq. "global" ) then
   res2@gsnCenterStringFontHeightF  = 0.014
else if ( region .eq. "NH" .or. region .eq. "SH" ) then
   res2@gsnCenterStringFontHeightF  = 0.02
else if ( region .eq. "Europe") then
   res2@gsnCenterStringFontHeightF  = 0.0102
   res2@gsnCenterStringOrthogonalPosF = 0.1
else
   res2@gsnCenterStringFontHeightF  = 0.0102   ;0.014  
   res2@gsnCenterStringOrthogonalPosF = 0.3
end if
end if
end if

res2@gsnStringFont = "helvetica-bold"

res2@cnLevelSelectionMode = "ExplicitLevels"; set explicit contour levels
res2@lbLabelFontHeightF      = 0.008     ; regola la dimensione delle label della barra

if (diagtype .eq. "ensmean") then
   if ( varobs .eq. "t2m") then
      res2@cnLevels=(/-2,-1,-.5,0.,.5,1,2/)
      res2@cnFillColors=(/5,4,3,2,6,7,8,9/)
   else if ( varobs .eq. "sst" ) then
      res2@cnLevels=(/-2,-1,-.5,-0.2,0.2,.5,1,2/)
      res2@cnFillColors=(/5,4,3,2,-1,6,7,8,9/)
   else if ( varobs .eq. "t850" ) then
      res2@cnLevels=(/-2,-1,-.5,0.,.5,1,2/)
      res2@cnFillColors=(/5,4,3,2,6,7,8,9/)
   else if (varobs .eq. "z500" ) then
      res2@cnLevels=(/-40,-20,-10,-5,5,10,20,40/)
      res2@cnFillColors=(/5,4,3,2,6,7,8,9,10/)
   else if (varobs .eq. "mslp" ) then
      res2@cnLevels=(/-4,-2,-1,-0.5,0.5,1,2,4/)
      res2@cnFillColors=(/5,4,3,2,6,7,8,9,10/)
   else if (varobs .eq. "mrlsl" ) then
      res2@cnLevels=(/-25,-12,-8,-4,-1,0,1,4,8,12,25/)
      res2@cnFillColors=(/20,18,16,14,12,-1,-1,10,8,6,5,4,3/)
   else if (varobs.eq."u200") then
      res2@cnLevels= (/-8,-5,-2.5,-1,1,2.5,5,8/)
      res2@cnFillColors= (/5,4,3,2,6,7,8,9,10/)
   else if (varobs.eq."v200") then
      res2@cnLevels= (/-7,-5,-3,-1,1,3,5,7/)
      res2@cnFillColors= (/5,4,3,2,6,7,8,9,10/)
   else
      res2@cnLevels=(/-200,-100,-50,-10,10,50,100,200/)
      res2@cnFillColors=(/5,4,3,2,-1,6,7,8,9/)
   end if
   end if
   end if
   end if
   end if
   end if
   end if
   end if
else
   if ( varobs .eq. "t2m") then
      res2@cnLevels=(/0.25,0.75,1.25,1.85,2.25,2.75,3.25/)
      res2@cnFillColors=(/2,16,13,12,11,10,8,6,4/)
   else if ( varobs .eq. "sst" ) then
      ;res2@cnLevels=(/0.25,0.75,1.25,1.85,2.25,2.75,3.25/)
      res2@cnLevels=(/0.125,0.375,0.625,0.875,1.125,1.375,1.625,1.875/) ; 2.25,2.75,3.25/)
      res2@cnFillColors=(/2,16,13,12,11,10,8,6,4/)
   else if ( varobs .eq. "t850" ) then
      res2@cnLevels=(/0.25,0.75,1.25,1.85,2.25,2.75,3.25/)
      res2@cnFillColors=(/2,16,13,12,11,10,8,6/)
   else if (varobs .eq. "z500" ) then
      res2@cnLevels=(/5,15,25,35,45,55,65/)
      res2@cnFillColors=(/2,16,13,12,11,10,8,6/)
   else if (varobs .eq. "mslp" ) then
      res2@cnLevels=(/0.5,1.5,2.5,3.5,4.5,5.5,6.5/)
      res2@cnFillColors=(/2,16,13,12,11,10,8,6/)
   else if (varobs .eq. "mrlsl" ) then
      ;res2@cnLevels=(/0.01,0.02,0.03,0.04,0.05,0.06,0.07,0.09,0.1/)
      res2@cnLevels=(/10,20,30,40,50,60,70,80,90/)
      res2@cnFillColors=(/2,16,13,12,11,10,8,6,4/)
   else if (varobs .eq. "u200" ) then
      res2@cnLevels=(/1,2,3,4,5,6,7/)
      res2@cnFillColors=(/2,16,13,12,11,10,8,6/)
   else if (varobs .eq. "v200" ) then
      ;res2@cnLevels=(/1,1.5,2,2.5,3,3.5,4/)
      res2@cnLevels=(/1,2,3,4,5,6,7/)
      res2@cnFillColors=(/2,16,13,12,11,10,8,6/)
   else
      res2@cnLevels=(/12.5,37.5,62.5,87.5,112.5,137.5,162.5,187.5/)
      res2@cnFillColors=(/2,16,13,12,11,10,8,6,4/)
   end if
   end if
   end if
   end if
   end if
   end if
   end if
   end if
end if
res2@cnLineLabelsOn          = False
res2@lbLabelBarOn            = False ;True   ;False for boxes
res2@cnFillOn                = True                       ; turn on color fill
;res2@cnFillMode              = "RasterFill"
res2@cnInfoLabelOn           = False                      ; turn off contour label
res2@cnLabelMasking          = True
res2@cnFillOn                 = True

;************************************************

   if ( region.eq."Tropics") then
      res2@tiMainFontHeightF = .014
      res2@lbBottomMarginF =-.7
   end if
   res2@cnInfoLabelOn = False
   res2@cnLineLabelsOn          = False
   if ((region .eq. "NH") .or. (region .eq. "SH")) then
      plot = gsn_csm_contour_map_polar(wks,vardiag,res2)
   else 
      plot=gsn_csm_contour_map(wks,vardiag,res2)
   end if
; add labelbar to second plot
;**********************************************************
   tmres    = True

;---Set the values you want for the map tickmarks.
   tmres@tmXBLabelFontHeightF = 0.009         ; Default is a bit large

   if (region .eq. "global" ) then

;---We're putting tickmarks on all four axes.
      tmres@tmYLValues = ispan(-90,90,30)
      tmres@tmYRValues = ispan(-90,90,30)
      tmres@tmXBValues = ispan(-180,180,30)
      tmres@tmXTValues = ispan(-180,180,30)
      map = add_map_tickmarks2(wks,plot,tmres) 
   else if ( region .eq. "Europe" ) then

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

   lbres                       = True
   if ( varobs .eq. "precip" ) then
       lbres@vpWidthF           = 0.6  ;lbw     ; labelbar width
       lbres@lbLabelFontHeightF = 0.009
   else if ( varobs .eq. "mrlsl" ) then
       lbres@vpWidthF           = 0.6  ;lbw     ; labelbar width
       lbres@lbLabelFontHeightF = 0.008
   else
       lbres@vpWidthF          = lbw     ; labelbar width
       lbres@lbLabelFontHeightF    = 0.012
   end if
   end if
   lbres@vpHeightF             = .05     ; labelbar height
   lbres@lbBoxMajorExtentF     = 0.6         ; puts space between color boxes
   lbres@lbOrientation         = "Horizontal"    ; orientation
   lbres@lbAutoManage          = False         ; we control label bar
   lbres@lbFillPattern         = "SolidFill"  
   lbres@lbFillColors          = res2@cnFillColors
   lbres@lbPerimOn             = False         ; Turn off labelbar perimeter.
   lbres@lbMonoFillPattern     = True          ; one pattern, all solid


   
   if (diagtype .eq. "ensmean") then
      if ( (varobs .eq. "t2m") .or. (varobs .eq. "t850") ) then
         labels=(/"<-2","-2:-1","-1:-0.5","-0.5:0","0:0.5","0.5:1","1:2",">2"/)
         nboxes=8
      else if (varobs .eq. "sst")  then
         labels=(/"<-2","-2:-1","-1:-0.5","-0.5:-0.2","-0.2:0.2","0.2:0.5","0.5:1","1:2",">2"/)
         nboxes=9
      else if (varobs .eq. "z500" ) then
         labels=(/"<-40","-40:-20","-20:-10","-10:-5","-5:5","5:10","10:20","20:40",">40"/)
         nboxes=9
      else if (varobs .eq. "u200" ) then
         labels=(/"<-8","-8:-5","-5:-2.5","-2.5:-1","-1:1","1:2.5","2.5:5","5:8",">8"/)
         nboxes=9
      else if (varobs .eq. "v200" ) then
         labels=(/"<-4","-4:-2","-2:-1","-1:-0.5","-0.5:0.5","0.5:1","1:2","2:4",">4"/)
         nboxes=9
      else if (varobs .eq. "mslp" ) then
         labels=(/"<-4","-4:-2","-2:-1","-1:-0.5","-0.5:0.5","0.5:1","1:2","2:4",">4"/)
         nboxes=9
      else if (varobs .eq. "mrlsl" ) then
         ;labels=(/"<-0.07","<-0.07:-0.05","-0.05:-0.03","-0.03:-0.01","-0.01:0.01","0.01:0.03","0.03:0.05","0.05:0.07",">0.07"/)
         labels=(/"<-24","-24:-12","-12:-8","-8:-4","-4:4","4:8","8:12","12:24",">24"/)
         nboxes=9
      else
         labels=(/"<-200","-200:-100","-100:-50","-50:-10","-10:10","10:50","50:100","100:200",">200"/)
         nboxes=9
      end if
      end if
      end if
      end if
      end if
      end if
      end if

   else
      if ( (varobs .eq. "t2m") .or. (varobs .eq. "t850") ) then
         labels=(/"0-0.5","0.5-1","1-1.5","1.5-2","2-2.5","2.5-3","3-3.5",">3.5"/)
         nboxes=8
      else if ( varobs .eq. "sst") then
         labels=(/"0-0.25","0.25-0.5","0.5-0.75","0.75-1","1-1.25","1.25-1.5","1.5-1.75",">1.75"/)
         nboxes=8
      else if (varobs .eq. "z500" ) then
         labels=(/"0-10","10-20","20-30","30-40","40-50","50-60","60-70",">70"/)
         nboxes=8
      else if (varobs .eq. "u200" ) then
         labels=(/"0-1","1-2","2-3","3-4","4-5","5-6","6-7",">7"/)
         nboxes=8
      else if (varobs .eq. "v200" ) then
         ;labels=(/"0.5-1","1-1.5","1.5-2","2-2.5","2.5-3","3-3.5","3.5-4",">4"/)
         labels=(/"0-1","1-2","2-3","3-4","4-5","5-6","6-7",">7"/)
         nboxes=8
      else if (varobs .eq. "mslp" ) then
         labels=(/"0-1","1-2","2-3","3-4","4-5","5-6","6-7",">7"/)
         nboxes=8
      else if (varobs .eq. "mrlsl" ) then
         ;labels=(/"0.01-0.02","0.02-0.03","0.03-0.04","0.04-0.05","0.05-0.06","0.06-0.07","0.07-0.08","0.08-0.09","0.09-0.1"/)
         labels=(/"10-20","20-30","30-40","40-50","50-60","60-70","70-80","80-90",">90"/)
         nboxes=9
      else
         labels=(/"0-25","25-50","50-75","75-100","100-125","125-150","150-175","175-200",">200"/)
         nboxes=9
      end if
      end if
      end if
      end if
      end if
      end if
      end if
   end if
  print("end SST diag 4")
  system("date")
   
  lbx=tofloat(getenv("lbx"))
  gsn_labelbar_ndc(wks,nboxes,labels,lbx,vpy-vph-0.05,lbres)
  draw(plot)
  frame(wks)
;*******************************************************************
  if ( write .eq. "TRUE" ) then

    nlat  = dimsizes(lat)
    nlon  = dimsizes(lon)

    diro = "./files/"                     ; Output directory
    filo = "SPS3.5_"+diagtype+"_"+varobs+"_"+yyyyfore+mmfore+"_l"+lead+".nc"  ; Output file
    system("/bin/rm -f " + diro + filo)    ; remove if exists
    fout  = addfile (diro + filo, "c")  ; open output file

    setfileoption(fout,"DefineMode",True)

    fAtt               = True            ; assign file attributes
    fAtt@title         = diagtype
    fAtt@Conventions   = "CF compliant"
    fAtt@creation_date = systemfunc ("date")
    fileattdef( fout, fAtt )            ; copy file attributes  ; MODIFY

    dimNames = (/"lat", "lon"/)
    dimSizes = (/ nlat,  nlon/)
    dimUnlim = (/False, False/)
    filedimdef(fout,dimNames,dimSizes,dimUnlim)

    filevardef(fout, "lat"  ,typeof(lat),getvardims(lat))  ; MODIFY
    filevardef(fout, "lon"  ,typeof(lon),getvardims(lon))  ; MODIFY
    filevardef(fout, varobs  ,typeof(vardiag),getvardims(vardiag))  ; MODIFY


   filevarattdef(fout,"lat"  ,lat)
   filevarattdef(fout,"lon"  ,lon)
   probAtt           = 0
   probAtt@units     = units
   probAtt@long_name = varobs+" "+diagtype
   filevarattdef( fout, varobs , probAtt )

   fout->lat    = (/lat/)
   fout->lon    = (/lon/)
   fout->$varobs$ = (/vardiag/)

  end if
;************************************************
   delete(wks)
;***********************************************
if ( region .eq. "global" ) then
   geom_value="80x80+930+830" 
else if ( region .eq. "NH" .or. region .eq. "SH" ) then
  geom_value=" 80x80+930+880" 
else if ( region .eq. "Europe") then
  geom_value=" 80x80+930+900" 
else
   geom_value="80x80+930+660"
end if
end if
end if
system("pwd")
print(plname+".png")
;system( "composite -geometry "+geom_value+" cmcc_logo_bw.jpg "+plname+".png "+plname+".png")
system( "touch "+plname+"_DONE")

end
