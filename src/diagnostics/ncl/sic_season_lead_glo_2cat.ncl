;************************************************
;load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
;load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl" 
;load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
;************************************************
begin
;************************************************
; plot parameters
;************************************************
;************************************************
; variable and file handling
;************************************************
  yyyyfore=getenv("yyyyfore")
  mmfore=getenv("mmfore")
  SS=getenv("SS")
  nrun=getenv("nrun")
  nmem=toint(nrun)
  mproj=getenv("mproj")
  flgmnthtmp=getenv("flgmnth")
  flgmnth=toint(flgmnthtmp)
  fn=getenv("inputm")
  in  = addfile(fn,"r")                            ; open netcdf file
  lead=getenv("lead")
  l1=toint(lead)
  monthstr=getenv("monthstr")
  template  = in->sic(:,:,:)                            ; read in variabl
  if (flgmnth .eq. 1 ) then
    sic=template(l1,:,:)
    flgfreq="m"
  else 
    sic=dim_avg_n_Wrap(template(0+l1:2+l1,:,:),0)
    flgfreq="l"
  end if
  fmask  = getenv("fmask")
  in  = addfile(fmask,"r")                            ; open netcdf file
  maskl=tofloat(in->LANDFRAC(0,:,:))  
  tmp=maskl
  maskl=where(maskl.lt.0.5,1.,1.e+20)
  maskl@_FillValue = 1.e+20
  copy_VarMeta(tmp,maskl)
  copy_VarMeta(template(0,:,:),sic)
  sic@_FillValue = 1.e+20
  
;************************************************
; polar projection plot
;************************************************
wks_type="png"
plname=getenv("plname")
wks  = gsn_open_wks(wks_type,plname)
plot = new(1,graphic)  
res                       = True

;---Maximize plot in frame
res@gsnMaximize           = True

res@gsnDraw  = False                          ; don't draw
res@gsnFrame = False                          ; don't advance frame
res@cnLinesOn  = False
res@cnFillOn   = True

res@cnExplicitLabelBarLabelsOn=True
res@lbLabelBarOn=False
res@lbLabelFontHeightF   = 0.012
res@gsnTickMarksOn = False 
res@mpMinLatF=50
res@mpGridAndLimbOn=False

res@cnFillColors         = (/"steelblue1","gold1","green4","olivedrab1","lightslateblue", "lightskyblue1","white"/)

res@cnFillDrawOrder       = "PreDraw"  

res@lbLabelBarOn=False
res@lbLabelFontHeightF   = 0.012
res@cnExplicitLabelBarLabelsOn=True
res@cnLevelSelectionMode="ExplicitLevels"
res@cnLevels     = (/15,30,45,60,75,90/)
res@cnMissingValFillColor="light grey"
res@gsnLeftString=""
res@gsnRightString=""
res@lbBoxEndCapStyle = "TriangleBothEnds"

res@mpOutlineOn               = True
res@mpDataBaseVersion         = "MediumRes"       ; default is "LowRes"
  
res@sfXArray                  = lon2d
res@sfYArray                  = lat2d
res@gsnAddCyclic              = False

plot(0) = gsn_csm_contour_map_polar(wks,sic*100,res)

resP  = True
resP@gsnFrame         = False                  ; don't advance panel plot
resP@gsnPanelLabelBar = True                   ; add common colorbar
resP@lbLabelFontHeightF =.01
resP@lbOrientation ="Vertical"

resP@gsnPanelXWhiteSpacePercent=5
resP@gsnPanelYWhiteSpacePercent=3

if (flgmnth .eq. 1 ) then
  leadmonth=l1+1
  res@gsnPanelMainString         = "Start-date "+yyyyfore+mmfore+" Lead month "+leadmonth+" ("+monthstr+") ~C~             SIC anomalies [~S~o~N~C]"
else
  res@gsnPanelMainString         = "Start-date "+yyyyfore+mmfore+" Lead season "+lead+" ("+SS+") ~C~             SIC anomalies [~S~o~N~C]"
end if
resP@gsnPanelFigureStringsFontHeightF=0.0095
resP@gsnPanelFigureStringsPerimOn=False
resP@gsnPanelFigureStringsBackgroundFillColor="transparent"
resP@amJust   = "BottomRight"
resP@gsnPanelRowSpec = True

gsn_panel(wks,plot,(/1,1/),resP)
frame(wks)

;************************************************
; plot parameters
;************************************************
;   wks_type="png"
;   plname=getenv("plname")
;   wks  = gsn_open_wks(wks_type,plname)
;   gsn_define_colormap(wks,"prob_t2m")
;   plot = new(1,graphic)                          ; create graphical array
;   res                      = True                ; make plot mods
;   res@gsnDraw              = False               ; don't draw
;   res@gsnFrame             = False               ; don't advance frame
;   res@gsnMaximize          = True
;   res@gsnAddCyclic         = True 
;   res@mpProjection         = mproj          ; choose projection
;   res@mpFillOn             = False
;   res@mpGridAndLimbOn      = False                ; turn on lat/lon lines
;   res@mpPerimOn            = False
;   res@gsnSpreadColors      = True               ; use full colormap
;   res@cnLinesOn            = False               ; turn off contour lines
;   res@lbLabelAutoStride    = True                ; automatic lb label stride
;   res@mpMinLatF            = -90                ; select subregion
;   res@mpMaxLatF            = 90
;   res@mpMinLonF            = -180
;   res@mpMaxLonF            = 180
;   res@mpGridLatSpacingF    = 30
;   res@mpGridLonSpacingF    = 60
;   res@mpCenterLonF          = 0
;   res@mpLandFillColor      = -1
;   res@gsnLeftString        = ""            ; left title, remove default
;   res@gsnRightString       = ""         ; right title, remove default: C
;   res@lbLabelFontHeightF   = 0.012             ; label font height
;   res@cnLevelSelectionMode = "ExplicitLevels"; set explicit contour levels
;   minf=0
;   maxf=1

;   res@cnLevels             = (/-2,-1,-.5,-.2,.2,.5,1,2/)
;   res@cnFillColors         = (/5,4,3,2,0,6,7,8,9/)
;   res@cnFillOn             = True

; ;************************************************

;   if (flgmnth .eq. 1 ) then
;     leadmonth=l1+1
;     res@tiMainString         = "Start-date "+yyyyfore+mmfore+" Lead month "+leadmonth+" ("+monthstr+") ~C~             SIC anomalies [~S~o~N~C]"
;   else
;     res@tiMainString         = "Start-date "+yyyyfore+mmfore+" Lead season "+lead+" ("+SS+") ~C~             SIC anomalies [~S~o~N~C]"
;   end if
;   res@lbTitleOn        =  True                ; turn on title
;   res@lbTitleString    = "min: "+ sprintf("%5.1f", minf) +"~C~max: " + sprintf("%5.1f", maxf) ; title string
;   res@lbTitlePosition  = "Right"              ; title position
;   res@lbTitleFontHeightF= .012                ; make title smaller
;   res@lbTitleDirection = "Across"
;   res@cnInfoLabelOn = False
;   plot(0)=gsn_csm_contour_map(wks,sic,res)
;   res@cnLineLabelsOn=False
;   res@lbLabelBarOn = False
; ;  iplot_hatch_def = gsn_csm_contour(wks,cc(:,:,0),res)
;   opt                      = True
;   opt@gsnShadeLow         = 6           ; cross hatch pattern
;   opt@gsnShadeFillType     = "pattern"
;   opt@cnInfoLabelOn=False
;   opt@cnLineLabelsOn=False
; ;  iplot_hatch_def = gsn_contour_shade(iplot_hatch_def,0.3,1.3, opt)
; ;
; ;  overlay(plot(0),iplot_hatch_def)
;************************************************
;    gsn_panel(wks,plot,(/1,1/),False)
; ;   frame(wks)
;    delete(wks)
;***********************************************
  checkfile=getenv("checkfile")
  system("touch "+checkfile)
end
