;======================================================================
; ESMF_regrid_17.ncl
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
begin

;--remove old checkfile
    checkfile="fileok"
    ; 28/12/2020 - 12:00
    ; isfilepresent raise an hdf5 error with complex path as /work/csp/sp1/CMCC-SPS3.5/WORK_IC4CAM/ECOPER_20201227_00_ok
    ; (it expect a supported file as netcdf,hdf5 etc. and return a misleading error message)
    ; fileexists support txt files (look at NCL doc page)
    ; since debug for isfilepresent was a nightmare, a verbose if then else statement has been preferred
    exists = fileexists(checkfile)
    if(.not.exists) then
        print(checkfile+" file not exists")
    else
        print(checkfile+" file exists")
        system("/bin/rm "+checkfile)
    end if   
        
;--define time var
    year="2023"
    mon="04"
    day="11"
    hh="00"

    tunits     = "days since "+year+"-"+mon+"-"+day+" "+hh+":00:00" ; "seconds/hours/days since ...."
    time       = cd_inv_calendar(tointeger(year),tointeger(mon),tointeger(day),0,0,0,tunits, 0)

    time!0="time"
    time@calendar="gregorian"
    time@units=tunits
;
                                                 ; do NOT use "months since ...."
    print("define time var")

; now do vertical interpolation to 83lev of CAM keeping ERA5 horizontal grid

;destination grid
    filC ="/data/inputs/CESM/inputdata/atm/cam/inic/fv/cami_0000-01-01_0.47x0.63_L83_c230109.nc"
    fC=addfile(filC,"r")
    hyao=fC->hyam
    hybo=fC->hybm
;---Data file containing source grid
    ERA5_file ="/work/csp/cp1/CPS/CMCC-CPS1/WORK_IC4CAM/ECEDA0_19931031_00.nc"
    sfile      = addfile(ERA5_file,"r")

;---Get coordinates of source grid
    src_lat  = sfile->lat
    src_lon  = sfile->lon
    src_lev  = sfile->lev
    hyai = sfile->hyam                                  ; midlayer coef
    hybi = sfile->hybm   
    p0   = 100000                                   ; reference pressure (Pa)
    var_name = "lnsp"    
    var_in   = sfile->$var_name$(0,0,:,:)              ; (time,lev,lat,lon)
    psfc = exp(var_in)                                 ; surface pressure (Pa)
    var_name = "t"    
    T137   = sfile->$var_name$(0,:,:,:)              ; (time,lev,lat,lon)
    T83=hyi2hyo(p0,hyai/p0,hybi,psfc,T137,hyao,hybo,1)
    var_name = "q"    
    Q137   = sfile->$var_name$(0,:,:,:)              ; (time,lev,lat,lon)
    Q83=hyi2hyo(p0,hyai/p0,hybi,psfc,Q137,hyao,hybo,1)
    var_name = "u"    
    U137   = sfile->$var_name$(0,:,:,:)              ; (time,lev,lat,lon)
    U83=hyi2hyo(p0,hyai/p0,hybi,psfc,U137,hyao,hybo,1)
    var_name = "v"    
    V137   = sfile->$var_name$(0,:,:,:)              ; (time,lev,lat,lon)
    V83=hyi2hyo(p0,hyai/p0,hybi,psfc,V137,hyao,hybo,1)

;---Save intermediate fields with ERA5 lat-lon horizontal grid and
;    CAM 83 final vertical levels
;---open output file
    output="/work/csp/as34319/scratch/interp/vert_inter_chec.nc"
    system("/bin/rm -f "+output)
    ncdf=addfile(output,"c")
    ncdf->lat=src_lat
    ncdf->lon=src_lon
    vaout=U83
    vaout!0="lev"
    vaout!1="lat"
    vaout!2="lon"
    ncdf->U83=vaout
    varin=U137
    varin!0="src_lev"
    ncdf->U137=varin
    vaout=V83
    vaout!0="lev"
    vaout!1="lat"
    vaout!2="lon"
    ncdf->V83=vaout
    varin=V137
    varin!0="src_lev"
    ncdf->V137=varin
    vaout=T83
    vaout!0="lev"
    vaout!1="lat"
    vaout!2="lon"
    ncdf->T83=vaout
    varin=T137
    varin!0="src_lev"
    ncdf->T137=varin
    vaout=Q83
    vaout!0="lev"
    vaout!1="lat"
    vaout!2="lon"
    ncdf->Q83=vaout
    varin=Q137
    varin!0="src_lev"
    ncdf->Q137=varin


    src_file = "/work/csp/cp1//inputs/CESM/CMCC-CPS1/regrid_files/src_fileEDA.nc"
    dst_file = "/work/csp/cp1//inputs/CESM/CMCC-CPS1/regrid_files/dst_fileFV0.47x0.63_L83.nc"
    wgt_file ="/work/csp/cp1//inputs/CESM/CMCC-CPS1/regrid_files/EDA2FV0.47x0.63_L83.nc"
    wgt_file_slon ="/work/csp/cp1//inputs/CESM/CMCC-CPS1/regrid_files/EDA2FV0.47x0.63_L83_slon.nc"
    wgt_file_slat ="/work/csp/cp1//inputs/CESM/CMCC-CPS1/regrid_files/EDA2FV0.47x0.63_L83_slat.nc"
    print("------------------------------------------------------------")
    print("Will be regridded to the FV 0.47x0.63 L83 grid")
    print("------------------------------------------------------------")

;--now do the horizontal interpolation
;---Data file containing destination grid
    dfile   = fC
    dst_lat = dfile->lat
    dst_lon = dfile->lon
    dst_slat = dfile->slat
    dst_slon = dfile->slon

;---Set up regridding options
    Opt                = True

    Opt@InterpMethod  = "bilinear"   ; "patch", "conserve"

    Opt@WgtFileName  = wgt_file

    Opt@SrcGridLat     = src_lat
    Opt@SrcGridLon     = src_lon
    Opt@SrcRegional    = False

    Opt@ForceOverwrite = True
    Opt@Debug          = True
    Opt@PrintTimings   = True

    Opt@DstGridLat = dst_lat
    Opt@DstGridLon = dst_lon
;    Opt@DstGridType ="unstructured"

;---Set up regridding options
    Opt1                = True

;---"bilinear" is the default. "patch" and "conserve" are other options.
    interp_method="bilinear"
    Opt1@InterpMethod     = interp_method
    Opt1@WgtFileName      = wgt_file_slat

    Opt1@SrcGridLat       = src_lat
    Opt1@SrcGridLon       = src_lon
    Opt1@SrcInputFileName = src_file

    Opt1@DstGridLat       = dst_slat
    Opt1@DstGridLon       = dst_lon

    Opt1@ForceOverwrite   = True
    Opt1@Debug            = True
    Opt1@PrintTimings     = True

;---Set up regridding options
    Opt2                = True

;---"bilinear" is the default. "patch" and "conserve" are other options.
    Opt2@InterpMethod     = interp_method
    Opt2@WgtFileName      = wgt_file_slon

    Opt2@SrcGridLat       = src_lat
    Opt2@SrcGridLon       = src_lon
    Opt2@SrcInputFileName = src_file

    Opt2@DstGridLat       = dst_lat
    Opt2@DstGridLon       = dst_slon

    Opt2@ForceOverwrite   = True
    Opt2@Debug            = True
    Opt2@PrintTimings     = True
;

;---Get variable to regrid   t
    var3d=T83
    nn=dimsizes(var3d)
    nlev=nn(0)
    nlat=dimsizes(dst_lat)
    nlon=dimsizes(dst_lon)
    var_out=new((/1,nlev,nlat,nlon/),typeof(var3d))
    printVarSummary(var_out)
    do k=0,nlev-1
       var_in=var3d(k,:,:)
;---Call the regridding function
       if(isfilepresent(wgt_file)) then
          var_regrid = ESMF_regrid_with_weights(var_in,wgt_file,Opt)
       else
          var_regrid = ESMF_regrid(var_in,Opt)
       end if
       printVarSummary(var_regrid)
       var_out(0,k,:,:)=var_regrid
    end do
    var_out!0="time"
    var_out!1="lev"
    var_out!2="lat"
    var_out!3="lon"
    delete(var_out@lev)
    delete(var_out@_FillValue)
    delete(var_out@missing_value)
    delete(var_out@mdims)
    delete(var_out@time)
    delete(var_out@remap)
    T=var_out
    delete(var_out)
    delete(var_regrid)

;---Get variable to regrid   q
    var3d   = Q83
    var_out=new((/1,nlev,nlat,nlon/),typeof(var3d))
    do k=0,nlev-1
       var_in=var3d(k,:,:)
;---Call the regridding function
       var_regrid = ESMF_regrid_with_weights(var_in,wgt_file,Opt)
       var_out(0,k,:,:)=var_regrid
    end do
    var_out!0="time"
    var_out!1="lev"
    var_out!2="lat"
    var_out!3="lon"
    delete(var_out@lev)
    delete(var_out@_FillValue)
    delete(var_out@missing_value)
    delete(var_out@mdims)
    delete(var_out@time)
    delete(var_out@remap)
    Q=var_out
    delete(var_out)
    delete(var_regrid)


;---Get variable to regrid   u
    var3d   = U83
    var_out=new((/1,nlev,dimsizes(dst_slat),nlon/),typeof(var3d))
    do k=0,nlev-1
       var_in=var3d(k,:,:)
;---Call the regridding function
       if(isfilepresent(wgt_file_slat)) then
          var_regrid = ESMF_regrid_with_weights(var_in,wgt_file_slat,Opt1)
       else
          var_regrid = ESMF_regrid(var_in,Opt1)
       end if
       var_out(0,k,:,:)=var_regrid
    end do
    var_out!0="time"
    var_out!1="lev"
    var_out!2="slat"
    var_out!3="lon"
    delete(var_out@lev)
    delete(var_out@_FillValue)
    delete(var_out@missing_value)
    delete(var_out@mdims)
    delete(var_out@time)
    delete(var_out@remap)
    U=var_out
    delete(var_out)
    delete(var_regrid)


;---Get variable to regrid   v
    var3d   = V83
    var_out=new((/1,nlev,nlat,dimsizes(dst_slon)/),typeof(var3d))
    do k=0,nlev-1
       var_in=var3d(k,:,:)
;---Call the regridding function
       if(isfilepresent(wgt_file_slon)) then
          var_regrid = ESMF_regrid_with_weights(var_in,wgt_file_slon,Opt2)
       else
          var_regrid = ESMF_regrid(var_in,Opt2)
       end if
       var_out(0,k,:,:)=var_regrid
    end do
    var_out!0="time"
    var_out!1="lev"
    var_out!2="lat"
    var_out!3="slon"
    delete(var_out@lev)
    delete(var_out@_FillValue)
    delete(var_out@missing_value)
    delete(var_out@mdims)
    delete(var_out@time)
    delete(var_out@remap)
    V=var_out
    delete(var_out)
    delete(var_regrid)


;---Get variable to regrid  lnsp
;    var_out=new((/1,nlat,nlon/),typeof(var_in))
;---Call the regridding function
;    var_regrid = ESMF_regrid_with_weights(var_in,wgt_file,Opt)
;--now get 2d vars
    var_in=psfc
    var_regrid = ESMF_regrid_with_weights(var_in,wgt_file,Opt)
    delete_VarAtts(var_regrid,-1)
    PS=new((/1,nlat,nlon/),typeof(var3d))
    PS(0,:,:)=var_regrid
    PS!0="time"
    PS!1="lat"
    PS!2="lon"
    PS@units="Pa"
    PS@long_name = "Surface Pressure"
    delete(PS@_FillValue)

;----------------------------------------------------------------------
;---writing section
;---open output file
    output="/work/csp/as34319/scratch/interp/FV0.47X0.63_L83_19800101.nc"
    print(" output file from ncl is "+output)
    system("/bin/rm -f "+output)
    ofile=addfile(output,"c")

    vNames = getfilevarnames(fC) ; get names of all variables on file
    voutNames=vNames
    nNames = dimsizes (vNames)   ; number of variables on the file
    print (vNames)               ; print all variable names on file

    do n=0,nNames-1              ; loop thru each variable
       print("input name "+vNames(n))
       print("output name "+voutNames(n))
       v = fC->$vNames(n)$        ; read the varible to memory

       dimv = dimsizes(v)        ; dimension size of the variable
       rank = dimsizes(dimv)     ; rank [ie: number of dimensions]
       if (rank.lt.3) then
           ofile->$voutNames(n)$=v
       end if
       delete(v)
       delete(dimv)
    end do

;       ofile->P0=fC->P0
;       ofile->hyai=fC->hyai
;    ofile->hybi=fC->hybi
;    ofile->hybm=fC->hybm
;    ofile->slat=fC->slat
;    ofile->slon=fC->slon
;    ofile->w_stag=fC->w_stag
;    ofile->gw=fC->gw
;    ofile->lev=fC->lev
;    ofile->ilev=fC->ilev
;    ofile->lat=dst_lat
;    ofile->lon=dst_lon
;    ofile->slat=dst_slat
;    ofile->slon=dst_slon
;    ofile->time_bnds=fC->time_bnds
;    ofile->date_written=fC->date_written
;    ofile->time_written=fC->time_written
;    ofile->ndbase=fC->ndbase
;    ofile->nsbase=fC->nsbase
;    ofile->nbdate=fC->nbdate
;    ofile->nbsec=fC->nbsec
;    ofile->mdt=fC->mdt
;    ofile->ndcur=fC->ndcur
;    ofile->nscur=fC->nscur
;    ofile->nsteph=fC->nsteph
;    ofile->date=fC->date
;    ofile->datesec=fC->datesec

;--now copy some variables from template too
;    ofile->CLDICE=fC->CLDICE
;    ofile->CLDLIQ=fC->CLDLIQ
;    ofile->CO2=fC->CO2
;    ofile->CO2_FFF=fC->CO2_FFF
;    ofile->CO2_LND=fC->CO2_LND
;    ofile->CO2_OCN=fC->CO2_OCN
;    ofile->DMS=fC->DMS
;    ofile->H2O2=fC->H2O2
;    ofile->H2SO4=fC->H2SO4
;    ofile->SO2=fC->SO2
;    ofile->SOAG=fC->SOAG

    ofile->PS=PS
    delete_VarAtts(T,-1)
    T@units="K"
    T@long_name = "Temperature"
    T@mdims = 1
    ofile->T=T
    delete_VarAtts(Q,-1)
    Q@units="kg/kg"
    Q@long_name = "Specific humidity"
    Q@mixing_ratio = "wet"
    Q@mdims = 1
    ofile->Q=Q
    delete_VarAtts(U,-1)
    U@units="m/s"
    U@mdims = 1
    U@long_name = "Zonal wind, staggered"
    ofile->US=U
    delete_VarAtts(V,-1)
    V@units="m/s"
    V@mdims = 1
    V@long_name = "Meridional wind, staggered"
    ofile->VS=V
    print(time)
    printVarSummary(time)
    ofile->time=time
    system("touch "+checkfile)

end

