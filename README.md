# denonavpcontrol
> A plugin for the Logitech Media Server to control a Denon or Marantz Audio/Video Receiver

---

## Introduction
This Logitech Media Server plugin will turn on and off a networked Denon or Marantz amplifier/receiver when a Squeezebox player is turned on/off or a song is played. The plugin will optionally set one of the Quick Select modes or AVR input sources, and set the volume of the Squeezebox to match the amplifier volume. The user can set an optional delay value after the AVR is powered on and set the maximum volume level they wish the amplifier to be set to when controlling the Squeezebox. The user can also modify the AVR audio settings during playback when using the iPeng (iOS) and Squeezer (Android) client apps or the Material Skin LMS interface.

The plugin uses the Denon/Marantz serial protocol over a wireless or wired network and therefore a network connection between the Logitech Media Server server and the AVP/AVR must be available.

The plugin has been tested with the Denon AVP-A1HD, as well as numerous Denon and Marantz AVR's, with the Squeezebox Receiver, Touch and software-based players such as Squeezelite. It should work with any Denon or Marantz AVR that supports the Denon/Marantz serial protocol over a network. The plugin has also been tested with the Apple iOS devices (Touch, iPhone and iPad) using the iPeng application and Android devices using the Squeezer application, as well as the LMS Material Skin interface. It should also work with Logitechs smart phone controllers.

## Details
  * Turns the AVR on when the user turns on a Squeezebox player or plays a song
  * Puts the AVR in standby when the user turns the player off
  * Changes the volume of the AVR when the user changes the player volume
  * Sets the player volume to the default setting of the AVR when turned on
  * Optionally sets one of the Quick Select (Denon), Smart Select (Marantz) modes or selects an AVR Input Source when turned on
  * The user specifies the maximum volume the amplifier can be set to
  * The user can pick an optional delay time after powering the AVR on before playback begins
  * The user can select between Main, Zone 2, Zone 3 and Zone 4
  * Optionally the plugin can synchronize the Squeezebox player volume to the AVR volume at track changes
  * Added the ability to control the AVR audio settings using the iPeng, Squeezer or Material Skin applications during playback
  * Volume control has been changed to be less linear with more loudness in the lower settings.
  * Supports .5 settings on volume adjustment to AVR
  
# Installation
See the [Installation Instructions](https://github.com/aesculus/denonavpcontrol/wiki/Installation-Instructions)

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
