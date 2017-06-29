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
#          output file include production and area for all crops. 
#
# Developed by: D. Yang and L. Ran
# UNC Institute for the Environment
#
# Date: 09/30/2015
###################################################################

set BASE=/nas01/depts/ie/cempd/EPIC/epic/scenarios
echo $BASE


#set EPIC output type: spinup or app
setenv TYPE  spinup

#set SCEN = "base_2002_HG_TD_MG_372"
#set SCEN = "base_2022_HI_HG_TD_MG_413_0acres_grass"
#set SCEN = "FML_2022_HI_HG_TD_MG_413_0acres_grass"
foreach SCEN ("FML_2022_HI_HG_TD_MG_413_0acres_grass" "base_2022_HI_HG_TD_MG_413_0acres_grass"  "base_2002_HG_TD_MG_372_0acres_grass" ) 

#setenv INDIR   ${BASE}/${SCEN}/output4CMAQ/${TYPE}_old1/toCMAQ
setenv INDIR   ${BASE}/${SCEN}/output4CMAQ/${TYPE}/toCMAQ

setenv SHAREDIR   ${BASE}/${SCEN}/share_data

setenv  YEARFILE   ${INDIR}/epic2cmaq_year.nc
setenv  SITEFILE   ${SHAREDIR}/EPICSites_Info.csv
setenv  BELDFILE   ${SHAREDIR}/beld4_CMAQ12km_2001.nc
if ( SCEN == "FML_2022_HI_HG_TD_MG_413_0acres_grass" ) then
  setenv  BELDFILE   ${SHAREDIR}/beld4_camq12km_2002_2011v.nc
endif 

#VAR-LIST = "GMN NMN NFIX  NITR AVOL DN YON QNO3 SSFN PRKN FNO FNO3 FNH3 OCPD 
#            TOC TNO3 DN2 YLDG T_YLDG YLDF T_YLDF YLN YLP FTN FTP IRGA WS
#            NS IPLD  IGMD IHVD  "  # variables in epic2cmaq_year.nc

# set variables to be included in computation
foreach spc ( QAP OCPD YLDG YLDF MUSL YW ) #FPL FPO MNP DRNP YLP QAP PRKP YP   PRKN QNO3 SSFN DRNN YLN AVOL YON )
#foreach spc ( FNO3 FNO FNH3 NFIX GMN NMN ) #T_YLDG T_YLDF ) #3N FNO3 YLN FNO FNH3 3N YLN NFIX TOC FNO FNO3 FNH3 T_YLDG T_YLDF )

# set regions to be used in summary any of "FIPS HUC8 REG10"
foreach reg ( HUC2 ) #items: HUC1 HUC2 STFIPS FIPS HUC8 REG10  
  setenv SPC  $spc
  setenv REG  $reg
  setenv OUTDIR  ./outputs_production/${TYPE}
  if ( ! -e $OUTDIR ) mkdir -p $OUTDIR

  # set crops in the summary
  # users can chose from "HAY", "ALFALFA", "OTHER_GRASS", "BARLEY", "EBEANS", "CORNG", 
  #             "CORNS", "COTTON", "OATS", "PEANUTS", "POTATOES", "RICE", "RYE", "SORGHUMG", 
  #             "SORGHUMS", "SOYBEANS", "SWHEAT", "WWHEAT", "OTHER_CROP", "CANOLA", "BEANS"

  #setenv CROPS  "ALFALFA BARLEY"

  setenv CROPS "ALL"

  # set output file
  setenv  OUTFILE   $OUTDIR/report_${SCEN}_${SPC}_${reg}_${TYPE}_area.csv
  setenv  OUTFILEb   $OUTDIR/report_${SCEN}_${SPC}_${reg}_${TYPE}_onlyarea.csv
  setenv  OUTFILEp   $OUTDIR/report_${SCEN}_${SPC}_${reg}_${TYPE}_onlyprod.csv

  echo "Run summary for " $SCEN  $TYPE  ${SPC}

  R CMD BATCH epic2cmaq_sum_year_mrb.R
end  #for spc
end  #for region
end  #for scen
