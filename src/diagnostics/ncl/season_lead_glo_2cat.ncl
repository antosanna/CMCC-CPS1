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
  yyyyfore=getenv("yyyy")
  mmfore=getenv("st")
  var=getenv("var")
  print("var "+var)
  SS=getenv("SS")
  nrun=getenv("nrun")
  nmem=toint(nrun)
  mproj=getenv("mproj")
  colormap=getenv("colormap")
  flgmnthtmp=getenv("flgmnth")
  flgmnth=toint(flgmnthtmp)
  fn=getenv("inputm")
  print("inputfile "+fn)
  units=getenv("units")
  print("units "+units)
  in  = addfile(fn,"r")                            ; open netcdf file
  lead=getenv("lead")
  l1=toint(lead)
  monthstr=getenv("monthstr")
  fact=tofloat(getenv("fact"))

  mon_in_sea=3
  template  = in->$var$
  if (flgmnth .eq. 1 ) then
     ts=template(l1,:,:)*fact
     copy_VarMeta(template(l1,:,:),ts)
     flgfreq="m"
  else
     ts=dim_avg_n_Wrap(template(0+l1:mon_in_sea-1+l1,:,:),0)*fact
     if(var.eq."precip")then
        ts=dim_avg_n_Wrap(template(0+l1:mon_in_sea-1+l1,:,:),0)*fact*mon_in_sea
     end if
     copy_VarMeta(template(l1,:,:),ts)
     flgfreq="l"
  end if
  ts@_FillValue = -999.
  if(var.eq."t850")then
     fmask  = getenv("orog")
     in = addfile(fmask,"r")
     maskl=tofloat(in->orog)
     ts@_FillValue = 1.e+20
     ;ts=where(maskl.ge.1400,ts@_FillValue,ts)
     ;copy_VarMeta(template(0,:,:),ts)
     ;ts@_FillValue = 1.e+20
   ;+MB
     orog=where(maskl.gt.1400,-1.,1.)
     orog=where(maskl.eq.1400,0,orog)
     copy_VarMeta(ts,orog)
     orog@_FillValue = 1.e+20   
   ;-MB
   end if

;************************************************
; plot parameters
;************************************************
 
   wks_type=getenv("pltype")
   plname=getenv("plname")
   print("plname"+plname)
   wks  = gsn_open_wks(wks_type,plname)
   gsn_define_colormap(wks,colormap)
   plot = new(2,graphic)                         ; create graphical array
  
  res                      = True                ; make plot mods
  res@gsnDraw              = False               ; don't draw
  res@gsnFrame             = False               ; don't advance frame
  res@gsnMaximize          = True
  res@gsnAddCyclic         = True 
  res@mpProjection         = mproj          ; choose projection
  res@mpGridLineColor      = "Black"
  res@mpGridAndLimbDrawOrder = "PreDraw"

; for t850
  ;if(var.eq."t850")then
  ;  res@cnMissingValFillColor   = "black"          ; color fill missing areas blue
  ;  res@cnMissingValPerimOn     = True            ; already turned on above   
  ;  res@cnMissingValFillPattern = 3               ; set the missing value fill pattern to 5
  ;  res@cnMissingValFillScaleF  = 0.8             ; increase the density of the fill pattern (default=1.0)   
  ;  res@cnMissingValPerimColor  = "black"         ; change the missing value perimeter to black
  ;  res@cnMissingValPerimDashPattern = 0          ; set the dash pattern of the missing value perimeter to 1
  ;  res@cnMissingValPerimThicknessF  = 2.0        ; increase the thickness of the missing value perimeter 3X
  ;end if
;for t850 end

  res@mpFillOn             = False
  res@mpGridAndLimbOn      = False                ; turn on lat/lon lines
  res@mpPerimOn            = False
  res@gsnSpreadColors      = True               ; use full colormap
  res@cnLinesOn            = False               ; turn off contour lines
  res@lbLabelAutoStride    = True                ; automatic lb label stride
  res@mpMinLatF            = -90             ; select subregion
  res@mpMaxLatF            = 90
  res@mpMinLonF            = -180
  res@mpMaxLonF            = 180
  res@mpGridLatSpacingF    = 30
  res@mpGridLonSpacingF    = 60
 res@mpCenterLonF          = 0
  res@mpLandFillColor      = -1
  res@gsnLeftString        = ""            ; left title, remove default
  res@gsnRightString       = ""         ; right title, remove default: C
  res@lbLabelFontHeightF   = 0.012             ; label font height
  res@cnLevelSelectionMode = "ExplicitLevels"; set explicit contour levels
  minf=min(ts)
  maxf=max(ts)

  if(var.eq."t2m") then
     res@cnLevels    = (/-2,-1,-.5,-.2,.2,.5,1,2/)
  else if (var.eq."sst") then
     res@cnLevels    = (/-2,-1,-.5,-.2,.2,.5,1,2/)
  else if (var.eq."precip") then
     res@cnLevels    = (/-200,-100,-50,-20,20,50,100,200/)
  else if (var.eq."mslp") then
     res@cnLevels    = (/-4,-2,-1,-.5,.5,1,2,4/)
 else if (var.eq."z500") then
     res@cnLevels    = (/-60,-40,-20,-10,10,20,40,60/)
  else if (var.eq."u200") then
     res@cnLevels    = (/-10,-8,-5,-2.5,2.5,5,8,10/)
  else if (var.eq."v200") then
     res@cnLevels    = (/-6,-4,-2,-1,1,2,4,6/)
  else if (var.eq."t850") then
     res@cnLevels    = (/-4,-2,-1,-.5,.5,1,2,4/)
  end if
  end if
  end if
  end if
  end if
  end if
  end if
  end if
  res@cnFillColors            = (/5,4,3,2,0,6,7,8,9/)
  res@cnFillOn             = True

;************************************************

   if (flgmnth .eq. 1 ) then
       leadmonth=l1+1
       res@tiMainString         = "Start-date "+yyyyfore+mmfore+" month "+leadmonth+" ("+monthstr+") ~C~           "+var+" anomalies "+units
   else
       res@tiMainString         = "Start-date "+yyyyfore+mmfore+" Lead season "+lead+" ("+SS+") ~C~           "+var+" anomalies "+units
   end if
   res@lbTitleOn        =  True                ; turn on title
   res@lbTitleString    = "min: "+ sprintf("%5.1f", minf) +"~C~max: " + sprintf("%5.1f", maxf) ; title string
   res@lbTitlePosition  = "Right"              ; title position
   res@lbTitleFontHeightF= .012                ; make title smaller
   res@lbTitleDirection = "Across"
  res@cnInfoLabelOn = False
   plot(0)=gsn_csm_contour_map(wks,ts,res)
  res@cnLineLabelsOn=False
  res@lbLabelBarOn = False
;  iplot_hatch_def = gsn_csm_contour(wks,cc(:,:,0),res)
  opt                      = True
  opt@gsnShadeLow         = 6           ; cross hatch pattern
  opt@gsnShadeFillType     = "pattern"
  opt@cnInfoLabelOn=False
  opt@cnLineLabelsOn=False
;  iplot_hatch_def = gsn_contour_shade(iplot_hatch_def,0.3,1.3, opt)
;
;  overlay(plot(0),iplot_hatch_def)




 if(var.eq."t850")then
      res3=True
      res3@gsnFrame            = False       ; Do not advance frome
      res3@gsnDraw             = False
      res3@gsnAddCyclic        = True

      res3@cnFillMode              = "AreaFill"
      res3@cnLevelSelectionMode    = "ExplicitLevels"                        ; set explicit contour levels
      res3@cnLevels                = (/0./)

      res3@cnInfoLabelOn       = False       ; turn off info label

      res3@cnLinesOn           = True       ; do not draw contour lines
      res3@cnLineLabelsOn      = False       ; do not draw contour labels
      res3@gsnLeftString    = ""    ; no titles
      res3@gsnRightString   = ""
      res3@tiXAxisString    = ""
      res3@tiYAxisString    = ""
      res3@gsnContourZeroLineThicknessF = 2.
      res3@mpProjection             = mproj
      res3@cnFillScaleF        = 0.8         ; add extra density
      plot4=gsn_csm_contour(wks,orog,res3)

      opt2                  = True
      opt2@gsnShadeFillType="color" ;"pattern"
      opt2@gsnShadeLow="white"                   ; Use fill Pattern #3
      plot4 = gsn_contour_shade(plot4,0.5,9999., opt2)   ; Shade contours below -5.
      delete(opt2)
      overlay(plot(0),plot4)

      plot5=gsn_csm_contour(wks,orog,res3)
      opt3                  = True
      opt3@gsnShadeFillType = "pattern"
      opt3@gsnShadeLow      = 3
      plot5 = gsn_contour_shade(plot5,0.5,9999.,opt3)
      overlay(plot(0),plot5)
      delete(opt3)

      delete(res3) 
end if


;************************************************
; variable and file handling
;************************************************

;****************here probability data ********************
;   
   prob_up=getenv("prob_up")
   prob_low=getenv("prob_low")
   fnl1 = addfile(prob_low,"r")
   low = fnl1->low33
   fnl1 = addfile(prob_up,"r")
   up = fnl1->up66
;  
fnall=getenv("inputmall")
print("second input file "+fnall)
b=addfile(fnall,"r")
tmp=b->$var$
if (flgmnth .eq. 1 ) then
   sst=tmp(:,l1,:,:)
   copy_VarMeta(tmp(:,l1,:,:),sst)
else 
   sst=dim_avg_n(tmp(:,0+l1:mon_in_sea-1+l1,:,:),1)
   copy_VarMeta(tmp(:,l1,:,:),sst)
end if
delete(tmp)

tsl=sst
tsu=sst
tsn=sst
;tmp=sst(0,:,:)
countl=0
do k=0,nmem-1
   tsl(k,:,:)=where (sst(k,:,:).lt.low,1.,0.)
   tsu(k,:,:)=where(sst(k,:,:).gt.up,1.,0.)
;   tmp=tsl(k,:,:)+tsu(k,:,:)
;   tsn(k,:,:)=where(tmp.eq.0.,1.,0.)
;   delete(tmp)
end do

   tsll=dim_avg_n_Wrap(tsl,0)
   tsuu=dim_avg_n_Wrap(tsu,0)
   tsll=where(tsll .ge. 0.4,tsll*10,ts@_FillValue)
   tsll@_FillValue = 1.e+20
   tsuu=where(tsuu .ge. 0.4,tsuu*1000,ts@_FillValue)
   copy_VarMeta(ts,tsuu)
   copy_VarMeta(ts,tsll)
;************************************************
; plot parameters
;************************************************
  res2                         = True                ; make plot mods
  res2@gsnDraw                 = False               ; don't draw
  res2@gsnFrame                = False        ; don't advance frame
  res2@cnLinesOn               = False
  res2@gsnSpreadColors         = False               ; use full colormap
  res2@gsnMaximize             = True
  res2@gsnAddCyclic             = True
  res2@cnLabelMasking           = True
  res2@mpProjection             = mproj          ; choose projection
  res2@mpGridLineColor          = "Black"
  res2@mpGridAndLimbDrawOrder   = "PreDraw"
  res2@mpFillOn                 = False
  res2@mpPerimOn                = False

  res2@mpMinLatF                = -90             ; select subregion
  res2@mpMaxLatF                = 90
  res2@mpMinLonF                = -180
  res2@mpMaxLonF                = 180
  res2@mpGridLatSpacingF        = 30
  res2@mpGridLonSpacingF        = 60

  res2@cnFillOn                = True     
  res2@cnFillMode              = "CellFill"
  res2@cnMissingValFillColor   = -1


  res2@mpCenterLonF            = 0
  res2@gsnLeftString           = ""                  ; left title, remove default
  res2@gsnRightString          = ""                  ; right title, remove default: C

  res2@cnLevelSelectionMode    = "ExplicitLevels"                        ; set explicit contour levels
  res2@cnLevels                = (/4,5,6,7,39,40,50,60,70,399,400,500,600,700,1000/)       ; set levels
  res2@cnLineLabelsOn          = False
  res2@lbLabelBarOn            = False

  res2@cnInfoLabelOn           = False                      ; turn off contour label
  res2@cnLabelMasking          = True
  res2@cnFillColors            = (/2,2,3,4,5,5,10,11,12,13,13,6,7,8,9,9/)
;************************************************

   res2@tiMainString            = "Probability Forecast"
   res2@cnMissingValFillColor   = -1
   plot(1)=gsn_csm_contour_map(wks,tsll,res2)
   res2@cnMissingValFillColor   = -1
   plot3=gsn_csm_contour(wks,tsuu,res2)
   overlay(plot(1),plot3)
   if(var.eq."t850")then
      res3=True
      res3@gsnFrame            = False       ; Do not advance frome
      res3@gsnDraw             = False
      res3@gsnAddCyclic        = True

      res3@cnFillMode              = "AreaFill"
      res3@cnLevelSelectionMode    = "ExplicitLevels"                        ; set explicit contour levels
      res3@cnLevels                = (/0./)

      res3@cnInfoLabelOn       = False       ; turn off info label

      res3@cnLinesOn           = True       ; do not draw contour lines
      res3@cnLineLabelsOn      = False       ; do not draw contour labels
      res3@gsnLeftString    = ""    ; no titles
      res3@gsnRightString   = ""
      res3@tiXAxisString    = ""
      res3@tiYAxisString    = ""
      res3@gsnContourZeroLineThicknessF = 2.	
      res3@mpProjection             = mproj  
      res3@cnFillScaleF        = 0.8         ; add extra density
      plot4=gsn_csm_contour(wks,orog,res3)
      printVarSummary(orog)
      printMinMax(orog,1)
      opt2                  = True
      opt2@gsnShadeFillType="color" ;"pattern"
      opt2@gsnShadeLow="white"                   ; Use fill Pattern #3
      plot4 = gsn_contour_shade(plot4,0.5,9999., opt2)   ; Shade contours below -5. 
      overlay(plot(1),plot4)
      
      plot5=gsn_csm_contour(wks,orog,res3)
      opt3                  = True
      opt3@gsnShadeFillType = "pattern"
      opt3@gsnShadeLow      = 3    
      plot5 = gsn_contour_shade(plot5,0.5,9999.,opt3)   
      overlay(plot(1),plot5)

   end if

   getvalues plot(1)                ; get plot size for use in creating labelbar
  "vpXF"      : vpx
  "vpYF"      : vpy
  "vpHeightF" : vph
  "vpWidthF"  : vpw
  end getvalues

  scalefactor=0.2
  lbw    = scalefactor * vpw           ; Make labelbar size a fraction of the plot.
  lbh    = scalefactor * vph

   lbres                       = True
   lbres@vpWidthF           = scalefactor * vpw     ; labelbar width
   lbres@vpHeightF          = scalefactor * vph     ; labelbar height
   lbres@lbBoxMajorExtentF  = 0.75         ; puts space between color boxes
   lbres@lbOrientation         = "Horizontal"    ; orientation
   lbres@lbAutoManage          = False         ; we control label bar
   lbres@lbFillPattern         = "SolidFill"
   lbres@lbLabelFontHeightF    = 0.008
   lbres@lbFillColors          = (/2,3,4,5/)
   lbres@lbPerimOn             = False         ; Turn off labelbar perimeter.
   lbres@lbMonoFillPattern     = True          ; one pattern, all solid
   lbres@lbTitleOn               = True
   lbres@lbTitlePosition         = "Bottom"
   lbres@lbTitleFontHeightF      = 0.015               ; label font height
   lbres@lbTitleString           = "Below lower tercile"

   ;lbres@lbFillPatterns        = (/3,4,5,6/)
   lbres@lbFillPatterns        = (/4,5,6,7/)

   labels = (/40,50,60,70/)

   gsn_labelbar_ndc(wks,4,labels,vpx+vph-lbw-0.125,0.1,lbres)


   delete(lbres@lbFillColors)
   delete(lbres@lbFillPatterns)
   lbres@lbFillColors  =  (/6,7,8,9,9/)
   lbres@lbFillPatterns = (/400,500,600,700,1000/)

   lbres@lbLabelFontHeightF    = 0.008
   lbres@lbTitleOn               = True
   lbres@lbTitlePosition         = "Bottom"
   lbres@lbTitleFontHeightF      = 0.015               ; label font height
   lbres@lbTitleString           = "Above upper tercile"

   gsn_labelbar_ndc(wks,4,labels,vpx+vph-lbw+0.375,0.1,lbres)
;************************************************
   gsn_panel(wks,plot,(/2,1/),False)
;   frame(wks)
   delete(wks)
;***********************************************
  checkfile=getenv("checkfile")
  system("touch "+checkfile)
end
