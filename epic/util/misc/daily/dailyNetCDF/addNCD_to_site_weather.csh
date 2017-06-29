#!/bin/csh -f
#BSUB -P  EPIC
#BSUB -R  mem96 -M 40
#BSUB -oo ncd_daily.log
##BSUB -q week
#
###################################################################
# Purpose: Transfer EPIC *NCD file to netcdf format
#          output4CMAQ/spinup or app/year/*NCD
#
# Developed by: D. Yang and L. Ran
# UNC Institute for the Environment
#
# Date: 09/30/2015
###################################################################

set BASE=/nas01/depts/ie/cempd/EPIC/epic/scenarios
echo $BASE


#set EPIC output type: spinup or app
setenv TYPE    app

#foreach SCEN ("FML_2022_HI_HG_TD_MG_413_0acres_grass") 
foreach SCEN ( "base_2002_HG_TD_MG_372_0acres_grass" ) #"base_2022_HI_HG_TD_MG_413_0acres_grass" "FML_2022_HI_HG_TD_MG_413_0acres_grass")

setenv CASE    $SCEN
setenv DAYDIR   ${BASE}/${SCEN}/output4CMAQ/$TYPE/daily 

setenv SHAREDIR   ${BASE}/${SCEN}/share_data

setenv OUTDIR  "./outputs_nc"
if ( ! -e $OUTDIR ) mkdir -p $OUTDIR

  setenv   METFILE   ../site_weather_dep_20020101_to_20021231.nc
  setenv   INPFILE   $OUTDIR/${CASE}_${TYPE}_ncd_bygrids_20020101_to_20021231.csv
  setenv   OUTFILE   $OUTDIR/${CASE}_${TYPE}_ncd_bygrids_20020101_to_20021231.ncf

  echo "Run daily for " ${SCEN}
  if ( -e $OUTFILE ) rm -f $OUTFILE
  ./csv2ioapi.exe

end  #for scen
