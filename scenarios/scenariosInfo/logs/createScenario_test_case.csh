#!/bin/csh -f
#**************************************************************************************
# Purpose:  to copy all files from an existing scenario
#
#
# Written by the Institute for the Environment at UNC, Chapel Hill
# in support of the CMAS project, 2010
#
#
#***************************************************************************************

setenv EPIC_DIR   /proj/ie/proj/EPIC/FESTCv1.3_Test/festc1_3/epic
setenv SCEN_DIR   /proj/ie/proj/EPIC/FESTCv1.3_Test/festc1_3/scenarios/test_case
setenv COMM_DIR   /proj/ie/proj/EPIC/FESTCv1.3_Test/festc1_3/epic/common_data

# mkdir case dirs   
mkdir -p  $SCEN_DIR/share_data
mkdir -p  $SCEN_DIR/scripts
mkdir -p  $SCEN_DIR/work_dir
cp $COMM_DIR/EPIC_model/app/EPICCONT.DAT $SCEN_DIR/share_data/.
sed -i '1s/^.\{,8\}/   22005/' $SCEN_DIR/share_data/EPICCONT.DAT
