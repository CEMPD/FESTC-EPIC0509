#!/bin/csh -f
#BSUB -P  EPIC
#BSUB -R  mem96 -M 40
#BSUB -oo swat_daily.log
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


#set EPIC output type: spinup or app
setenv TYPE    app

#foreach SCEN ("FML_2022_HI_HG_TD_MG_413_0acres_grass") 
foreach SCEN ( "base_2002_HG_TD_MG_372_0acres_grass" ) #"base_2022_HI_HG_TD_MG_413_0acres_grass" "FML_2022_HI_HG_TD_MG_413_0acres_grass")

setenv CASE    $SCEN
setenv DAYDIR   ${BASE}/${SCEN}/output4CMAQ/$TYPE/daily 

setenv SHAREDIR   ${BASE}/${SCEN}/share_data

setenv OUTDIR  "./outputs_nc"
if ( ! -e $OUTDIR ) mkdir -p $OUTDIR

setenv  SITEFILE   ${SHAREDIR}/EPICSites_Info.csv
setenv  BELDFILE   ${SHAREDIR}/beld4_camq12km_2022_2011v.nc
#setenv   METFILE   ${SHAREDIR}/site_weather_dep_20020101_to_20021231.nc
setenv   METFILE   ./site_weather_dep_20020101_to_20021231.nc


# set regions to be used in summary any of "FIPS HUC8 REG10"

  # set crops in the summary
  # NCD file: Y,M,D,PRCP,QNO3,SSFN,PRKN,DN,DN2,AVOL,HMN,NFIX,MUSL,
  #           YP,QAP,YON,YW,Q,HUSC

  setenv CROPS "ALL"
  #setenv CROPS "BARLEY"
  #setenv CROPS "OTHER_GRASS"

  # set output file
  #setenv  OUTFILE   $OUTDIR/swat_daily_${SCEN}_${TYPE}
  setenv  OUTFILE   $OUTDIR/${CASE}_${TYPE}_ncd_swat_20020101_to_20021231.csv

  echo "Run daily for " ${SCEN}
  #cp $METFILE $OUTFILE
  R CMD BATCH epic2cmaq_addNCD_toDailyWETH.R

end  #for scen
