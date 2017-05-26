#!/bin/csh -f
#**************************************************************************************
# Purpose:  to run EPIC model
#
# Written by:  D. Yang JUly 2010
# Modified by:  DY, 12/2012 -01/2013
#            
#
# Program: Epic0509.exe or Epic0509_rf.exe
#         Needed environment variables included in the script file to run.
# 
#***************************************************************************************
#
# Define environment variables
#
#set       CROPS = ( POTATOES )
#set       CROPSNUM = ( 21 22 )    # rainf and irr, use 0 for no simulation, e.g. (0 22) -> run irrigated potato only
set       CROPS = ( HAY  RICE )
set       CROPSNUM = ( 1 2 0 24)

set type = 'spinup'

setenv EPIC_DIR     /nas01/depts/ie/cempd/EPIC/epic
setenv COMM_DIR   $EPIC_DIR/common_data
setenv SCEN_DIR   $EPIC_DIR/scenarios/EPIC_112012_su_test4
setenv EXE_DIR    $EPIC_DIR/model/current
setenv SOIL_DIR   $COMM_DIR/BaumerSoils
setenv WEAT_DIR   $COMM_DIR/statWeath
setenv SHARE_DIR  $SCEN_DIR/share_data

setenv EPIC_CMAQ_OUTPUT  $SCEN_DIR/output4CMAQ/$type
if ( ! -e $EPIC_CMAQ_OUTPUT  ) mkdir -p $EPIC_CMAQ_OUTPUT
if ( ! -e $EPIC_CMAQ_OUTPUT/5years  ) mkdir -p $EPIC_CMAQ_OUTPUT/5years
if ( ! -e $EPIC_CMAQ_OUTPUT/daily  ) mkdir -p $EPIC_CMAQ_OUTPUT/daily  
if ( ! -e $EPIC_CMAQ_OUTPUT/toCMAQ  ) mkdir -p $EPIC_CMAQ_OUTPUT/toCMAQ


#
# run EPIC model spinup - rainfed
#

@ n = 1
foreach crop ( $CROPS )

  setenv CROP_NAME $CROPS
  setenv CROP_NUM  $CROPSNUM[$n]

#
# Set output dir
#
  setenv CROP_DIR   $SCEN_DIR/${CROP_NAME}/

  echo $CROP_NAME, $CROP_NUM

  @ cropN = $CROP_NUM
 
  if ( $cropN != 0 )  then
    setenv WORK_DIR   $SCEN_DIR/${CROP_NAME}/$type/rainf

    foreach out ( "NCM" "NCS" "DFA" "OUT" "SOL" "TNA" "TNS" )
      if ( ! -e $WORK_DIR/$out  ) mkdir -p $WORK_DIR/$out
    end

    time $EXE_DIR/EPIC0509su.exe

  endif

#
# run EPIC model spinup - irrigated
#

  @ n = $n + 1
  setenv CROP_NUM $CROPSNUM[$n]

  echo $CROP_NAME, $CROP_NUM

  @ cropN = $CROP_NUM

  if ( $cropN != 0 )  then
     setenv WORK_DIR   $SCEN_DIR/${CROP_NAME}/$type/irr

     foreach out ( "NCM" "NCS" "DFA" "OUT" "SOL" "TNA" "TNS" )
       if ( ! -e $WORK_DIR/$out  ) mkdir -p $WORK_DIR/$out
     end

     time $EXE_DIR/EPIC0509su.exe

  endif

end

