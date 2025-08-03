
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"   

;----------------------------------------------------------------------
; Procedure to add a main title and left, center, and right subtitles 
; to a page that has paneled plots. Set any title to an empty string
; ("") if it is not desired.
;
; One can certainly draw the main title using gsnPanelMainString, but 
; this procedure does it by hand here so it can better control the 
; position with respect to the subtitles.
; 
; This procedure assumes that the paneled plots have already been 
; created with a margin left at the top for titles. It will print a
; warning if it thinks there's not enough room.
;----------------------------------------------------------------------
procedure draw_panel_titles(wks,plots,main_title,left_title,center_title,right_title)
local n, bb, top, rgt, lft, max_top, min_lft, max_rgt, vpx, vpw, xpos, ypos, \
valid_class_types, nplots, txres, main_title_font_height, sub_title_font_height,\
title_margin
begin
  valid_class_types = (/"xyPlotClass","contourPlotClass","mapPlotClass","vectorPlotClass"/)
;
; Loop through each paneled plot and retrieve the NDC locations of the
; topmost plots. This information will be used for positioning the 
; titles later.
;
  nplots = dimsizes(plots)
  do n=0,nplots-1

;---Make sure this is a plot object, and not a labelbar object or something else.
    class = NhlClassName(plots(n))
    if(.not.any(class.eq.valid_class_types)) then
      continue
    end if
;
; If this is a plot object, then get the right, left, and top edges so
; we can determine where to add the subtitles.
;
    getvalues plots(n)
      "vpXF"     : vpx
      "vpWidthF" : vpw
    end getvalues
    bb  = NhlGetBB(plots(n))
    top = bb(0)     ; Top of plot, above any titles, tickmarks, etc.

    lft = vpx       ; left of plot edge (not including tickmarks)
    rgt = vpx+vpw   ; right of plot edge (not including tickmarks)
    if(n.eq.0)
      max_top = top
      max_rgt = rgt
      min_lft = lft
    else
      max_top = max((/max_top,top/))
      max_rgt = max((/max_rgt,rgt/))
      min_lft = min((/min_lft,lft/))
    end if
  end do

;---Set font height sizes and a margin between the plots and the titles
  main_title_font        = "helvetica-bold"
  sub_title_font         = "helvetica"
  sub_title_font_height  = 0.015
  main_title_font_height = 0.020
  sub_title_font_height  = 0.010
  title_margin           = 0.005

;---Set resources for subtitles
  txres = True
  txres@txFont        = sub_title_font
  txres@txFontHeightF = sub_title_font_height

;----------------------------------------------------------------------
; Add sub titles
;----------------------------------------------------------------------

;---Set Y position for three subtitles, and test that you have room.
  ypos = max_top + title_margin
  if(ypos.ge.1-(title_margin+sub_title_font_height)) then
    print("add_panel_titles: Warning: there may not be enough room for your titles.")
    print("   You may need to set gsnPanelTop equal to a value slightly smaller than " + \
           (1.-(title_margin+sub_title_font_height)))
  end if
  if(left_title.ne."")
    txres@txJust = "BottomLeft"
    xpos = min_lft
    gsn_text_ndc(wks,left_title,xpos,ypos,txres)
  end if

  if(center_title.ne."") then
    txres@txJust = "BottomCenter"
    xpos = (min_lft+max_rgt)*0.5
    gsn_text_ndc(wks,center_title,xpos,ypos,txres)
  end if

  if(right_title.ne."") then
    txres@txJust = "BottomRight"
    xpos = max_rgt
    gsn_text_ndc(wks,right_title,xpos,ypos,txres)
  end if

;----------------------------------------------------------------------
; Add main title, if any.
;----------------------------------------------------------------------
  if(main_title.ne."") then
;---Set resources for main title
    txres@txFont        = main_title_font
    txres@txFontHeightF = main_title_font_height
    txres@txJust = "BottomCenter"
    xpos = (min_lft+max_rgt)*0.5
    ypos = max_top + sub_title_font_height + 3*title_margin   ; add more of a margin
    if(ypos.ge.1.-main_title_font_height) then
      print("add_panel_titles: Warning: there may not be enough room for your titles.")
      print("   You may need to set gsnPanelTop equal to a value slightly smaller than " + \
               (1.-(sub_title_font_height + 3*title_margin + main_title_font_height)))
    end if
    gsn_text_ndc(wks,main_title,xpos,ypos,txres)
  end if
end

;----------------------------------------------------------------------
; Main driver code.
;----------------------------------------------------------------------
begin
;----------------------------------------------------------------------
; Read data
;----------------------------------------------------------------------
  ; DAILY DATA
  fn                            = getenv("DAILYFILE")
  print(fn)  
  a                             = addfile(fn,"r")
  sstd                          = a->analysed_sst(0,:,:)
  
  ; WEEKLY DATA
  fn                            = getenv("WEEKLYFILE")
  print(fn)  
  a                             = addfile(fn,"r")
  sstw                          = a->analysed_sst(0,:,:)
  ; MONTHLY DATA
  fn                            = getenv("MONTHLYFILE")
  print(fn)  
  a                             = addfile(fn,"r")
  sstm                          = a->analysed_sst(0,:,:)
  ; OUTPUT 
  on                            = getenv("OUTPUT")
  ; REFDATE 
  refdate                            = getenv("refdate")  
;----------------------------------------------------------------------
; Turn on graphics
;----------------------------------------------------------------------
  wks                           = gsn_open_wks("png",on)
  ;wks                          = gsn_open_wks("X11","mapoutlines")  
  plot                          = new(3,graphic)


;----------------------------------------------------------------------
; Set some map resources
;----------------------------------------------------------------------
  res                           = True

  res@gsnDraw                   = False                ; don't draw
  res@gsnFrame                  = False                ; don't advance frame
  res@cnInfoLabelOn             = False                ; turn off cn info label
  res@cnFillOn                  = True                 ; turn on color

  res@lbLabelBarOn              = False                ; turn off individual cb's
  ;res@cnFillOn                 = True                 ; turn on contour fill
  res@cnLinesOn                 = False                ; turn off contour lines
  res@cnLineLabelsOn            = False                ; turn off contour labels
  ;res@lbLabelBarOn             = True                 ; turn off labelbar

  res@cnFillPalette             = "GHRSST_anomaly"    ; set color map
  res@cnLevelSelectionMode      = "ManualLevels"       ; set manual contour levels
  res@cnMinLevelValF            = -3.0                 ; set min contour level
  res@cnMaxLevelValF            =  3.0                  ; set max contour level
  res@cnLevelSpacingF           =  0.5                  ; set contour spacing

  res@mpFillDrawOrder           = "PostDraw"           ; draw map fill last
  res@gsnRightString            = ""                   ; turn off special titles
  res@gsnLeftString             = ""

  res@mpCenterLonF              = 0
  res@pmTickMarkDisplayMode     = "Always"             ; tickmarks for some maps
  res@gsnAddCyclic              = True                ; don't add longitude cyclic point

  sk=4
  plot(0)                       = gsn_csm_contour_map(wks,sstd(::sk,::sk),res) 
  plot(1)                       = gsn_csm_contour_map(wks,sstw(::sk,::sk),res)
  plot(2)                       = gsn_csm_contour_map(wks,sstm(::sk,::sk),res)    

;************************************************
; create panel
;************************************************
  maititle                      = "ESACCI sst anomalies (1993-2022) for "+refdate
  subtitle                      = "sst data from Copernicus Marine Data Store"
  resP                          = True                 ; modify the panel plot
  resP@gsnFrame                 = False                ; Turn off so we can add titles
  resP@gsnMaximize              = True                

  resP@gsnPanelSave             = True                 ; Don't resize plots back to original size after done
  resP@gsnPanelTop              = 0.94                 ; Default is 1.0; may need to change to make room for titles

  ;---Create the plot
  resP@gsnPanelLabelBar         = True                 ; add common colorbar
  resP@lbLabelFontHeightF       = 0.01                 ; make labels smaller

  ; Set resources for when we turn on labelbar later
  resP@lbTitleFontHeightF       = .008                 ; make title smaller
  resP@lbTitleString            = "[deg C]"            ; title string
  resP@lbTitlePosition          = "Bottom"             ; title position
  resP@lbTitleDirection         = "Across"             ; title direction
  ;resP@lbLabelStride           = 2
  ;resP@lbLabelFontHeightF      = 0.025
  ;resP@pmLabelBarHeightF       = 0.1
  ;resP@lbBoxEndCapStyle        = "TriangleBothEnds"
  resP@lbOrientation            = "Horizontal"         ; orientation

  resP@gsnPanelFigureStrings    = (/"single day "+refdate,"last week mean","monthly mean"/) ; add strings to panel
  resP@amJust   = "BottomRight"

  gsn_panel(wks,plot,(/3,1/),resP)                     ; now draw as one plot
  draw_panel_titles(wks,plot,maititle,subtitle,"","")
  frame(wks)                                           ; now advance the frame!
end
