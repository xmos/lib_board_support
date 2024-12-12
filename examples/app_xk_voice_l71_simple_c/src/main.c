// Copyright 2024 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#include <stdio.h>
#include <xcore/channel.h>
#include "xk_voice_l71/board.h"

// Board configuration from lib_board_support
static const xk_voice_l71_config_t hw_config = {
        12288000// default_mclk
};


void tile_0_main(chanend_t c){
    printf("Hello from tile[0]\n");
    xk_voice_l71_AudioHwRemote(c); // Startup remote I2C master server task
    printf("Bye from tile[0]\n");
}

void tile_1_main(chanend_t c){
    printf("Hello from tile[1]\n");
    xk_voice_l71_AudioHwChanInit(c);
    xk_voice_l71_AudioHwInit(&hw_config);
    xk_voice_l71_AudioHwConfig(&hw_config, 48000, 24576000);
    chan_out_word(c, AUDIOHW_CMD_EXIT); // Kill the remote config task
    printf("Bye from tile[1]\n");
}
