#!/bin/csh -f
#BSUB -P EPIC
#BSUB -J year_summary
#BSUB -oo LOGS/run.cctm.waqs04_b25a_11b_P3.%J.qlog
#
###################################################################
# Purpose: Calculate summary total by regions, 
#          crops, and selected variables from the extracted
#          yearly EPIC output file:
#          output4CMAQ/spinup or app/toCMAQ/epic2cmaq_year.nc
#
# Developed by: D. Yang and L. Ran
# UNC Institute for the Environment
#
# Date: 09/30/2015
###################################################################

set BASE=/nas01/depts/ie/cempd/EPIC/epic/scenarios
echo $BASE


#set EPIC output type: spinup or app

#set SCEN = "base_2002_HG_TD_MG_372"
#set SCEN = "base_2022_HI_HG_TD_MG_413_0acres_grass"
#set SCEN = "FML_2022_HI_HG_TD_MG_413_0acres_grass"
#foreach SCEN ("FML_2022_HI_HG_TD_MG_413_0acres_grass")
foreach SCEN ("base_2002_HG_TD_MG_372_0acres_grass" ) # "base_2022_HI_HG_TD_MG_413_0acres_grass" ) 


setenv SHAREDIR   ${BASE}/${SCEN}/share_data

setenv  SITEFILE   ${SHAREDIR}/EPICSites_Info.csv
setenv  BELDFILE   ${SHAREDIR}/beld4_CMAQ12km_2001.nc
#setenv  BELDFILE   ${SHAREDIR}/beld4_camq12km_2022_2011v.nc


# set regions to be used in summary any of "FIPS HUC8 REG10"
foreach reg ( HUC8 ) #HUC2 ) #items: HUC1 HUC2 STFIPS FIPS HUC8 REG10  
  setenv REG  $reg
  setenv OUTDIR  ./outputs_${reg}
  if ( ! -e $OUTDIR ) mkdir -p $OUTDIR

  # users can chose from "HAY", "ALFALFA", "OTHER_GRASS", "BARLEY", "EBEANS", "CORNG", 
  #             "CORNS", "COTTON", "OATS", "PEANUTS", "POTATOES", "RICE", "RYE", "SORGHUMG", 
  #             "SORGHUMS", "SOYBEANS", "SWHEAT", "WWHEAT", "OTHER_CROP", "CANOLA", "BEANS"

  #setenv CROPS  "ALFALFA BARLEY"

  setenv CROPS "ALL"

  # set output file
  setenv  OUTFILE   $OUTDIR/report_${SCEN}_${reg}_area.csv
  echo "Run summary for " $SCEN 
  R CMD BATCH epic2cmaq_sum_croparea.R

end  #for region
end  #for scen
