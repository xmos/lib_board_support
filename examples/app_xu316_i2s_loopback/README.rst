
Using the Board Support library
===============================

Overview
--------

This example contains a simple application and demonstrates how to use this library to abstract away the board hardware setup code.

The application supports a simple |I2S| digital loopback which plays the samples received on all 8 ADC channels back out on the 8 DAC channels.
All of the |I2S| configuration is set in the defines at the top of ``main.xc`` which allows different sample rates, master clock frequencies and number of data bits etc. to be set before compilation. Sample rates of 44.1 kHz to 192 kHz have been tested.

Two build configurations are included:

    - XMOS_MASTER - This configures the ADCs and DACs to |I2S| slave and the xcore.ai device drives the |I2S| clocks. The on-chip application PLL is configured to drive the master clock to the mixed signal devices.
    - XMOS_SLAVE - This configures one the DACs to |I2S| master and the remaining DAC, all ADCs and the xcore.ai device to |I2S| slave. The on-chip application PLL is configured to drive the master clock to the mixed signal devices.


To build and run the example, run the following from an XTC tools terminal::
    cd examples/app_xu316_i2s_loopback
    cmake -G "Unix Makefiles" -B build

All required dependencies will be downloaded by the build system if not already present.

The application binaries can be built using ``xmake``::

    xmake -C build

To run the application use the following command::

    xrun bin/XMOS_MASTER/app_xu316_i2s_loopback_XMOS_MASTER.xe

or::

    xrun bin/XMOS_SLAVE/app_xu316_i2s_loopback_XMOS_SLAVE.xe

Connect an analog audio source to the chosen ADC input channels and then monitor the looped back output on the chosen DAC output channels.

Required tools and libraries
............................

  * XMOS XTC Tools: 15.3.0
  * lib_i2c (www.github.com/xmos/lib_i2c)
  * lib_i2s (www.github.com/xmos/lib_i2s)
  * lib_sw_pll (www.github.com/xmos/lib_sw_pll)
  * lib_xassert (www.github.com/xmos/lib_xassert)


Required hardware
.................

The hardware targeted is the `XK-AUDIO-316-MC board <https://www.xmos.com/download/XCORE_AI-Multichannel-Audio-Platform-1V1-Hardware-Manual(1V1).pdf>`_ although thanks to this library, porting it to other platforms supported by ``lib_board_support`` should be trivial.

Prerequisites
..............

 * This document assumes familiarity with |I2S| interfaces, the XMOS xCORE
   architecture, the XMOS tool chain and the xC language. Documentation related
   to these aspects which are not specific to this application note are linked
   to in the references appendix.
