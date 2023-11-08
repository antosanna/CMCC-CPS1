begin

ifile=getenv("ifile")
firstmonthdays=tofloat(getenv("firstmonthdays"))
fila=getenv("fila")
tunits=getenv("tunits")
;timeAtt@units     = "days since 2018-12-01"
nf=addfile(ifile,"r")
sic=nf->sic
siconc=sic*100.
copy_VarMeta(sic,siconc)
delete(siconc@_FillValue)
siconc=where(siconc.gt.1e10,0.,siconc)
delete(sic)
lattmp=nf->lat
latitude=tofloat(lattmp)
copy_VarMeta(lattmp,latitude)
lontmp=nf->lon
longitude=tofloat(lontmp)
copy_VarMeta(lontmp,longitude)
timetmp=nf->time
time=tofloat(timetmp)-firstmonthdays
ntime=dimsizes(time)
copy_VarMeta(timetmp,time)

delete(siconc@lat)
delete(siconc@lon)

;printVarSummary(siconc)
;printVarSummary(latitude)
;printVarSummary(longitude)
;printVarSummary(time)

nfa=addfile(fila,"r")
areatmp=nfa->cell_area
areacello=tofloat(areatmp)
copy_VarMeta(areatmp,areacello)

smask=getenv("smask")
nfmsk=addfile(smask,"r")
sftlf=nfmsk->sftlf
sftof=tofloat((1-sftlf)*100)
copy_VarMeta(siconc(0,:,:),sftof)
delete(sftof@_FillValue)
printVarSummary(sftof)

outfile=getenv("outfile")
system("/bin/rm -f "+outfile)   ; remove any pre-existing file
ncdf     = addfile(outfile ,"c")  ; open output netCDF file
filedimdef(ncdf,(/"time","y","x"/),(/ntime,180,360/),(/True,False,False/))
filevardef(ncdf, "time" ,typeof(time),(/"time"/) ) 
filevardef(ncdf, "siconc"  ,typeof(siconc),(/"time","y","x"/) )                           
filevardef(ncdf, "latitude"  ,typeof(longitude),(/"y"/))                          
filevardef(ncdf, "longitude"  ,typeof(longitude),(/"x"/))    
filevardef(ncdf, "areacello"  ,typeof(areacello),(/"y","x"/) )       
filevardef(ncdf, "sftof"  ,typeof(sftof),(/"y","x"/) )                           
latAtt=0
latAtt@units     = "degrees north"
latAtt@long_name = "Latitude"
filevarattdef( ncdf, "latitude", latAtt )
lonAtt=0
lonAtt@units     = "degrees east"
lonAtt@long_name = "Longitude"
filevarattdef( ncdf, "longitude", lonAtt )
sicAtt=0
sicAtt@units     = "%"
sicAtt@long_name = "Sea-ice area fraction"
filevarattdef( ncdf, "siconc", sicAtt )
timeAtt=0
timeAtt@units     = tunits
filevarattdef( ncdf, "time", timeAtt )
sftofAtt=0
sftofAtt@units     = "%"
sftofAtt@long_name = "Sea Area Fraction"
filevarattdef( ncdf, "sftof", sftofAtt )
areaAtt=0
areaAtt@units     = "m2"
areaAtt@long_name = "Ocean Grid-Cell Area"
filevarattdef( ncdf, "areacello", areaAtt )


ncdf->time=(/time/)
ncdf->siconc=(/siconc/)
ncdf->latitude=(/latitude/)
ncdf->longitude=(/longitude/)
ncdf->areacello=(/areacello/)
ncdf->sftof=(/sftof/)

end
