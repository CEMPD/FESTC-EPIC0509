#!/bin/csh -f
#BSUB -P  EPIC
#BSUB -M  96
#BSUB -oo swat_daily.log
#BSUB -q  bigmem
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
setenv TYPE  app
setenv year  2002

#foreach SCEN ("FML_2022_HI_HG_TD_MG_413_0acres_grass") 
foreach SCEN ( "base_2002_HG_TD_MG_372_0acres_grass" "base_2022_HI_HG_TD_MG_413_0acres_grass" "FML_2022_HI_HG_TD_MG_413_0acres_grass")

setenv CASE    $SCEN
setenv DAYDIR   ${BASE}/${SCEN}/output4CMAQ/$TYPE/daily 

setenv SHAREDIR   ${BASE}/${SCEN}/share_data

setenv OUTDIR  "./outputs_nc"
if ( ! -e $OUTDIR ) mkdir -p $OUTDIR

setenv  SITEFILE   ${SHAREDIR}/EPICSites_Info.csv

setenv  BELDFILE   ${SHAREDIR}/beld4_CMAQ12km_2001.nc
if ( $CASE == "FML_2022_HI_HG_TD_MG_413_0acres_grass" ) then
   setenv  BELDFILE   ${SHAREDIR}/beld4_camq12km_2022_2011v.nc
endif

#setenv   METFILE   ${SHAREDIR}/site_weather_dep_20020101_to_20021231.nc
setenv   METFILE   ../site_weather_dep_20020101_to_20021231.nc


# set regions to be used in summary any of "FIPS HUC8 REG10"

  # set crops in the summary
  # NCD file: Y,M,D,PRCP,QNO3,SSFN,PRKN,DN,DN2,AVOL,HMN,NFIX,MUSL,
  #           YP,QAP,YON,YW,Q,HUSC
  
#RUN NAME,      LOCATION NAME,      STATISTICAL WEATHER, STATISTICAL WIND,   SOIL FILE NAME,     OPERATION FILE NAME, LATITUDE,LONGITUDE,    Y  ,M  ,D  ,PRCP,   QNO3,   SSFN,   PRKN,     DN,    DN2,   AVOL,    HMN,   NFIX,   MUSL,     YP,    QAP,    YON,     YW,      Q,    FPO,    FPL,    MNP,   DRNN,    SSF,    PRK,   QDRN,   PRKP,    GMN,    NMN,    PET,     ET,   OCPD,   DRNP,      HUSC,  HU BASE 0, HU FRAC.,L-1 DEP,L-1 BD, L-1 NO3,L-1 NH3,L-1 ON, L-1 P,  L-1 OP, L-1 C,  L-1 NITR,L-2 DEP, L-2 BD, L-2 NO3,L-2 NH3,L-2 ON, L-2 P,  L-2 OP,  L-2 C,  L-2 NITR ,T-1 DEP,T-1 BD, T-1 NO3,T-1 NH3,T-1 ON, T-1 P,  T-1 OP, T-1 C,  T-1 NITR,L1 ANO3, L1 ANH3, L1 AON, L1 AP, L1 AOP, L2 ANO3, L2 ANH3, L2 AON, L2 AP, L2 AOP, CPNM, UN1,   HUI,   LAI,  CPHT,  CPNM, UN1,   HUI,   LAI,  CPHT,
# QNO3(kg/ha)...Q(mm)...HUSC(none)..L1_DEP(m),L1_BD(t/m**3),L1_NO3(kg/h)..
# L2_DEP(m)...L1_BD(t/m**3),T1_DET(m),T1_BD(t/m**3),T1_NO3(kg/h)...HUI(none)...CPHT(m)
#

  setenv CROPS "ALL"
  #setenv CROPS "BARLEY"
  #setenv CROPS "OTHER_GRASS"

  # set output file
  #setenv  OUTFILE   $OUTDIR/swat_daily_${SCEN}_${TYPE}
  setenv  OUTFILE   $OUTDIR/${CASE}_${TYPE}_ncd_bygrids_20020101_to_20021231.csv

  echo "Run daily for " ${SCEN}
  #cp $METFILE $OUTFILE
  R CMD BATCH epic2cmaq_NCD_sum.R

end  #for scen
