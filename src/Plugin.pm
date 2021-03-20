#	DenonAvpControl
#
#	Author:	Chris Couper <chris(dot)c(dot)couper(at)gmail(dot)com>
#	Credit To: Felix Mueller <felix(dot)mueller(at)gwendesign(dot)com>
#
#	Copyright (c) 2003-2008 GWENDESIGN, 2008-2021 Chris Couper
#	All rights reserved.
#
#	----------------------------------------------------------------------
#	Function:	Turn Denon AVP Amplifier on and off (works for TP and SB)
#	----------------------------------------------------------------------
#	Technical:	To turn the amplifier on, sends AVP net AVON.
#			To turn the amplifier off, sends AVP net AVOFF.
#			To set the % volume of the amplifier per the % of theSB
#
#	----------------------------------------------------------------------
#	Installation:
#			- Copy the complete directory into the 'Plugins' directory
#			- Restart SlimServer
#			- Enable DenonAvpControl in the Web GUI interface
#			- Set:AvpIP Address, On, Off and Quick Delays, Max Volume, Quickselect
#	----------------------------------------------------------------------
#	History:
#
#	2009/02/14 v1.0	- Initial version
#	2009/02/23 v1.1	- Added zones and synching volume of amp with Squeezebox
#	2009/07/25 v1.2	- Minor changes to discard callbacks from unwanted players
#	2009/09/01 v1.3	- Changed the player registration process
#	2009/09/01 v1.4	- Changed to support SBS 7.4
#	2009/12/01 v1.5 - Added menus to allow the user to change audio settings
#	2010/08/07 v1.6 - Accomodate updates to AVP protocol and to use digital passthrough on iPeng
#	2010/08/15 v1.7 - Update to support .5 db steps in volume
#	2012/01/28 v1.8 - fixed error in maxVol fetch
#	2012/01/30 v1.9 - QuickSelect Issues, removed dead code, strings.txt update
#	2012/01/30 v1.9.1 - Supports multiple plugin instances, better comms handling, reference levels
#   2019/08/21 v1.9.2 - Moved to LMS, new zone 4 support
#	2020/05/14 v2.0 - Added quick selection delay for use during startup.
#   2021/02/24 v2.1 - Retracted.
#   2021/02/24 v2.2 - Bug fixes.
#   2021/02/25 v2.3 - Install fix.
#	----------------------------------------------------------------------
#
#	This program is free software; you can redistribute it and/or modify
#	it under the terms of the GNU General Public License as published by
#	the Free Software Foundation; either version 2 of the License, or
#	(at your option) any later version.
#
#	This program is distributed in the hope that it will be useful,
#	but WITHOUT ANY WARRANTY; without even the implied warranty of
#	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#	GNU General Public License for more details.
#
#	You should have received a copy of the GNU General Public License
#	along with this program; if not, write to the Free Software
#	Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
#	02111-1307 USA
#
package Plugins::DenonAvpControl::Plugin;
use strict;
use base qw(Slim::Plugin::Base);

use Slim::Utils::Strings qw(string);
use Slim::Utils::Log;
use Slim::Utils::Prefs;
use Slim::Utils::Misc;

use File::Spec::Functions qw(:ALL);
use FindBin qw($Bin);

use Plugins::DenonAvpControl::DenonAvpComms;
use Plugins::DenonAvpControl::Settings;

#use Data::Dumper; #used to debug array contents

# ----------------------------------------------------------------------------
# Global variables
# ----------------------------------------------------------------------------
my $pluginReady=0; 	# determines if the plugin initialization is complete
my $surroundMode=-1;# Denon Surround Mode Index
my $roomEq =-1;		# Denon Room Equilizer Index
my $dynamicEq =-1;	# Denon Dynamic Equilizer Index
my $nightMode = -1;	# Denon Night Mode Index
my $restorer = -1;	# Denon Restorer Index
my $refLevel = -1;	# Denon Ref Level Index
my $gMenuUpdate;	# Used to signal that no menu update should occur
my $getexternalvolumeinfoCoderef; #used to report use of external volume control
#my $gOrigVolCmdFuncRef;		# Original function reference in SC

# Actual power state (needed for internal tracking)
my %iOldPowerState;

# ----------------------------------------------------------------------------
# References to other classes
# my $classPlugin = undef;

# ----------------------------------------------------------------------------
my $log = Slim::Utils::Log->addLogCategory({
	'category'     => 'plugin.denonavpcontrol',
	'defaultLevel' => 'ERROR',
	'description'  => 'PLUGIN_DENONAVPCONTROL_MODULE_NAME',
});

# ----------------------------------------------------------------------------
my $prefs = preferences('plugin.denonavpcontrol');

# ----------------------------------------------------------------------------
sub initPlugin {
	my $classPlugin = shift;

	# Not Calling our parent class prevents adds it to the player UI for the audio options
	 $classPlugin->SUPER::initPlugin();

	# Initialize settings classes
	my $classSettings = Plugins::DenonAvpControl::Settings->new( $classPlugin);

	# Install callback to get client setup
	Slim::Control::Request::subscribe( \&newPlayerCheck, [['client']],[['new']]);

	# init the DenonAvpComms plugin
	Plugins::DenonAvpControl::DenonAvpComms->new( $classPlugin);

	# getexternalvolumeinfo
	$getexternalvolumeinfoCoderef = Slim::Control::Request::addDispatch(['getexternalvolumeinfo'],[0, 0, 0, \&getexternalvolumeinfoCLI]);
	$log->debug( "*** DenonAvpControl: getexternalvolumeinfoCoderef: ".$getexternalvolumeinfoCoderef."\n");
	# Register dispatch methods for Audio menu options
	$log->debug("Getting the menu requests". "\n");
	
	#        |requires Client
	#        |  |is a Query
	#        |  |  |has Tags
	#        |  |  |  |Function to call
	#        C  Q  T  F

	Slim::Control::Request::addDispatch(['avpTop'],[1, 1, 0, \&avpTop]);
	Slim::Control::Request::addDispatch(['avpSM'],[1, 1, 0, \&avpSM]);
	Slim::Control::Request::addDispatch(['avpRmEq'],[1, 1, 0, \&avpRmEq]);
	Slim::Control::Request::addDispatch(['avpDynEq'],[1, 1, 0, \&avpDynEq]);
	Slim::Control::Request::addDispatch(['avpNM'],[1, 1, 0, \&avpNM]);
	Slim::Control::Request::addDispatch(['avpRes'],[1, 1, 0, \&avpRes]);
	Slim::Control::Request::addDispatch(['avpRefLvl'],[1, 1, 0, \&avpRefLvl]);
	Slim::Control::Request::addDispatch(['avpSetSM', '_surroundMode', '_oldSurroundMode'],[1, 1, 0, \&avpSetSM]);
	Slim::Control::Request::addDispatch(['avpSetRmEq', '_roomEq', '_oldRoomEq'],[1, 1, 0, \&avpSetRmEq]);
	Slim::Control::Request::addDispatch(['avpSetDynEq', '_dynamicEq', '_oldDynamicEq'],[1, 1, 0, \&avpSetDynEq]);
	Slim::Control::Request::addDispatch(['avpSetNM', '_nightMode', '_oldNightMode'],[1, 1, 0, \&avpSetNM]);
	Slim::Control::Request::addDispatch(['avpSetRes', '_restorer', '_oldRestorer'],[1, 1, 0, \&avpSetRes]);
	Slim::Control::Request::addDispatch(['avpSetRefLvl', '_refLevel', '_oldRefLevel'],[1, 1, 0, \&avpSetRefLvl]);

}

# ----------------------------------------------------------------------------
sub newPlayerCheck {
	my $request = shift;
	my $client = $request->client();

    if ( defined($client) ) {
		$log->debug( "*** DenonAvpControl: ".$client->name()." is: " . $client);

		# Do nothing if client is not a Receiver or Squeezebox
		if( !(($client->isa( "Slim::Player::Receiver")) || ($client->isa( "Slim::Player::Squeezebox2")))) {
			$log->debug( "*** DenonAvpControl: Not a receiver or a squeezebox b \n");
			#now clear callback for those clients that are not part of the plugin
			clearCallback();
			return;
		}

		#init the client
		my $cprefs = $prefs->client($client);
		my $avpIPAddress = "HTTP://" . $cprefs->get('avpAddress') . ":23";
		my $quickSelect = $cprefs->get('quickSelect');
		my $gZone = $cprefs->get('zone');
		my $pluginEnabled = $cprefs->get('pref_Enabled');
		my $audioEnabled = $cprefs->get('pref_AudioMenu');

		# Do nothing if plugin is disabled for this client
		if ( !defined( $pluginEnabled) || $pluginEnabled == 0) {
			$log->debug( "*** DenonAvpControl: Plugin Not Enabled for: ".$client->name()."\n");
			#now clear callback for those clients that are not part of the plugin
			clearCallback();
			return;
		} else {
			$log->debug( "*** DenonAvpControl: Plugin Enabled: \n");
			$log->debug( "*** DenonAvpControl: Quick Select: " . $quickSelect . "\n");
			$log->debug( "*** DenonAvpControl: zone: " . $gZone . "\n");
			$log->debug( "*** DenonAvpControl: IP Address: " . $avpIPAddress . "\n");

			# Install callback to get client state changes
			Slim::Control::Request::subscribe( \&commandCallback, [['power', 'play', 'playlist', 'pause', 'client', 'mixer' ]], $client);			
			
			#player menu
			if ($audioEnabled == 1 && $gZone==0) {
				$log->debug("Calling the plugin menu register". "\n");
				# Create SP menu under audio settings	
				my $icon = 'plugins/DenonAvpControl/html/images/audysseysettings.png';
				my @menu = ({
					stringToken   => getDisplayName(),
					id     => 'pluginDenonAvpControl',
					menuIcon => $icon,
					weight => 9,
					actions => {
						go => {
							player => 0,
							cmd	 => [ 'avpTop' ],
						}
					}
				});
				Slim::Control::Jive::registerPluginMenu(\@menu, 'settingsPlayer' ,$client);	
			};
		}
	}
	else {
		$log->debug( "*** DenonAvpControl: NewPlayerCheck entered without a valid client. \n");
	}	
}

# ----------------------------------------------------------------------------
sub getDisplayName {
#	return 'PLUGIN_DENONAVPCONTROL_MODULE_NAME';
	return 'PLUGIN_DENONAVPCONTROL';
}

# ----------------------------------------------------------------------------
sub shutdownPlugin {
	Slim::Control::Request::unsubscribe(\&newPlayerCheck);
  clearCallback();
}

# ----------------------------------------------------------------------------
sub clearCallback {

	$log->debug( "*** DenonAvpControl:Clearing command callback" . "\n");
	Slim::Control::Request::unsubscribe(\&commandCallback);

	# Give up rerouting
}

# ----------------------------------------------------------------------------
# Handlers for player based menu integration
# ----------------------------------------------------------------------------

# Generates the top menus as elements of the Player Audio menu
sub avpTop {
	my $request = shift;
	my $client = $request->client();
	my $cprefs = $prefs->client($client);
	
	my $pluginEnabled = $cprefs->get('pref_Enabled');
	my $iPower = $client->power();
	my $avpIPAddress = "HTTP://" . $cprefs->get('avpAddress') . ":23";
	my $refIcon = 'plugins/DenonAvpControl/html/images/mixersmall.png';

	# Do nothing if plugin is disabled for this client or the power is off
	if ( !defined( $pluginEnabled) || $pluginEnabled == 0 || $iPower == 0) {
		$log->debug( "Plugin Not Enabled for menu: \n");
		return;
	}
	
	$gMenuUpdate = 0; #suspend updating menus from avp
	$log->debug("Adding the menu elements to the audio menu". "\n");
	my $surroundIcon = 'plugins/DenonAvpControl/html/images/surroundmodes.png';
	my @menu = ();
	push @menu,	{
			text => $client->string('PLUGIN_DENONAVPCONTROL_AUDIO1'),
			id      => 'surroundmode',
			menuIcon => $surroundIcon,
			actions  => {
				go  => {
					player => 0,
					cmd    => [ 'avpSM' ],
					params	=> {
						menu => 'avpSM',
					},
				},
			},
		};
	push @menu,	{
			text => $client->string('PLUGIN_DENONAVPCONTROL_AUDIO2'),
			id      => 'roomequilizer',
			menuIconID => 'pluginDenonAvpControl',
			actions  => {
				go  => {
					player => 0,
					cmd    => [ 'avpRmEq' ],
					params	=> {
						menu => 'avpRmEq',
					},
				},
			},
		};
	push @menu,	{
			text => $client->string('PLUGIN_DENONAVPCONTROL_AUDIO3'),
			id      => 'dynamicequilizer',
			menuIconID => 'dynamicplaylist',
			actions  => {
				go  => {
					player => 0,
					cmd    => [ 'avpDynEq' ],
					params	=> {
						menu => 'avpDynEq',
					},
				},
			},
		};
	if ($dynamicEq == 2) {
		push @menu,	{
			text => $client->string('PLUGIN_DENONAVPCONTROL_AUDIO4'),
			id      => 'nightmode',
			menuIconID => 'settingsSleep',
			actions  => {
				go  => {
					player => 0,
					cmd    => [ 'avpNM' ],
					params	=> {
						menu => 'avpNM',
					},
				},
			},
		};
	};
	push @menu,	{
			text => $client->string('PLUGIN_DENONAVPCONTROL_AUDIO5'),
			id      => 'restorer',
			menuIconID => 'digitalinput',
			actions  => {
				go  => {
					player => 0,
					cmd    => [ 'avpRes' ],
					params	=> {
						menu => 'avpRes',
					},
				},
			},
		};
	
	push @menu,	{
			text => $client->string('PLUGIN_DENONAVPCONTROL_AUDIO6'),
			id      => 'reflevel',
			menuIcon => $refIcon,
			actions  => {
				go  => {
					player => 0,
					cmd    => [ 'avpRefLvl' ],
					params	=> {
						menu => 'avpRefLvl',
					},
				},
			},
		};

	my $numitems = scalar(@menu);
	
	$request->addResult("count", $numitems);
	$request->addResult("offset", 0);
	my $cnt = 0;
	for my $eachPreset (@menu[0..$#menu]) {
		$request->setResultLoopHash('item_loop', $cnt, $eachPreset);
		$cnt++;
	}
	
	$log->debug("done");
	$request->setStatusDone();
	
	# now check with the AVP to set the values of the modes
	Plugins::DenonAvpControl::DenonAvpComms::SendNetGetAvpSettings($client, $avpIPAddress);
}


# Generates the Surround Mode menu, which is a list of all surround modes
sub avpSM {
	my $request = shift;
	my $client = $request->client();
	my $cprefs = $prefs->client($client);
	my $avpIPAddress = "HTTP://" . $cprefs->get('avpAddress') . ":23";
	
	my @menu = ();
	my $i = 0;
	my $check;
	$gMenuUpdate = 1; # update menus from avp

	$log->debug("The value of surroundMode is:" .$surroundMode . "\n");

	while ($i <18) { #set the radio to the first item as default
		if ($i == $surroundMode) {
			$check = 1;
		} else {
			$check = 0;
		};
		push @menu, {
			text => $client->string('PLUGIN_DENONAVPCONTROL_SURMD'.($i+1)),
			radio => $check,
         actions  => {
           do  => {
               	player => 0,
               	cmd    => [ 'avpSetSM', $i , $surroundMode],
           	},
         },
		};
				
		$i++;
	}

	my $numitems = scalar(@menu);

	$request->addResult("count", $numitems);
	$request->addResult("offset", 0);
	my $cnt = 0;
	for my $eachItem (@menu[0..$#menu]) {
		$request->setResultLoopHash('item_loop', $cnt, $eachItem);
		$cnt++;
	}
	$request->setStatusDone();
	# check if menu not initialized and call AVP to see what mode its in
	if ($surroundMode == -1) {
		# call the AVP to get mode
		Plugins::DenonAvpControl::DenonAvpComms::SendNetGetAvpSettings($client, $avpIPAddress, "MS?");
	}
}

# Generates the Room Equilizer menu
sub avpRmEq {
	my $request = shift;
	my $client = $request->client();
	my $cprefs = $prefs->client($client);
	my $avpIPAddress = "HTTP://" . $cprefs->get('avpAddress') . ":23";

	my @menu = ();
	my $i = 0;
	my $check;
	$gMenuUpdate = 1; # update menus from avp

	while ($i <5) {

		if ($i == $roomEq) {
			$check = 1;
		} else {
			$check = 0;
		};

		push @menu, {
			text => $client->string('PLUGIN_DENONAVPCONTROL_RMEQ'.($i + 1)),
			radio => $check,
         actions  => {
           do  => {
               	player => 0,
               	cmd    => [ 'avpSetRmEq', $i, $roomEq ],
           	},
         },
		};
				
		$i++;
	}

	my $numitems = scalar(@menu);

	$request->addResult("count", $numitems);
	$request->addResult("offset", 0);
	my $cnt = 0;
	for my $eachItem (@menu[0..$#menu]) {
		$request->setResultLoopHash('item_loop', $cnt, $eachItem);
		$cnt++;
	}
	$request->setStatusDone();
	# check if menu not initialized and call AVP to see what mode its in
	if ($roomEq == -1) {
		# call the AVP to get mode
		Plugins::DenonAvpControl::DenonAvpComms::SendNetGetAvpSettings($client, $avpIPAddress, "PSROOM EQ: ?");
	}
}

# Generates the Dynamic Equilizer menu
sub avpDynEq {
	my $request = shift;
	my $client = $request->client();
	my $cprefs = $prefs->client($client);
	my $avpIPAddress = "HTTP://" . $cprefs->get('avpAddress') . ":23";

	my @menu = ();
	my $i = 0;
	my $check;
	$gMenuUpdate = 1; # update menus from avp

	while ($i <3) {

		if ($i == $dynamicEq) {
			$check = 1;
		} else {
			$check = 0;
		};

		push @menu, {
			text => $client->string('PLUGIN_DENONAVPCONTROL_DYNVOL'.($i + 1)),
			radio => $check,
         actions  => {
           do  => {
               	player => 0,
               	cmd    => [ 'avpSetDynEq', $i, $dynamicEq ],
           	},
         },
		};
				
		$i++;
	}

	my $numitems = scalar(@menu);

	$request->addResult("count", $numitems);
	$request->addResult("offset", 0);
	my $cnt = 0;
	for my $eachItem (@menu[0..$#menu]) {
		$request->setResultLoopHash('item_loop', $cnt, $eachItem);
		$cnt++;
	}
	$request->setStatusDone();
	# check if menu not initialized and call AVP to see what mode its in
	if ($dynamicEq == -1) {
		# call the AVP to get mode
		Plugins::DenonAvpControl::DenonAvpComms::SendNetGetAvpSettings($client, $avpIPAddress, "PSDYN ?");
	}
}

# Generates the Night Mode menu
sub avpNM {
	my $request = shift;
	my $client = $request->client();
	my $cprefs = $prefs->client($client);
	my $avpIPAddress = "HTTP://" . $cprefs->get('avpAddress') . ":23";

	my @menu = ();
	my $i = 0;
	my $check;
	$gMenuUpdate = 1; # update menus from avp

	while ($i <3) {
		if ($i == $nightMode) {
			$check = 1;
		} else {
			$check = 0;
		};
		push @menu, {
			text => $client->string('PLUGIN_DENONAVPCONTROL_NIGHT'.($i + 1)),
			radio => $check,
         actions  => {
           do  => {
               	player => 0,
               	cmd    => [ 'avpSetNM', $i, $nightMode ],
               	params => {
               	},
           	},
         },
		};
				
		$i++;
	}

	my $numitems = scalar(@menu);

	$request->addResult("count", $numitems);
	$request->addResult("offset", 0);
	my $cnt = 0;
	for my $eachItem (@menu[0..$#menu]) {
		$request->setResultLoopHash('item_loop', $cnt, $eachItem);
		$cnt++;
	}
	$request->setStatusDone();

	# check if menu not initialized and call AVP to see what mode its in
	if ($nightMode == -1) {
		# call the AVP to get mode
		Plugins::DenonAvpControl::DenonAvpComms::SendNetGetAvpSettings($client, $avpIPAddress, "PSDYNSET ?");
	}

}

# Generates the Restorer menu
sub avpRes {
	my $request = shift;
	my $client = $request->client();
	my $cprefs = $prefs->client($client);
	my $avpIPAddress = "HTTP://" . $cprefs->get('avpAddress') . ":23";

	my @menu = ();
	my $i = 0;
	my $check;
	$gMenuUpdate = 1; # update menus from avp

	while ($i <4) {
		if ($i == $restorer) {
			$check = 1;
		} else {
			$check = 0;
		};
		push @menu, {
			text => $client->string('PLUGIN_DENONAVPCONTROL_REST'.($i + 1)),
			radio => $check,
         actions  => {
           do  => {
               	player => 0,
               	cmd    => [ 'avpSetRes' , $i, $restorer],
               	params => {
               	},
           	},
         },
		};
				
		$i++;
	}

	my $numitems = scalar(@menu);

	$request->addResult("count", $numitems);
	$request->addResult("offset", 0);
	my $cnt = 0;
	for my $eachItem (@menu[0..$#menu]) {
		$request->setResultLoopHash('item_loop', $cnt, $eachItem);
		$cnt++;
	}
	$request->setStatusDone();

	# check if menu not initialized and call AVP to see what mode its in
	if ($restorer == -1) {
		# call the AVP to get mode
		Plugins::DenonAvpControl::DenonAvpComms::SendNetGetAvpSettings($client, $avpIPAddress, "PSRSTR ?");
	}
}

# Generates the Reference Level menu
sub avpRefLvl {
	my $request = shift;
	my $client = $request->client();
	my $cprefs = $prefs->client($client);
	my $avpIPAddress = "HTTP://" . $cprefs->get('avpAddress') . ":23";

	my @menu = ();
	my $i = 0;
	my $check;
	$gMenuUpdate = 1; # update menus from avp

	while ($i <4) {
		if ($i == $refLevel) {
			$check = 1;
		} else {
			$check = 0;
		};
		push @menu, {
			text => $client->string('PLUGIN_DENONAVPCONTROL_REF_LEVEL'.($i * 5)),
			radio => $check,
         actions  => {
           do  => {
               	player => 0,
               	cmd    => [ 'avpSetRefLvl' , $i, $refLevel],
               	params => {
               	},
           	},
         },
		};
				
		$i++;
	}

	my $numitems = scalar(@menu);

	$request->addResult("count", $numitems);
	$request->addResult("offset", 0);
	my $cnt = 0;
	for my $eachItem (@menu[0..$#menu]) {
		$request->setResultLoopHash('item_loop', $cnt, $eachItem);
		$cnt++;
	}
	$request->setStatusDone();

	# check if menu not initialized and call AVP to see what mode its in
	if ($refLevel == -1) {
		# call the AVP to get mode
		Plugins::DenonAvpControl::DenonAvpComms::SendNetGetAvpSettings($client, $avpIPAddress, "PSREFLEV ?");
	}
}

# ----------------------------------------------------------------------------
# Callback to get client state changes
# ----------------------------------------------------------------------------
sub commandCallback {
	my $request = shift;

	my $client = $request->client();
	# Do nothing if client is not defined
	if(!defined( $client) || $pluginReady==0) {
		$pluginReady=1;
		return;
	}
	my $cprefs = $prefs->client($client);
	my $gZone = $cprefs->get('zone');
	my $DenonVol;		# Denon Volume setting

	$log->debug( "*** DenonAvpControl: commandCallback() p0: " . $request->{'_request'}[0] . "\n");
	$log->debug( "*** DenonAvpControl: commandCallback() p1: " . $request->{'_request'}[1] . "\n");

	my $gPowerOnDelay = $cprefs->get('delayOn');	# Delay to turn on amplifier after player has been turned on (in seconds)
	my $gPowerOffDelay = $cprefs->get('delayOff');	# Delay to turn off amplifier after player has been turned off (in seconds)
	my $volumeSynch = $cprefs->get('pref_VolSynch');

	# Get power on and off commands
	# Sometimes we do get only a power command, sometimes only a play/pause command and sometimes both
	if ( $request->isCommand([['power']])
	 || $request->isCommand([['play']])
	 || $request->isCommand([['pause']])
	 || $request->isCommand([['playlist'], ['newsong']]) ) {
		$log->debug("*** DenonAvpControl: power request1: $request \n");
		my $iPower = $client->power();
		
		# Check with last known power state -> if different switch modes
		if ( $iOldPowerState{$client} ne $iPower) {
			$iOldPowerState{$client} = $iPower;

			$log->debug("*** DenonAvpControl: commandCallback() Power: $iPower \n");

			if( $iPower == 1) {
				# If player is turned on within delay, kill delayed power off timer
				Slim::Utils::Timers::killTimers( $client, \&handlePowerOff); 

				# Set timer to power on amplifier after a delay
				Slim::Utils::Timers::setTimer( $client, (Time::HiRes::time() + $gPowerOnDelay), \&handlePowerStatus); 
#				Slim::Utils::Timers::setTimer( $client, (Time::HiRes::time() + $gPowerOnDelay), \&handlePowerOn); 
			} else {
				# If player is turned off within delay, kill delayed power on timer
				Slim::Utils::Timers::killTimers( $client, \&handlePowerStatus); 
#				Slim::Utils::Timers::killTimers( $client, \&handlePowerOn); 

				# Set timer to power off amplifier after a delay
				Slim::Utils::Timers::setTimer( $client, (Time::HiRes::time() + $gPowerOffDelay), \&handlePowerOff); 
			}
		} elsif ($request->isCommand([['playlist'], ['newsong']])
			  || $request->isCommand([['pause']])) {
			# see if the user wants to synch the volume
			if ($volumeSynch == 1 && $gZone == 0) { #only works for main zone
				&handleVolumeRequest ($client);		
			}
		}
	# Get clients volume adjustment
	} elsif ( $request->isCommand([['mixer'], ['volume']])) {
		#check to make sure this is not us making the request first
		my $selfInitiated = $request->getResult('denonavpcontrolInitiated');
		if (! $selfInitiated) {
			my $volAdjust = $request->getParam('_newvalue');

			$log->debug("*** DenonAvpControl:new SB vol: $volAdjust  \n");
			
			my $char1 = substr($volAdjust,0,1);
			
			#if it's an incremental adjustment, get the new volume from the client
			if (($char1 eq '-') || ($char1 eq '+')) {
				$volAdjust = $client->volume(); 
				$log->debug("*** DenonAvpControl:current vol: $volAdjust  \n");				
			}

			my $maxVolume = $cprefs->get('maxVol');	# max volume user wants AVP to be set to
			$log->debug("*** DenonAvpControl:max volume: $maxVolume \n");
			my $subVol = sprintf("%3d",(80 + $maxVolume) * sqrt($volAdjust));
			my $digit = int(substr($subVol,2,1));
			$subVol = int(($subVol+2)/10);  #round up for values of .8 and .9
			my $width = 2;
			if (($digit>2) && ($digit<8)) {
				$subVol = $subVol*10 + 5;
				$width = 3;
			}
			$DenonVol = sprintf("%0*d",$width,$subVol); 
			
			$log->debug("*** DenonAvpControl:Calc Vol: $DenonVol \n");
			# kill any volume changes that may be going on within the timer
			Slim::Utils::Timers::killTimers( $client, \&handleVolChanges);
			# delay the volume changes by .125 second to give the AVP time to catch up
			Slim::Utils::Timers::setTimer( $client, (Time::HiRes::time() + .125), \&handleVolChanges, $DenonVol);			
		}
	}
}


# ----------------------------------------------------------------------------
sub handleVolChanges {
	my $client = shift;
	my $DenonVol = shift;
	my $cprefs = $prefs->client($client);
	my $avpIPAddress = "HTTP://" . $cprefs->get('avpAddress') . ":23";
	my $zone = $cprefs->get('zone');

	$log->debug("*** DenonAvpControl: VolChange: $DenonVol \n");
	Plugins::DenonAvpControl::DenonAvpComms::SendNetAvpVol($client, $avpIPAddress, $DenonVol, $zone);
}

# ----------------------------------------------------------------------------
sub handlePowerOn {
	my $class = shift;
	my $client = shift;
	my $cprefs = $prefs->client($client);
	my $avpIPAddress = "HTTP://" . $cprefs->get('avpAddress') . ":23";
	my $zone = $cprefs->get('zone');

	$log->debug("*** DenonAvpControl: handling Power ON \n");
	Plugins::DenonAvpControl::DenonAvpComms::SendNetAvpOn($client, $avpIPAddress, $zone);
}

# ----------------------------------------------------------------------------
sub handlePowerOn2 {
	my $class = shift;
	my $client = shift;
	my $cprefs = $prefs->client($client);
	my $avpIPAddress = "HTTP://" . $cprefs->get('avpAddress') . ":23";
	my $quickSelect = $cprefs->get('quickSelect');
	my $gZone = $cprefs->get('zone');
	my $gQuickDelay = $cprefs->get('delayQuick');	# Delay to set Quick setting (in seconds)

	$log->debug("*** DenonAvpControl: handling Power ON 2\n");
	if ( $quickSelect != 0 && $gZone == 0) {
		# only if quick select is turned on for master only
#		&handleQuickSelect($client);
		Slim::Utils::Timers::setTimer( $client, (Time::HiRes::time() + $gQuickDelay), \&handleQuickSelect); 
	} else {
		# no quick select so synch volumes
		Slim::Utils::Timers::setTimer( $client, (Time::HiRes::time() + 1), \&handleVolumeRequest); 
	}
}

# ----------------------------------------------------------------------------
sub handlePowerStatus {
	my $client = shift;
	my $cprefs = $prefs->client($client);
	my $avpIPAddress = "HTTP://" . $cprefs->get('avpAddress') . ":23";
	my $zone = $cprefs->get('zone');

	$log->debug("*** DenonAvpControl: handling Power ON Status \n");
	Plugins::DenonAvpControl::DenonAvpComms::SendNetAvpPowerStatus($client, $avpIPAddress, $zone);
}
# ----------------------------------------------------------------------------
sub handleVolumeRequest {
	my $client = shift;
	my $cprefs = $prefs->client($client);
	my $avpIPAddress = "HTTP://" . $cprefs->get('avpAddress') . ":23";

	$log->debug( "*** DenonAvpControl: this vol player: " . $client . "\n");

	#now check with the AVP and get its current volume to set the SC volume
	Plugins::DenonAvpControl::DenonAvpComms::SendNetAvpVolSetting($client, $avpIPAddress);
	# /updateSqueezeVol will set the SB with the current amp setting
}

# ----------------------------------------------------------------------------
sub handlePowerOff {
	my $client = shift;
	my $cprefs = $prefs->client($client);
	my $avpIPAddress = "HTTP://" . $cprefs->get('avpAddress') . ":23";
	my $zone = $cprefs->get('zone');

	$log->debug("*** DenonAvpControl: handling Power OFF \n");
	Plugins::DenonAvpControl::DenonAvpComms::SendNetAvpStandBy($client, $avpIPAddress, $zone);
}

# ----------------------------------------------------------------------------
sub handleQuickSelect {
	my $client = shift;
	my $cprefs = $prefs->client($client);
	my $avpIPAddress = "HTTP://" . $cprefs->get('avpAddress') . ":23";
	my $quickSelect = $cprefs->get('quickSelect');

	$log->debug("*** DenonAvpControl: handling quick select \n");
	Plugins::DenonAvpControl::DenonAvpComms::SendNetAvpQuickSelect($client, $avpIPAddress, $quickSelect);
}

# ----------------------------------------------------------------------------
sub updateSqueezeVol { #used to sync SB vol with AVP
	my $class = shift;
	my $client = shift;
	my $avpVol = shift;

	$log->debug( "*** DenonAvpControl: The Client is: " . $client . "\n");
	$log->debug( "*** DenonAvpControl: avp vol: " . $avpVol . "\n");
	# change the volume to the SC value from the AVP
	my $maxVolume = $prefs->client($client)->get('maxVol');	# max volume user wants AVP to be set to
	$log->debug("*** DenonAvpControl:max volume: $maxVolume \n");
	if ( (length($avpVol) < 3) || (substr($avpVol,2,1) ne '5') ) {
		$avpVol = substr($avpVol,0,2) * 10;
	}
	my $volAdjust = sprintf("%d", (($avpVol / (80 + $maxVolume))**2) + 0.5);
	$log->debug("*** DenonAvpControl: New SB Vol for AVP: " . $volAdjust . "\n");
	if ($volAdjust > 100) {
		$volAdjust = 100;
	}
	my $request = $client->execute([('mixer', 'volume', $volAdjust)]);
	# Add a result so we can detect our own volume adjustments, to prevent a feedback loop
	$request->addResult('denonavpcontrolInitiated', 1);
}

# ----------------------------------------------------------------------------
sub avpSetSM { # used to set the AVP surround mode
	my $request = shift;
	my $client = $request->client();
	my $cprefs = $prefs->client($client);

	my $avpIPAddress = "HTTP://" . $cprefs->get('avpAddress') . ":23";
	my $sMode = $request->getParam('_surroundMode'); #surround mode index
	my $sOldMode = $request->getParam('_oldSurroundMode'); #old surround mode index
	if ($sMode != $sOldMode) { #change the value
		Plugins::DenonAvpControl::DenonAvpComms::SendNetAvpSurroundMode($client, $avpIPAddress, $sMode);
		$surroundMode = $ sMode;
	}
	$request->setStatusDone();
}

# ----------------------------------------------------------------------------
sub updateSurroundMode { #used to sync Surround Mode with AVP
	my $class = shift;
	my $client = shift;
	$surroundMode = shift;
	my $request;

	$log->debug("*** DenonAvpControl: New SM is: " . $surroundMode. "\n");
	
	if ($gMenuUpdate) {
		Slim::Control::Request::executeRequest( $client, [ 'avpSM' ] ); 
#		Slim::Control::Jive::refreshPluginMenus($client);
	}
}


# ----------------------------------------------------------------------------
sub avpSetRmEq { # used to set the AVP room equilizer mode
	my $request = shift;
	my $client = $request->client();
	my $cprefs = $prefs->client($client);
	my $avpIPAddress = "HTTP://" . $cprefs->get('avpAddress') . ":23";

	my $sMode = $request->getParam('_roomEq'); #Room eq index
	my $sOldMode = $request->getParam('_oldRoomEq'); #Room eq index
	$log->debug("sMode: $sMode \n");
	if ($sMode != $sOldMode) {
		Plugins::DenonAvpControl::DenonAvpComms::SendNetAvpRoomMode($client, $avpIPAddress, $sMode);
		$roomEq = $ sMode;
	}
	$log->debug("roomEq: $roomEq \n");

	$request->setStatusDone();
}

# ----------------------------------------------------------------------------
sub updateRoomEq { #used to sync Room EQ with AVP
	my $class = shift;
	my $client = shift;
	$roomEq = shift;
	$log->debug("*** DenonAvpControl: New Room EQ is: " . $roomEq. "\n");

	if ($gMenuUpdate) {
		Slim::Control::Request::executeRequest( $client, [ 'avpRmEq' ] ); 
	}
}

# ----------------------------------------------------------------------------
sub avpSetDynEq{ # used to set the AVP dynamic equilizer mode
	my $request = shift;
	my $client = $request->client();
	my $cprefs = $prefs->client($client);
	my $avpIPAddress = "HTTP://" . $cprefs->get('avpAddress') . ":23";

	my $sMode = $request->getParam('_dynamicEq'); #dynamic equilizer mode
	my $sOldMode = $request->getParam('_oldDynamicEq'); # old dynamic equilizer mode
	$log->debug("sMode: $sMode \n");
	if ($sMode != $sOldMode) {
		Plugins::DenonAvpControl::DenonAvpComms::SendNetDynamicEq($client, $avpIPAddress, $sMode);
		$dynamicEq = $sMode;
	}

	$log->debug("dynamicEq: $dynamicEq \n");

	$request->setStatusDone();
}

# ----------------------------------------------------------------------------
sub updateDynEq { #used to sync Dynamic EQ with AVP
	my $class = shift;
	my $client = shift;
	$dynamicEq = shift;
	$log->debug("*** DenonAvpControl: Dynamic EQ is: " . $dynamicEq. "\n");

	if ($gMenuUpdate) {
		Slim::Control::Request::executeRequest( $client, [ 'avpDynEq' ] ); 
	}
}

# ----------------------------------------------------------------------------
sub avpSetNM { # used to set the AVP Night mode
	my $request = shift;
	my $client = $request->client();
	my $cprefs = $prefs->client($client);
	my $avpIPAddress = "HTTP://" . $cprefs->get('avpAddress') . ":23";

	my $sMode = $request->getParam('_nightMode'); #night mode index
	my $sOldMode = $request->getParam('_oldNightMode'); # old night mode index
	if ($sMode != $sOldMode) {
		Plugins::DenonAvpControl::DenonAvpComms::SendNetAvpNightMode($client, $avpIPAddress, $sMode);
		$nightMode = $sMode;
	}
	$log->debug("nightMode: $nightMode \n");

	$request->setStatusDone();
}

# ----------------------------------------------------------------------------
sub updateNM { #used to sync Night Mode with AVP
	my $class = shift;
	my $client = shift;
	$nightMode = shift;
	$log->debug("*** DenonAvpControl: Night Mode is: " . $nightMode. "\n");

	if ($gMenuUpdate) {
		Slim::Control::Request::executeRequest( $client, [ 'avpNM' ] ); 
	}
}

# ----------------------------------------------------------------------------
sub avpSetRes { # used to set the AVP restorer mode
	my $request = shift;
	my $client = $request->client();
	my $cprefs = $prefs->client($client);
	my $avpIPAddress = "HTTP://" . $cprefs->get('avpAddress') . ":23";

	my $sMode = $request->getParam('_restorer'); #restorer index
	my $sOldMode = $request->getParam('_oldRestorer'); # old restorer index
	if ($sMode != $sOldMode) {
		Plugins::DenonAvpControl::DenonAvpComms::SendNetAvpRestorerMode($client, $avpIPAddress, $sMode);
		$restorer = $sMode;
	}

	$log->debug("restorer: $restorer \n");

	$request->setStatusDone();
}

# ----------------------------------------------------------------------------
sub updateRestorer { #used to sync Restorer with AVP
	my $class = shift;
	my $client = shift;
	$restorer = shift;
	$log->debug("*** DenonAvpControl: Restorer Mode is: " . $restorer. "\n");

	if ($gMenuUpdate) {
		Slim::Control::Request::executeRequest( $client, [ 'avpRes' ] ); 
	}
}

# ----------------------------------------------------------------------------
sub avpSetRefLvl { # used to set the AVP restorer mode
	my $request = shift;
	my $client = $request->client();
	my $cprefs = $prefs->client($client);
	my $avpIPAddress = "HTTP://" . $cprefs->get('avpAddress') . ":23";

	my $sMode = $request->getParam('_refLevel'); #ref level index
	my $sOldMode = $request->getParam('_oldRefLevel'); # old ref level index
	if ($sMode != $sOldMode) {
		Plugins::DenonAvpControl::DenonAvpComms::SendNetRefLevel($client, $avpIPAddress, $sMode);
		$refLevel = $sMode;
	}

	$log->debug("ref level: $refLevel \n");

	$request->setStatusDone();
}

# ----------------------------------------------------------------------------
sub updateRefLevel { #used to sync reference level with AVP
	my $class = shift;
	my $client = shift;
	$refLevel = shift;
	$log->debug("*** DenonAvpControl: Reference Level is: " . $refLevel. "\n");

	if ($gMenuUpdate) {
		Slim::Control::Request::executeRequest( $client, [ 'avpRefLevel' ] ); 
	}
}

# ----------------------------------------------------------------------------
# used to determine if connection used is digital
# We don't care if the user wants to use this in analog or non 100%
sub denonAvpInit {
	my $client = shift;
}

# ----------------------------------------------------------------------------
# determine if this player is using the DenonAvpControl plugin and its enabled
sub usingDenonAvpControl() {
	my $client = shift;
	my $cprefs = $prefs->client($client);
	my $pluginEnabled = $cprefs->get('pref_Enabled');

	# cannot use DS if no digital out (as with Baby)
	if ( (!$client->hasDigitalOut()) || ($client->model() eq 'baby')) {
		return 0;
	}
 	if ($pluginEnabled == 1) {
		return 1;
	}
	return 0;
}

# ----------------------------------------------------------------------------
# external volume indication support code
# used by iPeng and other controllers
sub getexternalvolumeinfoCLI {
	my @args = @_;
	&reportOnOurPlayers();
	if ( defined($getexternalvolumeinfoCoderef) ) {
		# chain to the next implementation
		return &$getexternalvolumeinfoCoderef(@args);
	}
	# else we're authoritative
	my $request = $args[0];
	$request->setStatusDone();
}

# ----------------------------------------------------------------------------
sub reportOnOurPlayers() {
	# loop through all currently attached players
	foreach my $client (Slim::Player::Client::clients()) {
		if (&usingDenonAvpControl($client) ) {
			# using our volume control, report on our capabilities
			$log->debug("Note that ".$client->name()." uses us for external volume control");
			Slim::Control::Request::notifyFromArray($client, ['getexternalvolumeinfo', 0,   1,   string(&getDisplayName())]);
#			Slim::Control::Request::notifyFromArray($client, ['getexternalvolumeinfo', 'relative:0', 'precise:1', 'plugin:DenonAvpControl']);
			# precise:1		can set exact volume
			# relative:1		can make relative volume changes
			# plugin:DenonSerial	this plugin's name
		}
	}
}
	
# --------------------------------------- external volume indication code -------------------------------
# end with something for plugin to do
1;
