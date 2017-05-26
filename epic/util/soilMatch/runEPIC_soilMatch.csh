#!/bin/csh -f
#**************************************************************************************
# Purpose:  to run EPIC model
#
#
# Written by the Institute for the Environment at UNC, Chapel Hill
# in support of the CMAS project, 2010
#
# Written by: Fortran by Benson, script by IE  
#
# Program: Site12kmGrid.exe
#          Needed environment variables included in the script file to run.
#
#***************************************************************************************

#
# Define environment variables
#
# from interface
setenv  EPIC_DIR  /nas01/depts/ie/cempd/EPIC/epic
setenv  SCEN_DIR  $EPIC_DIR/scenarios/EPIC_112012_su_test4
#set  CROPS = "POTATOES CORNG"
#set  CROPS = "RICE"
set  CROPS = "RYE"

# Not from interface
setenv COMM_DIR $EPIC_DIR/common_data
setenv  EXE_DIR   $EPIC_DIR/util/soilMatch
setenv  WORK_DIR  $SCEN_DIR/work_dir
setenv  SHARE_DIR  $SCEN_DIR/share_data

foreach crop ($CROPS )

setenv CROP_NAME $crop

echo " ==== Running step 1 .... "
time $EXE_DIR/SOILMATCH12km1ST.exe
echo " ==== Completed step 1 !"   

# Run second step
echo " ==== Running step 2 .... "
time $EXE_DIR/SOILMATCH12km2ND.exe
echo " ==== Completed step 2 !"   

# Run third step
echo " ==== Running step 3 .... "
time $EXE_DIR/SOILMATCH12km3RD.exe
echo " ==== Completed step 3 !"   

# Run forth step
echo " ==== Running step 4 .... "
time $EXE_DIR/SOILMATCH12km4TH.exe
echo " ==== Completed step 4 !"   

# Run five step
echo " ==== Running step 5 .... "
time $EXE_DIR/SOILMATCH12km5TH.exe
echo " ==== Completed step 5 !"   

# Run six step
echo " ==== Running step 6 .... "
time $EXE_DIR/SOILMATCH12km6TH.exe
echo " ==== Completed step 6 !"   
 
echo " Merging *LOC to SOILLIST.DAT"
cat $SCEN_DIR/$CROP_NAME/*LOC > $SCEN_DIR/$CROP_NAME/SOILLIST.DAT

end
