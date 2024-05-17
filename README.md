# denonavpcontrol
> A plugin for the Lyrion Music Server to control a Denon or Marantz Audio/Video Receiver.

---

## Introduction
This plugin will turn on and off a networked Denon or Marantz amplifier/receiver when an LMS player is turned on/off or a song is played. The plugin can also be configured to invoke one of the AVR's Quick Select modes or set the input source after powering it on, and will set the initial volume of the player to match the amplifier volume. An optional delay value can be specified before issuing commands after the AVR is powered on, as well as the maximum volume level that the amplifier should be set to when controlling the player. The user can also modify the AVR audio settings during playback when using the iPeng (iOS), Squeezer (Android) or Squeeze Ctrl (Android) client apps or the Material Skin LMS plugin interface.

The plugin uses the Denon/Marantz serial protocol over a wireless or wired network and therefore a network connection between the Lyrion server and the AVP/AVR must be available.

The plugin has been tested with numerous Denon and Marantz AVR's, and with the Squeezebox Receiver, Touch and software-based players such as Squeezelite. It should work with any Denon or Marantz AVR that supports the Denon/Marantz serial protocol over a network. The plugin has also been tested with Apple iOS devices (Touch, iPhone and iPad) using the iPeng application, Android devices using the Squeezer and Squeeze Ctrl applications, and the Material Skin plugin on any devices it supports.

## Details
  * Turns the AVR on when the user turns on a Lyrion player or starts playing a song
  * Puts the AVR in standby when the user turns the player off
  * Changes the volume of the AVR when the user changes the player volume
  * Sets the player volume to the default setting of the AVR when turned on
  * Optionally sets one of the Quick Select (Denon) or Smart Select (Marantz) modes, or selects an AVR Input Source when turned on
  * The user specifies the maximum volume the amplifier can be set to
  * The user can pick an optional delay time after powering the AVR on before playback begins
  * The user can select between Main, Zone 2, Zone 3 and Zone 4
  * Optionally synchronize the Lyrion player's volume to the AVR volume at track changes
  * Optionally control AVR audio settings using LMS menus available under the iPeng, Squeezer, Squeeze Ctrl or Material Skin applications during playback
  
# Installation
See the [Installation Instructions](https://github.com/aesculus/denonavpcontrol/wiki/Installation-Instructions)

# How to Use
See [How to Use](https://github.com/aesculus/denonavpcontrol/wiki/How-to-Use)
## License

The MIT License

Copyright (c) 2008-2022, Christopher Couper and contributors

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
