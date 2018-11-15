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

#set YEAR = 2002
#set YEAR = 2006
#set YEAR = 2011
set YEAR = 2012

set BASEDIR = /66w/epic/lid/paper/yield
echo $BASEDIR

set WORKDIR = /66w/epic/lid/paper/plant_harvest
echo $WORKDIR

#set EPIC output type: spinup or app
setenv TYPE  app

#set SCEN = "US12KM_2001NLCD_2002"
#set SCEN = "US12KM_2006NLCD_2006"
#set SCEN = "US12KM_2011NLCD_2011NASS_2011"
set SCEN = "US12KM_2011NLCD_2011NASS_2012"


setenv  NASSIN $WORKDIR/USDA_Plant_Harvest_${YEAR}.csv

setenv  epicFile  $BASEDIR/$SCEN/$TYPE/epic2cmaq_year.nc

setenv  siteFile  $BASEDIR/$SCEN/EPICSites_Info.csv

#setenv  beld4File $BASEDIR/$SCEN/beld4_camq12km_2002_2011v.nc
#setenv  beld4File $BASEDIR/$SCEN/beld4_camq12km_2006_2011v.nc
#setenv  beld4File $BASEDIR/$SCEN/beld4_camq12km_2011_2011v.nc
setenv  beld4File $BASEDIR/$SCEN/beld4_CMAQ12km_2011.nc

setenv  OUTFILE  $WORKDIR/output/${YEAR}_planting.pdf


  echo "Plotting for " $SCEN  $TYPE  ${YEAR}

  /share/linux86_64/R-3.2.4/bin/R CMD BATCH  planting_plots.r
