#================
# FILE          : kiwiRuntimeChecker.pm
#----------------
# PROJECT       : OpenSUSE Build-Service
# COPYRIGHT     : (c) 2011 Novell Inc.
#               :
# AUTHOR        : Robert Schweikert <rschweikert@novell.com>
#               :
# BELONGS TO    : Operating System images
#               :
# DESCRIPTION   : Unit test implementation for the KIWIRuntimeChecker module.
#               :
# STATUS        : Development
#----------------
package Test::kiwiRuntimeChecker;

use strict;
use warnings;

use Common::ktLog;
use Common::ktTestCase;
use base qw /Common::ktTestCase/;

use KIWICommandLine;
use KIWILocator;
use KIWIRuntimeChecker;
use KIWIXML;

#==========================================
# Constructor
#------------------------------------------
sub new {
	# ...
	# Construct new test case
	# ---
	my $this = shift -> SUPER::new(@_);
	$this -> {dataDir} = $this -> getDataDir() . '/kiwiRuntimeChecker';
	$this -> {kiwi} = new Common::ktLog();
	$this -> {cmdL} = new KIWICommandLine($this->{kiwi});

	return $this;
}

#==========================================
# test_ctor_noArg1
#------------------------------------------
sub test_ctor_noArg1 {
	# ...
	# Test the runtime checker constructor
	# ---
	my $this = shift;
	my $kiwi = $this -> {kiwi};
	# Test missing second argument
	my $checker = new KIWIRuntimeChecker($kiwi);
	my $msg = $kiwi -> getMessage();
	my $expected = 'Expecting reference to KIWICommandLine object as second '
		. 'argument.';
	$this -> assert_str_equals($expected, $msg);
	my $msgT = $kiwi -> getMessageType();
	$this -> assert_str_equals('error', $msgT);
	my $state = $kiwi -> getState();
	$this -> assert_str_equals('failed', $state);
	# Test this condition last to get potential error messages
	$this -> assert_null($checker);
}

#==========================================
# test_ctor_noArg2
#------------------------------------------
sub test_ctor_noArg2 {
	# ...
	# Test the runtime checker constructor
	# ---
	my $this = shift;
	my $kiwi = $this -> {kiwi};
	# Test missing third argument
	my $cmd = $this -> __getCommandLineObj();
	my $checker = new KIWIRuntimeChecker($kiwi, $cmd);
	my $msg = $kiwi -> getMessage();
	my $expected = 'Expecting reference to KIWIXML object as third argument.';
	$this -> assert_str_equals($expected, $msg);
	my $msgT = $kiwi -> getMessageType();
	$this -> assert_str_equals('error', $msgT);
	my $state = $kiwi -> getState();
	$this -> assert_str_equals('failed', $state);
	# Test this condition last to get potential error messages
	$this -> assert_null($checker);
}

#==========================================
# test_ctor_valid
#------------------------------------------
sub test_ctor_valid {
	# ...
	# Test the runtime checker constructor
	# ---
	my $this = shift;
	my $kiwi = $this -> {kiwi};
	# No error construction
	my $cmd = $this -> __getCommandLineObj();
	my $xml = $this -> __getXMLObj( $this -> {dataDir} );
	my $checker = new KIWIRuntimeChecker($kiwi, $cmd, $xml);
	my $msg = $kiwi -> getMessage();
	$this -> assert_str_equals('No messages set', $msg);
	my $msgT = $kiwi -> getMessageType();
	$this -> assert_str_equals('none', $msgT);
	my $state = $kiwi -> getState();
	$this -> assert_str_equals('No state set', $state);
	# Test this condition last to get potential error messages
	$this -> assert_not_null($checker);
}

#==========================================
# test_buildProfWithDefPackages
#------------------------------------------
sub test_buildProfWithDefPackages {
	# ...
	# Test that using specified build profiles with configuration that has
	# default packages does not trigger an error
	# in the runtime checker.
	# ---
	my $this = shift;
	my $kiwi = $this -> {kiwi};
	my @profiles = ('my-first','my-second');
	my $cmd = $this -> __getCommandLineObj();
	$cmd -> setBuildProfiles(\@profiles);
	my $xml = $this -> __getXMLObj( $this -> {dataDir} . '/haveDefaultPkgs' );
	my $checker = new KIWIRuntimeChecker($kiwi, $cmd, $xml);
	my $res = $checker -> prepareChecks();
	my $msg = $kiwi -> getMessage();
	$this -> assert_str_equals('No messages set', $msg);
	my $msgT = $kiwi -> getMessageType();
	$this -> assert_str_equals('none', $msgT);
	my $state = $kiwi -> getState();
	$this -> assert_str_equals('No state set', $state);
	# Test this condition last to get potential error messages
	$this -> assert_not_null($res);
}

#==========================================
# test_conflictingProfiles
#------------------------------------------
sub test_conflictingProfiles {
	# ...
	# Test that conflicting values of the patternType attribute
	# are properly detected at runtime.
	# ---
	my $this = shift;
	my $kiwi = $this -> {kiwi};
	my @profiles = ('my-first','my-second');
	my $cmd = $this -> __getCommandLineObj();
	$cmd -> setBuildProfiles(\@profiles);
	my $xml = $this -> __getXMLObj( $this -> {dataDir} );
	my $checker = new KIWIRuntimeChecker($kiwi, $cmd, $xml);
	my $res = $checker -> prepareChecks();
	my $msg = $kiwi -> getMessage();
	my $expected = 'Conflicting patternType attribute values for specified '
	. 'profiles "my-first my-second" found';
	$this -> assert_str_equals($expected, $msg);
	my $msgT = $kiwi -> getMessageType();
	$this -> assert_str_equals('error', $msgT);
	my $state = $kiwi -> getState();
	$this -> assert_str_equals('failed', $state);
	# Test this condition last to get potential error messages
	$this -> assert_null($res);
}

#==========================================
# test_fsToolCheckFsysImg
#------------------------------------------
sub test_fsToolCheckFsysImg {
	# ...
	# Test the verification of the *fs tool presence verification.
	# Do not know how to hide the tool from within the test, thus certain
	# conditions of the test are only exercised on systems where the
	# tool is not present.
	# ---
	my $this = shift;
	my $kiwi = $this -> {kiwi};
	my $cmd = $this -> __getCommandLineObj();
	my $dataBaseDir = $this -> {dataDir} . '/fileSysImg/';
	my @fsTestDirs = glob "$dataBaseDir/*";
	for my $fsTestName (@fsTestDirs) {
		my $xml = $this -> __getXMLObj($fsTestName);
		my $checker = new KIWIRuntimeChecker($kiwi, $cmd, $xml);
		my $res = $checker -> createChecks();
		my $eMsg = $kiwi -> getErrorMessage();
		if ($eMsg) {
			# File system tool is not present
			my $fsTool;
			if ($fsTestName =~ 'btrfs' ) {
				$fsTool = 'mkfs.btrfs'
			} elsif ($fsTestName =~ 'ext2' ) {
				$fsTool = 'mkfs.ext2';
			} elsif ($fsTestName =~ 'ext3' ) {
				$fsTool = 'mkfs.ext3';
			} elsif ($fsTestName =~ 'ext4' ) {
				$fsTool = 'mkfs.ext4';
			} elsif ($fsTestName =~ 'reiserfs' ) {
				$fsTool = 'mkreiserfs';
			} elsif ($fsTestName =~ 'xfs' ) {
				$fsTool = 'mkfs.xfs';
			}
			my $logMsg = $kiwi -> getLogInfoMessage();
			my $expected = "warning: $fsTool not found\n";
			$this -> assert_str_equals($expected, $logMsg);
			my @prts = split /\//, $fsTestName;
			my $fsExpected = $prts[-1];
			$expected = 'Requested image creation with filesystem "'
			. $fsExpected
			. '"; but tool to create the file system could not '
			. 'be found.';
			$this -> assert_str_equals($expected, $eMsg);
			my $msgT = $kiwi -> getMessageType();
			$this -> assert_str_equals('error', $msgT);
			my $state = $kiwi -> getState();
			$this -> assert_str_equals('failed', $state);
			# Test this condition last to get potential error messages
			$this -> assert_null($res);
		} else {
			# Filesystem tool is present
			my $msg = $kiwi -> getMessage();
			$this -> assert_str_equals('No messages set', $msg);
			my $msgT = $kiwi -> getMessageType();
			$this -> assert_str_equals('none', $msgT);
			my $state = $kiwi -> getState();
			$this -> assert_str_equals('No state set', $state);
			# Test this condition last to get potential error messages
			$this -> assert_not_null($res);
		}
	}
}

#==========================================
# test_fsToolCheckIsoImg
#------------------------------------------
sub test_fsToolCheckIsoImg {
	# ...
	# Test the verification of the *fs tool presence verification.
	# Do not know how to hide the tool from within the test, thus certain
	# conditions of the test are only exercised on systems where the
	# tool is not present.
	# ---
	my $this = shift;
	my $kiwi = $this -> {kiwi};
	my $cmd = $this -> __getCommandLineObj();
	my $dataBaseDir = $this -> {dataDir} . '/liveIsoImg';
	my @fsTestDirs = glob "$dataBaseDir/*";
	for my $fsTestName (@fsTestDirs) {
		my $xml = $this -> __getXMLObj($fsTestName);
		my $checker = new KIWIRuntimeChecker($kiwi, $cmd, $xml);
		my $res = $checker -> createChecks();
		my $eMsg = $kiwi -> getErrorMessage();
		if ($eMsg) {
			# File system tool is not present
			my $fsTool;
			my $fsExpected;
			if ($fsTestName =~ 'clic') {
				$fsExpected = 'clicfs';
				$fsTool = 'mkclicfs';
			} elsif ($fsTestName =~ 'compressed' || $fsTestName =~ 'unified') {
				$fsExpected = 'squashfs';
				$fsTool = 'mksquashfs';
			}
			my $logMsg = $kiwi -> getLogInfoMessage();
			my $expected = "warning: $fsTool not found\n";
			$this -> assert_str_equals($expected, $logMsg);
			$expected = 'Requested image creation with filesystem "'
			. $fsExpected
			. '"; but tool to create the file system could not '
			. 'be found.';
			$this -> assert_str_equals($expected, $eMsg);
			my $msgT = $kiwi -> getMessageType();
			$this -> assert_str_equals('error', $msgT);
			my $state = $kiwi -> getState();
			$this -> assert_str_equals('failed', $state);
			# Test this condition last to get potential error messages
			$this -> assert_null($res);
		} else {
			# Filesystem tools is present
			my $msg = $kiwi -> getMessage();
			$this -> assert_str_equals('No messages set', $msg);
			my $msgT = $kiwi -> getMessageType();
			$this -> assert_str_equals('none', $msgT);
			my $state = $kiwi -> getState();
			$this -> assert_str_equals('No state set', $state);
			# Test this condition last to get potential error messages
			$this -> assert_not_null($res);
		}
	}
}

#==========================================
# test_fsToolCheckOemBtrfs
#------------------------------------------
sub test_fsToolCheckOemBtrfs {
	# ...
	# Test the verification of the *fs tool presence verification.
	# Do not know how to hide the tool from within the test, thus certain
	# conditions of the test are only exercised on systems where the
	# tool is not present.
	# ---
	my $this = shift;
	my $kiwi = $this -> {kiwi};
	my $cmd = $this -> __getCommandLineObj();
	my $configPath = $this -> {dataDir} . '/oemBtrfs';
	my $xml = $this -> __getXMLObj($configPath);
	my $checker = new KIWIRuntimeChecker($kiwi, $cmd, $xml);
	my $res = $checker -> createChecks();
	my $eMsg = $kiwi -> getErrorMessage();
	if ($eMsg) {
		# File system tool is not present
		my $logMsg = $kiwi -> getLogInfoMessage();
		my $expected = "warning: mkfs.btrfs not found\n";
		$this -> assert_str_equals($expected, $logMsg);
		$expected = 'Requested image creation with filesystem "btrfs"; '
		. 'but tool to create the file system could not '
		. 'be found.';
		$this -> assert_str_equals($expected, $eMsg);
		my $msgT = $kiwi -> getMessageType();
		$this -> assert_str_equals('error', $msgT);
		my $state = $kiwi -> getState();
		$this -> assert_str_equals('failed', $state);
		# Test this condition last to get potential error messages
		$this -> assert_null($res);
	} else {
		# Filesystem tools is present
		my $msg = $kiwi -> getMessage();
		$this -> assert_str_equals('No messages set', $msg);
		my $msgT = $kiwi -> getMessageType();
		$this -> assert_str_equals('none', $msgT);
		my $state = $kiwi -> getState();
		$this -> assert_str_equals('No state set', $state);
		# Test this condition last to get potential error messages
		$this -> assert_not_null($res);
	}
}

#==========================================
# test_fsToolCheckSplitImg
#------------------------------------------
sub test_fsToolCheckSplitImg {
	# ...
	# Test the verification of the *fs tool presence verification.
	# Do not know how to hide the tool from within the test, thus certain
	# conditions of the test are only exercised on systems where the
	# tool is not present.
	# ---
	my $this = shift;
	my $kiwi = $this -> {kiwi};
	my $cmd = $this -> __getCommandLineObj();
	my $configPath = $this -> {dataDir} . '/splitImg';
	my $xml = $this -> __getXMLObj($configPath);
	my $checker = new KIWIRuntimeChecker($kiwi, $cmd, $xml);
	my $res = $checker -> createChecks();
	my $locator = new KIWILocator($kiwi);
	my $haveBtrfs = $locator -> getExecPath('mkfs.btrfs');
	if ($haveBtrfs) {
		# Filesystem tool is present
		my $msg = $kiwi -> getMessage();
		$this -> assert_str_equals('No messages set', $msg);
		my $msgT = $kiwi -> getMessageType();
		$this -> assert_str_equals('none', $msgT);
		my $state = $kiwi -> getState();
		$this -> assert_str_equals('No state set', $state);
		# Test this condition last to get potential error messages
		$this -> assert_not_null($res);
	} else {
		# File system tool is not present
		my $logMsg = $kiwi -> getLogInfoMessage();
		my $expected = "warning: mkfs.btrfs not found\n";
		$this -> assert_str_equals($expected, $logMsg);
		my $eMsg = $kiwi -> getErrorMessage();
		$expected = 'Requested image creation with filesystem "btrfs"; '
		. 'but tool to create the file system could not '
		. 'be found.';
		$this -> assert_str_equals($expected, $eMsg);
		my $state = $kiwi -> getState();
		$this -> assert_str_equals('failed', $state);
		# Test this condition last to get potential error messages
		$this -> assert_null($res);
	}
}

#==========================================
# test_noBuildProfile
#------------------------------------------
sub test_noBuildProfile {
	# ...
	# Test that using no build profile does not trigger an error
	# in the runtime checker.
	# ---
	my $this = shift;
	my $kiwi = $this -> {kiwi};
	my $cmd = $this -> __getCommandLineObj();
	my $xml = $this -> __getXMLObj( $this -> {dataDir} );
	my $checker = new KIWIRuntimeChecker($kiwi, $cmd, $xml);
	my $res = $checker -> prepareChecks();
	my $msg = $kiwi -> getMessage();
	$this -> assert_str_equals('No messages set', $msg);
	my $msgT = $kiwi -> getMessageType();
	$this -> assert_str_equals('none', $msgT);
	my $state = $kiwi -> getState();
	$this -> assert_str_equals('No state set', $state);
	# Test this condition last to get potential error messages
	$this -> assert_not_null($res);
}

#==========================================
# test_noBuildType
#------------------------------------------
sub test_noBuildType {
	# ...
	# Test that an error is triggered if Kiwi cannot determine the build type
	# ---
	my $this = shift;
	my $kiwi = $this -> {kiwi};
	my $cmd = $this -> __getCommandLineObj();
	my $configDir = $this -> {dataDir} . '/noDefaultBuildType';
	# TODO
	# Change to a RuntimeChecker test when XML object becomes a dumb
	# container and looses notion of state
	#my $xml = $this -> __getXMLObj($configDir);
	#my $checker = new KIWIRuntimeChecker($kiwi, $cmd, $xml);
	#my $res = $checker -> prepareChecks();
	my $xml = new KIWIXML(
		$kiwi, $configDir, undef, undef,$this->{cmdL}
	);
	my $msg = $kiwi -> getMessage();
	$this -> assert_str_equals('Cannot determine build type', $msg);
	my $msgT = $kiwi -> getMessageType();
	$this -> assert_str_equals('error', $msgT);
	my $state = $kiwi -> getState();
	$this -> assert_str_equals('failed', $state);
	# Test this condition last to get potential error messages
	$this -> assert_null($xml);
}

#==========================================
# test_packageManagerCheck
#------------------------------------------
sub test_packageManagerCheck_ens {
	# ...
	# Test that the runtime check for package manager tool existence behaves
	# properly.
	# ---
	my $this = shift;
	my $kiwi = $this -> {kiwi};
	my $cmd = $this -> __getCommandLineObj();
	# Select manager least likely to be present we want this part of
	# the test to simulate a failure condition
	$cmd -> setPackageManager('ensconce');
	my $xml = $this -> __getXMLObj( $this -> {dataDir} );
	$xml -> setPackageManager('ensconce');
	my $checker = new KIWIRuntimeChecker($kiwi, $cmd, $xml);
	my $res = $checker -> prepareChecks();
	my $locator = new KIWILocator($kiwi);
	my $haveEnsconce = $locator -> getExecPath('ensconce');
	if ($haveEnsconce) {
		my $msg = $kiwi -> getMessage();
		$this -> assert_str_equals('No messages set', $msg);
		my $msgT = $kiwi -> getMessageType();
		$this -> assert_str_equals('none', $msgT);
		my $state = $kiwi -> getState();
		$this -> assert_str_equals('No state set', $state);
		$this -> assert_not_null($res);
		my $infoMsg = 'Found ensconce package manager, not hitting the '
			. "anticipated failure condition. This is NOT an error.\n";
		print STDOUT $infoMsg;
	} else {
		my $logInf = $kiwi -> getLogInfoMessage();
		$this -> assert_str_equals("warning: ensconce not found\n", $logInf);
		my $errMsg = $kiwi -> getErrorMessage();
		my $expected = 'Executable for specified package manager, ensconce, '
			. 'could not be found.';
		$this -> assert_str_equals($expected, $errMsg);
		my $state = $kiwi -> getState();
		$this -> assert_str_equals('failed', $state);
		$this -> assert_null($res);
	}
}

#==========================================
# test_packageManagerCheck_ens
#------------------------------------------
sub test_packageManagerCheck_zypp {
	# ...
	# Test that the runtime check for package manager tool existence behaves
	# properly.
	# ---
	my $this = shift;
	my $kiwi = $this -> {kiwi};
	my $cmd = $this -> __getCommandLineObj();
	# Test the most likely use case, zypper set as package manager in
	# config.xml, this test should succeed
	my $xml = $this -> __getXMLObj( $this -> {dataDir} );
	my $checker = new KIWIRuntimeChecker($kiwi, $cmd, $xml);
	my $res = $checker -> prepareChecks();

	my $locator = new KIWILocator($kiwi);
	my $haveZypper = $locator -> getExecPath('zypper');
	if ($haveZypper) {
		my $msg = $kiwi -> getMessage();
		$this -> assert_str_equals('No messages set', $msg);
		my $msgT = $kiwi -> getMessageType();
		$this -> assert_str_equals('none', $msgT);
		my $state = $kiwi -> getState();
		$this -> assert_str_equals('No state set', $state);
		$this -> assert_not_null($res);

	} else {
		my $logInf = $kiwi -> getLogInfoMessage();
		$this -> assert_str_equals("warning: zypper not found\n", $logInf);
		my $errMsg = $kiwi -> getErrorMessage();
		my $failExpect = 'Executable for specified package manager, zypper, '
			. 'could not be found.';
		$this -> assert_str_equals($failExpect, $errMsg);
		my $msgT = $kiwi -> getMessageType();
		$this -> assert_str_equals('error', $msgT);
		my $state = $kiwi -> getState();
		$this -> assert_str_equals('failed', $state);
		$this -> assert_null($res);
		my $infoMsg = 'Did not find zypper package manager, not hitting the '
			. "anticipated success condition. This is NOT an error.\n";
		print STDOUT $infoMsg;
	}
}

#==========================================
# test_useSingleBuildProfile
#------------------------------------------
sub test_useSingleBuildProfile {
	# ...
	# Test that using a single build profile does not trigger an error
	# in the runtime checker.
	# ---
	my $this = shift;
	my $kiwi = $this -> {kiwi};
	my @profiles = ('my-first');
	my $cmd = $this -> __getCommandLineObj();
	$cmd -> setBuildProfiles(\@profiles);
	my $xml = $this -> __getXMLObj( $this -> {dataDir} );
	my $checker = new KIWIRuntimeChecker($kiwi, $cmd, $xml);
	my $res = $checker -> prepareChecks();
	my $msg = $kiwi -> getMessage();
	$this -> assert_str_equals('No messages set', $msg);
	my $msgT = $kiwi -> getMessageType();
	$this -> assert_str_equals('none', $msgT);
	my $state = $kiwi -> getState();
	$this -> assert_str_equals('No state set', $state);
	# Test this condition last to get potential error messages
	$this -> assert_not_null($res);
}

#==========================================
# Private helper methods
#------------------------------------------
#==========================================
# __getCommandLineObj
#------------------------------------------
sub __getCommandLineObj {
	# ...
	# Create a command line object
	# ---
	my $this = shift;
	return new KIWICommandLine( $this -> {kiwi} );
}

#==========================================
# __getXMLObj
#------------------------------------------
sub __getXMLObj {
	# ...
	# Create an XML object with the given config dir
	# ---
	my $this      = shift;
	my $configDir = shift;
	# TODO
	# Fix the creation of the XML object once the ctor arguments change
	my $xml = new KIWIXML(
		$this -> {kiwi}, $configDir, undef, undef,$this->{cmdL}
	);
	if (! $xml) {
		my $msg = 'Failed to create XML obj, most likely improper config '
		. 'path: '
		. $configDir;
		$this -> assert_equals(1, $msg);
	}
	return $xml;
}

1;
