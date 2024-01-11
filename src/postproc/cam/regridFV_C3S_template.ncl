;***************************************************************
; NCL script
; regrid 6hr vars from ne60np4 to reg1x1
; for masked variables define and apply the mask after interpolation
;***************************************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
load "$HOME/CPS/CMCC-CPS1/src/templates/C3S_globalatt.ncl"

undef ("definitions")
function definitions(var,cell_method,level,dst_file,plev,nlev,lat,nlat,lon,mlon,timein,nt,reftime,hcrs,realization,lon_bnds,lat_bnds,frqvar,C3S_type)
begin
     yyyy=getenv("yyyy")
     st=getenv("st")
     if (frqvar.eq."12hr" ) then
           dimNames = (/"leadtime","plev","lat","lon", "str31",  "bnds"/)
           dimSizes = (/ nt   ,  nlev,  nlat , mlon ,dimsizes(realization),2/)
           dimUnlim = (/ False ,  False,  False,    False, False,  False  /)
     else if (frqvar.eq."6hr" .or. frqvar.eq."day") then
           dimNames = (/  "leadtime","lat",    "lon", "str31",  "bnds"/)  
           dimSizes = (/  nt, nlat ,   mlon ,  dimsizes(realization), 2 /) 
           dimUnlim = (/    False,False,    False, False,  False  /)   
     else
        dimNames = (/ "lat",    "lon", "str31",  "bnds"/)  
        dimSizes = (/ nlat ,   mlon ,  dimsizes(realization), 2 /) 
        dimUnlim = (/ False,    False, False,  False  /)   
     end if
     end if
     filedimdef(dst_file,dimNames,dimSizes,dimUnlim)
;
     if (frqvar.eq."12hr" ) then
         filevardef(dst_file, "plev", C3S_type, getvardims(plev))
         filevarattdef(dst_file,"plev" ,plev)
     end if
     filevardef(dst_file, "lat", C3S_type, getvardims(lat)) 
     filevarattdef(dst_file,"lat" ,lat)           
 
     filevardef(dst_file, "lon", C3S_type, getvardims(lon)) 
     filevarattdef(dst_file,"lon" ,lon)           

     filevardef(dst_file, "realization", typeof(realization), "str31")
     filevarattdef(dst_file,"realization" ,realization)           

;--- Define accessory vars required by C3S
     filevardef(dst_file, "lon_bnds", C3S_type, (/"lon","bnds"/))
     filevarattdef(dst_file,"lon_bnds" ,lon_bnds)           

     filevardef(dst_file, "lat_bnds", C3S_type, (/"lat","bnds"/))
     filevarattdef(dst_file,"lat_bnds" ,lat_bnds)           

     if (frqvar.ne."fix") then

        if (cell_method.eq."leadtime: sum".or.cell_method.eq."leadtime: maximum (interval: 0.5 hour)".or.cell_method.eq."leadtime: minimum (interval: 0.5 hour)".or.cell_method.eq."leadtime: mean (interval: 0.5 hour)") then
           time=timein-0.5
           time@bounds = "time_bnds" ;
           time_bnds=new((/nt,2/),C3S_type)
           time_bnds(:,0)=time(:)-0.5
           time_bnds(:,1)=time(:)+0.5
           delete_VarAtts(time_bnds,-1)
           leadtime=timein-0.5
           leadtime@bounds = "leadtime_bnds" ;
           leadtime_bnds=time_bnds
           filevardef(dst_file, "leadtime_bnds", C3S_type, (/"leadtime","bnds"/))
           filevarattdef(dst_file,"leadtime_bnds" ,leadtime_bnds)           
   
           filevardef(dst_file, "time_bnds", C3S_type, (/"leadtime","bnds"/))
           filevarattdef(dst_file,"time_bnds" ,time_bnds)           

           dst_file->time_bnds = (/time_bnds/)
           dst_file->leadtime_bnds = (/time_bnds/)
        else if (cell_method.eq."leadtime: point") then
           time=timein
           leadtime=timein
           delete(leadtime@bounds)
           delete(time@bounds)
        end if 
        end if 
        time@units = "days since "+yyyy+"-"+st+"-01T00:00:00Z" ;
        time@long_name = "Verification time of the forecast" ;
        time@standard_name = "time" ;
        time@calendar = "gregorian" ;
        delete(leadtime@calendar)
        leadtime@units = "days"
        leadtime@long_name = "Time elapsed since the start of the forecast"
        leadtime@standard_name = "forecast_period"
        filevardef(dst_file, "leadtime", C3S_type, "leadtime")
        filevarattdef(dst_file,"leadtime" ,leadtime)           

        filevardef(dst_file, "time", C3S_type, "leadtime")
        filevarattdef(dst_file,"time" ,time)           

        filevardef(dst_file, "reftime", C3S_type, "ncl_scalar")
        filevarattdef(dst_file,"reftime" ,reftime)           

        dst_file->time = (/time/)
        dst_file->leadtime = (/leadtime/)
        if (var.eq."sic") then
           dst_file->time = (/timein-1/)
           dst_file->leadtime = (/timein-1/)
        end if
        dst_file->reftime = (/reftime/)
        delete(leadtime@bounds)
        delete(time@bounds)
     end if 

     filevardef(dst_file, "hcrs", "character", "ncl_scalar")
     filevarattdef(dst_file,"hcrs" ,hcrs)           

     if (frqvar.eq."12hr") then
           dst_file->plev = (/ plev*100 /)
     end if
     dst_file->lat = (/ lat /)
     dst_file->lon = (/ lon /)
     dst_file->lon_bnds = (/ lon_bnds /)
     dst_file->lat_bnds = (/ lat_bnds /)
     dst_file->realization = (/realization/)
     dst_file->hcrs = (/hcrs/)

; trick. I do not know how to do without
     x=0.
     return(x)
end

begin

  srcFileName   = getenv("inputFV")
  srcGridName   = getenv("srcGridNameFV")
  dstGridName   = getenv("dstGridName")
  fixsimdays      = getenv("fixsimdays")   ; impostiamo da fuori 185 C3S2_370

; output required precision
  C3S_type="double"
  C3S_type_var="float"

  print("Beginning to regrid "+srcFileName)

; --- Define grid
  outputgrid=getenv("outputgrid")

; 0. Set the source/destination file names, 
;    open the source file for reading, 
;    create a destination file for regridded data.
;------------------------------------------------

  print(" ")
  print("Regridding: ")
  print("SRC:"+srcFileName)
  src_file=addfile(srcFileName,"r")

;
;
; 2. Generate a description file for the destination grid.
;-----------------------------------------------------
  print("---dstGridName "+dstGridName)
  if(isfilepresent(dstGridName)) then
      print("Found dstGrid description "+dstGridName)
  else
      print("Creating dstGrid description "+dstGridName)
      if(outputgrid.eq."reg1x1") then
        Opt                = True
        Opt@LLCorner       = (/-89.5,.5 /)
        Opt@URCorner       = (/ 89.5, 359.5 /)
        Opt@ForceOverwrite = True
        Opt@PrintTimings   = True
        Opt@Title          = "World grid 1x1 degree resolution"

        latlon_to_SCRIP(dstGridName,"1deg",Opt)

;---Clean up
        delete(Opt)
    else
        Opt               =True
        Opt@ForceOverWrite=True
        Opt@Debug         =False ; True
        Opt@PrintTimings  =False ; True
        lats              =latGlobeF(ny,"lat","latitude" ,"degrees_north")
        lons              =lonGlobeF(nx,"lon","longitude","degrees_east" )
        rectilinear_to_SCRIP(dstGridName,lats,lons,Opt)
        delete(lats)
        delete(lons)
        delete(Opt)
    end if
  end if

;
; 3. Generate the weights file, using the source and 
;    destination files created in #1 and #2.
;-----------------------------------------------------
   wgtFileName=getenv("wgtFileName") 
   Opt               = True
   Opt@WgtFileName=wgtFileName
   Opt@InterpMethod  ="bilinear" ; "patch", "conserve"
   Opt@SrcInputFileName  = srcFileName
   Opt@SrcTitle="FV grid"
;---Destination file options
   Opt@DstGridType       = "1x1"               ; 1x1 degree grid
   Opt@DstLLCorner       = (/ -89.5,   0.5/)
   Opt@DstURCorner       = (/  89.5, 359.5/)

   Opt@ForceOverwrite    = True

   Opt@PrintTimings  =False ; True

;
; 3. Generate the weights file for conservative interpolation, 
;    using the source and 
;    destination files created in #1 and #2.
;-----------------------------------------------------
   wgtFileNameCons=getenv("wgtFileNameCons") 
   OptCons               = True
   OptCons@WgtFileNameCons=wgtFileNameCons
   OptCons@InterpMethod  ="conserve"
   OptCons@SrcInputFileName  = srcFileName
   OptCons@SrcTitle="FV grid"
;---Destination file options
   OptCons@DstGridType       = "1x1"               ; 1x1 degree grid
   OptCons@DstLLCorner       = (/ -89.5,   0.5/)
   OptCons@DstURCorner       = (/  89.5, 359.5/)

   OptCons@ForceOverwrite    = True

   OptCons@PrintTimings  =False ; True

;---Read from the weight file the method used to derive the remap weights
   wgt_file       = addfile(wgtFileName, "r")
   dst_grid_dims  = wgt_file->dst_grid_dims
   dst_mlon       = dst_grid_dims(0)
   dst_nlat       = dst_grid_dims(1)
   dst_lat        = wgt_file->yc_b(::dst_mlon)
   dst_lon        = wgt_file->xc_b(:dst_mlon-1)

; =====================================================================
; Define input var list and output var and realm list 
; =====================================================================

  C3Stable=getenv("C3Stable")
  strs = asciiread(C3Stable,-1,"string")
  delim=","
  nfield = str_fields_count(strs(0), delim)
  field=1
  varin = str_get_field(strs(1:), field, delim) 
  field=2
  varout = str_get_field(strs(1:), field, delim) 
  field=3
  dimNames = str_get_field(strs(1:), field, delim) 
  field=4
  LongName = str_get_field(strs(1:), field, delim) 
  field=5
  StandardName = str_get_field(strs(1:), field, delim) 
  field=6
  units = str_get_field(strs(1:), field, delim) 
  field=7
  frq = str_get_field(strs(1:), field, delim) 
  field=8
  level = str_get_field(strs(1:), field, delim) 
  field=9
  realm = str_get_field(strs(1:), field, delim) 
  field=10
  conv_fac = tofloat(str_get_field(strs(1:), field, delim) )
  field=11
  coordinates = str_get_field(strs(1:), field, delim )
  field=12
  cell_method = str_get_field(strs(1:), field, delim )
  field=13
  varflg = toint(str_get_field(strs(1:), field, delim ))
  field=14
  type = str_get_field(strs(1:), field, delim )

  frqin="FRQIN"  ; output frequency
  typein="TYPEIN"  ; output frequency
  print("----going to process "+typein)

  if (typein.eq."h2")then
     plev       = (/1000.,925.,850.,700.,500.,400.,300.,200.,100.,50.,30.,10./)
     nlev=dimsizes(plev)
     plev!0     = "plev"
     plev@units = "Pa"
     plev@long_name = "pressure" ;
     plev@standard_name = "air_pressure" ;
     plev@axis = "Z" ;
     plev@positive = "down" ;
     plev&plev   =  plev
     levstr       = (/"1000","925","850","700","500","400","300","200","100","050","030","010"/)
  else
     plev=0     ; you need to define plev and nlev for function
                ; definitions
  end if
 

;---Use the destination grid info on the weight file to create lat/lon
  lat       = dst_lat                  ; get from weight file
  lat!0     = "lat"
  lat@units = "degrees_north" ;
  lat@long_name = "latitude" ;
  lat@standard_name = "latitude" ;
  lat@axis = "Y" ;
  lat@bounds = "lat_bnds" ;
  lat@valid_min = -90. ;
  lat@valid_max = 90. ;
  lat&lat   =  lat
  nlat      = dimsizes(lat)            ; same as dst_nlat

  lon       = dst_lon
  lon!0     = "lon"
  lon&lon   =  lon
  lon@units = "degrees_east" ;
  lon@long_name = "longitude" ;
  lon@standard_name = "longitude" ;
  lon@axis = "X" ;
  lon@bounds = "lon_bnds" ;
  lon@valid_min = 0. ;
  lon@valid_max = 360. ;
  mlon      = dimsizes(lon)            ; same as dst_mlon

;--- Define accessory vars required by C3S
  lon_bnds=new((/mlon,2/),C3S_type)
  lon_bnds(:,0)=lon(:)-0.5
  lon_bnds(:,1)=lon(:)+0.5
  delete_VarAtts(lon_bnds,-1)

  lat_bnds=new((/nlat,2/),C3S_type)
  lat_bnds(:,0)=lat(:)-0.5
  lat_bnds(:,1)=lat(:)+0.5
  delete_VarAtts(lat_bnds,-1)

  real="MEMBER"
  realization=tochar(real+"                      ")
  realization@units = "1"
  realization@long_name = "realization" ;
  realization@standard_name = "realization" ;
  realization@axis = "E" ;

  hcrs = tochar("")
  hcrs@grid_mapping_name = "latitude_longitude"

  height=0.     ; initialization needed to define attributes
  height@valid_min = 1.
  height@valid_max = 30.
  height@long_name = "height"
  height@standard_name = "height"
  height@units = "m"
  height@axis = "Z"
  height@positive = "up"

  yyyy=getenv("yyyy")
  st=getenv("st")
  reftime=0
  reftime@long_name = "Start date of the forecast" ;
  reftime@standard_name = "forecast_reference_time" ;
  reftime@calendar = "gregorian" ;
  reftime@units = "days since "+yyyy+"-"+st+"-01T00:00:00Z" ;

; Get extra vars needed to postproc
;  frqin.eq."6hr"
  if (typein.eq."h1")then
; CAM does not output u10 and v10 but the module only
     wind10=src_file->U10
; last dynamical level is about 60m
     u60=src_file->UBOT
     v60=src_file->VBOT
; Define some quantities needed for pp
     wind60=tofloat(sqrt(u60^2+v60^2))
     rapporto=where(wind60.ne.0.,wind10/wind60,0.)
  end if

;===================================================================
; definitions to use poisson extrapolation
;===================================================================
  guess     = 1                ; use zonal means
  is_cyclic = True             ; cyclic [global]
  nscan     = 1500             ; usually much less than this
  eps       = 1.e-2            ; variable dependent
  relc      = 0.6              ; relaxation coefficient
  opt       = 0                ; not used

;===================================================================
; get the coordinate dimension names and their sizes
;===================================================================
  dNames   = getvardims(src_file)       ; get level info from source file
  dSizes   = getfiledimsizes(src_file)
  it       = ind(dNames.eq."time")
  nt     = dSizes(it)
  timein=src_file->time

;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;                    PREDEFINE MODE
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    
  outDir=getenv("outdirC3S")
  if(isfilepresent(outDir+"/regridSE_C3S.ncl_"+typein+"_"+real+"_ok") ) then
     system("rm -f "+outDir+"/regridSE_C3S.ncl_"+typein+"_"+real+"_ok")
  end if

  typeofrun=getenv("typeofrun")
  Opt = True
  Opt@WgtFileName       = wgtFileName
  do k=0,dimsizes(varin)-1
    Opt@InterpMethod  ="bilinear" 
    if ( typein.eq.type(k)) then
       global=define_att(realm(k),level(k),frq(k)) 
       source=str_split(global@source,":")
       ini_term=getenv("ini_term")
       print(" ")
       print("Output C3S field -------- "+varout(k))
       print("type C3S field -------- "+type(k))
       dstFileName=outDir+"/"+ini_term+"_"+realm(k)+"_"+frq(k)+"_"+level(k)+"_"+varout(k)+"_"+real+".nc"
       print("DST:"+dstFileName)
       if(isfilepresent(dstFileName)) then
         system("rm "+dstFileName)
       end if
       setfileoption("nc","Format","NetCDF4Classic")
       setfileoption("nc","CompressionLevel",6)
       setfileoption("nc","preFill",False)
       dst_file=addfile(dstFileName,"c")     
       setfileoption(dst_file,"DefineMode",True)
   
    ;===================================================================
   ; create global attributes of the netCDF file containing regridded data
   ;===================================================================
       fileattdef( dst_file, global )        ; copy file attributes to netCDF file
       stat=definitions(varout(k),cell_method(k),level(k),dst_file,plev,dimsizes(plev),lat,nlat,lon,mlon,timein,nt,reftime,hcrs,realization,lon_bnds,lat_bnds,frq(k),C3S_type)
   ;===================================================================
   ; predefine the coordinate dimension names and their sizes
   ;===================================================================
   ;--- Loop over all variables and predfine meta data
       if (frq(k).eq."12hr")then
            filevardef(dst_file,varout(k),C3S_type_var \
                             , (/ "leadtime", "plev","lat", "lon" /)  )
       else if(frq(k).eq."6hr".or.frq(k).eq."day")then
            filevardef(dst_file,varout(k),C3S_type_var \
                                 , (/ "leadtime", "lat", "lon" /)        )
       else
          filevardef(dst_file,varout(k),C3S_type_var \
                                 , (/ "lat", "lon" /)        )
       end if 
       end if
   
       dumAtts = new( 1, C3S_type_var)
       dumAtts@long_name = LongName(k)
       dumAtts@standard_name = StandardName(k)
       dumAtts@units = units(k)
       dumAtts@coordinates = coordinates(k)
       if ( cell_method(k).ne."dummy" ) then
          dumAtts@cell_methods = cell_method(k)
       end if
       dumAtts@grid_mapping = "hcrs" ;
       if(varout(k).ne."tso".and.varout(k).ne."tsl".and.varout(k).ne."sic".and.varout(k).ne."sitemptop") then
          delete(dumAtts@_FillValue)
       else
          dumAtts@_FillValue=1.e+20
          dumAtts@missing_value=1.e+20
       end if
            
       filevarattdef(dst_file, varout(k) , dumAtts)
       delete([dumAtts])   ; may change size next iteration
   
   ;===================================================================
   ; explicitly exit file definition mode. **NOT REQUIRED in NCL**
   ;===================================================================
       setfileoption(dst_file,"DefineMode",False)
           
   ;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   ;        Write the basic and regridded data values to the predefined structures
   ;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   
       if (varout(k).ne."rlt") then
          if (typein.ne."h2")then
             var2regrid=conv_fac(k)*tofloat(src_file->$varin(k)$)
          end if
          if (typein.eq."h1")then
             if ( varout(k).eq."tas") then
                height=2.
                height@valid_max = 10.
                filevardef(dst_file, "height", C3S_type, "ncl_scalar")
                filevarattdef(dst_file,"height" ,height)           
                dst_file->height = (/ height/)
             end if
             if ( varout(k).eq."tdps") then
                tref=src_file->TREFHT
                rhref=src_file->RHREFHT
   ;__________________________________________________________
   ; compute dewpoint temp from t2m and rh2m
   ;__________________________________________________________
                var2regrid=dewtemp_trh(tref,rhref)
                height=2.
                height@valid_max = 10.
                filevardef(dst_file, "height", C3S_type, "ncl_scalar")
                filevarattdef(dst_file,"height" ,height)           
                dst_file->height = (/ height/)
             end if
             if ( varout(k).eq."uas") then
   ;__________________________________________________________
   ; derive u10 from ubot
   ;__________________________________________________________
                var2regrid=u60*rapporto
                height=10.
                height@valid_max = 30.
                filevardef(dst_file, "height", C3S_type, "ncl_scalar")
                filevarattdef(dst_file,"height" ,height)           
                dst_file->height = (/ height/)
             end if
             if ( varout(k).eq."vas") then
   ;_________________________________________________________
   ; derive v10 from vbot
   ;__________________________________________________________
                var2regrid=v60*rapporto
                height=10.
                height@valid_max = 30.
                filevardef(dst_file, "height", C3S_type, "ncl_scalar")
                filevarattdef(dst_file,"height" ,height)           
                dst_file->height = (/ height/)
             end if
             if ( varout(k).eq."sitemptop") then
   ;__________________________________________________________
   ; regrid icefrac from ne60np4 to reg1x1
   ;__________________________________________________________
                if(isfilepresent(wgtFileName)) then
                   icefrac1x1=ESMF_regrid_with_weights(src_file->ICEFRAC,wgtFileNameCons,OptCons)
                else
                   icefrac1x1=ESMF_regrid(src_file->ICEFRAC,OptCons)
                end if
   ;__________________________________________________________
   ; define icemask as 1 where icefrac > .15
   ;__________________________________________________________
                sim1x1=where(icefrac1x1.gt..15,1.,0.)
                ts1x1=ESMF_regrid_with_weights(src_file->TS,wgtFileName,Opt)
                landfrac1x1=ESMF_regrid_with_weights(src_file->LANDFRAC,wgtFileName,Opt)
   ;__________________________________________________________
   ; define lsm  as 1 where landfrac > .5
   ;__________________________________________________________
                lsm1x1=where(landfrac1x1.gt.0.5,1.,0.)
                ts1x1@_FillValue = 1.e+20
                ts1x1=where(lsm1x1.eq.1.,ts1x1@_FillValue,ts1x1)
                ts1x1=where(sim1x1.eq.0.,ts1x1@_FillValue,ts1x1)
   ;__________________________________________________________
   ; apply icemask to tskin
   ;__________________________________________________________
                dst_file->$varout(k)$ = (/ ts1x1/)
             else if ( varout(k).eq."tso") then
   ;__________________________________________________________
   ; regrid icefrac from ne60np4 to reg1x1
   ;__________________________________________________________
                if(isfilepresent(wgtFileName)) then
                   icefrac1x1=ESMF_regrid_with_weights(src_file->ICEFRAC,wgtFileNameCons,OptCons)
                else
                   icefrac1x1=ESMF_regrid(src_file->ICEFRAC,OptCons)
                end if
   ;__________________________________________________________
   ; define icemask as 1 where icefrac > .15
   ;__________________________________________________________
                sim1x1=where(icefrac1x1.gt..15,1.,0.)
                landfrac1x1=ESMF_regrid_with_weights(src_file->LANDFRAC,wgtFileName,Opt)
   ;__________________________________________________________
   ; define lsm  as 1 where landfrac > .5
   ;__________________________________________________________
                lsm1x1=where(landfrac1x1.gt.0.5,1.,0.)
   ;__________________________________________________________
   ; apply icemask to tskin
   ;__________________________________________________________
                ts1x1=ESMF_regrid_with_weights(src_file->TS,wgtFileName,Opt)

                ts1x1@_FillValue = 1.e+20
                ts1x1=where(icefrac1x1.gt.0.,273.15-1.8,ts1x1)
                ts1x1=where(landfrac1x1.gt.0.,ts1x1@_FillValue,ts1x1)
                poisson_grid_fill( ts1x1, is_cyclic, guess, nscan, eps, relc, opt)
                ts1x1@_FillValue = 1.e+20
                ts1x1=where(sim1x1.eq.1.,273.15-1.8,ts1x1)
                ts1x1=where(lsm1x1.eq.1.,ts1x1@_FillValue,ts1x1)
                ts1x1(:,0:30,:)=where(ts1x1(:,0:30,:).lt.273.15-1.8,273.15-1.8,ts1x1(:,0:30,:))
                ts1x1@_FillValue = 1.e+20
                dst_file->tso = (/ts1x1/)
             else if ( varout(k).eq."tsl") then
                if(isfilepresent(wgtFileName)) then
                   landfrac1x1=ESMF_regrid_with_weights(src_file->LANDFRAC,wgtFileName,Opt)
                else
                   landfrac1x1=ESMF_regrid(src_file->LANDFRAC,Opt)
                end if
   ;__________________________________________________________
   ; define lsm  as 1 where landfrac > .5
   ;__________________________________________________________
                lsm1x1small=where(landfrac1x1.gt.0.8,1.,0.)
                lsm1x1=where(landfrac1x1.gt.0.5,1.,0.)
                ts1x1=ESMF_regrid_with_weights(src_file->TS,wgtFileName,Opt)
                outvar=ts1x1*lsm1x1small
                outvar@_FillValue = 1.e+20
                outvar=where(outvar.eq.0.,outvar@_FillValue,outvar)
                poisson_grid_fill( outvar, is_cyclic, guess, nscan, eps, relc, opt)
                outvar=outvar*lsm1x1
                outvar@_FillValue = 1.e+20
                outvar=where(outvar.eq.0.,outvar@_FillValue,outvar)
                dst_file->$varout(k)$ = (/ outvar/)
             else if ( varout(k).eq."clt") then
                if(any(var2regrid.lt.-1.e-12))  then
                    print("clt contains one or more values lower than -1.e-12, cannot continue.")
                    exit
                end if
                if(isfilepresent(wgtFileName)) then
                   tmpclt = (/ ESMF_regrid_with_weights(var2regrid,wgtFileName,Opt) /)
                else
                   tmpclt = (/ ESMF_regrid(var2regrid,Opt) /)
                end if
                tmpclt=where(tmpclt.lt.0.,0.,tmpclt)
                dst_file->$varout(k)$ = (/ tmpclt/)
                delete(tmpclt)
   ;__________________________________________________________
             else 
                if(isfilepresent(wgtFileName)) then
                   dst_file->$varout(k)$ = (/ ESMF_regrid_with_weights(var2regrid,wgtFileName,Opt) /)
                else
                   dst_file->$varout(k)$ = (/ ESMF_regrid(var2regrid,Opt) /)
                end if
             end if
             end if
             end if
             end if
          else if(typein.eq."h0")then
             if(isfilepresent(wgtFileName)) then
                var1x1= ESMF_regrid_with_weights(var2regrid,wgtFileName,Opt)
             else
                var1x1= ESMF_regrid(var2regrid,Opt)
             end if
             if(varout(k).eq."orog" )then
                dst_file->$varout(k)$ = var1x1/9.18
             else if(varout(k).eq."sftlf" )then
                dst_file->$varout(k)$ = var1x1
             end if
             end if
          else if(typein.eq."h2")then
; varin T, Q, U...
; read the first pressure level defined through string variable levstr
; e.g. T1000, Q1000, U1000 ...
             varlevin=varin(k)+levstr(0)
             var2regrid=conv_fac(k)*tofloat(src_file->$varlevin$)
             if(isfilepresent(wgtFileName)) then
                var1x1= ESMF_regrid_with_weights(var2regrid,wgtFileName,Opt)
             else
                var1x1= ESMF_regrid(var2regrid,Opt)
             end if
             dim2d=dimsizes(var1x1)
; define the output variable on plev required by C3S
             var3d=new((/dim2d(0),nlev,dim2d(1),dim2d(2)/),C3S_type_var)
; assign the first level
             var3d(:,0,:,:)=var1x1
; now progres with other levels
             do il=1,nlev-1
                varlevin=varin(k)+levstr(il)
                var2regrid=conv_fac(k)*tofloat(src_file->$varlevin$)
                var3d(:,il,:,:)= ESMF_regrid_with_weights(var2regrid,wgtFileName,Opt)
             end do
             dst_file->$varout(k)$ = var3d
             delete(var2regrid)
   ;         frqin.eq."day"
          else if(typein.eq."h3")then
             if ( varout(k).eq."wsgmax") then
                height=10.
                height@valid_max = 30.
                filevardef(dst_file, "height", C3S_type, "ncl_scalar")
                filevarattdef(dst_file,"height" ,height)           
                dst_file->height = (/ height/)
             end if
             if ( varout(k).eq."tasmax") then
                height=2.
                height@valid_max = 10.
                filevardef(dst_file, "height", C3S_type, "ncl_scalar")
                filevarattdef(dst_file,"height" ,height)           
                dst_file->height = (/ height/)
             end if
             if ( varout(k).eq."tasmin") then
                height=2.
                height@valid_max = 10.
                filevardef(dst_file, "height", C3S_type, "ncl_scalar")
                filevarattdef(dst_file,"height" ,height)           
                dst_file->height = (/ height/)
             end if
             if (varout(k).eq."lweprsn") then
                var2regrid=(src_file->PRECSL*conv_fac(k)+src_file->PRECSC*conv_fac(k))
                var2regrid=where(var2regrid.lt.0.,0.,var2regrid)
                Opt@InterpMethod  ="conserve"
             end if
             if (varout(k).eq."lwepr") then
                if(any(var2regrid.lt.-0.005))  then
                    print("lwepr contains one or more values lower than -5mm/day, cannot continue.")
                    exit
                end if
                var2regrid=where(var2regrid.lt.0.,0.,var2regrid)
                Opt@InterpMethod  ="conserve"
             end if
             if ( varout(k).eq."sic" ) then
                if(isfilepresent(wgtFileName)) then
                   icefrac1x1=ESMF_regrid_with_weights(var2regrid,wgtFileNameCons,OptCons)        
                else
                   icefrac1x1=ESMF_regrid(var2regrid,OptCons)        
                end if
                delete(var2regrid)
   ;__________________________________________________________
   ; read lsm binary from repogrid
   ;__________________________________________________________
                lsmFileName=getenv("lsmFileName")
                lsm_file=addfile(lsmFileName,"r")
                landseamask=lsm_file->lsmC3S_SPS4(0,:,:) 
                icefrac1x1@_FillValue = 1.e+20
                ndims=dimsizes(icefrac1x1)
                do it=0,ndims(0)-1
                   icefrac1x1(it,:,:)=where(landseamask(:,:).eq.1.,icefrac1x1@_FillValue,icefrac1x1(it,:,:))
                end do
                dst_file->$varout(k)$ =(/icefrac1x1/)
             else if (varout(k).eq."lweprc".or.varout(k).eq."lwepr".or.varout(k).eq."lweprsn") then
                if(isfilepresent(wgtFileName)) then
                   tmp = (/ ESMF_regrid_with_weights(var2regrid,wgtFileNameCons,OptCons) /)
                else
                   tmp = (/ ESMF_regrid(var2regrid,OptCons) /)
                end if
                tmp=where(tmp.lt.0.,0.,tmp)
                dst_file->$varout(k)$ =(/tmp/)
             else    
                if(isfilepresent(wgtFileName)) then
                   dst_file->$varout(k)$ = (/ ESMF_regrid_with_weights(var2regrid,wgtFileName,Opt) /)
                else
                   dst_file->$varout(k)$ = (/ ESMF_regrid(var2regrid,Opt) /)
                end if
                delete(var2regrid)
             end if
             end if
          end if   ;if on output frq h1
          end if   ;if on output frq h3
          end if   ;if on output frq h2
          end if   ;if on output frq h0
       else   ; rlt
           var2regrid=conv_fac(k)*(src_file->FSNTOA-src_file->FSNT+src_file->FLNT)
           if(isfilepresent(wgtFileName)) then
              dst_file->$varout(k)$ = (/ ESMF_regrid_with_weights(var2regrid,wgtFileName,Opt) /)
           else
              dst_file->$varout(k)$ = (/ ESMF_regrid(var2regrid,Opt) /)
           end if
           delete(var2regrid)
       end if
    end if   ;if on selected frequency typein
  end do
; touch file to state that the process is correctly finished
  checkfile=getenv("checkfile")
  system("touch "+checkfile)
end
