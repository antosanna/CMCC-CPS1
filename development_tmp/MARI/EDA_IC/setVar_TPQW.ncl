 begin

  inI = addfile("CLIM_TPQW_MESE.nc","r")
  vtim_o = inI->time
  vlon   = inI->LONGXY
  vlat   = inI->LATIXY
  vpres  = inI->PSRF
  vtemp  = inI->TBOT
  vwind  = inI->WIND
  vhumi  = inI->QBOT
  vEE    = inI->EDGEE
  vEW    = inI->EDGEW
  vES    = inI->EDGES
  vEN    = inI->EDGEN

  inR = addfile("/work/csp/mb16318/scratch/files4CPS1/templates4CLM/TPHWL/clmforc.GSWP3.c2011.0.5x0.5.TPQWL.1901-MESE.nc", "r")
  vtim_r = inR->time
  ntim = dimsizes(vtim_o)

  print(ntim)

  vtim_n = new((/ntim/), typeof(vtim_o))

  do t=0,ntim-1
    vtim_n(t) = vtim_r(t)
  end do  

  print(vtim_n)

;-----------------------------------------------------------------
; save the new values
;-----------------------------------------------------------------

  save_dir  = "./"
  file_name = "CLIM_TPQW_MESE_time.nc" 
  system("/bin/rm -f " + save_dir + file_name) ; remove if exists
  fs = addfile(save_dir + file_name, "c")

;===================================================================
; explicitly declare file definition mode. Improve efficiency.

 setfileoption(fs,"DefineMode",True)

;Create some file attributes

 fAtt               = True            ; assign file attributes
 fAtt@title         = "CLM forcing 3-Hourly Atmospheric Forcing: Surface Pressure, Temperature, Wind, Humidity"
 fAtt@source_period = "1960-1969"
 fileattdef(fs, fAtt)

;===================================================================
;Define the file dimensions, NOTE that both dimensions are unlimited.

  dimNames = (/ "x", "y", "x_2", "time"/)
  dimSizes = (/  720, 360, 1, ntim/)
  dimUnlim = (/  False, False, False, True/)
  filedimdef(fs, dimNames, dimSizes, dimUnlim)

 delete_VarAtts(vtim_n, -1)
 time = vtim_n
 time!0 = "time" 
 time@calendar = "365_day"
 time@units = "days since 1960-MESE-01 00:00:00"
 time@long_name = "observation time"
 time@standard_name = "time"
 filevardef(fs, "time", typeof(time), getvardims(time))
 filevarattdef(fs,"time", time)

 delete_VarAtts(vlon, -1)
 LONGXY = vlon
 LONGXY!0 = "y"
 LONGXY!1 = "x"
 LONGXY@mode = "time-invariant"
 LONGXY@units = "degrees_east"
 LONGXY@long_name = "longitude"
 filevardef(fs, "LONGXY", typeof(LONGXY), getvardims(LONGXY))
 filevarattdef(fs,"LONGXY", LONGXY)

 delete_VarAtts(vlat, -1)
 LATIXY = vlat
 LATIXY!0 = "y"
 LATIXY!1 = "x"
 LATIXY@mode = "time-invariant"
 LATIXY@units = "degrees_north"
 LATIXY@long_name = "latitude"
 filevardef(fs, "LATIXY", typeof(LATIXY), getvardims(LATIXY))
 filevarattdef(fs,"LATIXY", LATIXY)

 delete_VarAtts(vEE, -1)
 EDGEE = vEE
 EDGEE!0 = "x_2"
 EDGEE@mode = "time-invariant"
 EDGEE@units = "degrees_east"
 EDGEE@long_name = "eastern edge in atmospheric data" 
 filevardef(fs, "EDGEE", typeof(EDGEE), getvardims(EDGEE))
 filevarattdef(fs,"EDGEE", EDGEE)

 delete_VarAtts(vEW, -1)
 EDGEW = vEW
 EDGEW!0 = "x_2"
 EDGEW@mode = "time-invariant"
 EDGEW@units = "degrees_east"
 EDGEW@long_name = "eastern edge in atmospheric data" 
 filevardef(fs, "EDGEW", typeof(EDGEW), getvardims(EDGEW))
 filevarattdef(fs,"EDGEW", EDGEW)

 delete_VarAtts(vES, -1)
 EDGES = vES
 EDGES!0 = "x_2"
 EDGES@mode = "time-invariant"
 EDGES@units = "degrees_north" 
 EDGES@long_name = "southern edge in atmospheric data"
 filevardef(fs, "EDGES", typeof(EDGES), getvardims(EDGES))
 filevarattdef(fs,"EDGES", EDGES)

 delete_VarAtts(vEN, -1)
 EDGEN = vEN
 EDGEN!0 = "x_2"
 EDGEN@mode = "time-invariant"
 EDGEN@units = "degrees_north" 
 EDGEN@long_name = "northern edge in atmospheric data"
 filevardef(fs, "EDGEN", typeof(EDGEN), getvardims(EDGEN))
 filevarattdef(fs,"EDGEN", EDGEN)

 delete_VarAtts(vpres, -1)
 PSRF = vpres
 PSRF!0 = "time"
 PSRF!1 = "y"
 PSRF!2 = "x"
 PSRF@mode = "time-dependent"
 PSRF@name = "PSRF"
 PSRF@_FillValue = 1.e+36 
 PSRF@units = "Pa"
 PSRF@long_name = "surface pressure at the lowest atm level"
 filevardef(fs, "PSRF", typeof(PSRF), getvardims(PSRF))
 filevarattdef(fs,"PSRF", PSRF)

 delete_VarAtts(vtemp, -1)
 TBOT = vtemp
 TBOT!0 = "time"
 TBOT!1 = "y"
 TBOT!2 = "x"
 TBOT@mode = "time-dependent"
 TBOT@name = "TBOT"
 TBOT@_FillValue = 1.e+36 
 TBOT@units = "K"
 TBOT@long_name = "temperature at the lowest atm level"
 filevardef(fs, "TBOT", typeof(TBOT), getvardims(TBOT))
 filevarattdef(fs,"TBOT", TBOT)

 delete_VarAtts(vwind, -1)
 WIND = vwind
 WIND!0 = "time"
 WIND!1 = "y"
 WIND!2 = "x"
 WIND@mode = "time-dependent"
 WIND@name = "WIND"
 WIND@_FillValue = 1.e+36 
 WIND@units = "m/s"
 WIND@long_name = "wind at the lowest atm level"
 filevardef(fs, "WIND", typeof(WIND), getvardims(WIND))
 filevarattdef(fs,"WIND", WIND)

 delete_VarAtts(vhumi, -1)
 QBOT = vhumi
 QBOT!0 = "time"
 QBOT!1 = "y"
 QBOT!2 = "x"
 QBOT@mode = "time-dependent"
 QBOT@name = "QBOT"
 QBOT@_FillValue =1.e+36 
 QBOT@units = "kg/kg"
 QBOT@long_name = "specific humidity at the lowest atm level"
 filevardef(fs, "QBOT", typeof(QBOT), getvardims(QBOT))
 filevarattdef(fs,"QBOT", QBOT)

 fs->time = (/vtim_n/)
 fs->LONGXY = (/vlon/)
 fs->LATIXY = (/vlat/)
 fs->EDGEE = (/vEE/)
 fs->EDGEW = (/vEW/)
 fs->EDGES = (/vES/)
 fs->EDGEN = (/vEN/)
 fs->PSRF = (/vpres/)
 fs->TBOT = (/vtemp/)
 fs->WIND = (/vwind/)
 fs->QBOT = (/vhumi/)

end 

