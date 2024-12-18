lib_board_support change log
============================

1.2.0
-----

  * ADDED: Support for XK-VOICE-L71

1.1.1
-----

  * CHANGED: Documentation improvements
  * REMOVED: Dependency of examples on lib_i2s

  * Changes to dependencies:

    - lib_i2c: 6.3.0 -> 6.4.0

    - lib_sw_pll: 2.3.0 -> 2.3.1

    - lib_xassert: 4.3.0 -> 4.3.1

1.1.0
-----

  * FIXED: DAC setup on channels 0 to 5 (DACs 0, 1 & 2) when dac_is_clock_master
    set to 1 (XMOS is slave) which caused distortion at higher frequencies

  * Changes to dependencies:

    - lib_i2c: 6.2.0 -> 6.3.0

    - lib_sw_pll: 2.2.0 -> 2.3.0

    - lib_xassert: 4.2.0 -> 4.3.0

1.0.1
-----

  * CHANGED: Documentation improvements

1.0.0
-----

  * ADDED: Board documentation
  * ADDED: Example apps showing use of library
  * ADDED: Callable from C
  * ADDED: I2C master exit API for XK-AUDIO-316-MC
  * ADDED: Explicit xk_evk_xu316_AudioHwChanInit() API
  * ADDED: NULL_BOARD default option so library can be included in a project
    without being used
  * FIXED: Missing lib_sw_pll dependency
  * FIXED: Uninitialised global interface for XK-AUDIO-216-MC setup

  * Changes to dependencies:

    - lib_i2c: Added dependency 6.2.0

    - lib_sw_pll: Added dependency 2.2.0

    - lib_xassert: Added dependency 4.2.0

0.1.1
-----

  * CHANGED: Pinned lib_i2c to >=6.2.0

0.1.0
-----

  * ADDED: Ported setup code from sw_usb_audio v8.1.0

