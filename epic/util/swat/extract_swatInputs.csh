#!/bin/csh -f
#**************************************************************************************
# Purpose:   Prepare swat inputs: dailyEPIC, NDEP, and weather
#
# Developed by: UNC Institute for the Environment
# Date: 10/30/2017
#
# Program: $EPIC_DIR/util/swat/extract_swatInputs.R
#
#***************************************************************************************

#
# Set up runtime environment
#
setenv    EPIC_DIR   /proj/ie/proj/staff/dyang/festc/festc1.4/epic
setenv    SCEN_DIR   /proj/ie/proj/staff/dyang/festc/festc1.4/epic/scenarios/test_case
setenv    SHARE_DIR  /proj/ie/proj/staff/dyang/festc/festc1.4/epic/scenarios/test_case/share_data

setenv    NDEP_TYPE  CMAQ
setenv    SIM_YEAR  2006

setenv    RUN_dailyEPIC  YES
setenv    RUN_MET   YES
setenv    RUN_NDEP  YES
# Get site infomation
setenv    SITE_FILE   ${SHARE_DIR}/AllSites_Info.csv

# Define ratio input file
setenv    RATIO_FILE  /proj/ie/proj/staff/dyang/festc/festc1.4/epic/common_data/util/swat/swat_inputs/subbasins-mapping_test_case.csv

# output location
setenv OUTDIR   $SCEN_DIR/output4SWAT
setenv SWAT_OUTDIR   $SCEN_DIR/output4SWAT/swat_inputs
if ( ! -e $OUTDIR) mkdir -p $OUTDIR
if ( ! -e $SWAT_OUTDIR ) mkdir -p $SWAT_OUTDIR
if ( ! -e $SWAT_OUTDIR/dailydep ) mkdir -p $SWAT_OUTDIR/dailydep
if ( ! -e $SWAT_OUTDIR/dailyweath ) mkdir -p $SWAT_OUTDIR/dailyweath
if ( ! -e $SWAT_OUTDIR/EPICinputPoint ) mkdir -p $SWAT_OUTDIR/EPICinputPoint
echo  'Extract swat inputs:  ' $SCEN_DIR
R CMD BATCH --no-save --slave $EPIC_DIR/util/swat/extract_swatInputs.R ${SCEN_DIR}/scripts/extract_swatInputs_CMAQ.log

