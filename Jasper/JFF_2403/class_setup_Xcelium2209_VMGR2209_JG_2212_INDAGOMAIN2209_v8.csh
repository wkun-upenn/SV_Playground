#!/bin/csh
###############################################################################
## This script makes it easy to test different versions of FV tools on 
## the San Jose grid, AWS and your own VM with minimal changes to the script
## How to use and modify this script:
## Section 1 - Choose which major release and streams and indicate where the 
##             root directory of your FV tool installation is located
## Section 2 - Shoudn't need to change anything in there as its based on 
##             section 1 env vars
## Section 3 - Maybe you want to do some customisation once the Section 2 
##             env vars have been set
###############################################################################

###################################################################
## Any problems or suggestions - Michael Avery mavery@cadence.com #
###################################################################

################################################################################
###################### SECTION 1 - EDITABLE SECTION ############################
################################################################################
# Comment vars in/out to get the combinations you need
# Which tool environment are you using??? Uncomment *only 1*
setenv MY_FV_TOOL_ENV "AWS";         #The AWS/Citrix environment
#setenv MY_FV_TOOL_ENV "SJ_GRID";    #The San Jose grid environment
#setenv MY_FV_TOOL_ENV "MY_LOCAL_VM" #Local Linux VM on my own Windows laptop 

#Depending upon which enviroment used then set licence server and
#the base path of tool installs
if ( $MY_FV_TOOL_ENV == "AWS") then
   setenv LM_LICENSE_FILE 5280@10.8.10.76 ;  #AWS/Citrix licence server
   #set FV_TOOL_BASE_DIR = "/cds" ;           #For AWS/Citrix installs
   #AWS/Citrix installs Paths changed to match SJ grid paths under /grid Jan 2019
   set FV_TOOL_BASE_DIR = "/cds/avs/install"
else if ( $MY_FV_TOOL_ENV == "SJ_GRID") then
   setenv LM_LICENSE_FILE "5280@sjflex1:5280@sjflex2:5280@sjflex3:27000@sjtplic:27000@sjtplic:27005@sjflex4:27005@sjflex5:27005@sjflex6" ;
   set FV_TOOL_BASE_DIR = "/grid/avs/install" ;  #For San Jose Grid installs  
   setenv TFO_SCRIPTS "/grid/tfo/scripts"
   setenv LSF_SCRIPTS "/grid/sfi/farm/bin"
else if ( $MY_FV_TOOL_ENV == "MY_LOCAL_VM") then
   setenv LM_LICENSE_FILE "5280@pc-mavery" ;       #For example,my local laptop licence server
   set FV_TOOL_BASE_DIR = "/home2/mavery/software/CDS" ;  #For example, my VM
endif

# Need to unset these vars before the user chooses software versions or in some  
# circumstances the shell remembers the previous value from a previous 
# execution. 

unsetenv XCELIUM_REL;  # !!! DONT COMMENT THIS OUT !!!
unsetenv JASPER_REL;   # !!! DONT COMMENT THIS OUT !!!
unsetenv INDAGO_REL;   # !!! DONT COMMENT THIS OUT !!!
unsetenv MDV_REL;      # !!! DONT COMMENT THIS OUT !!!

unset XCELIUM_REL;     # !!! DONT COMMENT THIS OUT !!!
unset JASPER_REL;      # !!! DONT COMMENT THIS OUT !!!
unset INDAGO_REL;      # !!! DONT COMMENT THIS OUT !!!
unset MDV_REL;         # !!! DONT COMMENT THIS OUT !!!
#///////// Major Software Release /////////////////

#Select Xcelium Major release number
#set XCELIUM_REL = "2003";
#set XCELIUM_REL = "2009";
#set XCELIUM_REL = "2103";
#set XCELIUM_REL = "2109";
set XCELIUM_REL = "2209";
#set XCELIUM_REL = "AGILE";
#set XCELIUM_REL = "MAIN";

#Select MDV Major release number from version 16.11 onwards

#set MDV_REL = "1903";
#set MDV_REL = "1909";
#set MDV_REL = "2003";
#set MDV_REL = "2009";
#set MDV_REL = "2103";
#set MDV_REL = "2109";
set MDV_REL = "2209";
#set MDV_REL = "AGILE";
#set MDV_REL = "MAIN";

#Select INDAGO Major release number
#set INDAGO_REL = "2103";
#set INDAGO_REL = "2109";
#set INDAGO_REL = "AGILE";
#set INDAGO_REL = "MAIN";
#set INDAGO_REL = "MAIN2103";
#set INDAGO_REL = "MAIN2109";
set INDAGO_REL = "MAIN2209";

#VIP Major release number from version 11.3 onwards
#VIPCAT cannot be installed using IScape
set VIPCAT_REL = "11.3"

#Jasper still isnt exactly the same nomenclature as other tools but it is a similar structure.
# !!!For versions prior to 1803 ensure that JASPER_REL is not set  !!!!!
#In addition, Jasper cannot be installed using IScape

#set JASPER_REL = "2019.06";
#set JASPER_REL = "2019.09";
#set JASPER_REL = "2019.12";
#set JASPER_REL = "2020.03";
#set JASPER_REL = "2020.09";
#set JASPER_REL = "2020.12";
#set JASPER_REL = "2021.03";
#set JASPER_REL = "2021.06";
#set JASPER_REL = "2021.09";
#set JASPER_REL = "2022.12p002";
set JASPER_REL = ""; #Set to empty string if one wants to use the latest stream

#///////// Software Stream required /////////////////
#set XCELIUM_stream = "19.03.002";
#set XCELIUM_stream = "19.09.001";
#set XCELIUM_stream = "19.09.002";
#set XCELIUM_stream = "20.03.001";
#set XCELIUM_stream = "22.09.006";
set XCELIUM_stream = "latest"

#set MDV_stream = "19.03.001";
#set MDV_stream = "19.09.001";
#set MDV_stream = "20.03.001";
#set MDV_stream = "22.09.002";
set MDV_stream = "latest";

#set INDAGO_stream = "21.03.001"
#set INDAGO_stream = "21.09.001"
#set INDAGO_stream = "22.09.001"
set INDAGO_stream = "latest";

#set VIPCAT_stream = "11.30.056-s"
#set VIPCAT_stream = "11.30.058-s"
#set VIPCAT_stream = "11.30.059-s"
#set VIPCAT_stream = "11.30.061-s";
#set VIPCAT_stream = "11.30.068-s";
#set VIPCAT_stream = "11.30.068-s";
#set VIPCAT_stream = "11.30.079-s";
#set VIPCAT_stream = "11.30.088-s";
set VIPCAT_stream = "latest"


#set JASPER_stream = "jasper_2019.03p001"
#set JASPER_stream = "jasper_2019.06p002"
#set JASPER_stream = "jasper_2019.09"
#set JASPER_stream = "jasper_2019.12"
#set JASPER_stream = "jasper_2019.12p002"
#set JASPER_stream = "jasper_2020.03"
#set JASPER_stream = "jasper_2020.03p002"
#set JASPER_stream = "jasper_2020.09"
#set JASPER_stream = "jasper_2020.12p002"
#set JASPER_stream = "jasper_2021.03"
#set JASPER_stream = "jasper_2021.03p002"
#set JASPER_stream = "jasper_2021.06"
#set JASPER_stream = "jasper_2021.06p001"
#set JASPER_stream = "jasper_2021.09"
#set JASPER_stream = "jasper_2021.09p001"
set JASPER_stream = "latest" #Note that if "latest" used then JASPER_REL should be set to empty string 

###############################################################################
###################### END OF SECTION 1 EDITABLE SECTION ######################
###############################################################################


###############################################################################
################### SECTION 2 - SHOULDNT NEED EDITING SECTION #################
###############################################################################

#££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££
#££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££
###############################################################################
#### !!!No need to edit this section as its based upon the env vars above !!!##
###############################################################################
#Clean non-tool PATH as per new Cadence IT RHEL65 image:-
            
setenv PATH /usr/lib64/qt-3.3/bin:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin;
#Set paths required for LSF on SJ grid
if ( $MY_FV_TOOL_ENV == "SJ_GRID") then
   setenv PATH "${PATH}:${TFO_SCRIPTS}:${LSF_SCRIPTS}"
   setenv PATH "${PATH}:${LSF_SCRIPTS}"
   setenv PATH "${PATH}:/grid/common/bin"
endif

#----------SVG Course area env vars -------------------------------------------
set SVG_HOME = /cds/avs/SVG_crs
set SVG_LAB_DIR = ${SVG_HOME}/labs
set SVG_SCRIPT_DIR = ${SVG_HOME}/scripts
set USER_LAB_DIR_NAME = course_lab_tar_files

#-----------Software root install directory changes very infrequently----------
set ALL_XCELIUM_BASE_DIR =  "${FV_TOOL_BASE_DIR}/xcelium"  ; #Only for Xcelium 1704 or later on NFS share
set ALL_INDAGO_BASE_DIR =   "${FV_TOOL_BASE_DIR}/indago";
set ALL_JASPER_BASE_DIR =   "${FV_TOOL_BASE_DIR}/jasper"  ; #This is for JASPER version 2203 and later, was previously /jaspergold
set ALL_MDV_BASE_DIR =      "${FV_TOOL_BASE_DIR}/vmanager" ;  #This is for MDV 
set ALL_VIPCAT_BASE_DIR =   "${FV_TOOL_BASE_DIR}/vipcat"   ; #This is for the VIP catalogue

######################################################
#Only add Xcelium or Incisive to PATH, never both
######################################################

   set XCELIUM_INST_DIR = ${ALL_XCELIUM_BASE_DIR}/${XCELIUM_REL}/${XCELIUM_stream}
   set XCELIUM_BIN_DIR = ${XCELIUM_INST_DIR}/bin
   set XCELIUM_TOOLS_BIN_DIR = ${XCELIUM_INST_DIR}/tools/bin
 setenv PATH "${PATH}:${XCELIUM_BIN_DIR}:${XCELIUM_TOOLS_BIN_DIR}"
 setenv ROOT_FIND_NAME "xmroot"
   
   set MDV_INST_DIR = ${ALL_MDV_BASE_DIR}/${MDV_REL}/${MDV_stream}
   set MDV_BIN_DIR = ${MDV_INST_DIR}/bin
   set MDV_TOOLS_BIN_DIR = ${MDV_INST_DIR}/tools/bin
 setenv PATH "${PATH}:${MDV_BIN_DIR}:${MDV_TOOLS_BIN_DIR}"

 setenv INDAGO_ROOT "${ALL_INDAGO_BASE_DIR}/${INDAGO_REL}/${INDAGO_stream}"
   set  INDAGO_BIN_DIR = ${INDAGO_ROOT}/bin
   set  INDAGO_TOOLS_BIN_DIR = ${INDAGO_ROOT}/tools/bin
 setenv PATH "${PATH}:${INDAGO_BIN_DIR}:${INDAGO_TOOLS_BIN_DIR}"

 setenv CDN_VIP_ROOT ${ALL_VIPCAT_BASE_DIR}/${VIPCAT_REL}/${VIPCAT_stream};
 setenv ABVIP_INST_DIR  "${CDN_VIP_ROOT}/tools/abvip"

#Additions for Jasper, noting the nomenclature changed from version 1803 onwards
  set JASPER_INST_DIR = "${ALL_JASPER_BASE_DIR}/${JASPER_REL}/${JASPER_stream}"   
  set JASPER_BIN_DIR = "${JASPER_INST_DIR}/bin"
##*****************************************************************
setenv PATH "${PATH}:${JASPER_BIN_DIR}"
##*****************************************************************


###############################################################################
#### !!!No need to edit this section above upon the env vars in ###############
##### the editable section at the beginning of this file        ###############
###############################################################################
################### END OF SECTION 2 SHOULDNT NEED EDITING SECTION #############
###############################################################################


###############################################################################
################### SECTION 3 -  CUSTOMISABLE SECTION #########################
###############################################################################

####   For UVM Course   ############################################
#setenv UVMHOME `${ROOT_FIND_NAME}`/tools/methodology/UVM/CDNS-1.1d/sv
setenv UVMHOME `${ROOT_FIND_NAME}`/tools/methodology/UVM/CDNS-1.2/sv


##############Copy labtar files and setup scripts from the NFS4 share
#mkdir -p ${USER_LAB_DIR_NAME}
#cp -r ${SVG_LAB_DIR}/* ${HOME}/${USER_LAB_DIR_NAME}
###############################################################################
##+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###############################################################################
#END OF SCRIPT
