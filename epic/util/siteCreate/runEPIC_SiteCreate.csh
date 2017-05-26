#!/bin/csh -f

#**************************************************************************************
# Purpose:  to run "Site File Creation" and "Delineation Soil, Site, and Crop Linkages"
#
# Written by the Institute for the Environment at UNC, Chapel Hill
# in support of the CMAS project, 2010
#
# Written by: Fortran by Benson, script by IE  
#
# Program: Site12kmGrid.exe, BELD4HUC8.exe
#          Needed environment variables included in the script file to run.
#
#***************************************************************************************
#
# Define environment variables
#
# from interface
setenv  EPIC_DIR  /nas01/depts/ie/cempd/EPIC/epic
setenv  SCEN_DIR  $EPIC_DIR/scenarios/test_terra

# Not from interface
setenv  EXE_DIR   $EPIC_DIR/util/siteCreate
setenv  WORK_DIR  $SCEN_DIR/work_dir
setenv  SHARE_DIR $SCEN_DIR/share_data
setenv  SIT_DIR   $SHARE_DIR/SIT  

#
#Set input varaibles
setenv INFILE1   "EPICSites_Info.csv"   
 
#Set output variables
if ( ! -e $SIT_DIR  ) mkdir -p $SIT_DIR  
if ( ! -e $WORK_DIR  ) mkdir -p $WORK_DIR

time $EXE_DIR/Site12kmGrid.exe


#  Delineation Soil, Site, and Crop Linkages

setenv INFILE2 "EPICSites_Crop.csv"

foreach crop ( "HAY" "ALFALFA" "OTHGRASS" "BARLEY" "EBEANS" "CORNG" "CORNS" "COTTON" "OATS" "PEANUTS" "POTATOES" "RICE" "RYE" "SORGHUMG" "SORGHUMS" "SOYBEANS" "SWHEAT" "WWHEAT" "OTHER" "CANOLA" "PEAS" )
    if ( ! -e $SCEN_DIR/$crop ) mkdir -p $SCEN_DIR/$crop
end


time $EXE_DIR/BELD4HUC8.exe

#echo "Site/Soil/Crop linkages run is completed. "

