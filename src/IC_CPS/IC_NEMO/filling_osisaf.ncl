begin

  fname_obs = getenv("filename_raw")
  fname_out = getenv("filename_filled")
  okflag=getenv("touch_fill")
  fobs = addfile(fname_obs, "r")
  tmp  = fobs->ice_conc(0,:,:)

  ; unpacking CF standard: raw -> percentuale (NCL non applica scale_factor in automatico)
  if (isatt(tmp, "scale_factor")) then
    ice = todouble(tmp) * todouble(tmp@scale_factor)
    if (isatt(tmp, "add_offset")) then
      ice = ice + todouble(tmp@add_offset)
    end if
  else
    ice = todouble(tmp)
  end if
  copy_VarCoords(tmp, ice)

  ; metadati coerenti col dato risultante (percentuale, non piu' raw/packed)
  if (isatt(ice, "scale_factor")) then
    delete(ice@scale_factor)
  end if
  if (isatt(ice, "valid_max")) then
    delete(ice@valid_max)
  end if
  if (isatt(ice, "valid_min")) then
    delete(ice@valid_min)
  end if
  ice@units      = "%"
  ice@_FillValue = -999.d

  is_cyclic  = False    ; CRITICO: proiezione LAEA, non periodica
  guess_type = 1
  nscan      = 1500
  eps        = 1.e-2
  relc       = 0.6

  poisson_grid_fill(ice, is_cyclic, guess_type, nscan, eps, relc, 0)

  fout = addfile(fname_out, "c")
  fout->ice_conc = ice

  print("Scritto: " + fname_out)
  system("touch "+okflag)
end
