#	DenonAvpComms
#
#	Author:	Chris Couper <chris(dot)c(dot)couper(at)gmail(dot)com>
#
#	Copyright (c) 2008-2021 Chris Couper
#	All rights reserved.
#
#	----------------------------------------------------------------------
#	Function:	Send HTTP Commands to support DenonAvpControl plugin
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
package Plugins::DenonAvpControl::DenonAvpComms;

use strict;
use base qw(Slim::Networking::Async);

use URI;
use Slim::Utils::Log;
use Slim::Utils::Misc;
use Slim::Utils::Prefs;
use Socket qw(:crlf);

# ----------------------------------------------------------------------------
my $log = Slim::Utils::Log->addLogCategory({
	'category'     => 'plugin.denonavpcontrol',
	'defaultLevel' => 'ERROR',
	'description'  => 'PLUGIN_DENONAVPCONTROL_MODULE_NAME',
});

# ----------------------------------------------------------------------------
# Global Variables
# ----------------------------------------------------------------------------
	my $prefs = preferences('plugin.denonavpcontrol'); #name of preferences
	my $self;
	my $gGetPSModes=0;	# looping through the PS modes

	my @surroundModes = ( # the avp surround mode commands
		'MSDIRECT',
		'MSPURE DIRECT',
		'MSSTEREO',
		'MSSTANDARD',
		'MSDOLBY DIGITAL',
		'MSDTS SURROUND',
		'MSMCH STEREO',
		'MSDOLBY H/P',
		'MSHOME THX CINEMA',
		'MSWIDE SCREEN',
		'MS7CH STEREO',
		'MSSUPER STADIUM',
		'MSROCK ARENA',
		'MSJAZZ CLUB',
		'MSCLASSIC CONCERT',
		'MSMONO MOVIE',
		'MSMATRIX',
		'MSVIDEO GAME',
		'MSVIRTUAL'
		);
	my @roomModes = ( # the avp room equilizer modes
		'PSROOM EQ:AUDYSSEY',
		'PSROOM EQ:BYP.LR',
		'PSROOM EQ:FLAT',
		'PSROOM EQ:MANUAL',
		'PSROOM EQ:OFF'
		);
	my @nightModes = ( # the avp night modes
		'PSDYNSET NGT',
		'PSDYNSET EVE',
		'PSDYNSET DAY',
		);
	my @restorerModes = ( # the avp restorer modes
		'PSRSTR OFF',
		'PSRSTR MODE1',
		'PSRSTR MODE2',
		'PSRSTR MODE3',
		);
	my @dynamicVolModes = ( # the avp dynamic volume modes
		'PSDYN OFF',
		'PSDYN ON',
		'PSDYN VOL'
		);
	my @refLevelModes = ( # the avp reference level modes
		'PSREFLEV 0',
		'PSREFLEV 5',
		'PSREFLEV 10',
		'PSREFLEV 15',
		);
# ----------------------------------------------------------------------------
# References to other classes
# ----------------------------------------------------------------------------
my $classPlugin		= undef;

# ----------------------------------------------------------------------------
sub new {
	my $ref = shift;
	$classPlugin = shift;

	$log->debug( "*** DenonAvpControl::DenonAvpComms::new() " . $classPlugin . "\n");
	$self = $ref->SUPER::new;
}

# ----------------------------------------------------------------------------
sub SendNetAvpVol {
	my $client = shift;
	my $url = shift;
	my $vol = shift;
	my $zone = shift;
	my $request;

	if ($zone == 0 ) {
		$request= "MV" .  $vol . $CR ;
	} elsif ($zone == 1 ) {
		$request= "Z2" .  $vol . $CR ;
	} elsif ($zone == 2 ) {
		$request= "Z3" .  $vol . $CR ;
	} else {
		$request= "Z4" .  $vol . $CR ;
	}
	$log->debug("Calling writemsg for volume command: $request");	
	writemsg($request, $client, $url);
}

# ----------------------------------------------------------------------------
sub SendNetAvpVolSetting {
	my $client = shift;
	my $url = shift;

	my $request = "MV?" . $CR ;
#	writemsg($request, $client, $url, 2);
	writemsg($request, $client, $url);
}

# ----------------------------------------------------------------------------
sub SendNetAvpSurroundMode {
	my $client = shift;
	my $url = shift;
	my $mode = shift;

	my $request = $surroundModes[$mode] . $CR ;
	writemsg($request, $client, $url);
}

# ----------------------------------------------------------------------------
sub SendNetAvpRoomMode {
	my $client = shift;
	my $url = shift;
	my $mode = shift;

	my $request = $roomModes[$mode] . $CR ;
	writemsg($request, $client, $url);
}

# ----------------------------------------------------------------------------
sub SendNetAvpNightMode {
	my $client = shift;
	my $url = shift;
	my $mode = shift;

	my $request = $nightModes[$mode] . $CR ;
	writemsg($request, $client, $url);
}

# ----------------------------------------------------------------------------
sub SendNetAvpRestorerMode {
	my $client = shift;
	my $url = shift;
	my $mode = shift;

	my $request = $restorerModes[$mode] . $CR ;
	writemsg($request, $client, $url);
}

# ----------------------------------------------------------------------------
sub SendNetDynamicEq {
	my $client = shift;
	my $url = shift;
	my $mode = shift;

	$log->debug("Calling writemsg for dynamic eq command");	
	my $request = $dynamicVolModes[$mode] . $CR ;
	writemsg($request, $client, $url);
}

# ----------------------------------------------------------------------------
sub SendNetRefLevel {
	my $client = shift;
	my $url = shift;
	my $mode = shift;

	$log->debug("Calling writemsg for reference level command");	
	my $request = $refLevelModes[$mode] . $CR ;
	writemsg($request, $client, $url);
}

# ----------------------------------------------------------------------------
sub SendNetGetAvpSettings {
	my $client = shift;
	my $url = shift;
	my $sMode = shift;
	my $request;

	if (!$sMode) {
		$gGetPSModes = 1; #its the main menu looking for all settings
		$request= "MS?" . $CR ;
	} else {
		$gGetPSModes = -1; #its the index menus looking for one setting
		$request= $sMode . $CR ;	
	}
	writemsg($request, $client, $url);
}

# ----------------------------------------------------------------------------
sub LoopGetAvpSettings {
	my $client = shift;
	my $url = shift;
	Slim::Utils::Timers::killTimers( $client, \&SendTimerLoopRequest);
	Slim::Utils::Timers::setTimer( $client, (Time::HiRes::time() + .3), \&SendTimerLoopRequest, $url);	
}

# ----------------------------------------------------------------------------
sub SendTimerLoopRequest {
	my $client = shift;
	my $url = shift;
	my $request;

	if ($gGetPSModes == 2) {
		$request= "PSROOM EQ: ?" . $CR ;
	} elsif ($gGetPSModes == 3) {
		$request= "PSDYN ?" . $CR ;
	} elsif ($gGetPSModes == 4) {
		$request= "PSDYNSET ?" . $CR ;
	} elsif ($gGetPSModes == 5) {
		$request= "PSRSTR ?" . $CR ;
	} elsif ($gGetPSModes == 6) {
		$request= "PSREFLEV ?" . $CR ;
	} else {
		$gGetPSModes = -1; #cancel it, we are done	
	}
	writemsg($request, $client, $url);	  
}

# ----------------------------------------------------------------------------
sub SendNetAvpMuteStatus {
	my $client = shift;
	my $url = shift;
	my $timeout = 1;
	my $request = "MU?" . $CR ;	

	$log->debug("Calling query for mute status");	
	writemsg($request, $client, $url, $timeout);
}

# ----------------------------------------------------------------------------
sub SendNetAvpMuteToggle {
	my $client = shift;
	my $url = shift;
	my $zone = shift;
	my $muteToggle = shift;
	my $timeout = 1;
	my $request;
	
	if ($zone == 0 ) {
		$request= "" ;
	} elsif ($zone == 1 ) {
		$request= "Z2" ;
	} elsif ($zone == 2 ) {
		$request= "Z3" ;
	} else {
		$request = "Z4" ;
	}

	if ($muteToggle == 1) {
		$request = $request . "MUON" . $CR ;
	}
	else {
		$request = $request . "MUOFF" . $CR ;
	}
	
	$log->debug("Calling writemsg for Mute command");	
	writemsg($request, $client, $url, $timeout);
}

# ----------------------------------------------------------------------------
sub SendNetAvpPowerStatus {
	my $client = shift;
	my $url = shift;
	my $zone = shift;
	my $request;
#	my $timeout = 1;
	my $timeout = 2;

	$log->debug("Calling query for zone state");	
	if ($zone == 0 ) {
		$request= "PW?" . $CR;
	} elsif ($zone == 1 ) {
		$request= "Z2?" . $CR ;
	} elsif ($zone == 2 ) {
		$request= "Z3?" . $CR ;
	} else {
		$request = "Z4?" . $CR ;
	}
	writemsg($request, $client, $url, $timeout);
}

# ----------------------------------------------------------------------------
sub SendNetAvpOn {
	my $client = shift;
	my $url = shift;
	my $zone = shift;
	my $request;
#	my $timeout = 1;
	my $timeout = 2;

	$log->debug("Calling writemsg for On command");	
	if ($zone == 0 ) {
		$request= "PWON" . $CR;
	} elsif ($zone == 1 ) {
		$request= "Z2ON" . $CR ;
	} elsif ($zone == 2 ) {
		$request= "Z3ON" . $CR ;
	} else {
		$request = "Z4ON" . $CR ;
	}
	writemsg($request, $client, $url, $timeout);
}

# ----------------------------------------------------------------------------
sub SendNetAvpStandBy {
	my $client = shift;
	my $url = shift;
	my $zone = shift;
	my $request;
	
	$log->debug("Calling writemsg for Standby command");
	if ($zone == 0 ) {
		$request= "PWSTANDBY" . $CR ;
	} elsif ($zone == 1 ) {
		$request= "Z2OFF" . $CR ;
	} elsif ($zone == 2 ) {
		$request= "Z3OFF" . $CR ;
	} else {
		$request= "Z4OFF" . $CR ;
	}
	writemsg($request, $client, $url);
}

# ----------------------------------------------------------------------------
sub SendNetAvpQuickSelect {
	my $client = shift;
	my $url = shift;
	my $quickSelect = shift;
	my $zone = shift;
	my $request;
	my $timeout = 5;

	$log->debug("Calling writemsg for quick select command");	
	if ($zone == 0 ) {
		$request = "MS";
	} else {
		$zone++;
		$request = "Z" . $zone;
	}
	$request = $request . "QUICK" . $quickSelect . $CR;
	$log->debug("Request is: " . $request);
	writemsg($request, $client, $url, $timeout);
}

# ----------------------------------------------------------------------------
sub writemsg {
	my $request = shift;
	my $client = shift;
	my $url = shift;
	my $timeout = shift;	

#	$log->debug("DenonAVP Command url: " . $url);

	my $u = URI->new($url);
	my @pass = [ $request, $client ];

	if (!$timeout) {
#		$timeout = .125;
		$timeout = .500;
		
	}

	$self->write_async( {
		host        => $u->host,
		port        => $u->port,
		content_ref => \$request,
		Timeout     => $timeout,
		skipDNS     => 1,
		onError     => \&_error,
		onRead      => \&_read,
		passthrough => [ $url, @pass ],
		} );
	$log->debug("Sent AVP command request: " . $request);
}

# ----------------------------------------------------------------------------
sub _error {
	my $self  = shift;
	my $errormsg = shift;
	my $url   = shift;
	my $track = shift;
	my $args  = shift;
	
	$log->debug("error routine called");

	my @track = @$track;
	my $request = @track[0];
	my $client = @track[1];
	
	my $error = "error connecting to url: error=$errormsg url=$url";
	$log->warn($error);
	
	$self->disconnect;
	
	if ($request =~ m/PW\?\r/ || $request =~ m/Z\d\?\r/) {	# power status timed out
		$log->debug("Calling HandlePowerOn\n");	
		$classPlugin->handlePowerOn($client);
	} else {		
		$gGetPSModes = 0; # we had an error so cancel anymore outstanding requests
	}
}

sub getCRLine($$) {
	my $socket = shift;
	my $maxWait = shift;
	my $buffer = '';
	my $start = Time::HiRes::time();
	my $c;
	my $r;
	B: while ( (Time::HiRes::time() - $start) < $maxWait ) {
		$r = $socket->read($c,1);
		if ( $r < 1 ) { next B; }
		$buffer .= $c;
		if ( $c eq "\r" ) { return $buffer; }
	}
	return $buffer;
}

sub clearbuf($) {
	my $socket = shift;
	my $maxWait = shift;
	my $c;
	my $r;
	my $i = 0;
	my $start = Time::HiRes::time();

	if (!$maxWait) {
		$maxWait = 1;
	}
	
	$log->debug("clearbuf routine called");
	do {
		$r = $socket->read($c,1);
		if ($r) {
			$i++;
		}
	}
	while ( (Time::HiRes::time() - $start) < $maxWait );
	
	$log->debug("clearbuf cleared ".$i." bytes\n");
}	
	
# ----------------------------------------------------------------------------
sub _read {
	my $self  = shift;
	my $url   = shift;
	my $track = shift;
	my $args  = shift;

	my $buf;
	my @track = @$track;
	my $i;
	my $sSM;
	my $request = @track[0];
	my $client = @track[1];
	my $len;
	my $subEvent;
	my $event;
	my $callbackOK; 	# the returned message when the command was successful
	my $callbackError; 	# the returned message when the command was not successful

	$log->debug("read routine called");
	$buf = &getCRLine($self->socket,.125);
	my $read = length($buf);
	
#	my $read = sysread($self->socket, $buf, 1024); # do our own sysread as $self->socket->sysread assumes http
#	my $read = sysread($self->socket, $buf, 135); # do our own sysread as $self->socket->sysread assumes http

	if ($read == 0) {
		$callbackOK = "";
		$self->_error("End of file", $url, $track, $args);
		return;
	} else {
		$callbackOK = $buf;
		$log->debug("Read ".$read."\n");
	}

	$log->debug("Buffer read ".$buf."\n");
	$log->debug("Client name: " . $client->name . "\n");	

	if ($gGetPSModes == -1 || $gGetPSModes == 6) {
		$log->debug("Disconnecting Comms Session. gGetPSModes:" . $gGetPSModes . "\n");		
		Slim::Utils::Timers::killTimers( $client, \&SendTimerLoopRequest);
		$self->disconnect;
		$gGetPSModes =0;
	}

	# see what is coming back from the AVP
	my $command = substr($request,0,3);
	$log->debug("Command is:" .$request);

	$log->debug("Subcommand is:" .$command. "\n");
	if ($request =~ m/PWON\r/ || $request =~ m/PW\?\r/) {	# power on or status
		if ($buf eq 'PWON'. $CR) {
#			&clearbuf($self->socket);
			$self->disconnect;
			$log->debug("Calling HandlePowerOn2\n");	
			$classPlugin->handlePowerOn2($client);
		} elsif ($buf eq 'PWSTANDBY'. $CR) {
			$self->disconnect;
			$log->debug("Calling HandlePowerOn\n");	
			$classPlugin->handlePowerOn($client);
		}
	} elsif ($request =~ m/Z\d\ON\r/ || $request =~ m/Z\d\?\r/) {	# zone power on or status
		if ($buf =~ m/Z\d\ON\r/) {	# zone is on
			$self->disconnect;
			$log->debug("Zone is powered on\n");
			$log->debug("Calling HandlePowerOn2\n");	
			$classPlugin->handlePowerOn2($client);
		}
		elsif ($buf =~ m/Z\d\OFF\r/) {	 # zone is off
			$self->disconnect;
			$log->debug("Calling HandlePowerOn for Zone\n");	
			$classPlugin->handlePowerOn($client);
		}	
#	} elsif (substr($request,0,7) eq 'MSQUICK') { # quick setting
	} elsif ($request =~ m/(MS|Z[2-4])QUICK\d\r/) {	# quick setting	
		if ($buf eq 'PWON'. $CR) {
#			&clearbuf($self->socket,5);
			$self->disconnect;
			$classPlugin->handleVolReq($client);
		} elsif ($buf =~ m/(MV|Z[2-4])\d\d/) {	# see if the element is a volume
			$event = substr($buf,0,2);
			if ( ($event eq 'MV' && substr($request,0,2) eq 'MS') || 
				  $event eq substr($request,0,2)) {   # make sure it's our volume
				$subEvent = substr($buf,2,3);
				# call the plugin routine to deal with the volume
#				&clearbuf($self->socket,5);
				$self->disconnect;		
				$classPlugin->updateSqueezeVol($client, $subEvent, 1);				 
			}
		}
	} elsif ($request =~ m/PWSTANDBY\r/ || $request =~ m/Z\d\OFF\r/ ) { #standby
#		if ($buf eq 'PWSTANDBY'. $CR) {
			$log->debug("Disconnect socket after Standby"."\n");
			$self->disconnect;
#		}
	} elsif ($request =~ m/MV\?/) {
		$log->debug("Volume setting inquiry"."\n");
		$event = substr($buf,0,2);
		if ($event eq 'MV') { #check to see if the element is a volume
			$subEvent = substr($buf,2,3);
			if ($subEvent eq 'MAX') {  # its not the one that tells us the volume change
				$self->disconnect;		
			} else {
				# call the plugin routine to deal with the volume
#				&clearbuf($self->socket);
				$self->disconnect;		
				$classPlugin->updateSqueezeVol($client, $subEvent);
	 
			}
		}
	} elsif ($request =~ m/MV/ || $request =~ m/Z\d\d\d/) {
		$log->debug("Process Volume Setting"."\n");
		$self->disconnect;
	} elsif ($request =~ m/MU\?/) {
		$log->debug("Mute status inquiry"."\n");
		$event = substr($buf,0,2);
		if ($event eq 'MU') { #check to see if the element is a muting status
			$subEvent = substr($buf,2,2);  # get the status
			if ($subEvent eq 'OF' || $subEvent eq 'ON') {
#				$self->disconnect;
				$classPlugin->handleMutingToggle($client, $subEvent);	
			}								
		}				
	} elsif ($request =~ m/MUO/) {
		$log->debug("Process Mute response"."\n");
		$self->disconnect;
	} elsif ($request =~ m/MS\?/ || $request =~ m/^PS/) {
		my @events = split(/\r/,$buf); #break string into array
		foreach $event (@events) { # loop through the event array parts
			$log->debug("The value of the array element is: " . $event . "\n");			
			$command = substr($event,0,2);
			if ($command eq 'MS') { #check to see if the element is a surround mode
				$i=0;
				$subEvent = substr($events[0],0,5);
				foreach (@surroundModes) {
					$sSM = substr($surroundModes[$i],0,5);
					if ($subEvent eq $sSM || ((substr($events[0],3,2) eq "CH") && ($sSM eq "MS7CH"))) {
						# call the surround mode plugin routine to set the value
						$log->debug("Surround Mode is: " . $surroundModes[$i] . "\n");
						$classPlugin->updateSurroundMode($client, $i);
					}
					$i++;
				} # foreach (@surroundModes)
			} elsif ($command eq 'PS') { #check to see if the element is a PS mode
				$subEvent = substr($events[0],0,6);
				if ( $subEvent eq 'PSROOM') { #room modes
					$i=0;
					foreach (@roomModes) {
						if ($roomModes[$i] eq $events[0]) {
							# call the room mode plugin routine to set the value
							$log->debug("Room Mode is: " . $roomModes[$i] . "\n");
							$classPlugin->updateRoomEq($client, $i);
						} # if
						$i++;
					} # foreach roomModes
				} elsif ($subEvent eq 'PSDYNS') { # night mode
					$i=0;
					foreach (@nightModes) {
						if ($nightModes[$i] eq $events[0]) {
							# call the night mode plugin routine to set the value
							$log->debug("Night Mode is: " . $nightModes[$i] . "\n");
							$classPlugin->updateNM($client, $i);
						} # if
						$i++;
					} # foreach nightModes
				} elsif ($subEvent eq 'PSDYN ') { # dynamic volume
					$i=0;
					foreach (@dynamicVolModes) {
						if ($dynamicVolModes[$i] eq $events[0]) {
							# call the dynamic vol mode plugin routine to set the value
							$log->debug("Dynamic Volume Mode is: " . $dynamicVolModes[$i] . "\n");
							$classPlugin->updateDynEq($client, $i);
						} # if
						$i++;
					} # foreach dynamicVolModes
				} elsif ($subEvent eq 'PSRSTR') { # restorer
					$i=0;
					foreach (@restorerModes) {
						if ($restorerModes[$i] eq $events[0])  {
							# call the restorer mode plugin routine to set the value
							$log->debug("Restorer Mode is: " . $restorerModes[$i] . "\n");
							$classPlugin->updateRestorer($client, $i);
						} # if
						$i++;
					} # foreach restorerModes
				} elsif ($subEvent eq 'PSREFL') { # reference level
					$i=0;
					foreach (@refLevelModes) {
						if ($refLevelModes[$i] eq $events[0])  {
							# call the refence level plugin routine to set the value
							$log->debug("Reference level is: " . $refLevelModes[$i] . "\n");
							$classPlugin->updateRefLevel($client, $i);
						} # if
						$i++;
					} # foreach refLevelModes
				}
			}
		} # foreach (@events)
		# now see if we should loop the AVP settings
		if ($gGetPSModes !=0) {
			$gGetPSModes++;
			LoopGetAvpSettings($client, $url);
		}
	} # if ($request =~ /PWON\r/) {	# power on ...

} # _read

1;