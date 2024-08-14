load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
load "$HOME/CPS/CMCC-CPS1/src/templates/C3S_globalatt.ncl"

undef ("definitions")
function definitions(ncdf,lat,nlat,lon,nlon,leadtime,time,nt,reftime,realization,lon_bnds,lat_bnds,leadtime_bnds,time_bnds,C3S_type)
begin

    ncdfAtt = True
    fileattdef( ncdf, ncdfAtt )            ; copy file attributes    


    dimNames = (/"leadtime","lat","lon", "str31",  "bnds"/)
    dimSizes = (/ nt   ,  nlat,  nlon,dimsizes(realization),2 /) 
    dimUnlim = (/ False , False, False,False,False/)   
    filedimdef(ncdf,dimNames,dimSizes,dimUnlim)


    filevardef(ncdf, "lat"  ,C3S_type,getvardims(lat))                          
    lat@bounds="lat_bnds"
    lat@valid_max = 90.d
    lat@valid_min = -90.d    
    lat@axis = "Y" 
    lat@standard_name = "latitude"
    filevarattdef(ncdf,"lat"  ,lat)                     ; copy lat attributes

    filevardef(ncdf, "lon"  ,C3S_type,getvardims(lon))           
    lon@bounds="lon_bnds"
    lon@valid_max = 360.d
    lon@valid_min = 0.d
    lon@axis = "X" 
    lon@standard_name = "longitude"
    filevarattdef(ncdf,"lon"  ,lon)                     ; copy lon attributes

    filevardef(ncdf, "realization", typeof(realization), "str31")
    filevarattdef(ncdf,"realization" ,realization)    

;--- Define accessory vars required by C3S 
    filevardef(ncdf, "lon_bnds", C3S_type, (/"lon","bnds"/))
    filevarattdef(ncdf,"lon_bnds" ,lon_bnds)

    filevardef(ncdf, "lat_bnds", C3S_type, (/"lat","bnds"/))
    filevarattdef(ncdf,"lat_bnds" ,lat_bnds)

    filevardef(ncdf, "leadtime", C3S_type, "leadtime")
    filevarattdef(ncdf,"leadtime" ,leadtime)

    filevardef(ncdf, "time", C3S_type, "leadtime")
    filevarattdef(ncdf,"time" ,time)

    filevardef(ncdf, "leadtime_bnds", C3S_type, (/"leadtime","bnds"/))
    filevarattdef(ncdf,"leadtime_bnds" ,leadtime_bnds)

    filevardef(ncdf, "time_bnds", C3S_type, (/"leadtime","bnds"/))
    filevarattdef(ncdf,"time_bnds" ,time_bnds)

    filevardef(ncdf, "reftime", C3S_type, "ncl_scalar")
    filevarattdef(ncdf,"reftime" ,reftime)

    ncdf->leadtime = (/leadtime/)
    ncdf->leadtime_bnds = (/leadtime_bnds/)
    ncdf->time = (/time/)
    ncdf->time_bnds = (/time_bnds/)
    ncdf->reftime = (/reftime/)

    hcrs=""
    hcrs@grid_mapping_name = "latitude_longitude"
    filevardef(ncdf, "hcrs", typeof(realization), "ncl_scalar")
    filevarattdef(ncdf,"hcrs" ,hcrs)

;    setfileoption(ncdf,"DefineMode",False)

     ncdf->lat    = (/lat/)
     ncdf->lon    = (/lon/) 
     ncdf->lon_bnds = (/ lon_bnds /)
     ncdf->lat_bnds = (/ lat_bnds /)
     ncdf->realization = (/realization/)
; trick. I do not know how to do without
     x=0.
     return(x)
end

begin

;---Remove old checkfile
    checkfile=getenv("check_iceregrid")
    if (isfilepresent(checkfile)) then
      system("/bin/rm " + checkfile)
    end if

;---Input file
    yyyy = getenv("yyyy")
    st = getenv("st")
    srcFileName = getenv("inputfile")
    lsmFileName = getenv("lsmfile")
    lsmfile = addfile(lsmFileName,"r")
    lsm=tofloat(lsmfile->lsmC3S_SPS4)
    delete(lsm@_FillValue)
    slm=lsm+1.
    slm=where(slm.eq.2.,0.,slm)
    lat=lsmfile->lat
    nlat=dimsizes(lat)
    lon=lsmfile->lon
    nlon=dimsizes(lon)

   ;--- Define accessory vars required by C3S 
    C3S_type="double"
    C3S_type_var="float"
    lon_bnds=new((/nlon,2/),C3S_type)
    lon_bnds(:,0)=lon(:)-0.5
    lon_bnds(:,1)=lon(:)+0.5
    delete_VarAtts(lon_bnds,-1)

    lat_bnds=new((/nlat,2/),C3S_type)
    lat_bnds(:,0)=lat(:)-0.5
    lat_bnds(:,1)=lat(:)+0.5
    delete_VarAtts(lat_bnds,-1)

    lon=lonFlip(lon)
    delete(lon@lonFlip)

    real=getenv("real")
    realization=tochar(real+"                      ")  
    realization@units = "1" 
    realization@long_name = "realization" ;
    realization@standard_name = "realization" ;
    realization@axis = "E" ;


    meshmaskfile = getenv("meshmaskfile")
    meshmask = addfile(meshmaskfile,"r")
    tmpnemo=meshmask->tmaskutil
    lsmnemo=where(tmpnemo.eq.0.,-999.,0.)
    lsmnemo@_FillValue=-999.


;---Output (and input) files
    srcGridName = getenv("srcGridName")
    dstGridName = getenv("dstGridName")
    wgtFile     = getenv("wgtFile")

;---Retrieve data from ORCA Grid
    sfile = addfile(srcFileName,"r")
    sic=sfile->aice ;aicen001
    ttmp   = sfile->time
    nt=dimsizes(ttmp)
    delete(ttmp)
    time=new(nt,C3S_type,"No_FillValue")
    ndays=new((/nt/), C3S_type)
    time_bnds=new((/nt,2/),C3S_type)
    mon=tointeger(st)
    yy=tointeger(yyyy)
    totdays=0.d
    do i=0,nt-1
       if (mon.gt.12) then
            yy=yy+1
            mon=1
       end if
       ndays(i)=todouble(days_in_month(yy,mon))
       time_bnds(i,1)=ndays(i)+totdays-1.d
       time_bnds(i,0)=totdays
       totdays=totdays+ndays(i)
       time(i)=(time_bnds(i,1)-time_bnds(i,0))/2+time_bnds(i,0)
       mon=mon+1
    end do

    time@units = "days since "+yyyy+"-"+st+"-01T00:00:00Z" ;
    time@long_name = "Verification time of the forecast" ;
    time@standard_name = "time" ;
    time@calendar = "gregorian" ;
    time@bounds = "time_bnds" ;
    leadtime=time
    leadtime@units = "days"
    leadtime@long_name = "Time elapsed since the start of the forecast"
    leadtime@standard_name = "forecast_period"
    leadtime@bounds = "leadtime_bnds" ;
    delete_VarAtts(leadtime,"calendar")

    delete_VarAtts(time_bnds,-1)

    leadtime_bnds=new((/nt,2/),C3S_type)
    leadtime_bnds=time_bnds
    delete_VarAtts(leadtime_bnds,-1)

    reftime=0
    reftime@long_name = "Start date of the forecast" ;
    reftime@standard_name = "forecast_reference_time" ;
    reftime@calendar = "gregorian" ;
    reftime@units = "days since "+yyyy+"-"+st+"-01T00:00:00Z" ;

  C3Stable=getenv("C3S_table_ocean2d")
  strs = asciiread(C3Stable,-1,"string")
  delim=","
  nfield = str_fields_count(strs(0), delim)
  field=1
  varname = str_get_field(strs(1:), field, delim) 
  print(varname)
  field=2
  varnameout = str_get_field(strs(1:), field, delim) 
  print(varnameout)
  field=3
  longname = str_get_field(strs(1:), field, delim) 
  print(longname)
  field=4
  standname = str_get_field(strs(1:), field, delim)
  print(standname)
  field=5
  unita = str_get_field(strs(1:), field, delim)
  print(unita)
  field=6
  realm = str_get_field(strs(1:), field, delim)
  print(realm)
  field=7
  level = str_get_field(strs(1:), field, delim)
  print(level)
  field=8
  addfact = tofloat(str_get_field(strs(1:), field, delim))
  print(addfact)
  field=9
  coord = str_get_field(strs(1:), field, delim)
  print(coord)
  field=10
  cell_method = (str_get_field(strs(1:), field, delim))
  print(cell_method)
  field=11
  reflev = todouble(str_get_field(strs(1:), field, delim))
  print(reflev)
  field=12
  model = str_get_field(strs(1:), field, delim)
  print(model)
  field=13
  fillval = tofloat(str_get_field(strs(1:), field, delim))
  print(fillval)



    nv=dimsizes(varname)

    nav_lat = meshmask->nav_lat
    nav_lon = meshmask->nav_lon

    lon=lonFlip(lon)
    delete(lon@lonFlip)

    first=1

;-----------------------------------------------------------------
; Set the poisson_grid_fill variables
; Global grid: Fill in over land             
;-----------------------------------------------------------------
    nscan = 1500             ; usually *much* fewer
    eps   = 1.e-2            ; variable depended
    gtype = True             ; Cyclic in longitude [global]
    guess = 0                ; use zonal means
    relc  = 0.6              ; standard relaxation coef
    opt   = 0

;---------------------------------------------
    outdir=getenv("outdirC3S")
    print("this is the output dir "+outdir)
    system("/bin/rm -f "+outdir+"/interp_cice2C3S_through_nemo.ncl_"+real+"_ok")
    do i=0,nv-1
       if(model(i).eq."cice") then
          xin   = sfile->$varname(i)$
          sic@_FillValue=0.
          xin=xin/sic
          xtmp=xin
          nn=dimsizes(xin)
          nt=nn(0)
      ;
          xtmppois=xtmp
      
          printVarSummary(xtmp)
          printVarSummary(lsmnemo)
          do it=0,nt-1
      
             xtmp(it,:,:)=where(lsmnemo(0,:,:).eq.lsmnemo@_FillValue,lsmnemo@_FillValue,xtmp(it,:,:))
      
             tmp2d=xtmp(it,:,:)
             poisson_grid_fill( tmp2d, gtype, guess, nscan, eps, relc, opt)
             xtmppois(it,:,:)=tmp2d
             delete(tmp2d)
          end do
      
          SKIP_ORCA_SCRIP_GEN  = True
          SKIP_WORLD_SCRIP_GEN = True
          SKIP_WGT_GEN         = True
      ;---if you want to print out the intermediate files set first=0
          if (first.eq.0) then
                SKIP_ORCA_SCRIP_GEN  = False
                SKIP_WORLD_SCRIP_GEN = False
                SKIP_WGT_GEN         = False
          end if
      ;----------------------------------------------------------------------
      ; Convert ORCA to SCRIP file.
      ;----------------------------------------------------------------------
          if(.not.SKIP_ORCA_SCRIP_GEN) then
          ;---Convert to an SCRIP Convention file.
                 Opt                = True
                 Opt@ForceOverwrite = True
                 Opt@PrintTimings   = True
                 Opt@Mask2D         = where(.not.ismissing(tos),1,0)
      
                 curvilinear_to_SCRIP(srcGridName,nav_lat,nav_lon,Opt)
      
      ;---Clean up
                 delete(Opt)
          end if
      ;----------------------------------------------------------------------
      ; Convert 2 degree world grid to SCRIP file
      ;----------------------------------------------------------------------
          if(.not.SKIP_WORLD_SCRIP_GEN)
                 Opt                = True
                 Opt@LLCorner       = (/-89.5,-179.5 /)
                 Opt@URCorner       = (/ 89.5, 179.5 /) 
                 Opt@ForceOverwrite = True
                 Opt@PrintTimings   = True
                 Opt@Title          = "World grid 1x1 degree resolution"
      
                 latlon_to_SCRIP(dstGridName,"1deg",Opt)
      
      ;---Clean up
                 delete(Opt)
          end if
      
      ;----------------------------------------------------------------------
      ; Generate interpolation weights for ORCA Grid to World Grid    
      ;----------------------------------------------------------------------
          if(.not.SKIP_WGT_GEN) then
                 Opt                      = True
                 Opt@SrcESMF              = False
                 Opt@DstESMF              = False
                 Opt@ForceOverwrite       = True
                 Opt@PrintTimings         = True
      
                 ESMF_regrid_gen_weights(srcGridName, dstGridName, wgtFile, Opt)
      
      ;---Clean up
                 delete(Opt)
          end if
      
      ;----------------------------------------------------------------------
      ; Interpolate data from ORCA to World 1-degree grid.
      ;----------------------------------------------------------------------
      
          Opt              = True
          Opt@PrintTimings = True
      
          tmp = ESMF_regrid_with_weights(xtmp(0,:,:),wgtFile,Opt)
          mm=dimsizes(tmp)
          varout=new((/nt,mm(0),mm(1)/),C3S_type_var)
          varout@_FillValue=1.e+20
      
          do it=0,nt -1
               tmp = ESMF_regrid_with_weights(xtmppois(it,:,:),wgtFile,Opt)
               tmp=lonFlip(tmp)
               varout(it,:,:)=where(slm(0,:,:).eq.0.,varout@_FillValue,tmp)
          end do
      
      ;---Clean up
          delete(Opt)
          first=1
      
      ;----------------------------------------------------------------------
      ;  Write to a new file 
      ;----------------------------------------------------------------------
          ini_term=getenv("ini_term")
          ic=getenv("ic")
      
          filename3=outdir+"/"+ini_term+"_"+realm(i)+"_mon_"+level(i)+"_"+varnameout(i)+"_"+real+".nc"
          print(filename3)
          system("/bin/rm -f "+filename3)   ; remove any pre-existing file
          setfileoption("nc","Format",  "NetCDF4Classic")
          setfileoption("nc","DefineMode",True)
          setfileoption("nc","CompressionLevel",6)
          setfileoption("nc","preFill",False)
      
          ncdf     = addfile(filename3 ,"c")
      
       ;===================================================================
      ; create global attributes of the netCDF file containing regridded data
      ;===================================================================
          global=define_att(realm(i),level(i),"mon")
          fileattdef( ncdf, global )        ; copy file attributes to netCDF file
      
          stat=definitions(ncdf,lat,nlat,lon,nlon,leadtime,time,nt,reftime,realization,lon_bnds,lat_bnds,leadtime_bnds,time_bnds,C3S_type)
             filevardef(ncdf,varnameout(i),C3S_type_var \
                                    , (/ "leadtime", "lat", "lon" /)        )
          coordinate="reftime realization time leadtime lat lon"
      
          dumAtts = new( 1, C3S_type_var)
          dumAtts@long_name = longname(i)
          dumAtts@standard_name = standname(i)
          dumAtts@units = unita(i)
          dumAtts@coordinates = coord(i)
          dumAtts@cell_methods = cell_method(i)
          dumAtts@grid_mapping = "hcrs" ;
      
          dumAtts@_FillValue=fillval(i)
          dumAtts@missing_value=fillval(i)
          filevarattdef(ncdf, varnameout(i) , dumAtts)
          delete([dumAtts])   ; may change size next iteration
      
          ncdf->$varnameout(i)$=(/varout/)
          system("touch "+checkfile)
     end if 
   end do
end

