// Copyright 2024 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#include <platform.h>
#include <stdio.h>
#include "xk_audio_316_mc_ab/board.h"

// Board configuration from lib_board_support
static const xk_audio_316_mc_ab_config_t hw_config = {
        CLK_FIXED,              // clk_mode. Drive a fixed MCLK output
        0,                      // 1 = dac_is_clock_master
        24576000,
        0,                      // pll_sync_freq (unused when driving fixed clock)
        AUD_316_PCM_FORMAT_I2S,
        32,
        2
};


void tile_0_main(SERVER_INTERFACE(i2c_master_if, i_i2c)){
    printf("Hello from tile[0]\n");
    xk_audio_316_mc_ab_board_setup(&hw_config);         // General board setup must be done on tile[0]
    xk_audio_316_mc_ab_i2c_master(&i_i2c);               // Run I2C master server task to allow control from tile[1]
    printf("Bye from tile[0]\n");
}

void tile_1_main(CLIENT_INTERFACE(i2c_master_if, i_i2c)){
    printf("Hello from tile[1]\n");
    xk_audio_316_mc_ab_AudioHwInit(i_i2c, &hw_config);  // Initialise the hardware
    xk_audio_316_mc_ab_AudioHwConfig(i_i2c, &hw_config, 48000, hw_config.default_mclk, 0, 24, 24);
    xk_audio_316_mc_ab_i2c_master_exit(i_i2c);          // Quit the I2C master on tile[0]
    printf("Bye from tile[1]\n");
}
