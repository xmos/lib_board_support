// Copyright 2024 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
/// Hardware setup APIs for the xk_audio_216_mc_ab
#pragma once

/**
 * \addtogroup xk_audio_216_mc_ab xk_audio_216_mc_ab
 *
 * The common defines for using lib_board_support.
 * @{
 */

typedef enum {
    /// Fixed mclk
    AUD_216_CLK_FIXED,

    /// ADAT or SPDIF clock recovery
    AUD_216_CLK_EXTERNAL_PLL,

    /// UAC sync mode clock recovery
    AUD_216_CLK_EXTERNAL_PLL_USB,
} xk_audio_216_mc_ab_clk_mode_t;


typedef enum {
    AUD_216_PCM_FORMAT_I2S,
    AUD_216_PCM_FORMAT_TDM
} xk_audio_216_mc_ab_pcm_format_t;

typedef enum {
    AUD_216_USB_A,
    AUD_216_USB_B
} xk_audio_216_mc_ab_usb_sel_t;

typedef struct {
    xk_audio_216_mc_ab_clk_mode_t clk_mode;

    /// Set to true to configure the external codec to generate an mclk
    char codec_is_clk_master;
    xk_audio_216_mc_ab_usb_sel_t usb_sel;
    xk_audio_216_mc_ab_pcm_format_t pcm_format;

    /// Frequency of generated sync clock for externall PLL, only used
    /// if clk_mode != AUD_216_CLK_FIXED
    unsigned pll_sync_freq;
} xk_audio_216_mc_ab_config_t;

//////// Convenience APIs for use with lib_xua
void xk_audio_216_mc_ab_AudioHwInit(const xk_audio_216_mc_ab_config_t & config);
void xk_audio_216_mc_ab_AudioHwConfig(const xk_audio_216_mc_ab_config_t & config,
                                      unsigned samFreq,
                                      unsigned mClk,
                                      unsigned dsdMode,
                                      unsigned sampRes_DAC,
                                      unsigned sampRes_ADC);

/**@}*/ // END: addtogroup xk_audio_216_mc_ab
