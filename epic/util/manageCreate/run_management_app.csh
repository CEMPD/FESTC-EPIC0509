#!/bin/csh -f

#**************************************************************************************
#  THIS PROGRAM GENERATES MANAGEMENT FILE FOR EPIC AT A 12 KM GRID LEVEL
#  FIRST IT READS AN EPIC SITE FILE LIST TO IDENTIFY THE LOCATION BY LATITUDE AND
#  LONGITUDE AS WELL AS 8-DIGIT HUC, COUNTY AND PRODUCTION REGION TO IDENTIFY THE
#  GIS DATA LINKAGES TO CREATE THE FILE AND TO LOCATE THE THE CLOSEST STATISTICAL 
#  WEATHER STATION DATA
#
# Written by: script by IE, UNC-Chapel Hill  
#
# Program: ManGenFERT.exe
#          Needed environment variables included in the script file to run.
#
#***************************************************************************************

# Define environment variables
#
setenv    EPIC_DIR   /nas01/depts/ie/cempd/EPIC/epic

# from Interface
setenv    SCEN_DIR   $EPIC_DIR/scenarios/EPIC_112012_su_test4
setenv    EXE_DIR    $EPIC_DIR/util/manageCreate

#put real crop num
set       CROPS = ( POTATOES )
set       CROPSNUM = ( 21 22 )       #set rainfed and irrigated crop number for each crop

# Not from interface
setenv    COMM_DIR  $EPIC_DIR/common_data
setenv    SOIL_DIR  $EPIC_DIR/common_data/BaumerSoils
setenv    MANG_DIR  $EPIC_DIR/common_data/util/manageCreate
setenv    WEAT_DIR  $EPIC_DIR/common_data/statWeath

setenv EPIC_CMAQ_OUTPUT  $SCEN_DIR/output4CMAQ/spinup

@ n = 1
foreach crop ( $CROPS )

# echo $CROPSNUM[$n]
  setenv    CROP_NAME $crop
  setenv CROP_NUM_RF $CROPSNUM[$n]
  @ n = $n + 1
  setenv CROP_NUM_IR $CROPSNUM[$n]
  echo $CROP_NAME
  echo $CROP_NUM_RF
  echo $CROP_NUM_IR
  
  # set up output files
  if ( ! -e $SCEN_DIR/$CROP_NAME/app/manage/OPC )  mkdir -p $SCEN_DIR/$CROP_NAME/app/manage/OPC
  time  $EXE_DIR/ManGenFERT.exe
  @ n = $n + 1

  echo " ---- Completed management app run of CROP: "  $CROP_NAME

end
