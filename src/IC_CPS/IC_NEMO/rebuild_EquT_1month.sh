#!/bin/sh -l 

. ~/.bashrc
# load variables from descriptor
. ${DIR_UTIL}/descr_CPS.sh
. ${DIR_UTIL}/load_nco
. ${DIR_UTIL}/load_cdo

set -evx
# set -evx non funziona

caso="cps_complete_test_output"   #$1
yyyy=2000  #`echo $caso|cut -d '_' -f2|cut -c 1-4`
set +evxu
. $DIR_UTIL/descr_ensemble.sh $yyyy
set -evxu
st="02"  #`echo $caso|cut -d '_' -f2|cut -c 5-6`

# Andrea+ year, nday e mm glieli facciamo prendere dal postrun che li definisce all'inizio
year=2000 #$2
mm="03"  #$3
nday="28"  #$4 
ndayfin="03"
ic="1 3 1"  #$5
# Andrea -

outdir="/work/csp/ab00920/CESM2/archive/cps_complete_test_output/ocn/hist"     #${DIR_ARCHIVE}/$1/ocn/hist"
cd $outdir

list=`ls *${year}${mm}${ndayfin}_*EquT_T_0???.nc`
# Andrea+ Commento perche' valido solo per il primo mese, nei mesi successivi ritrova comunque anche i mesi precedenti e non seleziona nulla
#for file in $list
#do
#   mm=`echo $file|cut -d '_' -f 5|cut -c 5,6`
#   break
#done
# Andrea-
# Andrea + 26/03/2020
if [ $year -le 1999 ] && [ $st == "05" -o $st == "06" ]
then
   export meshmaskfile="/data/inputs/CESM/inputdata/ocn/nemo/tn0.25v3/grid/ORCA025L75_domain_cfg.nc"  # $REPOSITORY/mesh_mask_b2000.nc"
else
   export meshmaskfile="/data/inputs/CESM/inputdata/ocn/nemo/tn0.25v3/grid/ORCA025L75_domain_cfg.nc"  # $REPOSITORY/mesh_mask_from2000.nc"
fi
#jpni=`ncdump -h $FILES4SPS3/mesh_mask.nc |grep 'x ='|cut -d '=' -f2|cut -d ';' -f1`
#jpnj=`ncdump -h $FILES4SPS3/mesh_mask.nc |grep 'y ='|cut -d '=' -f2|cut -d ';' -f1`
#klev=`ncdump -h $FILES4SPS3/mesh_mask.nc |grep 'z ='|cut -d '=' -f2|cut -d ';' -f1`
jpni=`ncdump -h $meshmaskfile |grep 'x ='|cut -d '=' -f2|cut -d ';' -f1`
jpnj=`ncdump -h $meshmaskfile |grep 'y ='|cut -d '=' -f2|cut -d ';' -f1`
klev=`ncdump -h $meshmaskfile |grep 'nav_lev ='|cut -d '=' -f2|cut -d ';' -f1`
# Andrea -

cat > $outdir/mergedomain$year$mm.ncl << EOF2
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
begin

vout=new((/$nday,$klev,$jpnj,$jpni/),"float")
vout@_FillValue=0.
EOF2
for ll in $list 
do
  file=$ll
  x1=`ncdump -h $ll |grep DOMAIN_position_first|cut -d '=' -f2|cut -d ',' -f1`
  if [ $x1 -ne 1 ]
  then
     x1=$(($x1 - 1))
  else
     x1=0
  fi
  x2=`ncdump -h $ll |grep DOMAIN_position_last|cut -d '=' -f2|cut -d ',' -f1`
  if [ $x2 -ne 1 ]
  then
     x2=$(($x2 - 1))
  else
     x2=0
  fi
  y1=`ncdump -h $ll |grep DOMAIN_position_first|cut -d '=' -f2|cut -d ',' -f2|cut -d ';' -f1`
  if [ $y1 -ne 1 ]
  then
     y1=$(($y1 - 1))
  else
     y1=0
  fi
  y2=`ncdump -h $ll |grep DOMAIN_position_last|cut -d '=' -f2|cut -d ',' -f2|cut -d ';' -f1`
  if [ $y2 -ne 1 ]
  then
     y2=$(($y2 - 1))
  else
     y2=0
  fi
  echo "in1  = addfile(\"$file\",\"r\")">>$outdir/mergedomain$year$mm.ncl
  echo " tmp = in1->toce ">>$outdir/mergedomain$year$mm.ncl
  echo " nn=dimsizes(tmp) ">>$outdir/mergedomain$year$mm.ncl
  echo "y2=$y2 ">>$outdir/mergedomain$year$mm.ncl
  echo "y1=$y1 ">>$outdir/mergedomain$year$mm.ncl
  echo "lat=in1->nav_lat ">>$outdir/mergedomain$year$mm.ncl
  echo "if ( lat(0,0) .lt. 0 ) then ">>$outdir/mergedomain$year$mm.ncl
  echo " vout(:,:,y2-nn(2)+1:y2,$x1:$x2) = in1->toce ">>$outdir/mergedomain$year$mm.ncl
  echo "else  ">>$outdir/mergedomain$year$mm.ncl
  echo " vout(:,:,y1:y1+nn(2)-1,$x1:$x2) = in1->toce ">>$outdir/mergedomain$year$mm.ncl
  echo "end if  ">>$outdir/mergedomain$year$mm.ncl
  echo " delete(tmp)   ">>$outdir/mergedomain$year$mm.ncl
  echo " delete(nn) ">>$outdir/mergedomain$year$mm.ncl
  echo " delete(lat) ">>$outdir/mergedomain$year$mm.ncl
done


cat >> $outdir/mergedomain$year$mm.ncl << EOF3
votest=getenv("votest")
setfileoption("nc", "FileStructure", "Advanced")
setfileoption("nc", "Format",  "NetCDF4")
system ("/bin/rm -f " + votest);
ncdf     = addfile(votest ,"c")  ; open output netCDF file
vout!2="nav_lat"
ncdf->toce=vout(:,:,348:655,:)

end
EOF3
echo "launching mergedomain$year$mm.ncl "`date`
#EquTfile=${caso}_1d_${year}${mm}01_${year}${mm}${nday}_grid_T_EquT.nc
EquTfile=${caso}_1d_${yyyy}${st}01_${year}${mm}${ndayfin}_grid_EquT_T.nc
export votest=$outdir/${EquTfile}
ncl $outdir/mergedomain$year$mm.ncl
echo "ended mergedomain$year$mm.ncl "`date`
nt=`cdo -ntime $outdir/${EquTfile}`
stat=$?
if [ $stat -eq 0 ]
then
   cd $outdir
   rootname=`basename $EquTfile |rev |cut -d '.' -f1 --complement|rev`
   $compress $EquTfile ${rootname}.zip.nc
   ncatted -O -a ic,global,a,c,"$ic" ${rootname}.zip.nc
   stat=$?
   if [ $stat -eq 0 ]
   then
      rm $EquTfile
      rm $outdir/mergedomain$year$mm.ncl
      #rm $outdir/${caso}_1d_${year}${mm}01_${year}${mm}${nday}_grid_T_EquT_0*.nc
      rm $outdir/${caso}_1d_${yyyy}${st}01_${year}${mm}${ndayfin}_grid_EquT_T_0*.nc
   fi
fi
