#!/bin/csh -f
#**************************************************************************************
# Purpose:  to copy all files from an existing scenario
#
#
# Written by the Institute for the Environment at UNC, Chapel Hill
# in support of the CMAS project, 2010
#
#
setenv EPIC_DIR   /nas01/depts/ie/cempd/apps/sallocator/festc1_2/epic
setenv SCEN_DIR   /nas01/depts/ie/cempd/apps/sallocator/festc1_2/epic/scenarios/temp
setenv COMM_DIR   /nas01/depts/ie/cempd/apps/sallocator/festc1_2/epic/common_data

#***************************************************************************************

cp -R /nas01/depts/ie/cempd/apps/sallocator/festc1_2/epic/scenarios/test_case /nas01/depts/ie/cempd/apps/sallocator/festc1_2/epic/scenarios/temp
sed -i '1s/^.\{,8\}/   22001/' $SCEN_DIR/share_data/EPICCONT.DAT
