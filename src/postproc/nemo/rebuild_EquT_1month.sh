#!/bin/sh -l 

. ~/.bashrc
# load variables from descriptor
. ${DIR_UTIL}/descr_CPS.sh
#set -evx
. ${DIR_UTIL}/load_cdo
. ${DIR_UTIL}/load_ncl

# set -evx non funziona

caso=$1
yyyy=$2  
curryear=$3 
currmon=$4
ic=$5
outdir=$6

set +evxu
. $DIR_UTIL/descr_ensemble.sh $yyyy
set -evxu

wkdir=$SCRATCHDIR/nemo_EquT/$caso
mkdir -p $wkdir
cd $wkdir

export meshmaskfile="$CESMDATAROOT/inputdata/ocn/nemo/tn0.25v3/grid/ORCA025L75_domain_cfg.nc"  
jpni=`ncdump -h $meshmaskfile |grep 'x ='|cut -d '=' -f2|cut -d ';' -f1`
jpnj=`ncdump -h $meshmaskfile |grep 'y ='|cut -d '=' -f2|cut -d ';' -f1`
klev=`ncdump -h $meshmaskfile |grep 'nav_lev ='|cut -d '=' -f2|cut -d ';' -f1`

first_file=`ls $outdir/${caso}_1d_${curryear}${currmon}01_${curryear}${currmon}??_grid_EquT_T_0???.nc|head -1`
nday=`cdo -ntime $first_file`
finaldate=${curryear}${currmon}${nday}
EquTfile=${caso}_1d_${curryear}${currmon}01_${finaldate}_grid_EquT_T.nc
list=`ls $outdir/${caso}_1d_${curryear}${currmon}01_${finaldate}_grid_EquT_T_0???.nc`

cat > $wkdir/mergedomain$curryear$currmon.ncl << EOF2
begin

vout=new((/$nday,$klev,$jpnj,$jpni/),"float")
lat_out=new((/$jpnj,$jpni/),"float")
vout@_FillValue=0.
EOF2

ymin=10000
ymax=1
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
  echo $ymin $y1
  if [[ $y1 -lt $ymin ]]
  then   
     ymin=$y1
  fi
  y2=`ncdump -h $ll |grep DOMAIN_position_last|cut -d '=' -f2|cut -d ',' -f2|cut -d ';' -f1`
  if [ $y2 -ne 1 ]
  then
     y2=$(($y2 - 1))
  else
     y2=0
  fi
  echo $ymax $y2
  if [[ $y2 -gt $ymax ]]
  then   
     ymax=$y2
  fi
  cat >> $wkdir/mergedomain$curryear$currmon.ncl << EOF2
in1  = addfile("$file","r")
tmp = in1->toce
nn=dimsizes(tmp)
y2=$y2
y1=$y1
lat=in1->nav_lat
if ( lat(0,0) .lt. 0 ) then
   vout(:,:,y2-nn(2)+1:y2,$x1:$x2) = in1->toce
   lat_out(y2-nn(2)+1:y2,$x1:$x2) =lat
else 
   vout(:,:,y1:y1+nn(2)-1,$x1:$x2) = in1->toce 
   lat_out(y1:y1+nn(2)-1,$x1:$x2) = lat
end if  
delete(tmp) 
delete(nn) 
delete(lat)

EOF2

done


cat >> $wkdir/mergedomain$curryear$currmon.ncl << EOF3
outfile=getenv("outfile")
setfileoption("nc", "FileStructure", "Advanced")
setfileoption("nc", "Format",  "NetCDF4")
system ("/bin/rm -f " + outfile);
ncdf     = addfile(outfile ,"c")  ; open output netCDF file
tmp=lat_out($ymin:$ymax,:)
ncdf->nav_lat=tmp
delete(tmp)
tmp=vout(:,:,$ymin:$ymax,:)
ncdf->toce=tmp

end
EOF3
echo $ymin
echo $ymax

echo "launching mergedomain$curryear$currmon.ncl "`date`
export outfile=$wkdir/${EquTfile}
set +euvx
. ${DIR_UTIL}/load_ncl
set -euvx
ncl $wkdir/mergedomain$curryear$currmon.ncl
echo "ended mergedomain$curryear$currmon.ncl "`date`
nt=`cdo -ntime $wkdir/${EquTfile}`
set +euvx
. ${DIR_UTIL}/load_nco
set -euvx
if [ -f $outfile ]
then
   rootname=`basename $outfile |rev |cut -d '.' -f1 --complement|rev`
   $DIR_UTIL/compress.sh $EquTfile $outdir/${rootname}.zip.nc
   ncatted -O -a ic,global,a,c,"$ic" $outdir/${rootname}.zip.nc
   if [ -f $outdir/${rootname}.zip.nc ]
   then
      rm $EquTfile
      rm $outdir/${caso}_1d_${curryear}${currmon}01_${finaldate}_grid_EquT_T_0*.nc
   fi
fi
