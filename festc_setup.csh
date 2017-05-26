#----------------------
#Setting the FESTC
#----------------------


#
#set festc install directory
#
setenv FESTC_HOME  /nas01/depts/ie/cempd/apps/sallocator/festc1_2


#Set festc interface program alias
alias festc  ${FESTC_HOME}/festc/festc


#
#set Spatial Allocator setting
#
setenv SA_HOME  /nas01/depts/ie/cempd/apps/sallocator/sa_052014
source ${SA_HOME}/bin/sa_setup.csh
