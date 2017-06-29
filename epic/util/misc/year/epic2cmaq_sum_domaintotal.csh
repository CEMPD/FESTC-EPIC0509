#!/bin/csh -f
#
###################################################################
# Purpose: Calculate summary total for the domain by crops and 
#          selected variables from the extracted EPIC output file:
#          output4CMAQ/spinup or app/toCMAQ/epic2cmaq_year.nc
#
# Developed by: D. Yang and L.Ran
# UNC Institute for the Environment
#
# Date: 09/30/2015
###################################################################

set BASE=/nas01/depts/ie/cempd/EPIC/epic/scenarios/
echo $BASE

#set SCEN = "FML_2022_HI_HG_TD_MG_413_0acres_grass"
#set SCEN = "base_2002_HG_TD_MG_372_0acres_grass"
#set SCEN = "base_2022_HI_HG_TD_MG_372_0acres_grass"
set SCEN = "base_2022_HI_HG_TD_MG_413_0acres_grass"

#set EPIC output type: spinup or app
setenv TYPE    app   #spinup   

setenv INDIR   ${BASE}/${SCEN}/output4CMAQ/$TYPE/toCMAQ
setenv SHAREDIR   ${BASE}/${SCEN}/share_data

setenv OUTDIR  "./outputs_production"
if ( ! -e $OUTDIR ) mkdir -p $OUTDIR

setenv  YEARFILE   ${INDIR}/epic2cmaq_year.nc
setenv  SITEFILE   ${BASE}/${SCEN}/share_data/EPICSites_Info.csv
setenv  BELDFILE   ${BASE}/${SCEN}/share_data/beld4_CMAQ12km_2001.nc

#VAR-LIST = "GMN NMN NFIX  NITR AVOL DN YON QNO3 SSFN PRKN FNO FNO3 FNH3 OCPD
#            TOC TNO3 DN2 YLDG T_YLDG YLDF T_YLDF YLN YLP FTN FTP IRGA WS
#            NS IPLD  IGMD IHVD  "  # variables in epic2cmaq_year.nc

#foreach spc ( PRKN QNO3 SSFN DRNN YLN AVOL YON )
#foreach spc ( FNO3 FNO FNH3 NFIX GMN NMN )
foreach spc ( T_YLDG T_YLDF )

  setenv SPC  $spc

  # set crops in the summary
  # users can chose from "EBEANS OTHGRASS OTHER SWHEAT ALFALFA COTTON SORGHUMS
  #                       BARLEY SOYBEANS CORNS OATS CANOLA RICE SORGHUMG HAY
  #                       PEANUTS CORNG POTATOES WWHEAT RYE" or ALL

  #setenv CROPS  "ALFALFA BARLEY"

  setenv CROPS "ALL"   


  setenv  OUTFILE   $OUTDIR/domaintotal_${SCEN}_${SPC}_${TYPE}.csv
  echo "Run summary for " ${SPC}


  R CMD BATCH epic2cmaq_sum_domaintotal.R
end

