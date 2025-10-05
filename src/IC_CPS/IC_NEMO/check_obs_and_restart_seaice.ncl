begin
dirciceic=getenv("dirciceic")
yyyy=getenv("yyyy")
st=getenv("st")
yynemo=getenv("yym1")
stnemo=getenv("stm1")
lastmonthday=getenv("ddobs")
typeofrun=getenv("typerun")
fnamemesh=getenv("fnamemesh")
fn=addfile(fnamemesh,"r")

lat_or=fn->nav_lat
lon_or=fn->nav_lon

msk  = tofloat(fn->tmaskutil(0,:,:))
msk@_FillValue=0
msk@_FillValue=-9999.

fnameobs=getenv("obsregfile")

;fnamesicic=getenv("inifnamesicic")

minlat=30
maxlat=90

pltype=getenv("pltype")
pltname=getenv("pltname")

fsicobs=addfile(fnameobs,"r")
;multiply for scale_factor 0.01
tmp=fsicobs->ice_conc*0.01
nn=dimsizes(tmp)
sicobs=tmp(nn(0)-1,0:nn(1)-2,1:nn(2)-2)
delete(tmp)
;printVarSummary(sicobs)
printMinMax(sicobs,1)
lat2d=lat_or(0:nn(1)-2,1:nn(2)-2)
lon2d=lon_or(0:nn(1)-2,1:nn(2)-2)

msk2d=msk(0:nn(1)-2,1:nn(2)-2)

wks=gsn_open_wks(pltype,pltname)  
noce=toint(getenv("nic"))

plot=new(noce+1,graphic)
;---Variable to hold plot options
res                       = True

;---Maximize plot in frame
res@gsnMaximize           = True


res@gsnDraw  = False                          ; don't draw
res@gsnFrame = False                          ; don't advance frame
res@cnLinesOn  = False
res@cnFillOn   = True

res@cnExplicitLabelBarLabelsOn=True
res@lbLabelBarOn=False
res@lbLabelFontHeightF   = 0.012
res@gsnTickMarksOn = False 
res@mpMinLatF=50
res@mpGridAndLimbOn=False

res@cnFillColors         = (/"steelblue1","gold1","green4","olivedrab1","lightslateblue", "lightskyblue1","white"/)

res@cnFillDrawOrder       = "PreDraw"  

res@lbLabe5BarOn=False
res@lbLabelFontHeightF   = 0.012
res@cnExplicitLabelBarLabelsOn=True
res@cnLevelSelectionMode="ExplicitLevels"
res@cnLevels     = (/15,30,45,60,75,90/)
res@cnMissingValFillColor="light grey"
res@gsnLeftString=""
res@gsnRightString=""
res@lbBoxEndCapStyle = "TriangleBothEnds"

res@mpOutlineOn               = True
res@mpDataBaseVersion         = "MediumRes"       ; default is "LowRes"
  
res@sfXArray                  = lon2d
res@sfYArray                  = lat2d
res@gsnAddCyclic              = False

plot(0) = gsn_csm_contour_map_polar(wks,sicobs,res)

fili = systemfunc("cd "+dirciceic+" ; ls CPS1.cice.r."+yyyy+"-"+st+"-01-00000.0?.nc")
nfils=dimsizes(fili)
ipoce=1
do nf=0,nfils-1
   fsic_ic = addfile (dirciceic+"/"+fili(nf), "r")
   sic=fsic_ic->aicen(:,0:nn(1)-2,1:nn(2)-2)
   sizes=dimsizes(sic)
   nlat=sizes(1)
   nlon=sizes(2)
   sic2d=dim_sum_n_Wrap(sic,0)
   sicmask=new((/nlat,nlon/),typeof(sic)) 
   sicmask=where(msk2d.eq.msk2d@_FillValue,msk2d,sic2d)
   copy_VarMeta(sic2d,sicmask)
   plot(ipoce) = gsn_csm_contour_map_polar(wks,sicmask(:,:)*100,res)
   ipoce=ipoce+1
   delete(fsic_ic)
   delete(sic)
end do

resP  = True
resP@gsnFrame         = False                  ; don't advance panel plot
resP@gsnPanelLabelBar = True                   ; add common colorbar
resP@lbLabelFontHeightF =.01
resP@lbOrientation ="Vertical"
resP@gsnPanelMainString = "Arctic Sea Ice concentration [%] ~C~     Initialization "+yyyy+st+"01"  

resP@gsnPanelXWhiteSpacePercent=5
resP@gsnPanelYWhiteSpacePercent=3

resP@gsnPanelFigureStrings=(/"~C~ OSISAF sea-ice ~C~  "+yynemo+stnemo+lastmonthday,"~C~NEMO IC 01  ~C~   ","~C~NEMO IC 02  ~C~   ","~C~NEMO IC 03  ~C~   ","~C~NEMO IC 04  ~C~   ","~C~NEMO IC 05  ~C~   " ,"~C~NEMO IC 06  ~C~   " ,"~C~NEMO IC 07  ~C~   " ,"~C~NEMO IC 08  ~C~   ","~C~NEMO IC 09"/)
resP@gsnPanelFigureStringsFontHeightF=0.0095
resP@gsnPanelFigureStringsPerimOn=False
resP@gsnPanelFigureStringsBackgroundFillColor="transparent"
resP@amJust   = "BottomRight"
resP@gsnPanelRowSpec = True
gsn_panel(wks,plot,(/1,3,3,3/),resP)
frame(wks)

end
