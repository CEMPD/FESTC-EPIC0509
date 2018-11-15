#!/bin/csh -f
#BSUB -P  EPIC
#BSUB -R  mem96 -M 40
#BSUB -oo year_crop_dep_tot.log
#BSUB -q week
#
###################################################################
# Purpose: Prepare inputs for *year.nc, 
#          output4CMAQ/spinup or app/year/*NCD
#
# Developed by:  UNC Institute for the Environment
#
# Date: 09/08/2017
###################################################################

set BASE=/proj/ie/proj/EPIC/epic/scenarios
echo $BASE

setenv RUN_DEP  YES
setenv RUN_TOT  YES
setenv RUN_CROP YES

# SCEN: "US12KM_2001NLCD_2002", "US12KM_2006NLCD_2006", "US12KM_2011NLCD_2011NASS_2011" )
foreach yr ( 2010 ) #2011 2012 ) #2002 2006 2010 2011 2012)
  setenv TYPE app    
  setenv YEAR $yr
  if ( $YEAR == 2002 ) then
    set  SCEN = "US12KM_2001NLCD_2002"
  endif
  if ( $YEAR == 2006 ) then
    set  SCEN = "US12KM_2006NLCD_2006"
  endif
  if ( $YEAR == 2010 ) then
    set  SCEN = "US12KM_2011NLCD_2011NASS_2010"
  endif
  if ( $YEAR == 2011 ) then
    set  SCEN = "US12KM_2011NLCD_2011NASS_2011"
  endif
  if ( $YEAR == 2012 ) then
    set  SCEN = "US12KM_2011NLCD_2011NASS_2012"
  endif

  setenv SHAREDIR   ${BASE}/${SCEN}/share_data

  setenv OUTDIR  ./outputs/toCMAQ_${yr}_4mmSlug
  if ( ! -e $OUTDIR ) mkdir -p $OUTDIR
  if ( ! -e $OUTDIR/dep ) mkdir -p $OUTDIR/dep
  if ( ! -e $OUTDIR/bycrops ) mkdir -p $OUTDIR/bycrops

  #setenv  INDIR   ${BASE}/${SCEN}/output4CMAQ/${TYPE}/toCMAQ
  setenv  INDIR      ./inputs/toCMAQ_${yr}_4mmSlug
  setenv  SITEFILE   ./inputs/from_epa/EPICSites_Info.csv
  setenv  BELDFILE   ./inputs/from_epa/beld4_CMAQ12km_2011nlcd_2012_nass.nc
  setenv  METFILE    ./inputs/from_epa/site_weather_dep_${YEAR}0101_to_${YEAR}1231.nc
  setenv  YEARFILE   ${INDIR}/epic2cmaq_year.nc
  setenv  NPCONTENTS  ./inputs/N_P_contents.csv

  # set regions to be used in summary any of "FIPS HUC8 REG10"
  foreach reg ( HUC8 FIPS )  
  setenv REG  $reg

  echo "Summarize deposition and yearly total: " $REG  ${SCEN}  
  setenv  OUTDEPPRE   $OUTDIR/dep/${SCEN}_deposition_${YEAR}
  setenv  OUTTOTPRE   $OUTDIR/${SCEN}_${YEAR}_${TYPE}
  setenv  OUTCROPRE   $OUTDIR/bycrops/${SCEN}_${YEAR}_${TYPE}
  R CMD BATCH --no-save --slave epic2cmaq_sum_year_tot.R $OUTDIR/${SCEN}_${TYPE}_$REG.log
  #R CMD BATCH epic2cmaq_sum_year_tot.R 

end  #reg
end  #for scen
