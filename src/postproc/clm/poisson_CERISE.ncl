;***************************************************************
; NCL script
; regrid vars from FV to reg1x1
; for masked variables define and apply the mask after interpolation
;***************************************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
load "$HOME/CPS/CMCC-CPS1/src/templates/C3S_globalatt.ncl"


begin

;  srcFileName   = getenv("inputFV")
  srcFileName   = "/work/cmcc/as34319/scratch/regrid_CERISE/sps4_199311_001/CLM/reg1x1/sps4_199311_001.clm2.h2.1993-11.zip.nc"
  src_file=addfile(srcFileName,"r")

  print("Beginning to regrid "+srcFileName)

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
  tsn=src_file->SNOTTOPL

;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;                    PREDEFINE MODE
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    
;  outDir=getenv("outdirC3S")
;  if(isfilepresent(outDir+"/regridSE_CERISE.ncl_"+typein+"_"+real+"_ok") ) then
;     system("rm -f "+outDir+"/regridSE_CERISE.ncl_"+typein+"_"+real+"_ok")
;  end if

  poisson_grid_fill( tsn, is_cyclic, guess, nscan, eps, relc, opt)
  dst_file=addfile("/work/cmcc/as34319/scratch/regrid_CERISE/sps4_199311_001/CLM/reg1x1/prova.nc","c")
  dst_file->SNOTTOPL = tsn
end
