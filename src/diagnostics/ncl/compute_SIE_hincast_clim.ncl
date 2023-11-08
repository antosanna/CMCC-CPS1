load "/zeus/opt/ncl/6.6.2/lib/ncarg/nclscripts/contrib/ut_string.ncl"

begin

; ---- Read Observation data ----
;
;read useful directories
st=getenv("st")
dirhc=getenv("dirhc")
ntime=toint(getenv("ntime"))
;
; read area cell
filarea=getenv("filarea")
fa=addfile(filarea,"r")
area_glob=fa->tarea
ndim=dimsizes(area_glob)
nlat=ndim(0)
nlon=ndim(1)
areain=area_glob(nlat/2:,:)
delete(area_glob)
; express area in km^2
area=(areain/1000000)
copy_VarMeta(areain,area)
delete(areain)
;
; read start-end reforecast period
hiniy=getenv("hiniy")
ihiniy=toint(hiniy)
hendy=getenv("hendy")
ihendy=toint(hendy)
ny=ihendy-ihiniy+1
; read hindcast member number
ne=toint(getenv("nhindmem"))
;
print("start hindcast section")
;sic_hc5d = new((/ny,ne,ntime+1,nlat/2,nlon/),"float",1.e+20)
areasic_hc=new((/ny*ne,ntime+1/),"float")
nrec=0
do iy=ihiniy,ihendy
   do ens=0,ne-1
      caso="sps3.5_"+iy+st+"_0"+sprinti("%0.2i",ens+1)
      filshc      = systemfunc("cd "+dirhc+"/"+caso+" ; ls "+caso+"*.nc")
      nfils=dimsizes(filshc)
      if(nfils.ne.6)then
         print("files for case "+caso+" are "+nfils+" instead of 6. EXIT")
         exit
      end if
      do ll=0,nfils-1
         fi = addfile (dirhc+"/"+caso+"/"+filshc(ll), "r")
         print("hindcast file "+dirhc+"/"+caso+"/"+filshc(ll))
; I want the first timestep void (for IC)
         sic=fi->aicen001(0,nlat/2:,:)
         sic=where(sic.gt..15,1.,0.)
         areasic_hc(nrec,ll)=dim_sum(dim_sum(sic*area))/1000000
      end do
      nrec=nrec+1
      delete(nfils)
   end do
end do

areasic_hc@_FillValue=1.e+20

delete(sic)
;

dotheplot=toint(getenv("dotheplot"))
if(dotheplot.eq.1)then
;#############################################
; PLOT resources
;#############################################

   outplot=getenv("outplot")
   plottype=getenv("plottype")
   wks = gsn_open_wks(plottype,outplot)
   
   res                       = True                        ; plot mods desired
   res@gsnDraw               = False             ; don't draw yet 
   res@gsnFrame              = False             ; don't advance frame yet 
   res@tiYAxisString         = "Extent (Millions of km~S~2~N~)"
   res@tiXAxisString         = "Forecast time (months)"
   res@tiMainString          = "Arctic Sea Ice Extent ~C~ "+st
   
   res@tmYLMode              = "Manual"
   res@trYMinF               = 2
   res@trYMaxF               = 18
   res@tmYLTickStartF        = 0
   res@tmYLTickEndF 	  = 18
   res@tmYLTickSpacingF      = 2
   
   res@tmXBFormat = "f"        ; remove the trailing ".0"
   res@trXMinF    = 0       ; starting point along X axis
   res@trXMaxF    = ntime
   res@tmXBMode   = "Explicit"
   res@tmXBValues = ispan(0,ntime,1)     ; choose first 13 timesteps
   ;labelsx=stime
   res@tmXBLabels =ispan(0,ntime,1)
   res@tmYLLabelFontHeightF    = 0.012
   res@tmXBLabelFontHeightF    = 0.012
   
   res@xyDashPattern  = 0
   res@xyLineColor    = "purple"
   plot=gsn_csm_y(wks,areasic_hc,res)
   
   getvalues plot                      ; Get plot size for use in
     "vpHeightF" : vph                 ; determining size of
     "vpWidthF"  : vpw                 ; labelbar.
   end getvalues
   
   draw(plot)   ; Draw base plot.
   frame(wks)    ; advance frame
end if

dstFileName=getenv("dstFileName")
if(isfilepresent(dstFileName)) then
   system("rm "+dstFileName)
end if
dst_file=addfile(dstFileName,"c")
dst_file->areasic_hc =areasic_hc

checkfile=getenv("checkfile")
system("touch "+checkfile)

end
