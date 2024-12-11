// Copyright 2024 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#include <platform.h>
#include <stdio.h>
#include <xs1.h>
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

int main(void)
{
    interface i2c_master_if i_i2c[1]; // Cross tile interface

    par {
        on tile[0]: {
            printf("Hello from tile[0]\n");
            xk_audio_316_mc_ab_board_setup(hw_config); // Setup must be done on tile[0]
            xk_audio_316_mc_ab_i2c_master(i_i2c);      // Run I2C master server task to allow control from tile[1]
            printf("Bye from tile[0]\n");
        }

        on tile[1]: {
            printf("Hello from tile[1]\n");
            xk_audio_316_mc_ab_AudioHwInit(i_i2c[0], hw_config);
            xk_audio_316_mc_ab_AudioHwConfig(i_i2c[0], hw_config, 48000, hw_config.default_mclk, 0, 24, 24);
            xk_audio_316_mc_ab_i2c_master_exit(i_i2c[0]);          // Quit the I2C master on tile[0]
            printf("Bye from tile[1]\n");
        }
    }
    return 0;
}
