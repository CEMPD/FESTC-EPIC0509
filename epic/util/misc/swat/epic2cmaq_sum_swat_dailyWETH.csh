#!/bin/csh -f
#BSUB -P EPIC -R mem96 -M 40
#BSUB -J swat_dep
#BSUB -oo LOGS/run.swat_dailyW.%J.qlog
#BSUB -q week

#
###################################################################
# Purpose: Prepare N Deposition inputs for SWAT by summarizing daily, 
#          met data, ${SHAREDIR}/dailyWETH
#
# Developed by: D. Yang and L. Ran
# UNC Institute for the Environment
#
# Date: 09/30/2015
###################################################################

set BASE    = /nas01/depts/ie/cempd/EPIC/epic
set SCENBASE = $BASE/scenarios/base_2022_HI_HG_TD_MG_413_0acres_grass
set COMMDATA = /nas01/depts/ie/cempd/EPIC/epic/common_data/EPIC_model
echo $BASE


#set EPIC output type: spinup or app
#foreach SCEN ("base_2002_HG_TD_MG_372") #  "base_2022_HI_HG_TD_MG_413_0acres_grass" "FML_2022_HI_HG_TD_MG_413_0acres_grass")

setenv SHAREDIR ${SCENBASE}/share_data
setenv METDIR   ${SHAREDIR}/dailyWETH   

setenv OUTDIR  "./outputs_HUC8/"
if ( ! -e $OUTDIR/dailyWETH/met ) mkdir -p $OUTDIR/dailyWETH/met
if ( ! -e $OUTDIR/dailyWETH/dep ) mkdir -p $OUTDIR/dailyWETH/dep

setenv YEARDIR   ${SCENBASE}/output4CMAQ/app/toCMAQ
setenv  YEARFILE   ${YEARDIR}/epic2cmaq_year.nc
setenv  SITEFILE   ${SHAREDIR}/EPICSites_Info.csv


# set regions to be used in summary any of "FIPS HUC8 REG10"
foreach reg ( HUC8 ) #items: HUC1 HUC2 STFIPS FIPS HUC8 REG10  
  setenv REG  $reg

  # set crops in the summary
  # NCD file: Y,M,D,PRCP,QNO3,SSFN,PRKN,DN,DN2,AVOL,HMN,NFIX,MUSL,
  #           YP,QAP,YON,YW,Q,HUSC

  #setenv CROPS  "CORNG"

  setenv CROPS "ALL"

  echo "Run daily met extraction for deposition.  " 

  R CMD BATCH epic2cmaq_sum_swat_dailyWETH.R
end  #for region
