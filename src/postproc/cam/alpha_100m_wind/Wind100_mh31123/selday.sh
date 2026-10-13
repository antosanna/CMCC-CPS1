#!/bin/sh -l

. $HOME/.bashrc
#load cdo/ncl 
. $DIR_UTIL/load_cdo
. $DIR_UTIL/load_ncl

#load Files 
data_dir="/work/csp/mh31123/scratch/Wind100/Data_alpha/6hourly_alpha/"
data_dir2="/work/csp/mh31123/scratch/Wind100/Data_alpha/moredays/"
# Specify the output directory for the alpha
output_dir="/work/csp/mh31123/scratch/Wind100/Data_alpha/alpha_185days/"
#1993-01-01 is 1993-07-04
#1997-02-01 is 1997-08-04
#1997-03-01 is 1997-09-01
#1997-04-01 is 1997-10-02
#1997-05-01 is 1997-11-01
#1997-06-01 is 1997-12-02
#1997-07-01 is 1998-01-01
#1997-08-01 is 1998-02-01
#1997-09-01 is 1998-03-04
#1997-10-01 is 1998-04-03
#1997-11-01 is 1998-05-04
#1997-12-01 is 1998-06-03

years=ispan(1993,2023,1)
files=(alpha_output_{1993..2023}01.nc)
for file in "${files[@]}";do
out_file="$out_dir${file%.nc}_01.nc"
cdo selday,1,2,3,4 "$data_dir$file" "$out_file"
done

cdo selday,1,2,3,4 "${data_dir}"alpha_output_200708.nc "${output_dir}"20070801.nc
cdo selday,1 "${data_dir}"alpha_output_200709.nc "${output_dir}"20070901.nc
cdo selday,1,2 "${data_dir}"alpha_output_200710.nc "${output_dir}"20071001.nc
cdo selday,1 "${data_dir}"alpha_output_200711.nc "${output_dir}"20071101.nc
cdo selday,1,2 "${data_dir}"alpha_output_200712.nc "${output_dir}"20071201.nc
cdo selday,1 "${data_dir}"alpha_output_200801.nc "${output_dir}"20080101.nc
cdo selday,1 "${data_dir}"alpha_output_200802.nc "${output_dir}"20080201.nc
cdo selday,1,2,3,4 "${data_dir}"alpha_output_200803.nc "${output_dir}"20080301.nc
cdo selday,1,2,3 "${data_dir}"alpha_output_200804.nc "${output_dir}"20080401.nc
cdo selday,1,2,3,4 "${data_dir}"alpha_output_200805.nc "${output_dir}"20080501.nc
cdo selday,1,2,3 "${data_dir}"alpha_output_200806.nc "${output_dir}"20080601.nc

#cdo selday,1,2,3,4,5 "${data_dir}"alpha_output_200807.nc "${data_dir}"20080701.nc
#cdo selday,1,2,3,4,5 "${data_dir}"alpha_output_200808.nc "${data_dir}"20080801.nc
#cdo selday,1,2 "${data_dir}"alpha_output_200809.nc "${data_dir}"20080901.nc
#cdo selday,1,2,3 "${data_dir}"alpha_output_200810.nc "${data_dir}"20081001.nc
#cdo selday,1,2 "${data_dir}"alpha_output_200811.nc "${data_dir}"20081101.nc
#cdo selday,1,2,3 "${data_dir}"alpha_output_200812.nc "${data_dir}"20081201.nc
#cdo selday,1,2 "${data_dir}"alpha_output_200901.nc "${data_dir}"20090101.nc
#cdo selday,1,2 "${data_dir}"alpha_output_200902.nc "${data_dir}"20090201.nc
#cdo selday,1,2,3,4,5 "${data_dir}"alpha_output_200903.nc "${data_dir}"20090301.nc
#cdo selday,1,2,3,4 "${data_dir}"alpha_output_200904.nc "${data_dir}"20090401.nc
#cdo selday,1,2,3,4,5 "${data_dir}"alpha_output_200905.nc "${data_dir}"20090501.nc
#cdo selday,1,2,3,4 "${data_dir}"alpha_output_200906.nc "${data_dir}"20090601.nc


cdo selday,1,2,3,4,5 "${data_dir}"alpha_output_200907.nc "${data_dir}"20090701.nc
cdo selday,1,2,3,4,5 "${data_dir}"alpha_output_200908.nc "${data_dir}"20090801.nc
cdo selday,1,2 "${data_dir}"alpha_output_200909.nc "${data_dir}"20090901.nc
cdo selday,1,2,3 "${data_dir}"alpha_output_200910.nc "${data_dir}"20091001.nc
cdo selday,1,2 "${data_dir}"alpha_output_200911.nc "${data_dir}"20091101.nc
cdo selday,1,2,3 "${data_dir}"alpha_output_200912.nc "${data_dir}"20091201.nc
cdo selday,1,2 "${data_dir}"alpha_output_201001.nc "${data_dir}"20100101.nc
cdo selday,1,2 "${data_dir}"alpha_output_201002.nc "${data_dir}"20100201.nc
cdo selday,1,2,3,4,5 "${data_dir}"alpha_output_201003.nc "${data_dir}"20100301.nc
cdo selday,1,2,3,4 "${data_dir}"alpha_output_201004.nc "${data_dir}"20100401.nc
cdo selday,1,2,3,4,5 "${data_dir}"alpha_output_201005.nc "${data_dir}"20100501.nc
cdo selday,1,2,3,4 "${data_dir}"alpha_output_201006.nc "${data_dir}"20100601.nc

cdo selday,1,2,3,4,5 "${data_dir}"alpha_output_201007.nc "${data_dir}"20100701.nc
cdo selday,1,2,3,4,5 "${data_dir}"alpha_output_201008.nc "${data_dir}"20100801.nc
cdo selday,1,2 "${data_dir}"alpha_output_201009.nc "${data_dir}"20100901.nc
cdo selday,1,2,3 "${data_dir}"alpha_output_201010.nc "${data_dir}"20101001.nc
cdo selday,1,2 "${data_dir}"alpha_output_201011.nc "${data_dir}"20101101.nc
cdo selday,1,2,3 "${data_dir}"alpha_output_201012.nc "${data_dir}"20101201.nc
cdo selday,1,2 "${data_dir}"alpha_output_201101.nc "${data_dir}"20110101.nc
cdo selday,1,2 "${data_dir}"alpha_output_201102.nc "${data_dir}"20110201.nc
cdo selday,1,2,3,4,5 "${data_dir}"alpha_output_201103.nc "${data_dir}"20110301.nc
cdo selday,1,2,3,4 "${data_dir}"alpha_output_201104.nc "${data_dir}"20110401.nc
cdo selday,1,2,3,4,5 "${data_dir}"alpha_output_201105.nc "${data_dir}"20110501.nc
cdo selday,1,2,3,4 "${data_dir}"alpha_output_201106.nc "${data_dir}"20110601.nc

cdo selday,1,2,3,4,5 "${data_dir}"alpha_output_201107.nc "${data_dir}"20110701.nc
cdo selday,1,2,3,4,5 "${data_dir}"alpha_output_201108.nc "${data_dir}"20110801.nc
cdo selday,1,2 "${data_dir}"alpha_output_201109.nc "${data_dir}"20110901.nc
cdo selday,1,2,3 "${data_dir}"alpha_output_201110.nc "${data_dir}"20111001.nc
cdo selday,1,2 "${data_dir}"alpha_output_201111.nc "${data_dir}"20111101.nc
cdo selday,1,2,3 "${data_dir}"alpha_output_201112.nc "${data_dir}"20111201.nc
cdo selday,1,2 "${data_dir}"alpha_output_201201.nc "${data_dir}"20120101.nc
cdo selday,1,2 "${data_dir}"alpha_output_201202.nc "${data_dir}"20120201.nc
cdo selday,1,2,3,4,5 "${data_dir}"alpha_output_201203.nc "${data_dir}"20120301.nc
cdo selday,1,2,3,4 "${data_dir}"alpha_output_201204.nc "${data_dir}"20120401.nc
cdo selday,1,2,3,4,5 "${data_dir}"alpha_output_201205.nc "${data_dir}"20120501.nc
cdo selday,1,2,3,4 "${data_dir}"alpha_output_201206.nc "${data_dir}"20120601.nc

cdo selday,1,2,3,4,5 "${data_dir}"alpha_output_201207.nc "${data_dir}"20120701.nc
cdo selday,1,2,3,4,5 "${data_dir}"alpha_output_201208.nc "${data_dir}"20120801.nc
cdo selday,1,2 "${data_dir}"alpha_output_201209.nc "${data_dir}"20120901.nc
cdo selday,1,2,3 "${data_dir}"alpha_output_201210.nc "${data_dir}"20121001.nc
cdo selday,1,2 "${data_dir}"alpha_output_201211.nc "${data_dir}"20121101.nc
cdo selday,1,2,3 "${data_dir}"alpha_output_201212.nc "${data_dir}"20121201.nc
cdo selday,1,2 "${data_dir}"alpha_output_201301.nc "${data_dir}"20130101.nc
cdo selday,1,2 "${data_dir}"alpha_output_201302.nc "${data_dir}"20130201.nc
cdo selday,1,2,3,4,5 "${data_dir}"alpha_output_201303.nc "${data_dir}"20130301.nc
cdo selday,1,2,3,4 "${data_dir}"alpha_output_201304.nc "${data_dir}"20130401.nc
cdo selday,1,2,3,4,5 "${data_dir}"alpha_output_201305.nc "${data_dir}"20130501.nc
cdo selday,1,2,3,4 "${data_dir}"alpha_output_201306.nc "${data_dir}"20130601.nc

cdo selday,1,2,3,4,5 "${data_dir}"alpha_output_201307.nc "${data_dir}"20130701.nc
cdo selday,1,2,3,4,5 "${data_dir}"alpha_output_201308.nc "${data_dir}"20130801.nc
cdo selday,1,2 "${data_dir}"alpha_output_201309.nc "${data_dir}"20130901.nc
cdo selday,1,2,3 "${data_dir}"alpha_output_201310.nc "${data_dir}"20131001.nc
cdo selday,1,2 "${data_dir}"alpha_output_201311.nc "${data_dir}"20131101.nc
cdo selday,1,2,3 "${data_dir}"alpha_output_201312.nc "${data_dir}"20131201.nc
cdo selday,1,2 "${data_dir}"alpha_output_201401.nc "${data_dir}"20140101.nc
cdo selday,1,2 "${data_dir}"alpha_output_201402.nc "${data_dir}"20140201.nc
cdo selday,1,2,3,4,5 "${data_dir}"alpha_output_201403.nc "${data_dir}"20140301.nc
cdo selday,1,2,3,4 "${data_dir}"alpha_output_201404.nc "${data_dir}"20140401.nc
cdo selday,1,2,3,4,5 "${data_dir}"alpha_output_201405.nc "${data_dir}"20140501.nc
cdo selday,1,2,3,4 "${data_dir}"alpha_output_201406.nc "${data_dir}"20140601.nc

cdo selday,1,2,3,4,5 "${data_dir}"alpha_output_201407.nc "${data_dir}"20140701.nc
cdo selday,1,2,3,4,5 "${data_dir}"alpha_output_201408.nc "${data_dir}"20140801.nc
cdo selday,1,2 "${data_dir}"alpha_output_201409.nc "${data_dir}"20140901.nc
cdo selday,1,2,3 "${data_dir}"alpha_output_201410.nc "${data_dir}"20141001.nc
cdo selday,1,2 "${data_dir}"alpha_output_201411.nc "${data_dir}"20141101.nc
cdo selday,1,2,3 "${data_dir}"alpha_output_201412.nc "${data_dir}"20141201.nc
cdo selday,1,2 "${data_dir}"alpha_output_201501.nc "${data_dir}"20150101.nc
cdo selday,1,2 "${data_dir}"alpha_output_201502.nc "${data_dir}"20150201.nc
cdo selday,1,2,3,4,5 "${data_dir}"alpha_output_201503.nc "${data_dir}"20150301.nc
cdo selday,1,2,3,4 "${data_dir}"alpha_output_201504.nc "${data_dir}"20150401.nc
cdo selday,1,2,3,4,5 "${data_dir}"alpha_output_201505.nc "${data_dir}"20150501.nc
cdo selday,1,2,3,4 "${data_dir}"alpha_output_201506.nc "${data_dir}"20150601.nc

cdo selday,1,2,3,4,5 "${data_dir}"alpha_output_201507.nc "${data_dir}"20150701.nc
cdo selday,1,2,3,4,5 "${data_dir}"alpha_output_201508.nc "${data_dir}"20150801.nc
cdo selday,1,2 "${data_dir}"alpha_output_201509.nc "${data_dir}"20150901.nc
cdo selday,1,2,3 "${data_dir}"alpha_output_201510.nc "${data_dir}"20151001.nc
cdo selday,1,2 "${data_dir}"alpha_output_201511.nc "${data_dir}"20151101.nc
cdo selday,1,2,3 "${data_dir}"alpha_output_201512.nc "${data_dir}"20151201.nc
cdo selday,1,2 "${data_dir}"alpha_output_201601.nc "${data_dir}"20160101.nc
cdo selday,1,2 "${data_dir}"alpha_output_201602.nc "${data_dir}"20160201.nc
cdo selday,1,2,3,4,5 "${data_dir}"alpha_output_201603.nc "${data_dir}"20160301.nc
cdo selday,1,2,3,4 "${data_dir}"alpha_output_201604.nc "${data_dir}"20160401.nc
cdo selday,1,2,3,4,5 "${data_dir}"alpha_output_201605.nc "${data_dir}"20160501.nc
cdo selday,1,2,3,4 "${data_dir}"alpha_output_201606.nc "${data_dir}"20160601.nc

cdo selday,1,2,3,4,5 "${data_dir}"alpha_output_201607.nc "${data_dir}"20160701.nc
cdo selday,1,2,3,4,5 "${data_dir}"alpha_output_201608.nc "${data_dir}"20160801.nc
cdo selday,1,2 "${data_dir}"alpha_output_201609.nc "${data_dir}"20160901.nc
cdo selday,1,2,3 "${data_dir}"alpha_output_201610.nc "${data_dir}"20161001.nc
cdo selday,1,2 "${data_dir}"alpha_output_201611.nc "${data_dir}"20161101.nc
cdo selday,1,2,3 "${data_dir}"alpha_output_201612.nc "${data_dir}"20161201.nc
cdo selday,1,2 "${data_dir}"alpha_output_201701.nc "${data_dir}"20170101.nc
cdo selday,1,2 "${data_dir}"alpha_output_201702.nc "${data_dir}"20170201.nc
cdo selday,1,2,3,4,5 "${data_dir}"alpha_output_201703.nc "${data_dir}"20170301.nc
cdo selday,1,2,3,4 "${data_dir}"alpha_output_201704.nc "${data_dir}"20170401.nc
cdo selday,1,2,3,4,5 "${data_dir}"alpha_output_201705.nc "${data_dir}"20170501.nc
cdo selday,1,2,3,4 "${data_dir}"alpha_output_201706.nc "${data_dir}"20170601.nc

cdo selday,1,2,3,4,5 "${data_dir}"alpha_output_201707.nc "${data_dir}"20170701.nc
cdo selday,1,2,3,4,5 "${data_dir}"alpha_output_201708.nc "${data_dir}"20170801.nc
cdo selday,1,2 "${data_dir}"alpha_output_201709.nc "${data_dir}"20170901.nc
cdo selday,1,2,3 "${data_dir}"alpha_output_201710.nc "${data_dir}"20171001.nc
cdo selday,1,2 "${data_dir}"alpha_output_201711.nc "${data_dir}"20171101.nc
cdo selday,1,2,3 "${data_dir}"alpha_output_201712.nc "${data_dir}"20171201.nc
cdo selday,1,2 "${data_dir}"alpha_output_201801.nc "${data_dir}"20180101.nc
cdo selday,1,2 "${data_dir}"alpha_output_201802.nc "${data_dir}"20180201.nc
cdo selday,1,2,3,4,5 "${data_dir}"alpha_output_201803.nc "${data_dir}"20180301.nc
cdo selday,1,2,3,4 "${data_dir}"alpha_output_201804.nc "${data_dir}"20180401.nc
cdo selday,1,2,3,4,5 "${data_dir}"alpha_output_201805.nc "${data_dir}"20180501.nc
cdo selday,1,2,3,4 "${data_dir}"alpha_output_201806.nc "${data_dir}"20180601.nc

cdo selday,1,2,3,4,5 "${data_dir}"alpha_output_201807.nc "${data_dir}"20180701.nc
cdo selday,1,2,3,4,5 "${data_dir}"alpha_output_201808.nc "${data_dir}"20180801.nc
cdo selday,1,2 "${data_dir}"alpha_output_201809.nc "${data_dir}"20180901.nc
cdo selday,1,2,3 "${data_dir}"alpha_output_201810.nc "${data_dir}"20181001.nc
cdo selday,1,2 "${data_dir}"alpha_output_201811.nc "${data_dir}"20181101.nc
cdo selday,1,2,3 "${data_dir}"alpha_output_201812.nc "${data_dir}"20181201.nc
cdo selday,1,2 "${data_dir}"alpha_output_201901.nc "${data_dir}"20190101.nc
cdo selday,1,2 "${data_dir}"alpha_output_201902.nc "${data_dir}"20190201.nc
cdo selday,1,2,3,4,5 "${data_dir}"alpha_output_201903.nc "${data_dir}"20190301.nc
cdo selday,1,2,3,4 "${data_dir}"alpha_output_201904.nc "${data_dir}"20190401.nc
cdo selday,1,2,3,4,5 "${data_dir}"alpha_output_201905.nc "${data_dir}"20190501.nc
cdo selday,1,2,3,4 "${data_dir}"alpha_output_201906.nc "${data_dir}"20190601.nc

cdo selday,1,2,3,4,5 "${data_dir}"alpha_output_201907.nc "${data_dir}"20190701.nc
cdo selday,1,2,3,4,5 "${data_dir}"alpha_output_201908.nc "${data_dir}"20190801.nc
cdo selday,1,2 "${data_dir}"alpha_output_201909.nc "${data_dir}"20190901.nc
cdo selday,1,2,3 "${data_dir}"alpha_output_201910.nc "${data_dir}"20191001.nc
cdo selday,1,2 "${data_dir}"alpha_output_201911.nc "${data_dir}"20191101.nc
cdo selday,1,2,3 "${data_dir}"alpha_output_201912.nc "${data_dir}"20191201.nc
cdo selday,1,2 "${data_dir}"alpha_output_202001.nc "${data_dir}"20200101.nc
cdo selday,1,2 "${data_dir}"alpha_output_202002.nc "${data_dir}"20200201.nc
cdo selday,1,2,3,4,5 "${data_dir}"alpha_output_202003.nc "${data_dir}"20200301.nc
cdo selday,1,2,3,4 "${data_dir}"alpha_output_202004.nc "${data_dir}"20200401.nc
cdo selday,1,2,3,4,5 "${data_dir}"alpha_output_202005.nc "${data_dir}"20200501.nc
cdo selday,1,2,3,4 "${data_dir}"alpha_output_202006.nc "${data_dir}"20200601.nc

cdo selday,1,2,3,4,5 "${data_dir}"alpha_output_202007.nc "${data_dir}"20200701.nc
cdo selday,1,2,3,4,5 "${data_dir}"alpha_output_202008.nc "${data_dir}"20200801.nc
cdo selday,1,2 "${data_dir}"alpha_output_202009.nc "${data_dir}"20200901.nc
cdo selday,1,2,3 "${data_dir}"alpha_output_202010.nc "${data_dir}"20201001.nc
cdo selday,1,2 "${data_dir}"alpha_output_202011.nc "${data_dir}"20201101.nc
cdo selday,1,2,3 "${data_dir}"alpha_output_202012.nc "${data_dir}"20201201.nc
cdo selday,1,2 "${data_dir}"alpha_output_202101.nc "${data_dir}"20210101.nc
cdo selday,1,2 "${data_dir}"alpha_output_202102.nc "${data_dir}"20210201.nc
cdo selday,1,2,3,4,5 "${data_dir}"alpha_output_202103.nc "${data_dir}"20210301.nc
cdo selday,1,2,3,4 "${data_dir}"alpha_output_202104.nc "${data_dir}"20210401.nc
cdo selday,1,2,3,4,5 "${data_dir}"alpha_output_202105.nc "${data_dir}"20210501.nc
cdo selday,1,2,3,4 "${data_dir}"alpha_output_202106.nc "${data_dir}"20210601.nc

cdo selday,1,2,3,4,5 "${data_dir}"alpha_output_202107.nc "${data_dir}"20210701.nc
cdo selday,1,2,3,4,5 "${data_dir}"alpha_output_202108.nc "${data_dir}"20210801.nc
cdo selday,1,2 "${data_dir}"alpha_output_202109.nc "${data_dir}"20210901.nc
cdo selday,1,2,3 "${data_dir}"alpha_output_202110.nc "${data_dir}"20211001.nc
cdo selday,1,2 "${data_dir}"alpha_output_202111.nc "${data_dir}"20211101.nc
cdo selday,1,2,3 "${data_dir}"alpha_output_202112.nc "${data_dir}"20211201.nc
cdo selday,1,2 "${data_dir}"alpha_output_202201.nc "${data_dir}"20220101.nc
cdo selday,1,2 "${data_dir}"alpha_output_202202.nc "${data_dir}"20220201.nc
cdo selday,1,2,3,4,5 "${data_dir}"alpha_output_202203.nc "${data_dir}"20220301.nc
cdo selday,1,2,3,4 "${data_dir}"alpha_output_202204.nc "${data_dir}"20220401.nc
cdo selday,1,2,3,4,5 "${data_dir}"alpha_output_202205.nc "${data_dir}"20220501.nc
cdo selday,1,2,3,4 "${data_dir}"alpha_output_202206.nc "${data_dir}"20220601.nc

cdo selday,1,2,3,4,5 "${data_dir}"alpha_output_202207.nc "${data_dir}"20220701.nc
cdo selday,1,2,3,4,5 "${data_dir}"alpha_output_202208.nc "${data_dir}"20220801.nc
cdo selday,1,2 "${data_dir}"alpha_output_202209.nc "${data_dir}"20220901.nc
cdo selday,1,2,3 "${data_dir}"alpha_output_202210.nc "${data_dir}"20221001.nc
cdo selday,1,2 "${data_dir}"alpha_output_202211.nc "${data_dir}"20221101.nc
cdo selday,1,2,3 "${data_dir}"alpha_output_202212.nc "${data_dir}"20221201.nc
cdo selday,1,2 "${data_dir}"alpha_output_202301.nc "${data_dir}"20230101.nc
cdo selday,1,2 "${data_dir}"alpha_output_202302.nc "${data_dir}"20230201.nc
cdo selday,1,2,3,4,5 "${data_dir}"alpha_output_202303.nc "${data_dir}"20230301.nc
cdo selday,1,2,3,4 "${data_dir}"alpha_output_202304.nc "${data_dir}"20230401.nc
cdo selday,1,2,3,4,5 "${data_dir}"alpha_output_202305.nc "${data_dir}"20230501.nc
cdo selday,1,2,3,4 "${data_dir}"alpha_output_202306.nc "${data_dir}"20230601.nc

