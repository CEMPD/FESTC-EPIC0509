#!/bin/csh -f
#**************************************************************************************
# Purpose:   repare N Deposition inputs for SWAT by summarizing met data,  
#           netcdf weather data under ${SHAREDIR}/ 
#           $COMMON_data/EPIC_model/dailyNDep_200? 
#
#
# Developed by: UNC Institute for the Environment
# Date: 10/30/2017
#
# Program: $EPIC_DIR/util/swat/epic2swat_extract_daily_ndep.R
#
#***************************************************************************************

#
# Set up runtime environment
#
setenv    EPIC_DIR  /proj/ie/proj/staff/dyang/festc/festc1.4/epic
setenv    SCEN_DIR  /proj/ie/proj/staff/dyang/festc/festc1.4/epic/scenarios/test_case
setenv    SHARE_DIR  /proj/ie/proj/staff/dyang/festc/festc1.4/epic/scenarios/test_case/share_data

# Get site infomation
setenv    SITE_FILE   ${SHARE_DIR}/EPICSites_Info.csv

# Define BELD4 input file
setenv DOMAIN_BELD4_NETCDF /proj/ie/proj/staff/dyang/festc/festc1.4/epic/scenarios/test_case/share_data/beld4_TESTGRIDS_2006.nc

# Location of deposition files 
setenv    NDEP_TYPE CMAQ
setenv    NDEP_FILE     /proj/ie/proj/staff/dyang/festc/festc1.4/epic/scenarios/test_case/share_data/site_weather_dep_20060101_to_20061231.nc
# output location
setenv OUTDIR   $SCEN_DIR/output4SWAT/NDEP/CMAQ
if ( ! -e $OUTDIR) mkdir -p $OUTDIR
if ( ! -e $OUTDIR/county ) mkdir -p $OUTDIR/county
if ( ! -e $OUTDIR/state ) mkdir -p $OUTDIR/state
if ( ! -e $OUTDIR/domain ) mkdir -p $OUTDIR/domain
if ( ! -e $OUTDIR/HUC8 ) mkdir -p $OUTDIR/HUC8
if ( ! -e $OUTDIR/HUC6 ) mkdir -p $OUTDIR/HUC6
if ( ! -e $OUTDIR/HUC2 ) mkdir -p $OUTDIR/HUC2

echo 'Extract daily depositon from yearly CMAQ or 2004/2008 averaged ndep: '/proj/ie/proj/staff/dyang/festc/festc1.4/epic/scenarios/test_case
R CMD BATCH --no-save --slave $EPIC_DIR/util/swat/epic2swat_extract_daily_ndepCMAQ.R ${SCEN_DIR}/scripts/epic2swat_extract_daily_ndepCMAQ.log

