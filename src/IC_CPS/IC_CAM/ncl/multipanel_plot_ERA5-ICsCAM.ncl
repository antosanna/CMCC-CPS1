;======================================================================
; plot_vert_levs
;
; Concepts illustrated:
;   - Interpolating from one grid to another using ESMF_regrid
;   - Interpolating data from ERA5 to CAM-SE grid 
;======================================================================
;
; These files are loaded by default in NCL V6.2.0 and newer
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
;
; This file still has to be loaded manually
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

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
  main_title_font_height = 0.022
  sub_title_font_height  = 0.015
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
;	 MAIN CODE
;----------------------------------------------------------------------
begin
    
; now do vertical interpolation to 83lev of CAM keeping ERA5 horizontal grid

;destination grid

;----Auxilliary file for CAM (templateL83)
    fileok = getenv("fileok2d")
    diri = getenv("diri")
    filename = getenv("filename")
    fili = systemfunc("cd "+diri+" ; ls "+filename+"*nc")
    print(fili)
    nfils = dimsizes(fili)
 
    fi = addfile (diri+"/"+fili(0), "r")
    cam_lat=fi->lat
    cam_lon=fi->lon
    cam_slat=fi->slat
    cam_slon=fi->slon
    hyao=fi->hyam
    hybo=fi->hybm
    ps=101300
    plevs_cam=(hyao+hybo)*ps
    plevs_cam=(plevs_cam/100)
    plevplot=getenv("value2check")
    value2check=tofloat(getenv("value2check"))
    print(plevs_cam)
    index10    = closest_val(value2check,plevs_cam)

;---Data file containing source grid
    ERA5_file = getenv("inputERA")
    sfile      = addfile(ERA5_file,"r")
    hyai = sfile->hyam                                  ; midlayer coef
    hybi = sfile->hybm
    plevs_era=hyai+hybi*ps
    plevs_era=(plevs_era/100)
    print(plevs_era)
   
    index10era    = closest_val(value2check,plevs_era)
    if (value2check .eq. 10) then
         index10era=index10era+1
         index10=index10+1
     end if
;    varera="q" ; getenv("var137")
;    varcam="Q"  ; getenv("var46")
    varera=getenv("varera")
    varcam=getenv("varcam")

    if (varcam .eq. "US" ) then
      	var="U"
       unit="m/s"
    else if ( varcam .eq. "VS" ) then
      	var="V"
       unit="m/s"
    else if ( varcam .eq. "T" ) then
      	var="T"
       unit="K"
    else 
      	var="Q"
       unit="kg/kg"
    end if
    end if
    end if

;---Get coordinates of source grid
    ;src_lat  = sfile->lat
    ;src_lon  = sfile->lon

    ;src_slat  = sfile->slat
    ;src_slon  = sfile->slon

    tmp = fi->$varcam$(0,:,:,:)
    nn=dimsizes(tmp)
    cam = new((/nfils,nn(0),nn(1),nn(2)/),typeof(tmp))
    cam(0,:,:,:)=tmp
    delete(tmp)
    do nf=1,nfils-1
       fi = addfile (diri+"/"+fili(nf), "r")
       cam(nf,:,:,:) = fi->$varcam$(0,:,:,:)
    end do

    var137 = sfile->$varera$

;----------------------------------------------------------------------
; Now graphics
;----------------------------------------------------------------------

    stdate=getenv("stdate")
    dirplots=getenv("dirplots")
    typeofplot=getenv("typeofplot")
    obs=getenv("obs")
    wks   = gsn_open_wks (typeofplot,dirplots+"/"+var+plevplot+"_panel_CAMvs"+obs+"_"+stdate)     ; send graphics to PNG file

;---Set plotting parameters

    plots = new(11,graphic)
    
    res                     = True
    res@gsnDraw             = False
    res@gsnFrame            = False
    res@mpFillOn            = False            ; no need   
    res@gsnAddCyclic = True            ;;---Change (maybe)
    
    if ( varera .eq. "q".and.plevplot.eq."10") then
       mini=3.e-6
       maxi=4.e-6
    else if ( varera .eq. "q".and.plevplot.eq."500") then
       mini=4.e-4
       maxi=7.e-3
    else
       maxi = toint(ceil(max(var137(0,index10era,:,:))))
       mini = toint(floor(min(var137(0,index10era,:,:))))
    end if
    end if
    levels1=fspan(mini, maxi, 9) 
    
    res@cnFillPalette       = "GHRSST_anomaly"
    res@cnLevelSelectionMode= "ExplicitLevels"   ; manual set levels
    labels1 = sprintf("%5.4E",levels1)   ; They both have length 4
    res@cnLevels            = levels1
    res@cnFillOn            = True             ; color fill plot
;    res@cnFillMode="RasterFill"
    res@cnLinesOn           = False
    res@cnLineLabelsOn      = False
    res@cnInfoLabelOn       = False
       
    res@lbLabelBarOn        = False            ; turn off individual label bars
    
    res@gsnStringFontHeightF= 0.02

    res@gsnCenterString     = obs+" closest "+plevplot+" hPa ("+sprintf("%5.2f", plevs_era(index10era))+" hPa)"
    res@gsnLeftString=""
    res@gsnRightString=""
    plots(0) = gsn_csm_contour_map(wks,var137(0,index10era,:,:),res)

    res2                      = res              ; Plot mods desired
    do nf=0,nfils-1
       res2@gsnCenterString     = "IC "+sprinti("%.2i",nf)+" CAM closest "+plevplot+" hPa ("+sprintf("%5.2f", plevs_cam(index10))+" hPa)"
       plots(nf+1) = gsn_csm_contour_map(wks,cam(nf,index10,:,:),res2)
    end do

    panres = True					; panel resource list
    panres@gsnFrame                = False 
    panres@gsnMaximize        = True
    panres@gsnPanelLabelBar   = True
    panres@pmLabelBarWidthF   = 0.8
    panres@lbLabelFontHeightF = 0.008
    ;;panres@gsnPanelYWhiteSpacePercent = 5.0	; set spacing vertically 
    panres@gsnPanelSave            = True 
    panres@gsnPanelRowSpec         = True                   ; tell panel what order to plot
    panres@gsnPanelTop             = 0.94
    panres@gsnPanelBottom          = 0.02
    title  = var+"["+unit+"] "+plevplot+"hPa"
    gsn_panel(wks,plots,(/1,3,3,3,1/),panres)
                                                ; between 2 panels	
    draw_panel_titles(wks,plots,title,"","",stdate)

  frame(wks)
  system("touch "+fileok)

end

