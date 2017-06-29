#!/bin/csh -f
#BSUB -P  EPIC
#BSUB -R  mem96 -M 40
#BSUB -oo tmean_dept.log
#BSUB -q week
#
###################################################################
# Purpose: Prepare inputs for SWAT by summarized data by regions, 
#          from the extracted EPIC *NCD output file:
#          output4CMAQ/spinup or app/year/*NCD
#
# Developed by: D. Yang and L. Ran
# UNC Institute for the Environment
#
# Date: 09/30/2015
###################################################################

set BASE=/nas01/depts/ie/cempd/EPIC/epic/scenarios
echo $BASE


foreach SCEN ("FML_2022_HI_HG_TD_MG_413_0acres_grass") 

setenv CASE    $SCEN

setenv SHAREDIR   ${BASE}/${SCEN}/share_data

setenv OUTDIR  "./outputs_tmean"
if ( ! -e $OUTDIR ) mkdir -p $OUTDIR

setenv  SITEFILE   ${SHAREDIR}/EPICSites_Info.csv
setenv  BELDFILE   ${SHAREDIR}/beld4_camq12km_2022_2011v.nc
#setenv   METFILE   ${SHAREDIR}/site_weather_dep_20020101_to_20021231.nc
setenv   METFILE   ./site_weather_dep_20020101_to_20021231.nc


# set regions to be used in summary any of "FIPS HUC8 REG10"

  # set crops in the summary

  echo "Calculate Tmean " ${SCEN}
  setenv  OUTFILE   $OUTDIR/tmean_dept_20020101_to_20021231.csv
  #cp $METFILE $OUTFILE
  R CMD BATCH epic2cmaq_tmean.R

end  #for scen
