|newpage|

XK-VOICE-L71 Voice Reference Design Evaluation Kit
==================================================

OVERVIEW

The voice reference design board can be used as a Raspberry Pi HAT for integration with host based applications or used standalone as a USB accessory to a host system. 

Features of the XK-VOICE-L71 include:

 - XU316-1024-QF60A-C24 xcore.ai processor
 - Raspberry Pi HAT connector
 - 2 x Infineon IM69D130 MEMS mics
 - 71mm inter-mic spacing
 - Microphone mute switch
 - Speaker output (Line level)
 - USB / I2S host interface support
 - Tri-colour LED
 - Single push button

For further information and detailed documentation please follow this link `XK-VOICE-L71 <https://www.xmos.com/xk-voice-l71>`_

The API included supports the following features:

 - Setting up of the DAC for either 16 kHz or 48 kHz. The DAC is always configured as I2S target (slave).
 - The DAC may be configured to accept data from either I2S_IN or I2S_OUT signals on the board.
 - Setting up of the Application PLL to drive a master clock at 12.288 MHz, 24.576 MHz or 49.152 MHz. Alternatively, it
   may be configured as an input to accept an external master clock.
 - Setting up of the I2C expander which controls signal connection to the Raspberry Pi style header, allowing connection to
   external systems. MCLK, I2S, SPI and INT connections may be individually enabled or disabled.
 - Provides a remote I2C master control task on tile[0] (I2S audio is on tile[1]) which may be exited once configuration is complete.
