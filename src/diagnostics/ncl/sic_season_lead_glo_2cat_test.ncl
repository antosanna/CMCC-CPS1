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
  yyyyfore="2013"
  mmfore="09"
  nrun="40"
  nmem=toint(nrun)
  mproj="CylidricalEquidistant"
  flgmnthtmp="1"
  flgmnth=toint(flgmnthtmp)
  fn="/work/csp/sp1/scratch/SPS3.5/CESM/monthly/sst/C3S/anom/sst_SPS3.5_sps3.5_201309_ens_ano.1993-2016.nc"
  in  = addfile(fn,"r")                            ; open netcdf file
  lead="0"
  l1=toint(lead)
  monthstr="September"
  template  = in->tso(:,:,:)                            ; read in variabl
  if (flgmnth .eq. 1 ) then
     sst=template(l1,:,:)
     flgfreq="m"
  else 
     sst=dim_avg_n_Wrap(template(0+l1:2+l1,:,:),0)
     flgfreq="l"
  end if
  fmask  = "/work/csp/sp1/CESMDATAROOT/CMCC-SPS3.5/files4SPS3.5/landfrac_1x1.nc"
  in  = addfile(fmask,"r")                            ; open netcdf file
  maskl=tofloat(in->LANDFRAC(0,:,:))  
  tmp=maskl
  maskl=where(maskl.lt.0.5,1.,1.e+20)
  maskl@_FillValue = 1.e+20
  copy_VarMeta(tmp,maskl)
  copy_VarMeta(template(0,:,:),sst)
  sst@_FillValue = 1.e+20
  
;************************************************

; plot parameters
;************************************************
 
   wks_type="png"
   plname="/work/csp/sp1/scratch/201309/diag/lead//sst_ano_forecast_glo_201309_m1"
   wks  = gsn_open_wks(wks_type,plname)
   gsn_define_colormap(wks,"prob_t2m")
   plot = new(2,graphic)                         ; create graphical array
  res                      = True                ; make plot mods
  res@gsnDraw              = False               ; don't draw
  res@gsnFrame             = False               ; don't advance frame
  res@gsnMaximize          = True
  res@gsnAddCyclic         = True 
  res@mpProjection         = mproj          ; choose projection
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
  minf=min(sst)
  maxf=max(sst)

  res@cnLevels    = (/-2,-1,-.5,-.2,.2,.5,1,2/)
  res@cnFillColors            = (/5,4,3,2,0,6,7,8,9/)
  res@cnFillOn             = True

;************************************************

   if (flgmnth .eq. 1 ) then
       leadmonth=l1+1
       res@tiMainString         = "Start-date "+yyyyfore+mmfore+" Lead month "+leadmonth+" ("+monthstr+") ~C~             SST anomalies [~S~o~N~C]"
   else
       res@tiMainString         = "Start-date "+yyyyfore+mmfore+" Lead season "+lead+" ("+SS+") ~C~             SST anemalies [~S~o~N~C]"
   end if
   res@lbTitleOn        =  True                ; turn on title
   res@lbTitleString    = "min: "+ sprintf("%5.1f", minf) +"~C~max: " + sprintf("%5.1f", maxf) ; title string
   res@lbTitlePosition  = "Right"              ; title position
   res@lbTitleFontHeightF= .012                ; make title smaller
   res@lbTitleDirection = "Across"
  res@cnInfoLabelOn = False
   plot(0)=gsn_csm_contour_map(wks,sst,res)
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

;************************************************
; variable and file handling
;************************************************

;****************here probability data ********************
;   
   pathterc="/work/csp/sp2/SPS3.5/CESM/pctl/"
   prob_up=pathterc+"sst_"+mmfore+"_l"+lead+"_33.nc"
   fnl1 = addfile(prob_up,"r")
   low = fnl1->low33
   prob_low=pathterc+"sst_"+mmfore+"_l"+lead+"_66.nc"
   fnl1 = addfile(prob_low,"r")
   up = fnl1->up66
;  
fnall="/work/csp/sp1/scratch/SPS3.5/CESM/monthly/sst/C3S/anom/sst_SPS3.5_sps3.5_201309_all_ano.1993-2016.nc"
b=addfile(fnall,"r")
if (flgmnth .eq. 1 ) then
   sstprob=b->tso(:,l1,:,:)
else 
   sstprob=dim_avg_n(b->tso(:,0+l1:2+l1,:,:),1)
end if

tsl=sstprob
tsu=sstprob
tsn=sstprob
delete(tmp)
tmp=sstprob(0,:,:)
countl=0
do k=0,nmem-1
   tsl(k,:,:)=where (sstprob(k,:,:).lt.low,1.,0.)
   tsu(k,:,:)=where(sstprob(k,:,:).gt.up,1.,0.)
   tmp=tsl(k,:,:)+tsu(k,:,:)
   tsn(k,:,:)=where(tmp.eq.0.,1.,0.)
   delete(tmp)
end do

   tsll=dim_avg_n_Wrap(tsl,0)
   tsnn=dim_avg_n_Wrap(tsn,0)
   tsuu=dim_avg_n_Wrap(tsu,0)
   tsll=where(tsll .ge. 0.4,tsll*10,tsll@_FillValue)
   tsnn=where(tsnn .ge. 0.4,tsnn*100,tsnn@_FillValue)
   tsuu=where(tsuu .ge. 0.4,tsuu*1000,tsuu@_FillValue)
   copy_VarMeta(template(0,:,:),tsll)
   copy_VarMeta(template(0,:,:),tsnn)
   copy_VarMeta(template(0,:,:),tsuu)
   printVarSummary(tsll)
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


  res2@mpCenterLonF            = 0
  res2@cnMissingValFillColor   = -1
  res2@gsnLeftString           = ""                  ; left title, remove default
  res2@gsnRightString          = ""                  ; right title, remove default: C

  res2@cnLevelSelectionMode    = "ExplicitLevels"                        ; set explicit contour levels
  res2@cnLevels                = (/4,5,6,7,39,40,50,60,70,399,400,500,600,700,1000/)       ; set levels
  res2@cnLineLabelsOn          = False
  res2@lbLabelBarOn            = False
  res2@cnFillOn                = True                                            ; turn on color fill
  res2@cnFillMode              = "CellFill"
  res2@cnInfoLabelOn           = False                      ; turn off contour label
  res2@cnLabelMasking          = True
  res2@cnFillColors            = (/2,2,3,4,5,5,10,11,12,13,13,6,7,8,9,9/)
;************************************************

   res2@cnMissingValFillColor   = -1
   res2@tiMainString            = "Probability Forecast"

   copy_VarMeta(template(0,:,:),tsll)
   plot(1)=gsn_csm_contour_map(wks,tsll,res2)
   res2@cnMissingValFillColor   = -1
   copy_VarMeta(tsll,tsuu)
   plot3=gsn_csm_contour(wks,tsuu,res2)

   overlay(plot(1),plot3)
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
  checkfile="checkfile"
  system("touch "+checkfile)
end
