;======================================================================
; orca_1.ncl
;
; Concepts illustrated:
;   - Drawing area and raster filled contours of ORCA data
;   - Using triangular meshes to create contours
;======================================================================
;
; These files are loaded by default in NCL V6.2.0 and newer
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
 

begin

  startdate=getenv("startdate")
  outputpath=getenv("outputpath")
  mesh=getenv("meshfile")
  orca=getenv("orca")

  orcafile = addfile(orca,"r")
  step=1
  sst  = orcafile->tn(:,0,0,::step,::step)      ; Read data
  sizes=dimsizes(sst)
  nens=sizes(0)
  nlat=sizes(1)
  nlon=sizes(2)
  meshfile = addfile(mesh,"r")
  msk  = tofloat(meshfile->tmaskutil(0,::step,::step))
  lat2d = meshfile->nav_lat
  lon2d = meshfile->nav_lon
  msk@_FillValue=0
  msk@_FillValue=-9999.

  sstmask=new((/nens,nlat,nlon/),typeof(sst)) 
  do ens=0,nens-1
     sstmask(ens,:,:)=where(msk.eq.msk@_FillValue,msk,sst(ens,:,:))
     sstzmean=dim_avg_n_Wrap(sst,1)
  end do
  copy_VarMeta(sst,sstmask)

  ;###########################
  ;---Start the graphics
  ;###########################
  ; increase page size 
  wks_type          = "png"
  wks_type@wkWidth  = 2000
  wks_type@wkHeight = 2000
  ; call wks resource 
  wks = gsn_open_wks(wks_type,outputpath+"/IC_NEMO_"+startdate+"01_all_anom")   ; send graphics to PNG file

  ; Debug purposes for faster polt
  ; WARNING
  ; this feature (lowresflag) does not necessarily produce correct contour representation
  ; but should beused just to check plot sizes, label, page etc.
  lowresflag                = False  ; enable dbg mode - plot of 1 point every sk    
  sk                        = 10     ; plot 1 points every 10
 
  ; resources
  res                       = True
  res@gsnDraw               = False             ; Don't draw plots; will
  res@gsnFrame              = False             ; panel them later.
  res@gsnMaximize           = True              ; Will maximize later
  res@mpOutlineOn           = True
  res@mpDataBaseVersion     = "MediumRes"       ; default is "LowRes"

  ; if lowresflag then activate resampling for faster plotting (dbg purposes) 
  if (lowresflag) then
    res@trGridType   = "TriangularMesh" ; this avoid failure of the script just for dbg mode
    res@sfYArray     = lon2d(::sk,::sk)
    res@sfXArray     = lat2d(::sk,::sk)
  
  else
    res@sfXArray     = lon2d
    res@sfYArray     = lat2d
  end if


  ;---This will position data correctly on map.
  res@gsnAddCyclic           = False      ; Data not global, don't add lon cyclic pt

  res@cnFillOn               = True                ; Turn on contour fill
  res@cnFillPalette          = "GHRSST_anomaly"    ; set color map
  res@cnLinesOn              = False               ; Turn off contour lines
  res@cnLevelSelectionMode   = "ManualLevels"      ; set manual contour levels
  res@cnMinLevelValF         =  -3.                ; set min contour level
  res@cnMaxLevelValF         =   3.                ; set max contour level
  res@cnLevelSpacingF        = 0.5                 ; Change contour level spacing
  res@lbLabelBarOn           = False

  res@mpFillOn               = True
  res@mpLandFillColor        = "tan"

  res@pmTickMarkDisplayMode  = "Always"    ; tickmarks with degree symbol

  res@pmLabelBarOrthogonalPosF = 0.1       ; move labelbar away from plot
  res@tiMainOffsetYF           = -0.03     ; move title towards plot

  plots = new(9,graphic)
  pp=1
  do e=0,nens-1
 
     res@gsnCenterString = "Orca Grid - "+startdate+"01 perturbation "+pp
     ; if dbg mode is activated, then resample for faster plot
     if (lowresflag) then
        plots(e) = gsn_csm_contour_map(wks,sstmask(e,::sk,::sk),res) 
     else
        plots(e) = gsn_csm_contour_map(wks,sstmask(e,:,:),res)
     end if     
     
     pp=pp+1

  end do

  ;---Set up resources for paneling four plots on one page.
  pres                    = True
  pres@gsnPaperWidth      = 34 ; 17
  pres@gsnPaperHeight     = 44 ;22
    
  pres@gsnMaximize        = True              ; Maximize paneled plots
  pres@gsnPanelLabelBar   = True              ; Turn on panel labelbar
  pres@pmLabelBarWidthF   = 0.4
  ;pres@pmLabelBarHeightF  = 0.7

  ; (I) in case of specified order 
  ;pres@gsnPanelRowSpec    = True             ; tell panel what order to plot
  ;gsn_panel(wks,plots,(/3,3,2/),pres)

  ; (II) let ncl decide
  gsn_panel(wks,plots,(/3,3/),pres)


end

