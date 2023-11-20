
begin

; ---- Read Observation data ----
yyyym1   = getenv("yyyym1")
stm1     = getenv("stm1")
filename = getenv("inpfile")
hemis = getenv("hemis")

lines = asciiread(filename,-1,"string")

strkey = yyyym1+",    "+stm1

seldata = str_match_ic_regex(lines, strkey)

  delim = ","


;---Read fields 1, 5 and 9.  The "var" suffix is used because "group" is a keyword.
  year        =   tointeger(str_get_field(seldata,1,delim))
  month       =   tointeger(str_get_field(seldata,2,delim))
  day         =   tointeger(str_get_field(seldata,3,delim))
  si_extent   =   tofloat(str_get_field(seldata,4,delim))
  N=dimsizes(si_extent)

ntime=toint(getenv("ntime"))
areasic_obs=new((/ntime+1/),"float",1.e+20)
areasic_obs(0) = si_extent(N-1)

;
;read useful directories
dirwkroot=getenv("dirwkroot")
diric=getenv("diric")
npoce=toint(getenv("npoce"))
typeofrun=getenv("typeofrun")
fileroot=getenv("fileroot")
yyyyfore=getenv("yyyy")
hiniy=getenv("hiniy")
hendy=getenv("hendy")
st=getenv("st")
;
filic = systemfunc("cd "+diric+" ; ls "+fileroot+"*nc")
nfilsic=dimsizes(filic)
fi = addfile (diric+"/"+filic(0), "r")
print("------goign to read "+diric+"/"+filic(0))
hiic=fi->aicen
ndim=dimsizes(hiic)
nlat=ndim(1)
nlon=ndim(2)
sic_ic = new((/npoce,nlat/2,nlon/),typeof(hiic))
delete(hiic)
do i=0,nfilsic-1
   fi = addfile(diric+"/"+filic(i),"r")
   if(hemis.eq."NH")then
      sic_ic(i,:,:)=dim_sum_n(fi->aicen(:,nlat/2:,:),0)
   else
      sic_ic(i,:,:)=dim_sum_n(fi->aicen(:,0:nlat/2-1,:),0)
   end if
end do

; read start-end reforecast period
; read hindcast member number
if(typeofrun.eq."forecast") then
   fileclim=getenv("fileclim")
   fi = addfile (fileclim, "r")
   tmp_areasic_hc=fi->areasic_hc(:,0:ntime-1)
   mdims=dimsizes(tmp_areasic_hc)
   areasic_hc=new((/mdims(0),ntime+1/),typeof(tmp_areasic_hc),1.e+20)
   areasic_hc(:,1:ntime)=tmp_areasic_hc
   delete(tmp_areasic_hc)
   printVarSummary(areasic_hc)
end if 
;

; now read forecast res
SPSsys=getenv("SPSSystem")
fili = systemfunc("cd "+dirwkroot+" ; ls "+SPSsys+"_"+yyyyfore+st+"*.cice.nc")
nfils=dimsizes(fili)
;nfils=5 ;for debug purposes
fi = addfile (dirwkroot+"/"+fili(0), "r")
print("going to read "+dirwkroot+"/"+fili(0))
tmp=fi->aice
nn=dimsizes(tmp)
;
; read area cell
ftarea=getenv("ftarea")
farea=addfile(ftarea,"r")
if(hemis.eq."NH")then
   areain=farea->tarea(nlat/2:,:)
else
   areain=farea->tarea(0:nlat/2-1,:)
end if
; express area in km^2
area=(areain/1000000)
copy_VarMeta(areain,area)
;

;
sic_fc = new((/nfils,ntime+1,nlat/2,nlon/),typeof(tmp))
pocefc = new((/nfils/),typeof(tmp))
sic_fc@_FillValue=1.e+20
delete(tmp)
delete(nn)
do nf=0,nfils-1
   print("going to read "+fili(nf))
   fi = addfile (dirwkroot+"/"+fili(nf), "r")
   ic = fi@ic
   strs = str_split(ic, "=")
   pocefc(nf)=toint(strs(3))-1
   tmp=fi->aice
   nn=dimsizes(tmp)
   if(hemis.eq."NH")then
      sic_fc(nf,1:nn(0),:,:)=tmp(:,nlat/2:,:)
   else
      sic_fc(nf,1:nn(0),:,:)=tmp(:,0:nlat/2-1,:)
   end if
   delete(tmp)
   delete(nn)
end do

sic_ic=where(sic_ic.gt..15,1.,0.)
sic_ic@_FillValue=1.e+20
; sie NH IC
printVarSummary(sic_ic)

sic_fc=where(sic_fc.gt..15,1.,0.)

areasic=new((/npoce,nfils,ntime+1/),typeof(sic_fc))
areasic_ic=new((/npoce,ntime+1/),typeof(sic_ic),1.e+20)
areasic_ic@_FillValue=1.e+20
areasic@_FillValue=1.e+20


do t=1,ntime
   do recfc=0,nfils-1
; express area in million of km^2
      areasic(toint(pocefc(recfc)),recfc,t)=dim_sum(dim_sum(sic_fc(recfc,t,:,:)*area))/1000000
   end do
end do
do pp=0,npoce-1
   areasic_ic(pp,0)=dim_sum(dim_sum(sic_ic(pp,:,:)*area))/1000000
end do
first_month=areasic_ic
;
do i=0,npoce-1
   first_month(i,1)=dim_avg(areasic(i,:,1))
end do

if(typeofrun.eq."forecast")then
   mnmx=new((/2,ntime+1/),typeof(areasic_hc))
   mnmx(0,:)=dim_min_n(areasic_hc,0)
   mnmx(1,:)=dim_max_n(areasic_hc,0)
end if

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
if(typeofrun.eq."forecast")then
   res@tiXAxisString         = "Forecast time (months)"
else
   res@tiXAxisString         = "Hindcast time (months)"
end if
res@tiMainString          = "Arctic Sea Ice Extent ~C~ "+yyyyfore+st+"01 present member number = "+sprinti("%0.2i",nfils)

res@tmYLMode              = "Manual"
res@trYMinF               = 2.
res@trYMaxF               = 18.
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

res@xyLineThicknessF=2
res@xyDashPattern  = 0
res@xyLineColor    = "purple"
plot=gsn_csm_y(wks,areasic(0,:,:),res)
res@xyLineColor    = "magenta"
plot2=gsn_csm_y(wks,areasic(1,:,:),res)
res@xyLineColor    = "pink"
plot3=gsn_csm_y(wks,areasic(2,:,:),res)
res@xyLineColor    = "red"
plot4=gsn_csm_y(wks,areasic(3,:,:),res)
res@xyLineColor    = "orange"
if(typeofrun.eq."forecast")then
   plot5=gsn_csm_y(wks,areasic(4,:,:),res)
   res@xyLineColor    = "yellow"
   plot6=gsn_csm_y(wks,areasic(5,:,:),res)
   res@xyLineColor    = "chartreuse"
   plot7=gsn_csm_y(wks,areasic(6,:,:),res)
   res@xyLineColor    = "chartreuse4"
   plot8=gsn_csm_y(wks,areasic(7,:,:),res)
   res@xyLineColor    = "blue4" 
   plot9=gsn_csm_y(wks,areasic(8,:,:),res)
end if

res@xyLineThicknessF=1
res@xyDashPattern  = 2
res@xyLineColors  := (/"purple","magenta","pink","red","orange","yellow","chartreuse","chartreuse4","blue4"/)
first_month_plot=gsn_csm_y(wks,first_month,res)

res@xyMarkLineMode = "Markers"
res@xyMarkerSizeF  = 0.015
res@xyMarker       = NhlNewMarker(wks, "z", 35, 0.0, 0.0, 1.0, 1.0, 0.)
res@xyMarkerColor  = "blue"
obsplot=gsn_csm_y(wks,areasic_obs,res)

res@xyMarkerSizeF  = 0.005
delete(res@xyMarker)
delete(res@xyMarkerColor)
res@xyMarkers       := (/16,16,16,16,16,16,16,16,16/)
res@xyMarkerColors  := (/"purple","magenta","pink","red","orange","yellow","chartreuse","chartreuse4","blue4"/)
icplot=gsn_csm_y(wks,areasic_ic,res)

delete(res@xyMarkLineMode)
delete(res@xyDashPattern)
delete(res@xyLineColors)
delete(res@xyLineColor)
delete(res@xyMarkerSizeF)
delete(res@xyMarkers)
delete(res@xyMarkerColors)
if(typeofrun.eq."forecast")then
   res@gsnXYFillColors = "lightgrey"
   res@xyLineColor     = -1
   botplot=gsn_csm_y(wks,mnmx(0:1,:),res)
end if 


if (typeofrun.eq."forecast")then
   overlay(plot2,botplot)
end if
overlay(plot2,first_month_plot)
overlay(plot2,icplot)
overlay(plot2,obsplot)
if(typeofrun.eq."forecast")then
   overlay(plot2,plot9)
   overlay(plot2,plot8)
   overlay(plot2,plot7)
   overlay(plot2,plot6)
   overlay(plot2,plot5)
end if
overlay(plot2,plot4)
overlay(plot2,plot3)
overlay(plot2,plot)

getvalues plot                      ; Get plot size for use in
  "vpHeightF" : vph                 ; determining size of
  "vpWidthF"  : vpw                 ; labelbar.
end getvalues

;***********************************************
; legend resources
;***********************************************
lbres                    = True          ; labelbar only resources
lbres@lbAutoManage       = False          ; Necessary to control sizes
lbres@vpWidthF           = 0.1 * vpw     ; labelbar width
lbres@vpHeightF          = 0.35 * vph     ; labelbar height
lbres@lbBoxMajorExtentF  = 1.          ; puts space between color boxes
lbres@lbFillColors       = (/"purple","magenta","pink","red","orange","yellow","chartreuse","chartreuse4","blue4","light grey","blue"/); labelbar colors
lbres@lbMonoFillPattern  = True          ; Solid fill pattern
lbres@lbLabelFontHeightF = 0.008 ;2          ; font height. default is small
lbres@lbLabelJust        = "CenterLeft"  ; left justify labels

if(typeofrun.eq."forecast")then
   lbid = gsn_create_labelbar(wks,11,(/"poce 1","poce 2","poce 3","poce 4","poce 5","poce 6","poce 7","poce 8","poce 9","Hindcast ("+hiniy+"-"+hendy+")","NSIDC"/),lbres)         ; create legend
else
   lbid = gsn_create_labelbar(wks,11,(/"poce 1","poce 2","poce 3","poce 4","NSIDC"/),lbres)         ; create legend
end if

amres = True
amres@amJust           = "TopRight"
amres@amParallelPosF   = -0.27         ; move legend to the right
amres@amOrthogonalPosF = -0.5            ; move the legend down
annoid1 = gsn_add_annotation(plot,lbid,amres)   ; add legend to plot

draw(plot2)   ; Draw base plot.
frame(wks)    ; advance frame
checkfile=getenv("checkfileplot")
system("touch "+checkfile)

end
