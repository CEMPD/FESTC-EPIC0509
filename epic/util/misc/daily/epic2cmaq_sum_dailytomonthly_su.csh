#!/bin/csh -fx
#BSUB -J daily2mon
#BSUB -o daily2month_su.log
#BSUB -P EPIC
#BSUB -q day
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
setenv TYPE   spinup     # spinup   app

#set SCEN = "base_2002_HG_TD_MG_372"
#set SCEN = "base_2022_HI_HG_TD_MG_413_0acres_grass"
#set SCEN = "FML_2022_HI_HG_TD_MG_413_0acres_grass"
foreach SCEN ( "FML_2022_HI_HG_TD_MG_413_0acres_grass" )
#foreach SCEN ( "base_2002_HG_TD_MG_372_0acres_grass"   "base_2022_HI_HG_TD_MG_413_0acres_grass" ) #"FML_2022_HI_HG_TD_MG_413_0acres_grass" )

setenv  INDIR      ${BASE}/${SCEN}/output4CMAQ/${TYPE}/toCMAQ
setenv  SHAREDIR   ${BASE}/${SCEN}/share_data
setenv  SITEFILE   ${BASE}/${SCEN}/share_data/EPICSites_Info.csv
setenv  BELDFILE   ${SHAREDIR}/beld4_CMAQ12km_2001.nc

#VAR-LIST = "GMN NMN NFIX  NITR AVOL DN YON QNO3 SSFN PRKN FNO FNO3 FNH3 OCPD 
#            TOC TNO3 DN2 YLDG T_YLDG YLDF T_YLDF YLN YLP FTN FTP IRGA WS
#            NS IPLD  IGMD IHVD  "  # variables in epic2cmaq_year.nc

# set variables to be included in computation

# set regions to be used in summary any of "FIPS HUC8 REG10"
if ( $SCEN == "base_2002_HG_TD_MG_372_0acres_grass") then
  if ($TYPE == "app") then
    setenv PATTERN  "base_372_0acre_TD_grass__time"    # for base_2002_HG_TD_MG_372_0acres_grass
  else 
    setenv PATTERN  "base_372_0acre_TD_grass_su__time" # for base_2002_HG_TD_MG_372_0acres_grass
  endif
endif
if ( $SCEN == "base_2022_HI_HG_TD_MG_413_0acres_grass" ) then
  if ($TYPE == "app") then
    setenv PATTERN  "base2022epic_time"    # for base_2002_HG_TD_MG_372_0acres_grass
  else 
    setenv PATTERN  "base2022epic_time" # for base_2002_HG_TD_MG_372_0acres_grass
  endif
endif
if ( $SCEN == "FML_2022_HI_HG_TD_MG_413_0acres_grass" ) then
  if ($TYPE == "app") then
    setenv PATTERN  "FML2022_epic_time"    # for base_2002_HG_TD_MG_372_0acres_grass
  else
    setenv PATTERN  "FML2022_epic_spinup_time" # for base_2002_HG_TD_MG_372_0acres_grass
  endif
endif

#setenv PATTERN   'base2022epic_time'              # for base_2022_HI_HG_TD_MG_413_0acres_grass
#setenv PATTERN   'base2022epic_spinup__time'      # for base_2022_HI_HG_TD_MG_413_0acres_grass
#setenv PATTERN   'base_2002_372_time'    # for base_2002_HG_TD_MG_372
#setenv PATTERN   'FML2022epic_time'    # for base_2002_HG_TD_MG_372

foreach reg ( HUC2 ) #items: HUC1 HUC2 STFIPS FIPS HUC8 REG10  
  setenv REG  $reg
  setenv OUTDIR  ./outputs_$reg/$TYPE
  if ( ! -e $OUTDIR ) mkdir -p $OUTDIR

  # set crops in the summary
  # users can chose from "HAY", "ALFALFA", "OTHER_GRASS", "BARLEY", "EBEANS", "CORNG", 
  #             "CORNS", "COTTON", "OATS", "PEANUTS", "POTATOES", "RICE", "RYE", "SORGHUMG", 
  #             "SORGHUMS", "SOYBEANS", "SWHEAT", "WWHEAT", "OTHER_CROP", "CANOLA", "BEANS"

  #setenv CROPS  "ALFALFA BARLEY"

  setenv CROPS "ALL"

  # set output file
  setenv  OUTFILE   $OUTDIR/report_${SCEN}_${reg}_${TYPE}

  echo "Run summary for " $SCEN  $TYPE  

  R CMD BATCH --no-save --slave epic2cmaq_sum_dailytomonthly.R $OUTDIR/report_${SCEN}_${reg}_${TYPE}.log

end  #for region
end  #for scen
