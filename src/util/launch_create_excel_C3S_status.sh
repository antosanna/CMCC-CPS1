#!/bin/sh -l 
#BSUB -q s_short
#BSUB -J C3S_monitor
#BSUB -e logs/C3S_monitor%J.err
#BSUB -o logs/C3S_monitor%J.out
#BSUB -sla SC_SERIAL_sps35 
#BSUB -P 0490 

# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. $DIR_UTIL/load_cdo
. $DIR_UTIL/load_nco

set -euvx
st=11


#TOBEMODIFIED path="/users_home/csp/sp1/SPS/CMCC-${SPSSYS}/scratch/C3S_HC_status/"
#TOBEMODIFIED pathcineca="/data/delivery/csp/c3s/cineca/"
mkdir -p $path

cd $path

# Csv summary creation (for python)
set +vx
# A csvfile for startdate
for st in 10 11 12 01 02 03 04 05 06 07 08 09; do 
	echo "Checking startdate $st"
	fname=${path}"C3S_status_${st}.csv"
	fnamecineca=${pathcineca}"C3S_status_${st}.csv"

	# clean report file if exist
	if [[ $(ls -1 $path/C3S_status_${st}.csv | wc -l ) -gt 0 ]]; then
		rm $path/C3S_status_${st}.csv
	fi

	# if exist copy from cineca use it, otherwise create status file
	if [[ -f $fnamecineca ]]; then
		set -vx

		rsync -auv $fnamecineca $path
		set +vx

	else 
		echo "STARTDATE;FindSpikes_l;TemplCk_l;MetaCk_l;QualityCk_l;CLM_logs;CAM_logs;OCE_logs;CICE_logs;OK" >> $fname
		for year in {1993..2016};do
			startdate=$year$st
			fs=0
			tc=0
			mc=0
			qc=0
			clm=0
			cam=0
			oce=0
			ice=0
			OK=0

			for pp in {01..40};do
				caso=${SPSsystem}_${startdate}_0${pp}
				fs_cnt=0
				fs_cnt=$( ls -1 $DIR_ARCHIVE_C3S/$startdate/findspikes*ok_0${pp}   2>/dev/null | wc -l  ) 
				tc_cnt=$( ls -1 $DIR_ARCHIVE_C3S/$startdate/tmpl_checker_ok_0${pp} 2>/dev/null | wc -l  )
				mc_cnt=$( ls -1 $DIR_ARCHIVE_C3S/$startdate/meta_checker_ok_0${pp} 2>/dev/null | wc -l  )
				qc_cnt=$( ls -1 $DIR_ARCHIVE_C3S/$startdate/qa_checker_ok_0${pp}   2>/dev/null | wc -l  )
				clm_cnt=$(ls -1 $DIR_ARCHIVE_C3S/$startdate/${caso}_clm_C3SDONE    2>/dev/null | wc -l  )
				cam_cnt=$(ls -1 $DIR_ARCHIVE_C3S/$startdate/${caso}_cam_C3SDONE    2>/dev/null | wc -l  )
				oce_cnt=$(ls -1 $DIR_ARCHIVE_C3S/$startdate/interp_ORCA2_1X1_gridT2C3S.ncl_r${pp}i00p00_ok     2>/dev/null | wc -l  ) #interp_ORCA2_1X1_gridT2C3S.ncl_r40i00p00_ok
				ice_cnt=$(ls -1 $DIR_ARCHIVE_C3S/$startdate/interp_cice2C3S_through_nemo.ncl_r${pp}i00p00_ok   2>/dev/null | wc -l  ) #interp_cice2C3S_through_nemo.ncl_r40i00p00_ok


				fs=$((  $fs_cnt  + $fs  ))
				tc=$((  $tc_cnt  + $tc  ))
				mc=$((  $mc_cnt  + $mc  ))
				qc=$((  $qc_cnt  + $qc  ))
				clm=$(( $clm_cnt + $clm ))
				cam=$(( $cam_cnt + $cam ))
				oce=$(( $oce_cnt + $oce ))
				ice=$(( $ice_cnt + $ice ))

			done
			if [[ $fs -eq 40 ]] && [[ $tc -eq 40 ]] && [[ $mc -eq 40 ]] && [[ $qc -eq 40 ]] && [[ $clm -eq 40 ]] && [[ $cam -eq 40 ]] && [[ $oce -eq 40 ]] && [[ $ice -eq 40 ]];then
				OK=1
			fi
			#echo "STARTDATE FS TC MC QC CLM CAM"
			echo "${startdate};${fs};${tc};${mc};${qc};${clm};${cam};${oce};${ice};${OK}" >> $fname
		done
	fi # end cineca statement
done

set +euvx 
conda activate CDSAPI
set -euvx

# clean report xls file if exist
excelfile=SPS4_HC_C3S_status.xlsx
if [[ $(ls -1 $path/$excelfile | wc -l ) -gt 0 ]]; then
	rm $path/$excelfile
fi

python $DIR_UTIL/create_excel_C3S_status.py ${excelfile} -p ${path}/ -l ${DIR_LOG}/C3S_hindcast/



exit 0
