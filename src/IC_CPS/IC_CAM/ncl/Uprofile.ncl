; ***********************************************
; xy_3.ncl
;
; Concepts illustrated:
;   - Reversing the Y axis
;   - Changing the line dash pattern in an XY plot
;   - Creating your own line dash pattern for an XY plot
;   - Changing the line color and thickness in an XY plot
;   - Creating a vertical profile plot
;
; ***********************************************
;
; These files are loaded by default in NCL V6.2.0 and newer
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
;************************************************
begin
;************************************************
; read in data
;************************************************
    diri = getenv("diric")
    pltype = getenv("pltype")
    pltname = getenv("pltname")
    filename = getenv("filename")
    fileok = getenv("fileok")
    yyyy = getenv("yyyy")
    lat1 = tofloat(getenv("lat1"))
    lat2 = tofloat(getenv("lat2"))
    st = getenv("st")
    fili = systemfunc("cd "+diri+" ; ls "+filename+"*nc")
    print(fili)
    nfils = dimsizes(fili)

  
  ; output required precision
    C3S_type="double"
    C3S_type_var="float"
  
 
    fi = addfile (diri+"/"+fili(0), "r")
    cam_lat=fi->slat
    cam_lon=fi->lon
    hyao=fi->hyam
    hybo=fi->hybm
    ps=101300
    plevs_cam=(hyao+hybo)*ps
    plevs_cam=(plevs_cam/100)
    lowest    = closest_val(20,plevs_cam)
    ;lowest=15
    u     = fi->US(0,0:lowest,:,:)                                      ; get u data
    dims=dimsizes(u)
    cam = new((/nfils,dims(0),dims(1),dims(2)/),typeof(u))
    delete(u)
    do nf=0,nfils-1
       fi = addfile (diri+"/"+fili(nf), "r")
       cam(nf,:,:,:) = fi->US(0,0:lowest,:,:)
    end do

    u2plot=dim_avg_n_Wrap(dim_avg_n_Wrap(cam(:,:,{lat1:lat2},:),2),2)
    printVarSummary(u2plot)
    u2plot@long_name="Zonal wind"  
;************************************************
; plotting parameters
;************************************************
    wks   = gsn_open_wks (pltype,pltname)                  ; send graphics to PNG file

    res                   = True                       ; plot mods desired
    res@trYReverse        = True                       ; reverse Y-axis
  res@xyDashPatterns     = (/0,0,0,0,0,0,0,0,0,0/) 
  res@xyLineThicknesses =(/3,3,3,3,3,3,3,3,3,3/)
  res@pmLegendDisplayMode    = "Always"            ; turn on legend
  res@pmLegendSide           = "Top"               ; Change location of 
  res@pmLegendParallelPosF   = .1                  ; move units right
  res@pmLegendOrthogonalPosF = -1.                ; move units down
  res@pmLegendWidthF         = 0.1                ; Change width and
  res@pmLegendHeightF        = 0.15                ; height of legend.
  res@lgPerimOn              = False               ; turn off box around
  res@lgLabelFontHeightF     = .012                 ; label font height
  res@xyExplicitLegendLabels = (/"10","1","2","3","4","5","6","7","8","9"/)         ; create explicit labels

;    res@xyDashPatterns    = 1                         ; choose dash patterns
   ; pattern string
   
    res@xyLineColors    = (/"blue","red","magenta","green","black","orange","light blue","grey","purple","yellow"/)
     res@trXMinF  = toint(min(u2plot))-1
     res@trXMaxF  = toint(max(u2plot))+1
    res@tiMainString    = "Vertical profile 50-60N zonal mean "+yyyy+st
;    res@xyLineThicknesses = 4.0
   
   ; the pattern string is the tricky part of this function. See the function
   ; documentation for examples of the patterns used in the present dash patterns
   
   ; this pattern will make a standard dash have more spaces between the lines
   ; so that when thickened for publication purposes, you can still see that
   ; a line is dashed. The $ is pen down (line), and the _ is pen up (space). 
   
;    pattern = "$$$$______$$$$______$$$$______$$$$_____$$$$______"
   
;    res@xyDashPatterns = NhlNewDashPattern(wks,pattern)
    plot  = gsn_csm_xy (wks,u2plot,cam&lev(0:lowest),res) ; create plot
   ;************************************************
    system("touch "+fileok)

end
