# FEST-C
Fertilizer Emission Scenario Tool for CMAQ : Generate fertilizer application input for CMAQ bi-directional NH3 modeling

FEST-C is a Java-based interface system that is used to simulate daily fertilizer application information using the Environmental Policy Integrated Climate (EPIC) model (http://epicapex.tamu.edu/epic) and to extract the EPIC daily output that is a required input for bidirectional NH3 modeling performed using the Community Multiscale Air Quality (CMAQ) modeling system (http://www.cmascenter.org/cmaq/). 

The FEST-C Git repository is available for release beginning with FEST-C version 1.2. 

Releases will soon be available available for:
FEST-C version 1.3
FEST-C version 2.0

To clone code from the CEMPD/FEST-C Git repository, specify the branch (i.e. version number) and issue the following command from within a working directory on your server. For example, to get FEST-C version 1.2:

git clone -b FESTCv1.2 https://github.com/CEMPD/FEST-C.git 

It is important to note that the cloned branch does not include common data required as input to run the model.  We recommend those not developing the code to go to the CMAS Center Software Clearinghouse to download the FEST-C version of interest and user's guide.  From http://www.cmascenter.org, select Download -> Software -> FEST-C and choose the version to get the FEST-C version with input data. 
