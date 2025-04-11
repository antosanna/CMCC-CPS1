;***************************************************************
; NCL script
; interp in time days -1 and +1 wrt to spike occurrence and replace
; values of input var only for the specific timesteps
;***************************************************************

begin

  npoints=toint(getenv("npoints"))
  npoints_lon=npoints
  npoints_lat=npoints
  checkfile=getenv("checkfile")
  srcFileName   = getenv("inputFV")
  dstFileName   = getenv("outputFV")
  caso   = getenv("caso")
  inputascii=getenv("inputascii")
  data = readAsciiTable(inputascii,1,"string",5)

  it_spike    = tointeger(str_get_field(data,1,";"))
  j_spike = stringtointeger(str_get_field(data,2,";"))
  i_spike = stringtointeger(str_get_field(data,3,";"))

  nn   = dimsizes(it_spike)
  n_spike   = nn(0)
  delete(nn)

  print("-----procedure to treat spikes "+n_spike)
  templateFileName   = getenv("templateFileName") ; daily-output frequency file to use as template for
                                          ; time
  src_template=addfile(templateFileName,"r")
  tmp=src_template->time
  timeday=tmp
  copy_VarMeta(tmp,timeday)

  print("Fixing for spikes: ")
  print("SRC:"+srcFileName)
  src_file=addfile(srcFileName,"r")
  exists = isfilepresent(dstFileName)
  if(exists) then
     print("---going to remove "+dstFileName)
     system("rm -f "+dstFileName)
  end if
  setfileoption("nc", "Format",  "NetCDF4Classic")
  setfileoption("nc","CompressionLevel",6)
  setfileoption("nc","preFill",False)
  dst_file     = addfile(dstFileName,"c")  ; open output netCDF file

  frq=getenv("frq")
  print("----going to process "+frq)

;===================================================================
; definitions to use poisson extrapolation
;===================================================================
  guess     = 1                ; use zonal means
  is_cyclic = True             ; cyclic [global]
  nscan     = 150             ; usually much less than this
  eps       = 1.e-2            ; variable dependent
  relc      = 0.6              ; relaxation coefficient
  opt       = 0                ; not used

;===================================================================
  vNames   = getfilevarnames(src_file)       ; get an array of file variable names on the given file
  nvars=dimsizes(vNames)
  timein=src_file->time
  if(frq.eq."day")then
     delete(timein)
     timein=timeday
  end if
  lat=src_file->lat
  lon=src_file->lon
  nlon=dimsizes(lon)
  nlat=dimsizes(lat)
  datein=cd_calendar(timein,-2)
  dateHHin=cd_calendar(timein,-3)
  do k=0,nvars-1   ; first on vars for there can be more than 1 spike
;loop on spikes
     if(vNames(k).eq."LANDFRAC".or.vNames(k).eq."PHIS")then
        dst_file->$vNames(k)$ = src_file->$vNames(k)$
        continue
     end if
     invar = src_file->$vNames(k)$
     origvar = invar
     mm=dimsizes(invar)
     dNames = getfilevardims(src_file,vNames(k))
     nn=dimsizes(dNames)
     if(nn.ge.3)then
        do is=0,n_spike-1
           print("----now processing "+it_spike(is,0))
           print("-----i index  "+i_spike(is,0))
           print("-----j index  "+j_spike(is,0))
           itnow=it_spike(is,0)
           spike_date=cd_calendar(timeday(itnow),-3)

           print("----itnow  "+itnow)
           print("----timeday  "+timeday(itnow))
           print("----day spike "+spike_date)

;the below array is 1 
           ind_spike=get1Dindex(dateHHin, spike_date) ;get the first index satisfying the requested condition
           print("ind_spike "+ind_spike)
           spike_date_in=cd_calendar(timein(ind_spike),-3)
           print("----input from daily "+spike_date_in)
           print("it_spike(is,0) "+it_spike(is,0))

           if(frq.eq."6hr")then
              incr=4
              nsteps2fix=incr+1
              ind_spike=ind_spike-2
           else if(frq.eq."12hr")then
              incr=2
              nsteps2fix=incr+1
              ind_spike=ind_spike-1
           else
              incr=0
              nsteps2fix=incr+1
           end if
           end if
           print("timesteps to fix "+nsteps2fix)
           print("snapshots to fix "+dateHHin(ind_spike:ind_spike+incr))
           print("date of spike "+spike_date)

           if(any(dNames.eq."time")) then
             ntime=mm(0)
             print("---fixing var "+vNames(k))
             if(nn.eq.3)then
                invar@_FillValue=1.e+20
                printVarSummary(invar)
                print("---ntime "+ntime)
                do i=0,incr ;loop spanning the affected day
                   print("incr is "+i)
                   print("snapshot being fixed now is "+dateHHin(ind_spike+i))

                   inow=i_spike(is,0)
                   jnow=j_spike(is,0)
                   imin=max((/0,inow-npoints/))
                   imax=min((/inow+npoints,nlon-1/))
                   jmin=max((/0,jnow-npoints/))
                   jmax=min((/jnow+npoints,nlat-1/))
                   actual_ind_spike=ind_spike+i
                   print("indices spike "+actual_ind_spike+" "+jnow+" "+inow)
                   print("spike value was "+invar(actual_ind_spike,jnow,inow))
                   invar(actual_ind_spike,jmin:jmax,imin:imax)=invar@_FillValue
                   poisson_grid_fill( invar(actual_ind_spike,:,:), is_cyclic, guess, nscan, eps, relc, opt)
                   invar(actual_ind_spike,max((/0,jmin-2/)):jmin+2,imin:imax)=smth9_Wrap(invar(actual_ind_spike,max((/0,jmin-2/)):jmin+2,imin:imax),0.5,0.25,False)
                   invar(actual_ind_spike,jmax-2:min((/jmax+2,jmax/)),imin:imax)=smth9_Wrap(invar(actual_ind_spike,jmax-2:min((/jmax+2,jmax/)),imin:imax),0.5,0.25,False)
                   invar(actual_ind_spike,jmin:jmax,max((/0,imin-2/)):imin+2)=smth9_Wrap(invar(actual_ind_spike,jmin:jmax,max((/0,imin-2/)):imin+2),0.5,0.25,False)
                   invar(actual_ind_spike,jmin:jmax,imax-2:min((/imax+2,imax/)))=smth9_Wrap(invar(actual_ind_spike,jmin:jmax,imax-2:min((/imax+2,imax/))),0.5,0.25,False)
                   print("after treatment is "+invar(actual_ind_spike,jnow,inow))

                end do
             end if
          end if   ;vars containing time dim
       end do  ; loop on n_spike
     end if      ;rank >=3
     print("---writing var "+vNames(k))
     dst_file->$vNames(k)$ = invar
     delete(dNames)
     delete(mm)
     delete(invar)
     delete(origvar)
  end do   ;loop on vars
  system("touch "+checkfile)
  print("touched file "+checkfile)
  
exit
; the rest is to plot results in case of doubts
  if(docheckplot.eq.1)then
     do k=0,n_spike-1
;************************************************
; create plot
;************************************************
     pltype=getenv("pltype")
     pltname=getenv("pltname")
     cmap = read_colormap_file("gui_default")
     wks   = gsn_open_wks (pltype,pltname)

     plot = new(2,graphic)
     res                   = True                       ; plot mods desired
     res@gsnFrame          = False                      ; don't advance frame yet
     res@gsnDraw   = False
     res@pmLegendDisplayMode    = "Always"
     res@pmLegendSide           = "Top"                 ; Change location of
     res@pmLegendParallelPosF   = 1.15                   ; move units right
     res@pmLegendOrthogonalPosF = -1.                  ; more neg = down
     res@lgLabelFontHeightF=0.021
     res@cnFillOn            = True            ; turn on color
     res@cnFillPalette       = cmap
     res@lbLabelBarOn        = False           ; 
    
     res@pmLegendWidthF         = 0.07                  ; Change width and
     res@pmLegendHeightF        = 0.2
    ; res@xyExplicitLegendLabels = label
;     res@xyMarkerColors := (/"blue","red"/)
;     res@xyExplicitLegendLabels = (/"before", "after"/)
;     res@xyDashPattern  = 0                         ; Make curves all solid
;     res@xyMarkLineMode = "MarkLines"               ; Markers *and* lines
;     res@xyMarker      = 1
;     res@xyMarkerSizeF=0.03
     res@tiMainString         = var2check +" timeseries before treatment"
     res@tiYAxisString =""
;     res@tmXTOn=False
; res@tmXTMajorOn=False
;     res@tmYROn=False
; res@tmYRMajorOn=False


      res@cnLineLabelsOn      = False
      res@cnLinesOn           = False
      MinLon   = lon(max((/0,i_spike(0,0)-30/)))
      res@mpMinLonF   = MinLon
      MaxLon   = lon(min((/i_spike(0,0)+30,nlon-1/)))
      res@mpMaxLonF   = MaxLon
      MinLat   = lat(max((/0,j_spike(0,0)-30/)))
      res@mpMinLatF   = MinLat
      MaxLat   = lat(min((/j_spike(0,0)+30,nlat-1/)))
      res@mpMaxLatF   = MaxLat
      res@cnLevelSelectionMode = "ManualLevels"
      res@cnMinLevelValF       = floor(min(origvar(ind_spike,{MinLat:MaxLat},{MinLon:MaxLon})))
      res@cnMaxLevelValF       = ceil(max(origvar(ind_spike,{MinLat:MaxLat},{MinLon:MaxLon})))
      res@cnLevelSpacingF      = 2.
      ik=it_spike(k,0)
      plot(0)  = gsn_csm_contour_map(wks,origvar(ik,:,:),res)
      res@tiMainString         = var2check +" timeseries after treatment with npoints "+npoints
      plot(1)  = gsn_csm_contour_map(wks,invar(ik,:,:),res)
;************************************************
; create panel
;************************************************
     resP                     = True                ; modify the panel plot
     resP@gsnPanelMainString = "SPIKES HEALING"

     resP@gsnPanelLabelBar    = True                ; add common colorbar
     resP@lbLabelFontHeightF  = 0.007               ; make labels smaller

     gsn_panel(wks,plot,(/2,1/),resP)               ; now draw as one plot
  end do
  end if
end
