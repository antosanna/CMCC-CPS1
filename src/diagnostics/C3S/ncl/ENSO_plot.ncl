load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/cd_string.ncl"
;*****************************************************
begin

;*****************************************************
; open files and read in monthly data
;*****************************************************
write="FALSE"
REG=getenv("REG")
tstart =getenv("yyyym1")
tend   =getenv("yyyy")
st   = getenv("st")
nens   = toint(getenv("nens"))
stm1=getenv("st")
refperiod   = getenv("refperiod")
dirplots=getenv("dirplots")

figtype=getenv("figtype")

dir =getenv("workdir_anom") 
v1    = addfile (dir+"/sst_SPS3.5_sps_"+tend+st+"_all_ano."+refperiod+".nc","r")
tstmp    = v1->tso(:,0:5,:,:)
timetmp  = v1->time(0:5)
ts=new((/nens,18,180,360/),typeof(tstmp),tstmp@_FillValue)
ts(:,12:17,:,:)=tstmp
time=new((/18/),typeof(timetmp))
time=fspan(0,17,18)
time@units="months since "+tstart+"-"+stm1+"-15 12:00:00"
delete(time@calendar)
format= "%c ~C~%Y"
stime=cd_string(time,format)
ts@_FillValue=1.e+20

ts!0    = "ensemble"
ts!1    = "time"
ts!2    = "lat"
ts!3    = "lon"

 ncep_dir = getenv("ncep_dir")  
 fname=ncep_dir+"/sstoi.indices"
 strs = asciiread(fname,-1,"string")

 delim = " "
 field = 1    ;this is to select last archived year
 tmp = stringtointeger(str_get_field(strs, field, delim))
; tendobs=(tmp(dimsizes(tmp)-1))
 delete(tmp)
 field = 2    ;this is to select last archived month
 tmp = stringtointeger(str_get_field(strs, field, delim))
 monl=tmp(dimsizes(tmp)-1)
 print(monl)
 if ( REG .eq. "Nino1+2" ) then
    field = 4    ;this is Nino1+2 anomaly index
 else if( REG .eq. "Nino3" ) then
    field = 6    ;this is Nino3 anomaly index
 else if ( REG .eq. "Nino4" ) then
    field = 8    ;this is Nino4 anomaly index
 else if ( REG .eq. "Nino3.4" ) then
    field = 10 ;this is Nino3.4 anomaly index
 end if
 end if
 end if
 end if
 delete(tmp)
 tmp = stringtofloat(str_get_field(strs, field, delim))
 onino3=tmp(dimsizes(tmp)-12:dimsizes(tmp)-1)
 delete(tmp)

;*****************************************************   
; CALCULATE Nino3 Index
;*****************************************************
lt1=getenv("lt1")
lt2=getenv("lt2")
lg1=getenv("lg1")
lg2=getenv("lg2")
print(lt1)
print(lt2)
print(lg1)
print(lg2)
nino3=wgt_areaave_Wrap(ts(:,:,{lt1:lt2},{lg1:lg2}),1,1,0)

nino3!0    = "ensemble"
nino3!1    = "time"
nino3&time = time
ninoemtmp=dim_avg_n_Wrap(nino3,0)

ninoem=ninoemtmp(12:17)

printVarSummary(ninoem)
print(ninoem)

onino3!0    = "time"

print(dimsizes(onino3))
onino3new=new((/18/),double,nino3@_FillValue)
onino3new(0:11)=onino3

onino3new!0    = "time"
onino3new&time = time


;print(onino3new)
;*****************************************************   
; CALCULATE MIN & MAX and Ensemble Mean
;*****************************************************

mnmx      = new ((/6,18/), double)
mnmx@_FillValue=-999.
mnmx(0,:) = dim_min( nino3(time|:,ensemble|:) )
mnmx(1,:) = dim_max( nino3(time|:,ensemble|:) )
mnmx(2,:) = dim_median( nino3(time|:,ensemble|:) )
mnmx(3,:) = dim_avg( nino3(time|:,ensemble|:) )
mnmx(3,0:10)=mnmx@_FillValue
printVarSummary(mnmx)
mnmx(4,:) = onino3new 
mnmx(4,0:10)=mnmx@_FillValue
mnmx(4,12)=mnmx(3,12)
mnmx(4,13:17)=mnmx@_FillValue
mnmx(5,:) = onino3new

mmax=max(mnmx)+1
mmin=min(mnmx)-1

;*****************************************************
; -- PLOT SETTINGS
;*****************************************************
plname=dirplots+"/sst_"+REG+"_mem_"+tend+"_"+st
wks = gsn_open_wks(figtype,plname)                 ; create plot
colors = (/"white","black","Red","LightBlue","lightpink"/)
gsn_define_colormap(wks, colors)  


res                    = True              ; plot mods desired
res@gsnDraw            = False             ; don't draw yet
res@gsnFrame           = False             ; don't advance frame yet

res@vpHeightF          = 0.4               ; change aspect ratio of plot
res@vpWidthF           = 0.7

res@trYMaxF            = mmax
res@trYMinF            = mmin

res@xyMonoLineColor    = False             ; want colored lines
;res@xyLineColors       = (/"Red","Red","black","LightBlue","lightpink"/) ; colors chosen
;res@xyLineColors       = (/"Red","black","black","LightBlue","lightpink"/) ; colors chosen
res@xyLineThicknesses  = (/3,2,2,2,2/)      ; line thicknesses
res@xyDashPatterns     = (/0,1,0,0,0/)      ; make all lines solid

res@tiYAxisString    = "~F35~J~F~C"      ; add an axis title    
res@txFontHeightF    = 0.007            ; change title font heights
res@gsnYRefLine      = 0.0             ; create a reference line
res@tmYLLabelFontHeightF    = 0.012
res@tmXBLabelFontHeightF    = 0.012
res@tiMainString     = REG+" Index issued "+tend+st


res@tmXBFormat = "f"        ; remove the trailing ".0"
res@trXMinF    = 0       ; starting point along X axis
res@trXMaxF    = 17
res@tmXBMode   = "Explicit"
res@tmXBValues = ispan(0,17,1)     ; choose first 13 timesteps
labelsx=stime
labelsx(1)=" "
labelsx(3)=" "
labelsx(5)=" "
labelsx(7)=" "
labelsx(9)=" "
labelsx(11)=" "
labelsx(13)=" "
labelsx(15)=" "
labelsx(17)=" "
res@tmXBLabels = labelsx    

obs_plot = gsn_csm_y (wks,mnmx(5,:),res)       ; create line plot

res@xyLineColors = "red"
res@xyMonoDashPattern  = True 
res@xyDashPattern = 1

raccordo_plot = gsn_csm_y (wks,mnmx(4,:),res)       ; create line plot

; Create a plot with the area between both curves filled in blue.

delete(res@xyLineColors)
delete(res@xyDashPattern)
res@gsnXYFillColors = "LightBlue"
res@xyLineColor     = -1                           ; We don't want the line, so make it transparent.

bot_plot  = gsn_csm_y (wks,mnmx(0:2:2,:),res)  ; Create filled XY plot.

; Create a plot with the area between both curves filled in pink.

res@gsnXYFillColors = "lightpink"
res@xyLineColor     = -1                           ; We don't want the line, so make it transparent.

printVarSummary(mnmx(1:2,:))
up_plot  = gsn_csm_y (wks,mnmx(1:2,:),res)  ; Create another filled XY plot.
      
; Create a plot with the ensmble mean line filled in red.

res@gsnXYFillColors = "Red"
;res@gsnXYFillColors = "black"
;res@xyLineColor     =  "red"                          ; We don't want the line, so make it transparent.
res@xyLineColors    = "red"

mid_plot  = gsn_csm_y (wks,mnmx(3,:),res)  ; Create another filled XY plot.

;
; Overlay the top and mid plots on the bottom plot.
;
; Don't draw anything yet, because we still need to
; attach a legend and some titles.
;
  overlay(bot_plot,mid_plot)
  overlay(bot_plot,obs_plot)
  overlay(bot_plot,raccordo_plot)
  overlay(bot_plot,up_plot)

getvalues bot_plot                      ; Get plot size for use in
  "vpHeightF" : vph                 ; determining size of
  "vpWidthF"  : vpw                 ; labelbar.
end getvalues

;***********************************************
; legend resources
;***********************************************
lbres                    = True          ; labelbar only resources
lbres@lbAutoManage       = True          ; Necessary to control sizes
lbres@vpWidthF           = 0.2 * vpw     ; labelbar width
lbres@vpHeightF          = 0.2 * vph     ; labelbar height
lbres@lbBoxMajorExtentF  = 0.75          ; puts space between color boxes
lbres@lbFillColors       = (/"black","Red","LightBlue","lightpink"/)  ; labelbar colors
lbres@lbMonoFillPattern  = True          ; Solid fill pattern
lbres@lbLabelFontHeightF = 0.1          ; font height. default is small
lbres@lbLabelJust        = "CenterLeft"  ; left justify labels

lbid = gsn_create_labelbar(wks,4,(/"NCEP","Ensmean","Below median","Above median"/),lbres)         ; create legend

amres = True
amres@amJust           = "TopRight"
amres@amParallelPosF   = -0.3         ; move legend to the right
amres@amOrthogonalPosF = -0.5            ; move the legend down
annoid1 = gsn_add_annotation(bot_plot,lbid,amres)   ; add legend to plot

draw(bot_plot)   ; Draw base plot.
frame(wks)    ; advance frame
;*******************************************************************
  if ( write .eq. "TRUE" ) then

    ntime  = 6  ;dimsizes(time)

    diro = "./files/"                     ; Output directory
    filo = "SPS3_"+REG+"_"+tend+st+".nc"  ; Output file
    system("/bin/rm -f " + diro + filo)    ; remove if exists
    fout  = addfile (diro + filo, "c")  ; open output file

    setfileoption(fout,"DefineMode",True)

    fAtt               = True            ; assign file attributes
    fAtt@title         = REG
    fAtt@Conventions   = "CF compliant"
    fAtt@creation_date = systemfunc ("date")
    fileattdef( fout, fAtt )            ; copy file attributes  ; MODIFY

    dimNames = (/"time"/)
    dimSizes = (/ ntime/)
    dimUnlim = (/False/)
    filedimdef(fout,dimNames,dimSizes,dimUnlim)

    filevardef(fout, "time"  ,typeof(time),getvardims(time))  ; MODIFY
    filevardef(fout, "nino"  ,typeof(ninoem),getvardims(ninoem))  ; MODIFY


   filevarattdef(fout,"time"  ,time)
   probAtt           = 0 
   probAtt@units     = "degC"
   probAtt@long_name = REG
   filevarattdef( fout, "nino" , probAtt )

   fout->time    = time(12:17)
   fout->nino = (/ninoem/)

  end if
;*******************************************************************
geom_value=" 80x80+930+670" 
system("pwd")
print(plname+".png")
system( "composite -geometry "+geom_value+" cmcc_logo_bw.jpg "+plname+".png "+plname+".png")
system( "touch "+plname+"_DONE")

end
