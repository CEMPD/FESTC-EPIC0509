#!/bin/csh -f
#**************************************************************************************
# Purpose:   Prepare runoff inputs for SWAT by extracting 
#           EPIC daily output files  output4CMAQ/app/daily/*NCD 
#
#
# Developed by: UNC Institute for the Environment
# Date: 10/30/2018
#
# Program: $EPIC_DIR/util/swat/epic2swat_extract_daily_epic.R
#
#***************************************************************************************

#
# Set up runtime environment
#
setenv    EPIC_DIR  /proj/ie/proj/staff/dyang/festc/festc1.4/epic
setenv    SCEN_DIR  /proj/ie/proj/staff/dyang/festc/festc1.4/epic/scenarios/test_case
setenv    SHARE_DIR  /proj/ie/proj/staff/dyang/festc/festc1.4/epic/scenarios/test_case/share_data
setenv    SIM_YEAR  2006

# Get site infomation
setenv    SITE_FILE   ${SHARE_DIR}/EPICSites_Info.csv

# Define BELD4 input file, get crop fractions 
setenv DOMAIN_BELD4_NETCDF /proj/ie/proj/staff/dyang/festc/festc1.4/epic/scenarios/test_case/share_data/beld4_TESTGRIDS_2006.nc

# EPIC input location
setenv DAY_DIR   $SCEN_DIR/output4CMAQ/app/daily

# SWAT output location
setenv OUTDIR   $SCEN_DIR/output4SWAT/dailyEPIC
if ( ! -e $OUTDIR/county ) mkdir -p $OUTDIR/county
if ( ! -e $OUTDIR/state ) mkdir -p $OUTDIR/state
if ( ! -e $OUTDIR/domain ) mkdir -p $OUTDIR/domain
if ( ! -e $OUTDIR/HUC8 ) mkdir -p $OUTDIR/HUC8
if ( ! -e $OUTDIR/HUC6 ) mkdir -p $OUTDIR/HUC6
if ( ! -e $OUTDIR/HUC2 ) mkdir -p $OUTDIR/HUC2

setenv REGION HUC8

echo 'Run EPIC daily summary for swat: ' /proj/ie/proj/staff/dyang/festc/festc1.4/epic/scenarios/test_case
R CMD BATCH --no-save --slave $EPIC_DIR/util/swat/epic2swat_extract_dailyEPIC.R ${SCEN_DIR}/scripts/epic2swat_extract_dailyEPIC.log

