#!/bin/sh -l 

# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh


set -eu
finaldir=/work/csp/cp1/scratch/ANTO/20240110_CPS1_modif

listafiles=" checklists/sps4_hindcast_IC_CAM_list.csv         checklists/sps4_hindcast_IC_NEMO_list.csv       checklists/sps4_hindcast_IC_NEMO_list.juno.csv development_tmp/ANTO/rename_nemo_C3S.sh       src/IC_CPS/IC_NEMO/launch_nemo_rebuild_restart.sh src/IC_CPS/IC_NEMO/nemo_rebuild_restart.sh       src/postproc/cam/regridFV_C3S.sh                src/postproc/clm/clm_standardize2c3s.py        src/postproc/clm/postpc_clm.sh               src/postproc/nemo/interp_ORCA2_1X1_gridT2C3S_template.sh   src/recover/recover_interrupted.sh               src/templates/C3S_globalatt.txt                 src/templates/SPS4_hindcast_production_list_template.xlsx src/templates/env_workflow_sps4.xml_cmcc      src/templates/postproc_C3S.sh                src/templates/template.lt_archive_moredays  src/util/CPS1_checkfile_dictionary.txt     src/util/SPS4_IC_CAM_checklist.sh         src/util/SPS4_IC_lists_send2drive.sh     src/util/condaactivation.sh             src/util/descr_CPS.sh                 src/util/load_miniconda              "
cd /users_home/csp/cp1/CPS/CMCC-CPS1
tar -cvf deleteme.tar $listafiles
mv deleteme.tar $finaldir
