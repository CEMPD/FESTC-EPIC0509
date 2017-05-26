#!/bin/csh -fx
#
###################################################################
# Purpose: Convert the BELD4 dataset into IOAPI format 
#          for CMAQ-bidi NH3 modeling
#
# Developed by: Jesse Bash at EPA ORD AMAD 
# Adapted by:   D. Yang, UNC Institute for the Environment
#
# Date: 09/30/2015
###################################################################

setenv INDIR   /nas01/depts/ie/cempd/EPIC/epic/scenarios/base_2002_HG_TD_MG_372/share_data

setenv INFILE   ${INDIR}/beld4_CMAQ12km_2001.nc

setenv OUTDIR  "./outputs"

if ( ! -e $OUTDIR ) mkdir -p $OUTDIR
setenv OUT_FILE   ${OUTDIR}/beld4_CMAQ12km_2001.ncf


#users should use the same grid name defined in the GRIDDEC file from MCIP output
setenv GRID_NAME "CMAQ12km"

setenv  EXE_DIR   "./"

time  $EXE_DIR/Beld_nc2ioapi.exe 

mv OUTFILE $OUT_FILE

