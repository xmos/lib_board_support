// Copyright 2024-2026 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#include <stdio.h>
#include "xk_evk_xu316/board.h"
#include "xk_audio_216_mc_ab/board.h" // Not needed by this example application. This is just here to test inclusion from C.

// Board configuration from lib_board_support
static const xk_evk_xu316_config_t hw_config = {
        12288000// default_mclk
};


void tile_0_main(SERVER_INTERFACE(i2c_master_if, i_i2c)){
    printf("Hello from tile[0]\n");
    xk_evk_xu316_i2c_master(&i_i2c);  // Run I2C master server task to allow control from tile[1]
    printf("Bye from tile[0]\n");
}

void tile_1_main(CLIENT_INTERFACE(i2c_master_if, i_i2c)){
    printf("Hello from tile[1]\n");
    xk_evk_xu316_AudioHwInit(i_i2c, &hw_config);
    xk_evk_xu316_AudioHwConfig(i_i2c, 48000, hw_config.default_mclk, 0, 24, 24);
    xk_evk_xu316_i2c_master_exit(i_i2c); // Quit the I2C master on tile[0]
    printf("Bye from tile[1]\n");
}
