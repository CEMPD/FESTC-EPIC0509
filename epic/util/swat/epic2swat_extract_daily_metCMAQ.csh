#!/bin/csh -f
#**************************************************************************************
# Purpose:   Prepare N Deposition and weather inputs for SWAT by summarizing  
#           netcdf weather data under ${SHAREDIR}/ 
#           $COMMON_data/EPIC_model/dailyNDep_200?/ 
#
#
# Developed by: UNC Institute for the Environment
# Date: 10/30/2017
#
# Program: $EPIC_DIR/util/swat/epic2swat_daily_depWETHnc.R
#
#***************************************************************************************

#
# Set up runtime environment
#
setenv    EPIC_DIR  /proj/ie/proj/staff/dyang/festc/festc1.4/epic
setenv    SCEN_DIR  /proj/ie/proj/staff/dyang/festc/festc1.4/epic/scenarios/test_case
setenv    SHARE_DIR  /proj/ie/proj/staff/dyang/festc/festc1.4/epic/scenarios/test_case/share_data

# Get site infomation
setenv    SITE_FILE   ${SHARE_DIR}/allSites_Info.csv

# Define BELD4 input file, get crop fractions 
setenv DOMAIN_BELD4_NETCDF /proj/ie/proj/staff/dyang/festc/festc1.4/epic/scenarios/test_case/share_data/beld4_TESTGRIDS_2006.nc

# met yearly file location
setenv    NDEP_TYPE CMAQ
setenv    DEPMET_FILE  /proj/ie/proj/staff/dyang/festc/festc1.4/epic/scenarios/test_case/share_data/site_weather_dep_20060101_to_20061231.nc

# output location
setenv OUTDIR   $SCEN_DIR/output4SWAT/dailyWETH/CMAQ
if ( ! -e $OUTDIR) mkdir -p $OUTDIR
if ( ! -e $OUTDIR/county ) mkdir -p $OUTDIR/county
if ( ! -e $OUTDIR/state ) mkdir -p $OUTDIR/state
if ( ! -e $OUTDIR/domain ) mkdir -p $OUTDIR/domain
if ( ! -e $OUTDIR/HUC8 ) mkdir -p $OUTDIR/HUC8
if ( ! -e $OUTDIR/HUC6 ) mkdir -p $OUTDIR/HUC6
if ( ! -e $OUTDIR/HUC2 ) mkdir -p $OUTDIR/HUC2

setenv REGION HUC8

echo 'Extract daily met/dep for SWAT from ' /proj/ie/proj/staff/dyang/festc/festc1.4/epic/scenarios/test_case
R CMD BATCH --no-save --slave $EPIC_DIR/util/swat/epic2swat_extract_daily_metCMAQ.R ${SCEN_DIR}/scripts/epic2swat_extract_daily_metCMAQ.log

