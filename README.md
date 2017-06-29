# H1 Generate fertilizer application input for CMAQ bi-directional NH3 modeling

The Fertilizer Emission Scenario Tool for CMAQ (FEST-C) system is used to simulate daily fertilizer application information using the Environmental Policy Integrated Climate (EPIC) model for a defined CMAQ domain. This EPIC output information is a required input for CMAQ bi-directional NH3 modeling. The FEST-C contains two major components - a Java-based interface and EPIC modeling system. The FEST-C interface integrates the WRF/CMAQ with EPIC through the current release of the Spatial Allocator (SA v4.2) Raster Tools system. The interface contains 13 sub-interface tools which guide users through the EPIC simulations for CMAQ. The FEST-C system can be used in assessing not only the impacts of agricultural fertilization and management practices on the air quality (NH3) and climate (N2O), but also the impacts of meteorology/climate and air quality (N deposition) on crop yield, soil erosion and overall nitrogen, carbon and phosphorus biogeochemical status of the agricultural ecosystem. 

FEST-C works for domains at different resolutions and in any of the four WRF projection coordinate systems - longitude/latitude, Lambert Conformal Conic, Universal Polar Stereographic, and Mercator

## Features

## Java-based FEST-C interface with 13 sub-interface tools to:

-	Build the input database of 21 crops for EPIC model simulations for a given CMAQ domain
-	Simulate daily fertilizer application information based entirely on simulated plant demand in response to local soil and weather conditions using EPIC,
-	Extract EPIC daily output for CMAQ bi-directional NH3 modeling, and
-	Visualize the simulation results spatially over the modeling domain.

## EPIC Modeling system including:

-	EPIC model version 0509 from Texas A&M University (TAMU), modified by EPA to meet CMAQ input requirements, 
-	Utility programs to build EPIC input data sets for CMAQ domain grid cells,
-	Common data sets (e.g. weather station climate statistic files and built soil data files) included in the 
EPIC modeling,
-	Scenarios which contain a test case and to store users\' application scenarios, and
-	Documentation of the EPIC Modeling System for CMAQ 12km Grids in the FEST-C.

Requirements: FESTCv1.3, [Spatial Allocator v4.3 Raster Tools](https://github.com/CMASCenter/Spatial-Allocator)  


### UPDATES in Version 1.3 (06/30/2017)

        1. Added additional output for bare land fraction and soil moisture
        2. General bug fixes for elevation error and parameter inconsistencies
        3. Adjusted crop input parameters to improve yield evaluation in comparison to observations.
        4. Added new feature which transfers beld4 file to ioapi format in the beld4 generation utilities.
        5. Added 2011 crop fraction for US and Canada for beld4 generation.
        6. Added NLCD default year when new scenario is created.
        7. Fixed consistent checking on acreage filter and fertlizer year; update on scenario saving structures.
        8. Update jar packages/utilities to work with 64-bit system.
        9. Modified festc run script.  The script name changed from "festc" to "festc.sh"
        10. Enhanced scenario saving feature when exiting festc.
        11. Reduced number of output variables from EPIC2CMAQ
        12. Fixed a bug in the daily extraction for EPIC2CMAQ

### UPDATES in Version 1.2  (02/03/2016)

-       Enhanced FEST-C interface options for spinup and app simulations
-       Modified daily and annual output to include wind erosion and phosphorus variables
-       Added more utility tools to process EPIC output data
-       Elevation bug fix



### Update release: 09/30/2015

        1. Enhancement on N input and many others

### Update release: 09/12/2014  

        1. Bug fix in scenario management

### First release:  05/30/2014
