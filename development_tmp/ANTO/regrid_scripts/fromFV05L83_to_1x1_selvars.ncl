;======================================================================
; This file still has to be loaded manually
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin
    INTERP_METHOD = "bilinear"      ; default
    wgt_file       = getenv("wgt_file")
;    wgt_file       = "FV_2_reg1x1.nc"   
    nlat=180
    nlon=360
    okfile=getenv("okfile")
    yyyy=getenv("yyyy")
;    mon=getenv("mon")
    pnew=keyword_values(key_path, "pnew","integer")
;    pnew = (/ 1000, 975, 950, 925, 900, 875, 850, 825, 800, 775, 750, 700, 650, 600, 550, 500, 450, 400, 350, 300, 250, 225, 200, 175, 150, 125, 100, 70, 50, 30, 20, 10, 7, 5, 3, 2, 1/)
    vNames=keyword_values(key_path, "vNames","string")
;    vNames = (/"FLDS","FLNS","FSNTOA","FSUTOA","ICEFRAC","LHFLX","OMEGA","OMEGAT","PRECC","PRECL","PSL","T","U","V","Z3","TS","TREFHT","TSMN","TSMX","U10"/)

    nlev=dimsizes(pnew)
;----------------------------------------------------------------------
; Input section
;----------------------------------------------------------------------

;---Read data from input file containing source grid
    srcFileName = getenv("srcFileName")
    print("---going to read input file "+srcFileName)
    sfile       = addfile(srcFileName,"r")
    PHIS = sfile->PHIS(0,:,:)                       ; surface geopotential [2D]
    PSFC = sfile->PS                       ; surface pressure [2D]
    P0mb = 1000.
    tmp = sfile->T
    time = sfile->time
    nt=dimsizes(time)
    nn=dimsizes(tmp)
    nlevin=nn(1)
    tbot = tmp(:,nlevin-1,:,:)                       ; surface T [2D]
    delete(tmp)
    delete(nn)

;---Read hybrid level from ref file to be compliant to clim mean files done with cdo which does not have these vars
    hybridlevfile = getenv("hybridlevfile")
    hyfile       = addfile(hybridlevfile,"r")
    hyam = hyfile->hyam
    hybm = hyfile->hybm

; Regridding section
;----------------------------------------------------------------------

;---Read data from input file containing source grid
;---Set up options for regridding
    Opt                   = True

    Opt@WgtFileName       = wgt_file
    Opt@SrcInputFileName  = srcFileName        ; optional, but good idea
    Opt@SrcTitle          = "FV Grid"
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
    global@creation_date = systemfunc("date")
;----------------------------------------------------------------------
; Regrid the data. 
;----------------------------------------------------------------------
    outdir=getenv("outdir")
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
;          rgrdFileName=outdir+"/"+dstFileName+"_"+vNames(n)+"_"+yyyy+"-"+mon+".nc"
          rgrdFileName=outdir+"/"+dstFileName+"_"+vNames(n)+"_"+yyyy+".nc"
          if(isfilepresent(rgrdFileName)) then
             system("rm -f " + rgrdFileName)
          end if
          rgrd_nc = addfile(rgrdFileName,"c")

          fileattdef( rgrd_nc, global )        ; copy global file attributes
          filedimdef(rgrd_nc,"time",-1,True)   ; force an unlimited dimension    
          vout=new((/nt,nlev,nlat,nlon/),typeof(v))
          vout!0="time"
          vout!1="plev"
          vout!2="lat"
          vout!3="lon"
          print("nlev ="+nlev)
          do k=0,nlev-1

             print("now k ="+k)
             tmpv=v_plev(:,k,:,:)
             if(isfilepresent(wgt_file)) then
                vout(:,k,:,:) = ESMF_regrid_with_weights(tmpv,wgt_file,Opt)
             else
                vout(:,k,:,:)  = ESMF_regrid(tmpv,Opt)     ; Do the regridding
             end if
          end do
          printVarSummary(vout)
;          delete(vout@time)
;          delete(vout@remap)
;          delete(vout@missing_value)
;          delete(vout@_FillValue)
          rgrd_nc->$voutNames(n)$=vout
          pnew!0="plev"
          rgrd_nc->plev=pnew
          delete (vout)


       else if (rank.eq.3) then
;          rgrdFileName=outdir+"/"+dstFileName+"_"+vNames(n)+"_"+yyyy+"-"+mon+".nc"
          rgrdFileName=outdir+"/"+dstFileName+"_"+vNames(n)+"_"+yyyy+".nc"
          if(isfilepresent(rgrdFileName)) then
             system("rm -f " + rgrdFileName)
          end if
          rgrd_nc = addfile(rgrdFileName,"c")

          fileattdef( rgrd_nc, global )        ; copy global file attributes
          filedimdef(rgrd_nc,"time",-1,True)   ; force an unlimited dimension    
          vout=new((/nt,nlat,nlon/),typeof(v))
          vout!0="time"
          vout!1="lat"
          vout!2="lon"
          if(isfilepresent(wgt_file)) then
             vout = ESMF_regrid_with_weights(v(:,:,:),wgt_file,Opt)
          else
             vout  = ESMF_regrid(v(:,:,:),Opt)     ; Do the regridding
          end if
          printVarSummary(vout)
;          delete(vout@time)
;          delete(vout@remap)
;          delete(vout@missing_value)
;          delete(vout@_FillValue)
          rgrd_nc->$voutNames(n)$=vout
          rgrd_nc->time=time
          delete (vout)
       end if
       end if

      delete (v)
      delete (dimv)
  end do
  system("touch " + okfile)

end
