#!/usr/bin/perl

# This file creates all the necessary checks for your data.
# Run this file on its own before you test the database on the developmental
#    server.
##########################################################
# USAGE:
# From the top directory of your database, run the following command.
# perl ./.test/preconfigure.pl
##################################################################
#Flow
#-----------------------------------------------------------------
#
my $yesQ;

 $directoryList = "./.test/master_dir_map";
 $utilsFile = "./.test/utilities.pl";
 $tempDir = "./.test";
 $toolsDir = "./.test";
 $reportFile = "$toolsDir/testReport";
 @results = ();
 my %toolExeAndExpr = ();
 my %toolExeAndVersion = ();
 my %toolExeAndLogfile = ();
 my $expr, $logFile, $version;
#
##
### Todays Date required to delete older tar files.
##
print `touch time_stamp.file`;
$line = `ls -lt time_stamp.file`;
print `rm time_stamp.file`;
($priv, $num, $owner, $group, $size, $mon, $modDay, $timYr, $filename) = split(" ", $line);
$todays_date = "${mon}/${modDay}";
#
 if(-e $utilsFile) {
    do($utilsFile);
 }
 else {
    print "\nPlease make sure that the \".test\" directory is in your top-level directory, and that it contains all the necessary files..\n";
    print "utilities.pl, test_engine.pl, testscript.cmd\n";
    print "\nThen rerun this script from the top-level directory\n";
    exit;
 }
#
 if (-e "./.test/testReport") {
    print "Deleting previous test run results.\n";
    print "..\n";
    &callCommand("rm ./.test/testReport");
 }
 if (-e "./.test/installed_dir_map") {
    print "..\n";
    &callCommand("rm ./.test/installed_dir_map");
 }
#
$yesQ = "yes";
 print "Are you DONE with modifying the files in your course (y/n)?";
 while($yesQ eq "yes") {
   $_ = <STDIN>;
   chomp($_);
   if(m/y/i) { 
     $yesQ = "yes";
      print "\nMaking master directory list, for use in later comparison.\n";
      &mkDirMap($directoryList,".");
      last;
   }
   elsif(m/n/i) {
     $yesQ = "no"; 
      print "\nPlease make sure all your files are complete and accurate.\n";
      print "Once you run this script, you should not modify any of your files, except the ones in the \".test\" directory.\n";
      print "Then rerun this script\n";
      exit;
   }
   else {print "Please choose Yes(y) or No(n): "; }
 } #End while
#
$yesQ = "yes";
 if(-e ".class_setup") {
   print "\nIs your course .class_setup file created and complete, and sourced (y/n)?";
   while($yesQ eq "yes") {
     $_ = <STDIN>;
     chomp($_);
     if(m/y/i) {
       $yesQ = "yes";
       last;
     }
     elsif(m/n/i) {
       $yesQ = "no";
        print "\nPlease make sure the .class_setup file is complete and accurate. Also, source the .class_setup file, to make the executables available.\n";
        print "Once you run this script, you should not modify any of your files, except the ones in the \".test\" directory.\n";
        print "Then rerun this script\n";
        exit;
     }
     else {print "Please choose Yes(y) or No(n): "; }
   } #End while
 } # end if
 else {
     print "\nYou do not have a .class_setup file in your course database.\n";
     print "Please make sure you have created one and set all the paths\n";
     print "to your executables correctly\n";
     print "Then, rerun this script\n";
     exit;
 } #end else
#
$yesQ = "yes";
 $configfile = "./.test/config.pl";
 open(configFile,"> $configfile") || die "Could not open $configFile for writing\n"; 
 print "\n\nThe config.pl file is the only file you need to create/modify for a testscript.\n";
 print "\nDo you need help with creating the config.pl file (y/n)?";
 while($yesQ eq "yes") {
   $_ = <STDIN>;
   chomp($_);
   if(m/y/i) {
     $yesQ = "yes";
##### THE FOLLOWING VARIABLES ARE REQUIRED FOR ALL COURSES #########
     print "Enter the course name {My Educational Services Course}: ";
     $courseName = <STDIN>;
     chomp($courseName);
     if($courseName eq "") { $courseName = "My Educational Services Course"; }
     print configFile "\$courseName = \"$courseName\"\;\n";
     print "\nEnter the version number that will be printed on the books {1.0}: ";
     $courseVersion = <STDIN>;
     chomp($courseVersion);
     if($courseVersion eq "") { $courseVersion = "1.0"; }
     print configFile "\$courseVersion = \"$courseVersion\"\;\n";
     print "\nEnter the date when the course was released, or speculated to release {$todays_date}: ";
     $relDate = <STDIN>;
     chomp($relDate);
     if($relDate eq "") { $relDate = $todays_date; }
     print configFile "\$releaseDate = \"$relDate\"\;\n";
     print configFile "\$tempDir = \"./.test\"\;\n";
     print configFile "\$reportFile = \"\$tempDir/testReport\"\;\n";

     print "\nEnter the name of the operating systems the course should work on separated by commas (For example: Linux,Solaris,HP,IBM,Windows {Linux}): ";
     $osName = <STDIN>;
     chomp($osName);
     if($osName eq "") { $osName = "Linux"; }
     print configFile "\$osName = \"$osName\"\;\n";
     print "\n\nI need the tool executables used in your course, to create the testscripts.\n";
     print "Enter the tool executables separated by commas: ";
     $toolsUsed = <STDIN>;
     chomp($toolsUsed);
     $toolsUsed =~ s/ //g;
     @toolExecs = split(/,/, $toolsUsed);
     #my %toolExecs = map {$_, 1} @toolExecs;
     print "\n\nI will prompt you to enter just the command options. \n";
     print "I could grep the version from a logfile, if the tool is generating a logfile.\n";
     foreach $tool(@toolExecs) {
       $expr = "";
       $version = "";
       $logFile = "";
       $yesV = "no";
       while($yesV eq "no") {
         print "   For example, enter: \"-version\", or \"-W\", or \"-V\"\n";
         print "   , or \"-nogui -f $toolsDir/script1.cmd -logfile $toolsDir/${tool}.log\"\n";
         print "   , or \"-nog  -replay $toolsDir/script2.cmd -log $toolsDir/${tool}.log\"\n";
         print "   to get the version, without opening the graphical interface.\n";
         print "\nEnter the command options for the ${tool} tool: ";
         $expr = <STDIN>;
         chomp($expr);
         print "Calling command, \"$tool $expr\"\n";
         @results = &ckToolAndVersion("$tool", "ANY", "$expr", "ANY");
         #@results = &callCommandNoStdOut("$tool $expr");
         foreach(@results) {
           print "$_";
         }
         print "\nDid this print a version number that is relevant to your course? (y/n)";
         $_ = <STDIN>;
         chomp($_);
         if(m/y/i) {
            $toolExeAndExpr{$tool} = "$expr";
            print "\n\nEnter the version number for the ${tool} now (if not checking for any specific version, just press Enter): ";
            $version = <STDIN>;
            chomp($version);
            if($version eq "") { $version = "ANY"; }
            $toolExeAndVersion{$tool} = "$version";
            print "\nIf you specified a logfile in your command/expression, it is important to specify the same logfile in the following variable.\n";
            print "\nEnter the name of the logfile, including directory (. or ./.test) for ${tool} now (if none, just press Enter): ";
            $logFile = <STDIN>;
            chomp($logFile);
            if(-e "$logFile" or $logFile eq "") {
              if($logFile eq "") { $logFile = "ANY"; }
              $toolExeAndLogfile{$tool} = "$logFile";
              $yesV = "yes";
            } # end if
            else {
               print "\nCould not find any ${logFile} in here.\n";
               print "Please try again\n";
            } #end else
         }
         elsif (m/n/i) {
           print "\n\nMay be, you misspelt the executable, or the command options?\n";
           print "If you generated a logfile, did you check ${toolsDir}/${tool}.log for the version number?\n";
           print "Well, let's try it again...\n";
         } #end elsif
         else {print "Please choose Yes(y) or No(n): "; } #end ifelse
         &callCommand("reset");
       } # End while
      # # &callCommand("reset");
##
     } # End foreach of the tools.
### Write tool commands into config File.
     $firstTime = 1;
     print configFile "\%toolExeAndExpr = (";
     foreach $tool(@toolExecs) {
            if($firstTime) {
               print configFile "\'$tool\' =\> \'$toolExeAndExpr{$tool}\'";
               $firstTime = 0;
            }
            else { 
              print configFile ", \'$tool\' =\> \'$toolExeAndExpr{$tool}\'";
            }
     } # End foreach
     print configFile ")\;\n";
# Write versions.
     $firstTime = 1;
     print configFile "\%toolExeAndVersion = (";
     foreach $tool(@toolExecs) {
            if($firstTime) {
               print configFile "\'$tool\' =\> \'$toolExeAndVersion{$tool}\'";
               $firstTime = 0;
            }
            else {
              print configFile ", \'$tool\' =\> \'$toolExeAndVersion{$tool}\'";
            }
     } # End foreach
     print configFile ")\;\n";
# Write logfiles.
     $firstTime = 1;
     print configFile "\%toolExeAndLogfile = (";
     foreach $tool(@toolExecs) {
            if($firstTime) {
               print configFile "\'$tool\' =\> \'$toolExeAndLogfile{$tool}\'";
               $firstTime = 0;
            }
            else {
              print configFile ", \'$tool\' =\> \'$toolExeAndLogfile{$tool}\'";
            }
     } # End foreach
     print configFile ")\;\n";
# Gather licenses.
     my %toolExeAndSoftRel = ();
     my %toolExeAndLicenses = ();
     print "\nYou will now be asked to enter the name of the licenses used in your course. Based on the Software Releases, I can print out the list of licenses for the software releases, and you can use them to fill this requirement.\n";
     foreach $tool(@toolExecs) {
       $checkReleases = "yes";
       $foundL = 0;
       while($checkReleases eq "yes") {
         print "Please enter the Software Release Number for the $tool tool (Example:- IC61, ASSURA317): "; 
         $softRel = <STDIN>;
         chomp($softRel);
         $rel = $softRel;
         if($rel =~ "UPDATE") {
           ($rel, $rest) = split(/UPDATE/, $rel);
         }
         elsif($releasejoin =~ "HF") {
           ($rel, $rest) = split(/HF/, $rel);
         }
         else {
           ($rel, $rest) = split(/([UQMI]SR)/, $rel);
         }
         $softRel = $rel;
         &searchLicense($softRel);
         print "\nDoes this output show the relevant licenses for the ${tool} tool? (y/n) ";
         $_ = <STDIN>;
         chomp($_);
         if(m/y/i) {
            $toolExeAndSoftRel{$tool} = "$softRel";
            print "\nEnter the names of licenses corresponding to each tool executable. Multiple licenses for the same tool can be separated by commas. Use the exact license name printed from previous result.\n";
            print "Enter the names of licenses for the ${tool} tool: ";
            $licenses = <STDIN>;
            chomp($licenses);
            $licenses =~ s/ //g;
            @licensesList = split(/,/, $licenses);
            foreach $license (@licensesList) {
               @response = &callCommand("lmstat -i '$license'");
               if ($#response ge 0) {
                  print "Found $license license\n";
                  $foundL = 1;
                } 
                else {
                   print "WARNING: Call to lmstat -i '$license' failed.\n";
                }
            } #End inner foreach.
            if($foundL eq 1) {
              print "Found atleast one of the licenses specified.\n";
              $toolExeAndLicenses{$tool} = "$licenses";
              $checkReleases = "no";
            }
            else {
               print "None of the licenses specified were found. Check if you entered them correctly.\n";
               print "Your .cshrc should have LM_LICENSE_FILE specified and set to a running licenser server.\n";
               print "\nLet's try again\n";
               print "If you did not specify a license server, to exit this script, use Ctrl+C at any time. \n";
            }
         } # If found licenses.
         elsif(m/n/i) {
           print "Did you specify the Software Release correctly without underscores or periods?\n";
           print "Also, check the license servers were specified correctly, and retry this script.\n";
           print "Your .cshrc should have LM_LICENSE_FILE specified and set to a running licenser server.\n";
           print "You can also use, lmstat -a to get a list of licenses currently on the server.\n";
           print "\nLet's try again\n";
           print "If you did not specify a license server, to exit this script, use Ctrl+C at any time. \n";
         }
         else {
           print "\nSorry. You have to specify yes or no. Let's try again\n";
         } # End correct licenses printed out.
       } # End while
     } # End outer foreach.
### Gather Software Releases.
     $firstTime = 1;
     print configFile "\%toolExeAndSoftRel = (";
     foreach $tool(@toolExecs) {
              if($firstTime) {
                 print configFile "\'${tool}\' =\> \'$toolExeAndSoftRel{$tool}\'";
                 $firstTime = 0;
              }
              else {
                 print configFile ", \'${tool}\' =\> \'$toolExeAndSoftRel{$tool}\'";
              }
     }
     print configFile ")\;\n";
### Gather Software Releases.
     $firstTime = 1;
     print configFile "\%toolExeAndLicenses = (";
     foreach $tool(@toolExecs) {
              if($firstTime) {
                 print configFile "\'${tool}\' =\> \'$toolExeAndLicenses{$tool}\'";
                 $firstTime = 0;
              }
              else {
                 print configFile ", \'${tool}\' =\> \'$toolExeAndLicenses{$tool}\'";
              }
     }
     print configFile ")\;\n";
# Gather number of licenses.
     %toolExecAndnumLicenses = ();
     $firstTime = 1;
     print configFile "\%toolExeAndNumLicenses = (";
     foreach $tool(@toolExecs) {
        if($firstTime) { 
           print configFile "\'${tool}\' =\> \'1\'";
           $firstTime = 0;
         } 
         else {
           print configFile ", \'${tool}\' =\> \'1\'";
         }
     } # End foreach.
     print configFile ")\;\n";
####
### Enter logfile grep string.
     print "\nEnter any additional info you want searched in your logfiles. If none, just press Enter: ";
     $_ = <STDIN>;
     chomp($_);
     print configFile "\$additionalLogTestString = \"$_\"\;\n";
###
#
### For Windows and complex checkSysConf requirements.
     if(!($osName =~ m/Windows/i)) {
       print "\nThe checkSysConf utility works with almost all non MS-Windows Cadence Software.\n";
       print "By default the testscript will use checkSysConf to make sure the labs have the right configuration.\n";
       print "If you expect that using checkSysConf can be complicated, then say NO to the following variable.\n";
       print "\nDo you want to use checkSysConf? (y/n)";
       $useCheckSysConf = "no";
       $yesQ = "yes";
       while($yesQ eq "yes") {
         $_ = <STDIN>;
         chomp($_);
         if(m/y/i) {
           $useCheckSysConf = "yes";
           last;
         }
         elsif(m/n/i) {
           $useCheckSysConf = "no";
         }
         else {print "Please choose Yes(y) or No(n): "; }
       } #End while
       if($useCheckSysConf eq "yes") {
        foreach $tool(keys %toolExeAndExpr) {
          $checkReleases = "yes";
          $foundL = 0;
          while($checkReleases eq "yes") {
            @results = &callCommand("which $tool");
            $resolvedPath = join("", @results);
            $resolvedPath =~ s/\/$tool//;
            if($resolvedPath =~ m/tools(.*?)bin/) {
              $resolvedPath =~ s/tools(.*?)bin/tools\/bin/;
            }
            else {
              $resolvedPath =~ s/\/bin/\/tools\/bin/;
            }
            &report("INFO: THE RESOLVED PATH IS $resolvedPath");
            if(-e "${resolvedPath}/checkSysConf") {
                 @results = &callCommandPathIncluded("${resolvedPath}/checkSysConf -r");
                 foreach (@results) {
                   chomp($_);
                   &report("INFO: $_");
                 } # Print the output of checkSysConf -r right away.
                 print "\nDoes this output show the relevant Software Releases for the ${tool} tool? (y/n) ";
                 $_ = <STDIN>;
                 chomp($_);
                 if(m/y/i) {
                    print "\nPlease enter the Software Release Number for the $tool tool (Example:- IC6.1, AV31): ";
                    $softRel = <STDIN>;
                    chomp($softRel);
                    $toolExeAndCheckSoftRel{$tool} = "$softRel";
                    print "\n\nThis is the result for the checkSysConf $softRel\n\n";
                    sleep 1;
                    @results = &callCommandPathIncluded("${resolvedPath}/checkSysConf $softRel");
                    foreach (@results) {
                      chomp($_);
                      &report("INFO: $_");
                    } # Print the output of checkSysConf $softRel right away.
                    sleep 2;
                    print "\n\nCheck the results of the checkSysConf and make sure it passes. If you are not concerned about the FAILURE, make sure you set the \$useCheckSysConf variable to \"NO\" and add the information from the checkSysConf output into the variables in config.pl, so that the testscript passes in the classroom. \n";
                   $checkReleases = "no";
                 } ## End if software release found.
                 elsif(m/n/i) {
                   print "Please check to make sure the path to checkSysConf is included in your path.\n";
                   print "Check the tool paths in the .class_setup, and retry this script\n";
                   print "You can also use, /toolPath/checkSysConf -r to get a list of Software Releases supported.\n";
                   $checkReleases = "no";
                   last;
                 } # End correct licenses printed out.
                 else {
                   print "\nSorry. You have to specify yes or no. Let's try again\n";
                 }  
            } # end if resolved checkConf exists.
            else {
               print "Please check to make sure the path to checkSysConf is included in your path.\n";
               print "Check the tool paths in the .class_setup, and retry this script\n";
               print "You can also use, /toolPath/checkSysConf -r to get a list of Software Releases supported.\n";
               sleep 2;
               $checkReleases = "no";
               last;
            }
          } # End while
        } # End foreach tools.
       } # useCheckSysConf yes or no
### Gather Software Releases.
       if($useCheckSysConf eq "yes" and $checkReleases = "no") { print configFile "\$useCheckSysConf = \"YES\"\;\n"; }
       else { print configFile "\$useCheckSysConf = \"NO\"\;\n"; }
       $firstTime = 1;
       print configFile "\%toolExeAndCheckSoftRel = (";
       foreach $tool(keys %toolExeAndExpr) {
         if($firstTime) {
            print configFile "\'${tool}\' =\> \'$toolExeAndCheckSoftRel{$tool}\'";
            $firstTime = 0;
         }
         else {
            print configFile ", \'${tool}\' =\> \'$toolExeAndCheckSoftRel{$tool}\'";
         }
       }
       print configFile ")\;\n";
####
       print configFile "\$osVersion = \"ANY\"\;\n";
       print configFile "\$cpuArch = \"ANY\"\;\n";
       print configFile "\$machType = \"ANY\"\;\n";
       print configFile "\$physMem = \"ANY\"\;\n";
       print configFile "\$totalSwap = \"ANY\"\;\n";
       print configFile "\$freeDisk = \"ANY\"\;\n";
     } # If not Windows.
     else {
       print "I am dumping a variable call useCheckSysConf which must be set to NO for all Windows systems.\n";
       print configFile "\$useCheckSysConf = \"NO\"\;\n";
       print "I am dumping a bunch of variables that are helpful to check the configuration of the Windows system. Use the worst case scenario values for each variable.\n";
       print configFile "\$osVersion = \"ANY\"\;\n";
       print configFile "\$cpuArch = \"ANY\"\;\n";
       print configFile "\$machType = \"ANY\"\;\n";
       print configFile "\$physMem = \"ANY\"\;\n";
       print configFile "\$totalSwap = \"ANY\"\;\n";
       print configFile "\$freeDisk = \"ANY\"\;\n";
     }

###Enter additional files to search for.
     print "\n\nYou can enter any additional files or directories to search for.\n";
     print "For example, the TSMC libraries require the following file in the classroom server: /cds/libraries/RC71USR1/RC_7_1.qqqq.tar.gz\n";
     print "\nSpecify the filename including the path to look for: ";
     $_ = <STDIN>;
     chomp($_);
     print configFile "\$additionalFile = \"$_\"\;\n";
#   
###Enter additional comments.
     print "\n\nYou can enter comments into your course testing for ES administrators or students to look into.\n";
     print "For example: This course is meant for Cadence classrooms only. For offsites, please contact the developer for library data.\n";
     print "\nSpecify a comment, about this course testing: ";
     $_ = <STDIN>;
     chomp($_);
     print configFile "\$comment = \"$_\"\;\n";

##
#   
     print "\n\n***** Now, you can run .testscript successfully!! *****\n\n";
     print "As you probably know, you should NOT modify any of your files, except the ones in the \".test\" directory. Otherwise, you will have to run .testscript after deleting master_dir_map.\n";
     print "Also, you will NOT have to run preconfigure.pl again, unless you are unhappy with your configuration.\n";
     last;
   } # if you said yes to needing the help to create a config file.
   elsif(m/n/i) {
     $yesQ = "no";
      close(configFile);
      print "As you probably know, you should NOT modify any of your files, except the ones in the \".test\" directory. Otherwise, you will have to run .testscript after deleting master_dir_map.\n";
      print "Good luck testing!!\n";
      exit(1);
   }
   else {print "Please choose Yes(y) or No(n): "; }
 } ## while.
#
#################**************************###################
# EOF ##
