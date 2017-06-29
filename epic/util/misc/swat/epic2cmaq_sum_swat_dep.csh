#!/bin/csh -f
##BSUB -P EPIC -R mem96 -M 40
#BSUB -P EPIC 
#BSUB -J swat_dep
#BSUB -oo LOGS/run.swat_dep.%J.qlog
#BSUB -q week

#
###################################################################
# Purpose: Prepare N Deposition inputs for SWAT by summarizing met data, 
#          from the extracted EPIC *NCD output file:
#          $COMMON_data/EPIC_model/dailyNDep_2004
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

set year = 2004
setenv YEARDIR   ${SCENBASE}/output4CMAQ/app/toCMAQ
setenv METDIR   ${COMMDATA}/dailyNDep_${year} # dailyNDep_2004
setenv SHAREDIR   ${SCENBASE}/share_data

setenv OUTDIR  "./outputs_HUC8/${year}"
if ( ! -e $OUTDIR ) mkdir -p $OUTDIR

setenv  YEARFILE   ${YEARDIR}/epic2cmaq_year.nc
setenv  SITEFILE   ${SHAREDIR}/EPICSites_Info.csv
#setenv  BELDFILE   ${SHAREDIR}/beld4_CMAQ12km_2001.nc


# set regions to be used in summary any of "FIPS HUC8 REG10"
foreach reg ( HUC8 ) #items: HUC1 HUC2 STFIPS FIPS HUC8 REG10  
  setenv REG  $reg

  # set crops in the summary
  # NCD file: Y,M,D,PRCP,QNO3,SSFN,PRKN,DN,DN2,AVOL,HMN,NFIX,MUSL,
  #           YP,QAP,YON,YW,Q,HUSC

  #setenv CROPS  "CORNG"

  setenv CROPS "ALL"

  # set output file
  setenv  OUTFILE   $OUTDIR/ndep5yr_${year}_${reg}_

  echo "Run daily met extraction for deposition.  " 

  R CMD BATCH epic2cmaq_sum_swat_dep.R
endp  #for region
