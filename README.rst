:orphan:

#################
lib_board_support
#################

:vendor: XMOS
:version: 1.0.0
:scope: General Use
:description: Support library for XMOS development kits
:category: General Purpose
:keywords: I2C
:devices: xcore.ai, xcore-200

Summary
*******

``lib_board_support`` contains board specific hardware configuration code for various `XMOS`
evaluation and development kits.

Features
********

  * Support for the following boards:
     * ``XK_EVK_XU316``
     * ``XK_AUDIO_316_MC``
     * ``XK_AUDIO_216_MC``
  * Simple examples to demonstrating usage from both `XC` and `C`.

Known Issues
************

  * None

Required Tools
**************

  * XMOS XTC Tools: 15.3.0

Required Libraries (dependencies)
*********************************

  * lib_i2c (www.github.com/xmos/lib_i2c)
  * lib_sw_pll (www.github.com/xmos/lib_sw_pll)
  * lib_xassert (www.github.com/xmos/lib_xassert)

Related Application Notes
*************************

The following application notes use this library:

  * `AN02003: SPDIF/ADAT/I²S Receive to I²S Slave Bridge with ASRC <https://www.xmos.com/file/an02003>`_
  * `AN02016: Integrating Audio Weaver (AWE) Core into USB Audio <https://www.xmos.com/file/an02016>`_

Support
*******

This package is supported by XMOS Ltd. Issues can be raised against the software at: http://www.xmos.com/support


