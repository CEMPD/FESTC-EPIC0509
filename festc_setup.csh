#----------------------
#Setting the FESTC
#----------------------


#
#set festc install directory
#
setenv FESTC_HOME /proj/ie/proj/EPIC/FESTCv1.3_Test/festc1_3


#Set festc interface program alias
alias festc  ${FESTC_HOME}/festc/festc.sh


#
#set Spatial Allocator setting
#
setenv SA_HOME /proj/ie/proj/EPIC/SA_FESTCv1.3
source ${SA_HOME}/bin/sa_setup.csh
