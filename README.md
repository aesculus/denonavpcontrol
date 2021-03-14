# denonavpcontrol
> A plugin for the Logitech Media Server to control a Denon/Marrantz Receiver

---

## Introduction
This Logitech Media Server plugin will turn on and off a networked Denon amplifier/receiver when the Squeezebox is turned on/off or a song is played. The plugin will optionally set one of the Quick Select modes, and set the volume of the Squeezebox to match the amplifier volume. The user can also set a optional on or off delay timer and set the maximum volume level they wish the amplifier to be set to when controlling the Squeezebox. The user can modify the Denon audio settings during playback when using the iPeng application on an iTouch device.

The plugin uses the Denon serial protocol over a wireless or wired network and therefore a network connection between the Logitech Media Server server and the Denon amplifier must be available.

The plugin has only been tested with the Denon AVP-A1HD and the Squeezebox Receiver and Touch but it should work with any Denon amplifier/receiver that supports the Denon serial protocol over a network and other Squeezebox's as well. The plugin has also been tested with the Apple iOS devices (Touch, iPhone and iPad) using the iPeng applications. It should also work with Logitechs smart phone controllers.

## Details
  * Turns the Denon amplifier on when the user turns on a Squeezebox or plays a song
  * Puts the Denon amplifier in standby when the user turns the Squeezebox off
  * Changes the volume of the Denon amplifier when the user changes the Squeezebox volume
  * Sets the Squeezebox volume to the default setting of the Denon amplifier when turned on
  * Optionally sets one of the three Denon Quick Select modes when turned on
  * The user specifies the maximum volume the amplifier can be set to
  * The user can pick an optional on and/or off delay timer as well as Quick Select timer
  * The plugin can be enabled/disabled without restarting the LMS
  * The user can select between Main, Zone 2, Zone 3 and Zone 4
  * Optionally the plugin can set the Squeezebox volume from the amplifier volume at track changes
  * Added the ability to control the DENON audio settings using the iPeng application during playback.
  * Supports 100% volume setting on players with iPeng 1.2.5 and greater.  Volume control has been changed to be less linear with more loudness in the lower settings.
  * Supports .5 settings on volume adjustment to Denon
  
# Installation
See the [Installation Instructions](https://github.com/aesculus/denonavpcontrol/blob/master/wiki/InstallationInstructions.wiki)

# How to Use
See [How to Use](https://github.com/aesculus/denonavpcontrol/wiki/How-to-Use)
## Licence

The MIT License

Copyright (c) 2008-2021, Christopher Couper and contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

```
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
```
