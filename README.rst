:orphan:

#####################################
lib_board_support: XMOS board support
#####################################

:vendor: XMOS
:version: 1.5.0
:scope: General Use
:description: Support library for XMOS development kits
:category: General Purpose
:keywords: Serial interface, Ethernet, ADC, DAC
:devices: xcore.ai, xcore-200

*******
Summary
*******

``lib_board_support`` contains board specific hardware configuration code for various `XMOS`
evaluation and development kits.

********
Features
********

* Support for the following `XMOS` boards:

  * ``XK-EVK-XU316``
  * ``XK-AUDIO-316-MC``
  * ``XK-AUDIO-216-MC``
  * ``XK-EVK-XU216``
  * ``XK-ETH-316-DUAL``
  * ``XK-VOICE-L71``

* Simple examples demonstrating usage from both `XC` and `C` (where supported).

************
Known issues
************

* Support for SMI (used in the Ethernet PHY drivers) requires the lib_ethernet dependency, which is not included in
  this repository to avoid introducing dependencies into non-Ethernet applications. Any Ethernet application
  targeting either XK-EVK-XU216 or XK-ETH-316-DUAL boards must include lib_ethernet explicitly.

****************
Development repo
****************

* `lib_board_support <https://www.github.com/xmos/lib_board_support>`_

**************
Required tools
**************

* XMOS XTC Tools: 15.3.1

*********************************
Required libraries (dependencies)
*********************************

* `lib_i2c <https://www.xmos.com/file/lib_i2c>`_
* `lib_sw_pll <https://www.xmos.com/file/lib_sw_pll>`_
* `lib_xassert <https://www.xmos.com/file/lib_xassert>`_

*************************
Related application notes
*************************

The following application notes use this library:

* `AN02003: SPDIF/ADAT/I²S Receive to I²S Slave Bridge with ASRC <https://www.xmos.com/file/an02003>`_
* `AN02016: Integrating Audio Weaver (AWE) Core into USB Audio <https://www.xmos.com/file/an02016>`_

*******
Support
*******

This package is supported by XMOS Ltd. Issues can be raised against the software at: http://www.xmos.com/support
