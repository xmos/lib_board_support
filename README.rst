:orphan:

#####################################
lib_board_support: XMOS board support
#####################################

:vendor: XMOS
:version: 1.2.0
:scope: General Use
:description: Support library for XMOS development kits
:category: General Purpose
:keywords: I2C
:devices: xcore.ai, xcore-200

*******
Summary
*******

``lib_board_support`` contains board specific hardware configuration code for various `XMOS`
evaluation and development kits.

********
Features
********

 * Support for the following boards:
    * ``XK_EVK_XU316``
    * ``XK_AUDIO_316_MC``
    * ``XK_AUDIO_216_MC``
    * ``XK_EVK_XU216``
 * Simple examples to demonstrating usage from both `XC` and `C`.

************
Known issues
************

 * XK_EVK_XU216 support is currently only for the GigE PHY. The required dependency lib_ethernet to support
   SMI has not been added to this repo to avoid unneeded dependencies in non-Ethernet applications and will 
   be required by any Ethernet application for this board anyway.

 * XK_ETH_XU316_DUAL_100M is currently an unreleased board and hence has no documentation.

 * XK_ETH_XU316_DUAL_100M uses the TI DP83826 PHY. During testing we noticed that very occasionally (1% of the time) the first
   packet sent after initialisation may be dropped for certain link partners. Subsequent packets are always OK. This is consistent with a similar bug seen on the `TI forum <https://e2e.ti.com/support/interface-group/interface/f/interface-forum/956808/dp83822i-after-link-up-first-packet-is-not-being-transmitted>`_. For most applications this is not
   an issue however for test cases it may be worth noting. Sending an initial dummy Tx packet works around this issue.


****************
Development repo
****************

 * `lib_board_support <https://www.github.com/xmos/lib_board_support>`_

**************
Required tools
**************

 * XMOS XTC Tools: 15.3.0

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


