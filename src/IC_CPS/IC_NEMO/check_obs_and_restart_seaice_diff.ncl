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

res@gsnTickMarksOn = False 
res@mpMinLatF=50
res@mpGridAndLimbOn=False

res@cnFillColors         = (/"steelblue1","gold1","green4","olivedrab1","lightslateblue", "lightskyblue1","white"/)

res@cnFillDrawOrder       = "PreDraw"  

res@lbLabelBarOn=False
;res@lbLabelFontHeightF =.01
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

delete(res@cnFillColors)
delete(res@cnLevels)

fili = systemfunc("cd "+dirciceic+" ; ls CPS1.cice.r."+yyyy+"-"+st+"-01-00000.0?.*nc")
nfils=dimsizes(fili)
ipoce=1
do nf=0,nfils-1
   fsic_ic = addfile (dirciceic+"/"+fili(nf), "r")
   sic=fsic_ic->aicen(:,0:nn(1)-2,1:nn(2)-2)

   sizes=dimsizes(sic)
   nlat=sizes(1)
   nlon=sizes(2)
   printVarSummary(sic)
   sic2d=dim_sum_n_Wrap(sic,0)
  
   res@cnFillPalette="nrl_sirkes" ;"BlWhRe"
   res@cnExplicitLabelBarLabelsOn=True
   res@cnLevelSelectionMode="ExplicitLevels"
   res@cnLevels=(/-30.,-20.,-10.,10.,20.,30./)
   res@lbLabelStrings=(/"-30","-20","-10","10","20","30"/)
   res@cnMissingValFillColor="light grey"
   res@gsnLeftString=""
   res@gsnRightString=""
   res@lbBoxEndCapStyle = "TriangleBothEnds"

 
   sicmask=new((/nlat,nlon/),typeof(sic)) 
   sicmask=where(msk2d.eq.msk2d@_FillValue,msk2d,sic2d)
   copy_VarMeta(sic2d,sicmask)
   printVarSummary(sicmask)
   plot(ipoce) = gsn_csm_contour_map_polar(wks,sicmask(:,:)*100-sicobs,res)

   ipoce=ipoce+1
   delete(fsic_ic)
   delete(sic)

end do



;***************************************
; panel first two plots
;***************************************
  pres1                     = True
  pres1@gsnPanelLabelBar    = True       ; common label bar
  pres1@gsnPanelMainString = "SPS4 Arctic Sea Ice concentration [%] - Initialization "+yyyy+st+"01"
  pres1@gsnFrame            = False      ; don't advance frame yet
  pres1@lbOrientation       = "horizontal" ; vertical label bar
; we use PanelBottom to tell the plot to only draw in the top part of the page.
; since there are two plots here, and we have limited the plot to the upper
; 0.6 of the page, each plot will have a size 0.3.
  pres1@gsnPanelBottom      = 0.7        ; move bottom up from 0.0 to 0.4
   pres1@gsnPanelFigureStrings=(/"~C~ OSISAF sea-ice ~C~  "+yynemo+stnemo+lastmonthday/)
   pres1@gsnPanelFigureStringsFontHeightF=0.0095
   pres1@gsnPanelFigureStringsPerimOn=False
   pres1@gsnPanelFigureStringsBackgroundFillColor="transparent"
   pres1@pmLabelBarOrthogonalPosF=-0.03 
   pres1@amJust   = "BottomRight"
  pres1@amParallelPosF =0.85
  ;pres1@gsnPanelRowSpec = True
  gsn_panel(wks,plot(0),(/1,1/),pres1)


;***************************************
; create panel of just third plot to keep aspect ratio
; the same as the panel above
;***************************************
  pres2                     = True
  pres2@gsnPanelLabelBar    = True       ; common label bar
  pres2@gsnPanelTop         = 0.65        ; draw up to the bdry of upper plot
  pres2@gsnPanelBottom      = 0.       ; move bottom up so size is 0.3
  pres2@gsnFrame            = False      ; don't advance frame yet
  pres2@lbOrientation       = "vertical" ; vertical label bar
  pres2@gsnPanelFigureStrings=(/"~C~NEMO IC 01  ~C~   ","~C~NEMO IC 02  ~C~   ","~C~NEMO IC 03  ~C~   ","~C~NEMO IC 04  ~C~   ","~C~NEMO IC 05  ~C~   " ,"~C~NEMO IC 06  ~C~   " ,"~C~NEMO IC 07  ~C~   " ,"~C~NEMO IC 08  ~C~   ","~C~NEMO IC 09"/)
  pres2@gsnPanelFigureStringsFontHeightF=0.0095
  pres2@gsnPanelFigureStringsPerimOn=False
  pres2@gsnPanelFigureStringsBackgroundFillColor="transparent"
  pres2@amJust   = "BottomRight"
  pres2@amParallelPosF =0.72
  pres2@gsnPanelRowSpec = True
  pres2@pmLabelBarOrthogonalPosF=0.03
  pres2@gsnPanelXWhiteSpacePercent=5
  pres2@gsnPanelYWhiteSpacePercent=3
  gsn_panel(wks,plot(1:noce),(/3,3,3/),pres2)

; now advance frame for all plots
  frame(wks)














end
