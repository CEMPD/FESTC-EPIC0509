# FEST-C version 1.3 Public Release June 2017

FEST-C version 1.3 Public Release June 2017
Fertilizer Emission Scenario Tool for CMAQ : Generate fertilizer application input for CMAQ bi-directional NH3 modeling
Compiled in the 64-bit Linux environment


-       Version 1.3 06/30/2017 Release updates

        1) Added additional output for bare land fraction and soil moisture

        2) General bug fixes for elevation error and parameter inconsistencies

        3) Adjusted crop input parameters to improve yield evaluation in comparison to observations.

        4) Added new feature which transfers beld4 file to ioapi format in the beld4 generation utilities.

        5) Added 2011 crop fraction for US and Canada for beld4 generation.

        6) Added NLCD default year when new scenario is created.

        7) Fixed consistent checking on acreage filter and fertlizer year; update on scenario saving structures.

        8) Update jar packages/utilities to work with 64-bit system.

        9) Modified festc run script.  The script name changed from "festc" to "festc.sh"

        10) Enhanced scenario saving feature when exiting festc.

        11) Reduced number of output variables from EPIC2CMAQ
        12) Fixed a bug in the daily extraction for EPIC2CMAQ

-       Update release: 02/03/2016
                (1) Enhanced FEST-C  interface options for spinup and app simulations
                (2) Modified daily and annual output to include wind erosion and phosphorus variables
                (3) Added more utility tools to process EPIC output data
                (4) Elevation bug fix

-       Update release: 09/30/2015.  Enhancement on N input and many others
-       Update release: 09/12/2014.  Bug fix in scenario management
-       First release:  05/30/2014
