#!/bin/csh -f
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
setenv TYPE   spinup  # spinup   app

#set SCEN = "base_2002_HG_TD_MG_372"
set SCEN = "base_2022_HI_HG_TD_MG_413_0acres_grass"
#set SCEN = "FML_2022_HI_HG_TD_MG_413_0acres_grass"
#foreach SCEN ("base_2002_HG_TD_MG_372" ) 

setenv INDIR   ${BASE}/${SCEN}/output4CMAQ/${TYPE}/toCMAQ

setenv SHAREDIR   ${BASE}/${SCEN}/share_data

setenv  YEARFILE   ${INDIR}/epic2cmaq_year.nc
setenv  SITEFILE   ${SHAREDIR}/EPICSites_Info.csv
setenv  BELDFILE   ${SHAREDIR}/beld4_CMAQ12km_2001.nc

#VAR-LIST = "GMN NMN NFIX  NITR AVOL DN YON QNO3 SSFN PRKN FNO FNO3 FNH3 OCPD 
#            TOC TNO3 DN2 YLDG T_YLDG YLDF T_YLDF YLN YLP FTN FTP IRGA WS
#            NS IPLD  IGMD IHVD  "  # variables in epic2cmaq_year.nc

# set variables to be included in computation
#            1    2   3    4     5   6    7    8     9   10 
set spcs = "FNH3 FNO  FNO3 NFIX GMN  NMN  FPL  FPO  YLN YLP \ 
           PRKN  QNO3 SSFN YON  AVOL DN   DN2  DRNN PRCP IRGA \
           ET    Q    SSF  PRK  QDRN YLDG YLDF NDEP_crop NDEP_grid"

set units = " kg   kg   kg   kg   kg   kg   kg  kg   kg   kg \
              kg   kg   kg   kg   kg   kg   kg  kg_pha mmXha mmXha \
              mmXha mmXha mmXha mmXha mmXha ton ton kg kg "

# set regions to be used in summary any of "FIPS HUC8 REG10"
foreach reg ( GRIDID ) #items: HUC1 HUC2 STFIPS FIPS HUC8 REG10 GRIDID
  setenv SPC  $spc
  setenv REG  $reg
  setenv OUTDIR  ./outputs_$reg
  if ( ! -e $OUTDIR ) mkdir -p $OUTDIR

  # set crops in the summary
  # users can chose from "HAY", "ALFALFA", "OTHER_GRASS", "BARLEY", "EBEANS", "CORNG", 
  #             "CORNS", "COTTON", "OATS", "PEANUTS", "POTATOES", "RICE", "RYE", "SORGHUMG", 
  #             "SORGHUMS", "SOYBEANS", "SWHEAT", "WWHEAT", "OTHER_CROP", "CANOLA", "BEANS"

  #setenv CROPS  "ALFALFA BARLEY"

  setenv CROPS "ALL"

  # set output file
  setenv  OUTFILE   $OUTDIR/report_${SCEN}_${SPC}_${reg}_${TYPE}.csv

  echo "Run summary for " $SCEN  $TYPE  ${SPC}

  R CMD BATCH epic2cmaq_sum_year.R
end  #for region
