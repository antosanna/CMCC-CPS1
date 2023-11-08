; this one calculates both the total hemispheric sea-ice covered area and
; that splitted into longitutdinal bins

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl" 

begin

   diri=getenv("diri")
   dira=getenv("dira")
   lat1=tofloat(getenv("lat1"))
   lat2=tofloat(getenv("lat2"))
   filename=getenv("filename")
   csv_filename=getenv("csv_filename")
   csv_filename_bin=getenv("csv_filename_bin")
   fila=getenv("fila")
   nrun2diag=toint(getenv("nrun2diag"))
   okfile=getenv("okfile")

   f = addfile (diri+"/"+filename, "r")
   sicfrac = f->sic    ; expressed as fraction

   lon = f->lon
   lat = f->lat

   sic=where(sicfrac(:,{lat1:lat2},:).gt.1e+19,0,sicfrac(:,{lat1:lat2},:))
   copy_VarMeta(sicfrac(:,{lat1:lat2},:),sic)
;   printVarSummary(sic)
   ndim=dimsizes(sic)
   ntime=ndim(0)
  nz   = ntime  ; # of columns
  fmt_str = "%s"+str_concat(conform_dims(nz-1,"%7.4f,",-1))
  formato = fmt_str+"%7.4f"

   fa = addfile(fila,"r") 
   tmp= fa->cell_area({lat1:lat2},:)
   area=tofloat(tmp/1000000)   ;espresso in km
   area!1="lon"
   area&lon=lon

   areasic=new((/ntime/),typeof(sic))
   do k=0,ntime-1
        areasic(k)=dim_sum_Wrap(dim_sum_Wrap(sic(k,:,:)*area))/1000000
;divide ancora per 1milione per esigenze SIPN-->dato finale e' espresso in milioni di kmq
   end do

; now the same but  for longitudinal bins
   nrow=36
   areasicbin=new((/ntime,nrow/),typeof(sic))
   lon1=0.5
   lon2=9.5
   do i=0,nrow-1 
     do t=0,ntime-1
        areasicbin(t,i)=dim_sum_Wrap(dim_sum_Wrap(sic(t,:,{lon1:lon2})*area(:,{lon1:lon2})))/1000000
     end do
     lon1=lon1+10.
     lon2=lon2+10.
;     print(" row "+i+" lon1 "+lon1+" lon2 "+lon2)
   end do


;   print(areasic)
;   print("sea ice area: min="+min(areasic)+" max="+max(areasic)) 


;#############################################
; WRITE CSV FILE



;---Remove file just in case
  system("rm -f " + csv_filename)


;---Create row format string. It will have "%7.4f" repeated nz times
; str_concat(conform_dims(nz,"%7.4f,",-1))
;  fmt_str = "%s" + conform_dims(nz-1,"%7.4f,") + str_concat("%7.4f,"-1)

;
; Loop through each column of each block and write the
; column of data to a List object.  We can then use
; write_table to append a whole block of formatted data
; to an ASCII file.
;
  dtmp=True

;---Create a new List object for this block of data
    dlist = NewList("lifo")

;---Loop in reverse order so items are written in correct order
    do j=nz-1,0,1
      ListPush(dlist,(/areasic(j)/))
    end do  

;---Push array of row headers onto list object
    str = unique_string("test")
;    dtmp@$str$ = sprinti("%0.2i",i+1)+"-- "
    dtmp@$str$ = ""
    ListPush(dlist,dtmp@$str$)

;---Append this List of data to file.
    write_table(csv_filename, "a", dlist, formato)

;#############################################
; WRITE CSV FILE BINS

  nz   = ntime  ; # of columns
  ny   = 36     ; # of rows


;---Remove file just in case
  system("rm -f " + csv_filename_bin)


;---Create row format string. It will have "%8.4f" repeated nz times

;
; Loop through each column of each block and write the
; column of data to a List object.  We can then use
; write_table to append a whole block of formatted data
; to an ASCII file.
;
  dtmp=True

;---Create a new List object for this block of data
    dlist = NewList("lifo")

;---Loop in reverse order so items are written in correct order
    do j=nz-1,0,1
      ListPush(dlist,(/areasicbin(j,:)/))
    end do  

;---Push array of row headers onto list object
    str = unique_string("test")
;    dtmp@$str$ = sprinti("%0.2i",i+1)+"-- "
    dtmp@$str$ = ""
    ListPush(dlist,dtmp@$str$)

;---Append this List of data to file.
    write_table(csv_filename_bin, "a", dlist, formato)
  filename = "example1b.csv"
  system("rm -rf " + filename)

    system("touch "+okfile) 
  
end
