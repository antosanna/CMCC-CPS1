begin

yyyy=getenv("yyyy")
st=getenv("st")
ppp=getenv("ppp")
checkfile=getenv("checkfile")

ntime=0
month=toint(st)
year=toint(yyyy)
do nm=0,5

   if ( month .gt. 12 ) then
      month=1
      year=year+1
   end if
   year@calendar = "noleap"
   ndays=days_in_month(year,month)
   ntime=ntime+ndays	
   month=month+1

end do

filetype=getenv("filetype")
pathfile=getenv("datadir")
meshmaskfile = getenv("meshmaskfile")
meshmask = addfile(meshmaskfile,"r")

;************************************************
; variable and file handling
;************************************************

   diri = getenv("datadir")
   varm=getenv("var")
   SPSsys=getenv("SPSsys")
   flist=SPSsys+"_"+yyyy+st+"_"+ppp+"/ocn/hist/*"+yyyy+st+"_"+ppp+"_*"+filetype+".zip.nc"   ;getenv("flist")

   fili = systemfunc("cd "+diri+" ; ls "+flist)
   print(fili)
   nfils = dimsizes(fili) 

   fi = addfile (diri+"/"+fili(0), "r")
   varstd = fi->$varm$
   nn=dimsizes(varstd)
   rank=dimsizes(nn)

if ( rank .eq. 4 ) then
   if ( filetype .eq. "grid_EquT_T" ) then
; first 300m
      depth=fi->deptht(0:34)
   end if
   if ( filetype .eq. "grid_U" ) then
      depth=fi->depthu(0:34)
   end if
   if ( filetype .eq. "grid_V" ) then
      depth=fi->depthv(0:34)
   end if
end if  

if ( rank .eq. 4 ) then
   fall = addfiles (diri+"/"+fili, "r")
   varall=fall[:]->$varm$(:,0:34,:,:)
else if ( rank .eq. 3 ) then
   fall = addfiles (diri+"/"+fili, "r")
   varall=fall[:]->$varm$
end if
end if

if ( filetype .eq. "grid_EquT_T" ) then

   varall_slab=dim_avg_n_Wrap(varall,2)
   delete(varall)
   varall=varall_slab

else
   nav_lat = meshmask->nav_lat
   nav_lon = meshmask->nav_lon
end if

filo=getenv("filo")   ;with full path
system("/bin/rm -f " + filo) 
fout  = addfile (filo, "c")  ; open output file
setfileoption("nc","Format","NetCDF4Classic")
setfileoption("nc","CompressionLevel",6)

;-------- New
global = True
copy_VarAtts(fili, global)

if (isatt(fili,"title")) then
    global@TITLE = "REMAPPED: " + sfile@title
end if
global@creation_date = systemfunc("date")
    
fileattdef( fout, global )        ; copy global file attributes
filedimdef(fout,"time_counter",-1,True)   ; force an unlimited dimension

if ( rank .eq. 4 ) then
   fout->depth = depth
end if
fout->$varm$ = varall
;#######
system("touch "+checkfile)


end
