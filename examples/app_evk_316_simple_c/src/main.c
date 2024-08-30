// Copyright 2024 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#include <stdio.h>
#include <xcore/channel.h>
#include "xk_evk_xu316/board.h"
#include "xk_audio_216_mc_ab/board.h" // Not needed by this example application. This is just here to test inclusion from C.

// Board configuration from lib_board_support
static const xk_evk_xu316_config_t hw_config = {
        12288000// default_mclk
};


void tile_0_main(chanend_t c){
    printf("Hello from tile[0]\n");
    xk_evk_xu316_AudioHwRemote(c); // Startup remote I2C master server task
    printf("Bye from tile[0]\n");
}

void tile_1_main(chanend_t c){
    printf("Hello from tile[1]\n");
    xk_evk_xu316_AudioHwInit(c, &hw_config);
    xk_evk_xu316_AudioHwConfig(48000, hw_config.default_mclk, 0, 24, 24);
    chan_out_word(c, AUDIOHW_CMD_EXIT); // Kill the remote config task
    printf("Bye from tile[1]\n");
}
