// Copyright 2024 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
/// Hardware setup APIs for the xk_audio_316_mc_ab
#pragma once

#if __XC__
#define BS_PORT port
#else
#include <xcore/port.h>
#define BS_PORT port_t
#endif

#include <xccompat.h>
#include "i2c.h"

/* I2C interface ports */
extern BS_PORT p_scl;
extern BS_PORT p_sda;

/// Start an i2s master thread which uses the DAC pins
#define xk_audio_316_mc_ab_i2c_master(i2c) i2c_master((i2c), 1, p_scl, p_sda, 100)


typedef enum {
    CLK_FIXED,
    CLK_CS2100,
    CLK_PLL
} xk_audio_316_mc_ab_mclk_modes_t;

typedef enum {
    AUD_316_PCM_FORMAT_I2S,
    AUD_316_PCM_FORMAT_TDM
} xk_audio_316_mc_ab_pcm_format_t;

typedef struct {
    xk_audio_316_mc_ab_mclk_modes_t clk_mode;
    char dac_is_clock_master; // bool

    // fixed clock config
    unsigned default_mclk;

    // cs2100 clock config
    unsigned pll_sync_freq;

    xk_audio_316_mc_ab_pcm_format_t pcm_format;
    unsigned i2s_n_bits;

    unsigned i2s_chans_per_frame;
} xk_audio_316_mc_ab_config_t;

void xk_audio_316_mc_ab_board_setup(const REFERENCE_PARAM(xk_audio_316_mc_ab_config_t, config));

void xk_audio_316_mc_ab_AudioHwInit(CLIENT_INTERFACE(i2c_master_if, i2c), const REFERENCE_PARAM(xk_audio_316_mc_ab_config_t, config));


void xk_audio_316_mc_ab_AudioHwConfig(CLIENT_INTERFACE(i2c_master_if, i2c), const REFERENCE_PARAM(xk_audio_316_mc_ab_config_t, config), unsigned samFreq, unsigned mClk, unsigned dsdMode, unsigned sampRes_DAC, unsigned sampRes_ADC);
