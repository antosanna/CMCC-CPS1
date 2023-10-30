;======================================================================
; This file still has to be loaded manually
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin
    outdir="/data/csp/sps-dev/CMCC-CPS1/regrid_files/"
    wgt_file       = outdir+"CAMFV05_2_reg1x1_bilinear_C3S.nc"
    INTERP_METHOD = "bilinear"      ; default
    nlat=180
    nlon=360
    okfile="okfile_bil"
    vNames = (/"LANDFRAC"/)

;----------------------------------------------------------------------
; Input section
;----------------------------------------------------------------------

;---Read data from input file containing source grid
    srcFileName = "/work/csp/as34319/CESM2/archive/cps_complete_test_output/atm/hist/cps_complete_test_output.cam.h0.2000-02.nc"
    rgrdFileName = outdir+"SPS4_C3S_LSFRAC.nc"
    print("---going to read input file "+srcFileName)
    rgrd_nc       = addfile(rgrdFileName,"c")
    sfile       = addfile(srcFileName,"r")

    cornerFileName = "/data/inputs/CESM/inputdata/share/scripgrids/fv0.47x0.63_141008.nc"
    cfile       = addfile(cornerFileName,"r")
; Regridding section
;----------------------------------------------------------------------

;---Read data from input file containing source grid
;---Set up options for regridding
    Opt                   = True

    Opt@WgtFileName       = wgt_file
    Opt@SrcInputFileName  = srcFileName        ; optional, but good idea
    Opt@SrcTitle          = "FV Grid"
    Opt@SrcGridCornerLat = cfile->grid_corner_lat
    Opt@SrcGridCornerLon = cfile->grid_corner_lon
;    Opt@SrcMask2D         = where(ismissing(temp(0,0,:,:)),0,1)

;---Destination file options
    Opt@DstGridType       = "1x1"               ; 5x5 degree grid
    Opt@DstLLCorner       = (/ -89.5,   0.5/)
    Opt@DstURCorner       = (/  89.5, 359.5/)

    Opt@ForceOverwrite    = True
    ;;Opt@PrintTimings    = True
    ;;Opt@Debug           = True

;--------------------------------------------------------------
; Define new isobar levels
;--------------------------------------------------------------

;--------------------------------------------------------------
; Define global att
;--------------------------------------------------------------
    global = True
    copy_VarAtts(sfile, global)
    if (isatt(sfile,"title")) then
       global@TITLE = "REMAPPED: " + sfile@title
    end if
    global@remap         = "NCL: ESMF_regrid_with_weights"
    global@remap_method  = INTERP_METHOD
; for conserve method vertices of grids are needed: compute them here
    global@creation_date = systemfunc("date")
;----------------------------------------------------------------------
; Regrid the data. 
;----------------------------------------------------------------------
    dstFileName=getenv("dstFileName")
    voutNames=vNames
    nNames = dimsizes (vNames)   ; number of variables on the file
    print (vNames)               ; print all variable names on file
    Opt@WgtFileName      = wgt_file

    do n=0,nNames-1              ; loop thru each variable
       print("input name "+vNames(n))
       print("output name "+voutNames(n))
       v = sfile->$vNames(n)$        ; read the varible to memory

       dimv = dimsizes(v)        ; dimension size of the variable
       rank = dimsizes(dimv)     ; rank [ie: number of dimensions]

       if (rank.eq.4) then
          intyp = 1                             ; 1=linear, 2=log, 3=log-log
          kxtrp = True                          ; True=extrapolate
          varflg = 0
          if ( vNames(n) .eq. "T") then
             varflg = 1
          end if
          if (vNames(n).eq."Z3")then
             intyp = 2                             ; 1=linear, 2=log, 3=log-log
             varflg = -1
          end if
          v_plev = vinth2p_ecmwf(v, hyam,hybm,pnew,PSFC, intyp, P0mb, \
                               1,kxtrp,varflg,tbot,PHIS)
          printVarSummary(v_plev)
          print("nlev ="+nlev)
          do k=0,nlev-1

             print("now k ="+k)
             tmpv=v_plev(:,k,:,:)
             if(isfilepresent(wgt_file)) then
                vout = ESMF_regrid_with_weights(tmpv,wgt_file,Opt)
             else
                vout  = ESMF_regrid(tmpv,Opt)     ; Do the regridding
             end if
          end do
          printVarSummary(vout)
          pnew!0="plev"


       else if (rank.eq.3) then

          if(isfilepresent(wgt_file)) then
             vout = ESMF_regrid_with_weights(v(:,:,:),wgt_file,Opt)
          else
             vout  = ESMF_regrid(v(:,:,:),Opt)     ; Do the regridding
          end if
          nn=dimsizes(vout)
          rgrd_nc->lsFracC3S_SPS4=vout
          printVarSummary(vout)
       end if
       end if

      delete (v)
      delete (dimv)
  end do
  lat=new(nn(1),typeof(vout))
  lon=new(nn(2),typeof(vout))
  lat(0)=-89.5
  do l=1,nn(1)-1
     lat(l)=lat(l-1)+1.
  end do
  lon(0)=.5
  do l=1,nn(2)-1
     lon(l)=lon(l-1)+1.
  end do
  rgrd_nc->lon=lon
  rgrd_nc->lat=lat
  system("touch " + okfile)

end
