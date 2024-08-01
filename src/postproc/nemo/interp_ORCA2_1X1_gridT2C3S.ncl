load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
load "$HOME/CPS/CMCC-CPS1/src/templates/C3S_globalatt.ncl"

undef ("definitions")
function definitions(ncdf,lat,nlat,lon,nlon,leadtime,time,depth,nt,reftime,realization,lon_bnds,lat_bnds,leadtime_bnds,time_bnds,depth_bnds,C3S_type,vname)
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

    filevardef(ncdf, "time_bnds", C3S_type, (/"leadtime","bnds"/))
    filevarattdef(ncdf,"time_bnds" ,time_bnds)

    filevardef(ncdf, "leadtime_bnds", C3S_type, (/"leadtime","bnds"/))
    filevarattdef(ncdf,"leadtime_bnds" ,leadtime_bnds)

    if(vname.eq."somss300".or.vname.eq."somtt300") then
       filevardef(ncdf, "depth_bnds", C3S_type, (/"bnds"/))
       filevarattdef(ncdf,"depth_bnds" ,depth_bnds)
    end if

    filevardef(ncdf, "reftime", C3S_type, "ncl_scalar")
    filevarattdef(ncdf,"reftime" ,reftime)

    ncdf->leadtime = (/leadtime/)
    ncdf->time = (/time/)
    ncdf->leadtime_bnds = (/leadtime_bnds/)
    ncdf->time_bnds = (/time_bnds/)
    ncdf->reftime = (/reftime/)

    hcrs=tochar("")
    hcrs@grid_mapping_name = "latitude_longitude"
    filevardef(ncdf, "hcrs", typeof(realization), "ncl_scalar")
    filevarattdef(ncdf,"hcrs" ,hcrs)

;    setfileoption(ncdf,"DefineMode",False)

     ncdf->lat    = (/lat/)
     ncdf->lon    = (/lon/) 
     ncdf->lon_bnds = (/ lon_bnds /)
     ncdf->lat_bnds = (/ lat_bnds /)
     ncdf->realization = (/realization/)
     ncdf->hcrs = (/hcrs/)
; trick. I do not know how to do without
     x=0.
     return(x)
end

undef ("avg300")
function avg300(sshn,field,tmask,fse3t,e3t_0,missval)
begin
     nn=dimsizes(field)
     nt=nn(0)
     jpi=nn(3)
     jpj=nn(2)
     jpk=nn(1)
     out300=sshn*0.
     out300@_FillValue=missval
     zthick=sshn(0,:,:)
     zthicklast=sshn(0,:,:)*0.
; find ilevel with (ilevel+1) the deepest W-level above 300m (we assume we can use e3t_0 to do this search...)
     ilevel   = 0 
     zthick_0 = 0.
     do jk = 0, jpk-2
         zthick_0 = zthick_0 + e3t_0(jk)
         if( zthick_0 .lt. 300. ) then
            ilevel = jk
         end if
     end do
     do it=0,nt-1
        out300(it,:,:)=field(it,0,:,:)*tmask(0,:,:)*sshn(it,:,:)
     end do
     do jk = 0, ilevel
        zthick = zthick + fse3t(jk,:,:)*tmask(jk,:,:)
        do it=0,nt-1
           out300(it,:,:)  = out300(it,:,:)  + fse3t(jk,:,:) * field(it,jk,:,:) * tmask(jk,:,:)
        end do
     end do
     zthicklast = where(tmask(ilevel+1,:,:).ne.0,where(fse3t(ilevel+1,:,:).lt.300. - zthick,fse3t(ilevel+1,:,:),300. - zthick),0.)
     do it=0,nt-1
        out300(it,:,:) = out300(it,:,:) + field(it,ilevel+1,:,:) * zthicklast  * tmask(ilevel+1,:,:)
     end do
     zthick=zthick+zthicklast
     zthick@_FillValue=0.
     do it=0,nt-1
        out300(it,:,:) = where(ismissing(zthick),0.,out300(it,:,:)/zthick)
     end do
     return(out300)
end

begin
;---Input file
    yyyy = getenv("yyyy")
    st = getenv("st")
    srcFileName = getenv("inputfile")
    print("going to read "+srcFileName)
    lsmFileName = getenv("lsmfile")
    lsmfile = addfile(lsmFileName,"r")
    lsm=tofloat(lsmfile->lsmC3S_SPS4)
    delete(lsm@_FillValue)
    lsm=lsm+1.
    lsm=where(lsm.eq.2.,0.,lsm)
    lat=lsmfile->lat
    delete(lat@_FillValue)
    nlat=dimsizes(lat)
    lon=lsmfile->lon
    delete(lon@_FillValue)
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
    tmp=lonFlip(lsm)
    lsm=tmp
    copy_VarMeta(tmp,lsm)
    delete(tmp)


    real=getenv("real")
    realization=tochar(real+"                      ")  
    realization@units = "1" 
    realization@long_name = "realization" ;
    realization@standard_name = "realization" ;
    realization@axis = "E" ;

    temperature=0.d
    temperature@long_name = "Isotherm Temperature"
    temperature@standard_name = "sea_water_potential_temperature"
    temperature@units = "degC" 

    sigma_theta=0.d
    sigma_theta@long_name = "Sigma-theta of Sea Water"
    sigma_theta@standard_name = "sea_water_sigma_theta"
    sigma_theta@units = "kg m-3" 

    depth=0.d
    depth@long_name = "depth"
    depth@standard_name = "depth"
    depth@units = "m" 
    depth@axis = "Z"
    depth@positive = "down"

    depth_bnds=new((/2/),C3S_type)
    depth_bnds(0)=0.
    depth_bnds(1)=300.
    delete_VarAtts(depth_bnds,-1)

    meshmaskfile = getenv("meshmaskfile")
    meshmask = addfile(meshmaskfile,"r")
    tmpnemo=meshmask->tmaskutil
    lsmnemo=where(tmpnemo.eq.0.,-999.,0.)
    lsmnemo@_FillValue=-999.
    delete(tmpnemo)


;---Output (and input) files
    srcGridName = getenv("srcGridName")
    dstGridName = getenv("dstGridName")
    wgtFile     = getenv("wgtFile")

;---Retrieve data from ORCA Grid
    sfile = addfile(srcFileName,"r")
    ttmp   = sfile->time_counter
    nt=dimsizes(ttmp)
    ndays=new((/nt/), C3S_type)
    time=new((/nt/), C3S_type,"No_FillValue")
    time_bnds=new((/nt,2/),C3S_type)
    mm=tointeger(st)
    yy=tointeger(yyyy)

    totdays=0.d
    do i=0,nt-1
       if (mm.gt.12) then
            yy=yy+1
            mm=1
       end if
       ndays(i)=todouble(days_in_month(yy,mm))
       time_bnds(i,1)=ndays(i)+totdays-1.d
       time_bnds(i,0)=totdays
       totdays=totdays+ndays(i)
       time(i)=(time_bnds(i,1)-time_bnds(i,0))/2+time_bnds(i,0)
       mm=mm+1
    end do

    delete(ttmp)

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
  print(C3Stable)
  strs = asciiread(C3Stable,-1,"string")
  delim=","
  nfield = str_fields_count(strs(0), delim)
  print(nfield)
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

  nv=dimsizes(varname)

  nav_lat = sfile->nav_lat
  nav_lon = sfile->nav_lon
  tem = sfile->thetao
  sal = sfile->so
  sshn = sfile->zos

  tmask = tofloat(meshmask->tmask(0,:,:,:))
  fse3t = tofloat(meshmask->e3t_0(0,:,:,:))
;  fse3t = tofloat(meshmask->e3t(0,:,:,:))
;  e3t_0 = tofloat(meshmask->e3t_0(0,:))
  e3t_0 = tofloat(meshmask->e3t_1d(0,:))

  lon=lonFlip(lon)
  delete(lon@lonFlip)

  outdir=getenv("outdirC3S")
  system("/bin/rm -f "+outdir+"/interp_ORCA2_1X1_gridT2C3S.ncl_"+real+"_ok")
  print("this is the output dir "+outdir)
  do i=0,nv-1
       if (model(i).eq."nemo") then

;-----------------------------------------------------------------
; Set the poisson_grid_fill variables
; Global grid: Fill in over land             
;-----------------------------------------------------------------
          nscan = 1500             ; usually *much* fewer
          eps   = 0.001            ; variable depended
          gtype = True             ; Cyclic in longitude [global]
          guess = 1                ; use zonal means
          relc  = 0.6              ; standard relaxation coef
          opt   = 0
   
   ;---------------------------------------------
          if(varname(i).ne."somtt300".and.varname(i).ne."somss300")then
             xtmp   = tofloat(sfile->$varname(i)$) 
          end if
          print("processing var "+varname(i))
          if ( varname(i).eq."somss300") then
             xtmp=avg300(sshn,sal,tmask,fse3t,e3t_0,fillval(i))
          end if
          if ( varname(i).eq."somtt300") then
             xtmp=avg300(sshn,tem,tmask,fse3t,e3t_0,fillval(i))
          end if

          nn=dimsizes(xtmp)
          print("var size "+nn)
          rank=dimsizes(nn)
          print("var rank "+rank)
          delete(nn)
          if(rank.eq.3)then
             tos=xtmp(0,:,:)
          end if
          xtmp@_FillValue=1.e+20
          printVarSummary(lsmnemo)
          printVarSummary(xtmp)
          do it=0,nt-1
   
             xtmp(it,:,:)=where(lsmnemo(0,:,:).eq.lsmnemo@_FillValue,lsmnemo@_FillValue,xtmp(it,:,:))
   
             tmp2d=xtmp(it,:,:)
             poisson_grid_fill( tmp2d, gtype, guess, nscan, eps, relc, opt)
             xtmp(it,:,:)=tmp2d
             delete(tmp2d)
          end do
   
   ;----------------------------------------------------------------------
   ; Convert ORCA to SCRIP file.
   ;----------------------------------------------------------------------
          if(.not.isfilepresent(srcGridName)) then
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
          if(.not.isfilepresent(dstGridName))
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
          if(.not.isfilepresent(wgtFile)) then
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
   ;       Opt@Debug        = True
          Opt@PrintTimings = True
   
          tmp = ESMF_regrid_with_weights(xtmp(0,:,:),wgtFile,Opt)
          nn2=dimsizes(tmp)
          print("dimensions nn2 are "+nn2)
          varout=new((/nv,nt,nn2(0),nn2(1)/),"float")
          varout@_FillValue = 1.e+20
          delete(tmp)
   
          do it=0,nt -1
            tmp2d=xtmp(it,:,:)
            tmp = ESMF_regrid_with_weights(tmp2d,wgtFile,Opt)
            tmp=tmp+addfact(i)
            varout(i,it,:,:)=where(lsm(0,:,:).eq.0.,varout@_FillValue,tmp)
            delete(tmp)
            delete(tmp2d)
          end do
   
   ;---Clean up
          delete(Opt)
   
   ;----------------------------------------------------------------------
   ;  Write to a new file 
   ;----------------------------------------------------------------------
          ini_term=getenv("ini_term")
   ;QUESTO VA MODIFICATO SEGUENDO CAM
   
          filename3=outdir+"/"+ini_term+"_"+realm(i)+"_mon_"+level(i)+"_"+varnameout(i)+"_"+real+".nc"
          print(filename3)
          system("/bin/rm -f "+filename3)   ; remove any pre-existing file
          setfileoption("nc","DefineMode",True)
          setfileoption("nc", "Format",  "NetCDF4Classic")
          setfileoption("nc","CompressionLevel",6)
          setfileoption("nc","preFill",False)
   
          ncdf     = addfile(filename3 ,"c")
   
          tmp=lonFlip(varout(i,:,:,:))
   ;       print("tmp prima della scrittura "+tmp)
    ;===================================================================
   ; create global attributes of the netCDF file containing regridded data
   ;===================================================================
          global=define_att(realm(i),level(i),"mon")
          fileattdef( ncdf, global )        ; copy file attributes to netCDF file
   
          stat=definitions(ncdf,lat,nlat,lon,nlon,leadtime,time,depth,nt,reftime,realization,lon_bnds,lat_bnds,leadtime_bnds,time_bnds,depth_bnds,C3S_type,varname(i))
          filevardef(ncdf,varnameout(i),C3S_type_var \
                                 , (/ "leadtime", "lat", "lon" /)        )
          dumAtts = new( 1, C3S_type_var)
          dumAtts@_FillValue = fillval(i)
          dumAtts@missing_value = fillval(i)
          dumAtts@long_name = longname(i)
          dumAtts@standard_name = standname(i)
          dumAtts@units = unita(i)
          dumAtts@coordinates = coord(i)
          dumAtts@cell_methods = cell_method(i)
          dumAtts@grid_mapping = "hcrs" ;
          filevarattdef(ncdf, varnameout(i) , dumAtts)
          delete([dumAtts])   ; may change size next iteration
   
          depth=0.d
          if (reflev(i).eq.300.d) then
              depth=reflev(i)
              depth@bounds="depth_bnds"
              filevardef(ncdf, "depth", C3S_type, "ncl_scalar")
              filevarattdef(ncdf,"depth" ,depth)    
              ncdf->depth = (/depth/)
              ncdf->depth_bnds = (/depth_bnds/)
          end if
   
   
          temperature=0.d
          if(varname(i).eq."t14d".or.varname(i).eq."t17d".or.varname(i).eq."t20d".or.varname(i).eq."t26d".or.varname(i).eq."t28d")then
             temperature=reflev(i)
             filevardef(ncdf, "temperature", C3S_type, "ncl_scalar")
             filevarattdef(ncdf,"temperature" ,temperature)    
             ncdf->temperature = (/temperature/)
          end if
    
          sigma_theta=0.d
          if(varname(i).eq."mlotst0.01".or.varname(i).eq."mlotst")then
             sigma_theta=reflev(i)
             filevardef(ncdf, "sigma_theta", C3S_type, "ncl_scalar")
             filevarattdef(ncdf,"sigma_theta" ,sigma_theta)    
             ncdf->sigma_theta = (/sigma_theta/)
          end if
   
          ncdf->$varnameout(i)$=(/tmp/)
          delete(tmp)
       end if  ; if on nemo vars
  end do   ; end loop on var
  check_oceregrid=getenv("check_oceregrid")
  system("touch "+check_oceregrid)

end

