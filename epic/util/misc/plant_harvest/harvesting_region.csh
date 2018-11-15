#!/bin/csh -f
#
###################################################################
# Purpose: Calculate summary total by regions, 
#          crops, and selected variables from the extracted
#          yearly EPIC output file:
#          output4CMAQ/spinup or app/toCMAQ/epic2cmaq_year.nc
#          output file include production and area for all crops. 
#
# Developed by: ELlen Cooter and L. Ran
# US EPA
#
# Date: 20170819
###################################################################

set YEAR = 2002
#set YEAR = 2006
#set YEAR = 2012

set BASEDIR = /proj/ie/proj/EPIC/epic/scenarios
echo $BASEDIR

set WORKDIR = $cwd
echo $WORKDIR

#set EPIC output type: spinup or app
setenv TYPE  app


set SCEN = "US12KM_2001NLCD_2002"
#set SCEN = "US12KM_2006NLCD_2006"
#set SCEN = "US12KM_2011NLCD_2011NASS_2011"
#set SCEN = "US12KM_2011NLCD_2011NASS_2012"

setenv  NASSIN $WORKDIR/USDA_Plant_Harvest_${YEAR}.csv

setenv  epicFile  $BASEDIR/$SCEN/output4CMAQ/$TYPE/toCMAQ/epic2cmaq_year.nc

setenv  siteFile  $BASEDIR/$SCEN/share_data/EPICSites_Info.csv

setenv  beld4File $BASEDIR/$SCEN/share_data/beld4_camq12km_2002_2011v.nc
#setenv  beld4File $BASEDIR/$SCEN/share_data/beld4_camq12km_2006_2011v.nc
#setenv  beld4File $BASEDIR/$SCEN/share_data/beld4_camq12km_2011_2011v.nc
#setenv  beld4File $BASEDIR/$SCEN/share_data/beld4_CMAQ12km_2011.nc

setenv  OUTFILE  $WORKDIR/output_region/${YEAR}_harvesting_region.pdf
if ( ! -e $WORKDIR/output_region )   mkdir -p $WORKDIR/output_region 

  echo "Plotting for " $SCEN  $TYPE  ${YEAR}

  R CMD BATCH  harvesting_plots_region.r
