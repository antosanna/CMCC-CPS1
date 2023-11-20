; Horizontally interpolate to height coordinates ("z")
  height = 100.   ; 2km 
; z should be geoptential height
  u100 = wrf_user_intrp3d(u,z,"h",height,0.,False)  
