#!/bin/csh -fx

#**************************************************************************************
#  THIS PROGRAM GENERATES MANAGEMENT FILE FOR EPIC AT A 12 KM GRID LEVEL
#  FIRST IT READS AN EPIC SITE FILE LIST TO IDENTIFY THE LOCATION BY LATITUDE AND
#  LONGITUDE AS WELL AS 8-DIGIT HUC, COUNTY AND PRODUCTION REGION TO IDENTIFY THE
#  GIS DATA LINKAGES TO CREATE THE FILE AND TO LOCATE THE THE CLOSEST STATISTICAL 
#  WEATHER STATION DATA
#
# Written by: script by IE, UNC-Chapel Hill  
#
# Program: MANGENSU102312.exe
#          Needed environment variables included in the script file to run.
#
#***************************************************************************************

# Define environment variables
#
setenv    EPIC_DIR   /nas01/depts/ie/cempd/EPIC/epic

# from interface
setenv    SCEN_DIR   $EPIC_DIR/scenarios/EPIC_112012_su_test
setenv    EXE_DIR   $EPIC_DIR/util/manageCreate

#set       CROPS = "POTATOES CORNG"
set       CROPS = "POTATOES"

# Not from interface
setenv    SOIL_DIR  $EPIC_DIR/common_data/BaumerSoils
setenv    MANG_DIR  $EPIC_DIR/common_data/util/manageCreate
setenv    WEAT_DIR  $EPIC_DIR/common_data/statWeath

foreach crop ($CROPS )
  setenv    CROP_NAME $crop
  # set up output files
  if ( ! -e $SCEN_DIR/$CROP_NAME/spinup/manage/OPC )  mkdir -p $SCEN_DIR/$CROP_NAME/spinup/manage/OPC
  time  $EXE_DIR/ManGenSU.exe
end
