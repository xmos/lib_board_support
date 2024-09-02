
Using the Board Support library
===============================

Overview
--------

This example contains a simple application and demonstrates how to use this library to abstract away the board hardware setup code.
The application doesn't do anything other than setup the DAC and initialise the Master clock. It is mainly intended for testing usage via `C`.

Required tools and libraries
............................

  * XMOS XTC Tools: 15.3.0
  * lib_i2c (www.github.com/xmos/lib_i2c)
  * lib_i2s (www.github.com/xmos/lib_i2s)
  * lib_sw_pll (www.github.com/xmos/lib_sw_pll)
  * lib_xassert (www.github.com/xmos/lib_xassert)


Required hardware
.................

The hardware targeted is the `XK-AUDIO-XU316-MC board <https://www.xmos.com/download/XCORE_AI-Multichannel-Audio-Platform-1V1-Hardware-Manual(1V1).pdf>`_.

Prerequisites
..............

 * This document assumes familiarity with the XMOS xCORE
   architecture, the XMOS tool chain and the xC language. Documentation related
   to these aspects which are not specific to this application note are linked
   to in the references appendix.
