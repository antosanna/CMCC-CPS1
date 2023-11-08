;*****************************************************
; sst_timeseries.ncl
;
; Concepts illustrated:
;   - Drawing an XY plot with three different Y axes
;   - Drawing a custom legend inside an XY plot
;   - Maximizing the size of several different objects on a frame
;   - Maximizing plots after they've been created
;*****************************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
;*****************************************************
begin
;
;************************************************
; read in netCDF file MODEL
;************************************************
yyyy=getenv("yyyy")
yy=getenv("yy")
st=getenv("st")
pltype=getenv("pltype")
pltdir=getenv("pltdir")
pltname=getenv("pltname")
var=getenv("var")
nmon=toint(getenv("nmon"))
outvar=getenv("outvar")

;----Auxilliary file for CAM (templateL46)
path = getenv("diri")
filename = getenv("filename")
fili = systemfunc("cd "+path+" ; ls *"+filename)
print(fili)
nfiles = dimsizes(fili)
print(nfiles)
 
b = addfile (path+"/"+fili(0), "r")
print(path+"/"+fili(0))
sst=b->$var$(:,0,0)
time_counter=b->time_counter
nn=dimsizes(sst)
ssttoplot=new((/nfiles+2,nmon/),typeof(sst))
tplot=new((/nfiles+2,nmon/),typeof(time_counter))
ssttoplot(2,0:nn(0)-1)=sst
tplot(0,0:nn(0)-1)=ispan(1,nn(0),1)
do id=2,nfiles
   b=addfile(path+"/"+fili(id-1),"r")
   print("addfile "+     path+"/"+fili(id-1))
   delete(sst)
   delete(time_counter)
   delete(nn)
   sst=b->$var$(:,0,0)
   time_counter=b->time_counter
   nn=dimsizes(sst)
   ssttoplot(id,0:nn(0)-1)=sst
   tplot(id,0:nn(0)-1)=ispan(1,nn(0),1)
end do
ssttoplot(0,:)=dim_avg_n(ssttoplot(2:nfiles+1,:),0)
ssttoplot(1,:)=dim_median_n(ssttoplot(2:nfiles+1,:),0)
std_var=dim_stddev_n(ssttoplot,0)
varmin=min(ssttoplot)-max(std_var)
varmax=max(ssttoplot)+max(std_var)
;
;  wks = gsn_open_wks(pltype,pltdir+"/SPS3.5_"+yyyy+st+"_"+outvar+"_timeseries")
  wks = gsn_open_wks(pltype,pltdir+"/"+pltname)

 res=True
 res@xyLineThicknesses = (/  3.0/)          ; make second line thicker
; res@xyLineColors      = (/"red"/)          ; change line color
 res@tiMainString      = outvar+" "+sprinti("%2.0i",nfiles)+" members start-date "+yyyy+st
  res@trYMinF  = varmin                   ; min value on y-axis
  res@trYMaxF  =  varmax                   ; max value on y-axis
  print(res@trYMinF)

; res@xyLineColors      := (/"red","green","RoyalBlue","orange","LightSkyBlue","black","magenta","purple","seagreen","yellow"/)          ; change line color
; res@xyLineColors      := "grey"  ;use this if you want different colors for different lines
 res@xyLineColor  = "grey"
 res@xyLineColors(0)  := "red"
 res@xyLineColors(1)  := "purple"
 res@xyMarkLineMode = "MarkLines"               ; Markers *and* lines
; res@xyMarkers      = (/16,16,16,16,16,16,16,16,16,16/)               ; 3 different markers
 res@xyMarkerColors = res@xyLineColor 
 res@xyMarkerSizeF     = 0.005                     ; Marker size (default 0.01)
;  res@tmXBMode   = "Manual"
;  res@tmXBTickStartF  = 1
;  res@tmXBTickEndF    = 6
  res@tmXBMode        = "Explicit"	
  taxis      = ispan(toint(st),toint(st)-1+nmon,1)
  res@tmXBValues      = taxis
  ilabelm=taxis
  ilabely=taxis
  label=new(dimsizes(ilabely),"string")
  do m=0,nmon-1
     ilabely(m)=toint(yyyy)
     if (ilabelm(m).gt.12) then
        ilabelm(m)=ilabelm(m)-12
        ilabely(m)=toint(yyyy)+1
     end if
     label(m)=tostring(ilabelm(m))+"/"+tostring(ilabely(m))
  end do
  res@tmXBLabels = label
  res@tmXBTickSpacingF= 1
  res@tmXBLabelFontHeightF = 0.009

  res@gsnMaximize = True

 plot  = gsn_csm_xy (wks,taxis,ssttoplot,res) ; create plot



end

