// Copyright 2024 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#include <stdio.h>
#include <xcore/channel.h>
#include "xk_voice_l71/board.h"

#include <stdlib.h>
#include <math.h>
#include <xscope.h>
#include <xs1.h>
#include <xclib.h>
#include <xcore/assert.h>
#include <platform.h>

#include "sw_pll.h"
#include "i2s.h"

#define MCLK_FREQUENCY              24576000
#define I2S_FREQUENCY               48000
#define N_SINE                      16

#define NUM_I2S_CHANNELS            2
#define NUM_I2S_LINES               ((NUM_I2S_CHANNELS + 1) / 2)


// Board configuration from lib_board_support
static const xk_voice_l71_config_t hw_config = {
        CLK_FIXED,
        1, // DAC is clock master
        MCLK_FREQUENCY,
};


typedef struct i2s_callback_args_t {
    bool did_restart;                           // Set by init
    int sine_table[N_SINE];
    unsigned counter;
} i2s_callback_args_t;



I2S_CALLBACK_ATTR
static void i2s_init(void *app_data, i2s_config_t *i2s_config){
    printf("I2S init\n");
    i2s_callback_args_t *cb_args = app_data;

    i2s_config->mode = I2S_MODE_I2S;
    i2s_config->mclk_bclk_ratio = (MCLK_FREQUENCY / (I2S_FREQUENCY * 32 * 2));
    printf("I2S mclk:bclk Ratio: %u\n", i2s_config->mclk_bclk_ratio);

    for(int i = 0; i < N_SINE; i++){
        cb_args->sine_table[i] = (1 << 30) * sin(6.2831853072 * i / N_SINE);
    }

    cb_args->did_restart = true;
}

I2S_CALLBACK_ATTR
static i2s_restart_t i2s_restart_check(void *app_data){
    i2s_callback_args_t *cb_args = app_data;
    (void)cb_args;

    return I2S_NO_RESTART;
}


I2S_CALLBACK_ATTR
static void i2s_send(void *app_data, size_t num_out, int32_t *i2s_sample_buf){
    i2s_callback_args_t *cb_args = app_data;

    for(int i = 0; i < num_out; i++){
        i2s_sample_buf[i] = cb_args->sine_table[cb_args->counter];
        // printf("%ld\n", clz(i2s_sample_buf[i]));
    }
    if(++(cb_args->counter) == N_SINE){
        cb_args->counter = 0;
    }
}

I2S_CALLBACK_ATTR
static void i2s_receive(void *app_data, size_t num_in, const int32_t *i2s_sample_buf){
    i2s_callback_args_t *cb_args = app_data;
    (void)cb_args;
}


void i2s_tone_gen(void){

    // I2S resources
    port_t p_i2s_dout[NUM_I2S_LINES] = {PORT_I2S_DAC0};
    port_t p_i2s_din[NUM_I2S_LINES] = {PORT_I2S_ADC0};
    port_t p_bclk = PORT_I2S_BCLK;
    port_t p_mclk = PORT_MCLK_IN;
    port_t p_lrclk = PORT_I2S_LRCLK;
    xclock_t i2s_ck_bclk = XS1_CLKBLK_1;

    port_enable(p_bclk);
    // NOTE:  p_lrclk does not need to be enabled by the caller



    // Initialise app_data
    i2s_callback_args_t app_data = {
        .did_restart = false,
        .sine_table = {0},
        .counter = 0
    };

    // Initialise callback function pointers
    i2s_callback_group_t i2s_cb_group;
    i2s_cb_group.init = i2s_init;
    i2s_cb_group.restart_check = i2s_restart_check;
    i2s_cb_group.receive = i2s_receive;
    i2s_cb_group.send = i2s_send;
    i2s_cb_group.app_data = &app_data;

    printf("Starting I2S master\n");

    i2s_master(
            &i2s_cb_group,
            p_i2s_dout,
            NUM_I2S_LINES,
            p_i2s_din,
            NUM_I2S_LINES,
            p_bclk,
            p_lrclk,
            p_mclk,
            i2s_ck_bclk);
}

void tile_0_main(chanend_t c){
    printf("Hello from tile[0]\n");
    xk_voice_l71_AudioHwRemote(c); // Startup remote I2C master server task
    printf("Bye from tile[0]\n");
}

void tile_1_main(chanend_t c){
    printf("Hello from tile[1]\n");
    xk_voice_l71_AudioHwChanInit(c);
    xk_voice_l71_AudioHwInit(&hw_config);
    // xk_voice_l71_AudioHwConfig(&hw_config, I2S_FREQUENCY, MCLK_FREQUENCY);
    i2s_tone_gen();
    chan_out_word(c, AUDIOHW_CMD_EXIT); // Kill the remote config task
    printf("Bye from tile[1]\n");
}
