###################################################################
#  Title:       Course Database Testing Facility  (test_engine.pl)
#  Date:        25 Sep 2005
#  Location:    Cadence Design System, Inc.
####################################################################
#  Abstract:
#  This 'perl' program controls the test sequence for installed Cadence
#  Education Services course material.
#
#                          Copyright  2001
#
#               CADENCE  DESIGN  SYSTEMS  INCORPORATED
#
# The copyright notice appearing above is included to provide statutory
# protection in the event of unauthorized or unintentional public disclosure
# without written consent of an officer of Cadence Design Systems Incorporated.
#
#######################################################################
# This is the script to be run to verify a course database/software
# installation.
########################################################################

####################################################################
#
#  Usage:
#  test_engine.pl [options] configFile
#
#  Return Value:
#  Upon successful completion, a status of '0' is returned.  Otherwise,
#  a non-zero status is returned.
#####################################################################
##############
#  Global variables for this program.
##############
$courseName = "";
$softwareRelease = "";
$courseVersion = "";
$releaseDate = "";
$toolExe = "";
$toolVersion = "";
$toolExpr = "-version";
$tempDir = "./.test";
$toolsDir = "./.test";
$toolLogFile = "";
$verbose = "";
$errors = 0;
$warnings = 0;
$reportFile = "$toolsDir/testReport";
@tokens = ();
@configItems = ();
@commands = ();
$licenseFile = "";
$installFile = "$toolsDir/installed_dir_map";
$masterFile = "$toolsDir/master_dir_map";
$comment = "";
$additionalFile = "";
###################
##  Declare the path to the file containing the variables. 
###################
$configFile = "$toolsDir/config.pl";
###################
##  Declare the path to the file containing common utility functions. 
###################
$utilsFile = ".test/utilities.pl";
###################
#  Introduce the program.
###################
printf(" Education Services Course Database Test Facility\n");
printf(" ************************************************\n");
printf(" \n");
###################
##******  Is this file readable? *********** ##
###################
unless(-r $utilsFile) {
   report("$0: FATAL: Cannot load utilities file '$utilsFile'.");
   exit(1);
}
unless(-w $toolsDir) {
   report("$0: FATAL: Cannot write to the directory '$toolsDir'.");
   report("Please change permissions on this directory to enable write.");
   exit(1);
}
&report("ERROR: Configuration file not specified: $configFile") unless($configFile);
&report("ERROR: Report File not specified: $reportFile") unless($reportFile);

###################
#  Load the common utility functions.
###################
do($utilsFile);

###################
#  Abort if 'perl' is not in the current path.
###################
unless(&findExec("perl")) {
   report("Must have 'perl' in search path.");
   exit(1);
}
###################
#  Abort if the version of 'perl' is less than 5.0.
###################
unless($] ge 5) {
  report("Must have perl 5.X or higher.");
  exit(1);
}
###################
#  Abort if we are running on an unsupported operating system.
###################
unless(&runningSupportedOS()) {
   report("Cannot run under unsupported OS '$^O'.");
   exit(1);
}
###################
#  If an improper number of arguments has been specified, issue an error
#  message and abort.
###################
if($#ARGV lt 0) { 
   report("Too few arguments specified (need at least 1).");
}
###############
###############
## BUILD NEW MASTER DIRECTORY MAP FILE
###############
if (-e $masterFile) {}
else {
  print "\nThis must be the first run of your testscript. \n";
  print "Making master directory list, for use in later comparison.\n";
  print "\nDO NOT DELETE THIS OR ANY OTHER FILES IN THE DATABASE, AFTER YOU SETUP YOUR SCRIPTS.\n\n";
  &mkDirMap($masterFile,".");
}

########## DELETE PREVIOUS RESULTS #######################
if (-e "./.test/testReport" || -e "./.test/installed_dir_map") {
  if (&runningUnix() || &runningLinux()) {
    print "\nDeleting previous test run results.\n";
    &callCommand("rm ./.test/testReport ./.test/installed_dir_map");
  }
  if (&runningNT()) {
    print "\nDeleting previous test run results.\n";
    system('cmd /c del .test\testReport .test\installed_dir_map');
  }
}

##############
#  Process command-line arguments.
##############
if($#ARGV >= 1)
{
   report("Unrecognized argument '@ARGV[0]'.") unless(@ARGV[0] eq '-v');
   $verbose = "true";
   $configFile = @ARGV[1];
}
###################################################
#  Obtain the configuration for this test run.
###################################################
do($configFile);

&report( " **********************************************************\n");
&report( " Running the Installation Test Script\n");
&report( " **********************************************************\n");
&report(sprintf("\nTest Started %s\n",scalar(localtime(time()))));

###  Add the tools directory to the search path.
$ENV{PATH} = "$toolsDir:$ENV{PATH}";

#
# Make sure that all the files exist. 
# This tests the sanctity of the compressions and copying.
&report("ERROR: Directory Map not written.\n") unless(&mkDirMap($installFile,"."));
&report("ERROR: Directory Maps dont match.\n") unless(&compareDirMaps($masterFile,$installFile));
########## Check for Additional Directories #######################
if(-e "$additionalFile" or -d "$additionalFile") {
     &report("Info: Found $additionalFile. You might need to install it as needed.\n"); 
}
else {
     &report("ERROR: $additionalFile not found. Install this $additionalFile file on the server.\n") unless($additionalFile eq "");
}
###########################################################################
# Checking the tool executable and version.
#  Evaluate the tool expression, complain and exit if no test succeeded.
###########################################################################
my $toolVersionExists;
TOOLS: foreach $toolExe (keys(%toolExeAndVersion))
{
  $toolExpr = $toolExeAndExpr{$toolExe};
  $toolLogfile = $toolExeAndLogfile{$toolExe};
  $toolVersionLine = $toolExeAndVersion{$toolExe};
  $qstringdot=split("\\,", $toolVersionLine);
  @versionSplit = split(/,/, $toolVersionLine);
  $toolVersionExists = "FAIL";
  if($qstringdot ge "2")
  {
    report("\nINFO: Testing multiple versions of the same tool.\n");
  }
  VERSIONS: foreach $toolVersion (@versionSplit)
  {
    if(&ckToolAndVersion("$toolExe","$toolVersion","$toolExpr","$toolLogfile"))
    {
      $toolVersionExists = "PASS";
      last VERSIONS;
    }
  }
  report("ERROR: No valid tool found matching '$toolExe' with the version(s) '$toolVersionLine'.") unless($toolVersionExists eq "PASS");
}

###########################################################################
# Checking the licenses.
# Make sure all the licenses specified are available.
###########################################################################
my $toolLicenseExists = "NOTFOUND";
TOOLS: foreach $toolExe (keys(%toolExeAndLicenses))
{
  $toolLicenseLine = $toolExeAndLicenses{$toolExe};
  $needLicenses = $toolExeAndNumLicenses{$toolExe};
  $qstringdot=split("\\,", $toolLicenseLine);
  @licenseSplit = split(/,/, $toolLicenseLine);
  $toolLicenseExists = "NOTFOUND";
  if($qstringdot ge "2")
  {
    report("\nINFO: Testing multiple license strings for the same/similar tools.\n");
  }
  PATTERNS: foreach $license (@licenseSplit)
  {
    &report("Checking license $license\n");
    $toolLicenseExists = &chkFlexlmLic($license, $needLicenses);
    if($toolLicenseExists eq "true") {
      $toolLicenseExists = "FOUND";
      &report("$toolLicenseExists valid licenses for $toolExe and is $license");
    }
    else {
       &report("WARNING: The $needLicenses $license licenses specified were not found in your license file");
    }
  }
  report("ERROR: No valid licenses found matching '$toolLicenseLine'.") unless($toolLicenseExists eq "FOUND");
  if($toolLicenseExists eq "FOUND") { report("INFO: Found atleast one of the specified licenses. "); }
}
#
###########################################################################
# Compare the System Profiles.
# This tests whether the current system matches required system configuration.
###########################################################################
 &compareSysProfiles($configFile);

#####################################
# Check for the string in the log file.
#
if($additionalLogTestString ne "") {
my $patternFound = "";
  OUTER: foreach $toolExe(keys(%toolExeAndLogfile)) {
    if($toolExeAndLogfile{$toolExe} ne "") {
      @logfile = &readTextFile($toolExeAndLogfile{$toolExe});
      INNER: foreach $line (@logfile) { 
        if($line =~ /$additionalLogTestString/) { 
          $patternFound = "FOUND";
          last OUTER;
        }  
      } # END INNER foreach
    } # If logfile exists.
  } # Check all tools.
  &report("WARNING: Requested pattern string '$additionalLogTestString' not found in the log files.") unless($patternFound eq "FOUND");
}
#End of testing reports
 &report(sprintf("\nEnd testing %s\n",scalar(localtime(time()))));
###########################################################################
#Read and finalize the report output. Print pass or fail in the report.
###########################################################################
  @output = &readTextFile($reportFile);

# Check the output for any errors.
    foreach $line (@output) {
         $warnings++ if($line =~ /WARNING:/);
         if($line =~ /ERROR:/) {
            print("Testing FAILED with:\n   $line\n");
            $errors++
         }
         if($line =~ /FATAL:/) {
            print("FATAL ERROR :\n   $line\n");
            exit(1);
         }
      } ## End foreach.
#
if($errors == 0 ) {
  &report("\nTesting of '$courseName' PASSED.\n");
} else { &report("\nTesting of '$courseName' FAILED.\n");}
 &report(" with $warnings WARNINGS and $errors ERRORS. \nCheck .test/testReport for problems.\n");
#

 &report ("$comment\n");

&report(".\n");
