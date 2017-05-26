#!/bin/csh -f
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

foreach SCEN ("base_2002_HG_TD_MG_372") #  "base_2022_HI_HG_TD_MG_413_0acres_grass" "FML_2022_HI_HG_TD_MG_413_0acres_grass")

setenv YEARDIR   ${BASE}/${SCEN}/output4CMAQ/${TYPE}_old1/toCMAQ
setenv DAYDIR   ${BASE}/${SCEN}/output4CMAQ/$TYPE/daily 

setenv SHAREDIR   ${BASE}/${SCEN}/share_data

setenv OUTDIR  "./outputs_swat"
if ( ! -e $OUTDIR ) mkdir -p $OUTDIR

setenv  YEARFILE   ${YEARDIR}/epic2cmaq_year.nc
setenv  SITEFILE   ${SHAREDIR}/EPICSites_Info.csv
setenv  BELDFILE   ${SHAREDIR}/beld4_CMAQ12km_2001.nc


# set regions to be used in summary any of "FIPS HUC8 REG10"
#foreach reg ( HUC8 ) #items: HUC1 HUC2 STFIPS FIPS HUC8 REG10  
# setenv REG  $reg

  # set crops in the summary
  # NCD file: Y,M,D,PRCP,QNO3,SSFN,PRKN,DN,DN2,AVOL,HMN,NFIX,MUSL,
  #           YP,QAP,YON,YW,Q,HUSC

  #setenv CROPS  "CANOLA BEANS"

  setenv CROPS "ALL"

  # set output file
  #setenv  OUTFILE   $OUTDIR/swat_daily_${SCEN}_${TYPE}
  setenv  OUTFILE   $OUTDIR/HUC8_

  echo "Run daily for " ${SCEN}

  R CMD BATCH epic2cmaq_sum_byday_swat.R
#end  #for region
end  #for scen
