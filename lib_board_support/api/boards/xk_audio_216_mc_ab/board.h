// Copyright 2024 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
/// Hardware setup APIs for the xk_audio_216_mc_ab
#pragma once

#include <xccompat.h>

/**
 * \addtogroup xk_audio_216_mc_ab xk_audio_216_mc_ab
 *
 * The common defines for using lib_board_support.
 * @{
 */

/** Type of clock to be instantiated. This may be a fixed clock using an external generator or
 * an adjustable clock using an external PLL (CS2100) in either digital Rx clock recovery or
 * USB clock recovery using synchronous mode.
 */
typedef enum {
    AUD_216_CLK_FIXED,
    AUD_216_CLK_EXTERNAL_PLL,
    AUD_216_CLK_EXTERNAL_PLL_USB,
} xk_audio_216_mc_ab_clk_mode_t;

/** Formats supported by the DAC and ADC. Either I2S using multiple data lines or TDM
 * supporting multi-channel using a single data line.
 */
typedef enum {
    AUD_216_PCM_FORMAT_I2S,
    AUD_216_PCM_FORMAT_TDM
} xk_audio_216_mc_ab_pcm_format_t;

/** Selects which USB port to use - either type A or type B
 */
typedef enum {
    AUD_216_USB_A,
    AUD_216_USB_B
} xk_audio_216_mc_ab_usb_sel_t;

/** @struct xk_audio_216_mc_ab_config_t
 *  @brief Configuration struct type for setting the hardware profile.
 *  @var xk_audio_216_mc_ab_config_t::clk_mode
 *  See xk_audio_216_mc_ab_clk_mode_t for clock mode available options.
 *  @var xk_audio_216_mc_ab_config_t::codec_is_clk_master
 *  Boolean setting for whether the DAC or the xcore-200 is I2S clock master. Set to 0 to make the xcore-200 master.
 *  @var xk_audio_216_mc_ab_config_t::usb_sel
 *  USB port slection - see xk_audio_216_mc_ab_usb_sel_t for options.
 *  @var xk_audio_216_mc_ab_config_t::pll_sync_freq
 *  When the external PLL is used, this defines the nominal reference clock frequency for multiplication by the PLL.
 * 
 */
typedef struct {
    xk_audio_216_mc_ab_clk_mode_t clk_mode;
    char codec_is_clk_master;
    xk_audio_216_mc_ab_usb_sel_t usb_sel;
    xk_audio_216_mc_ab_pcm_format_t pcm_format;
    unsigned pll_sync_freq;
} xk_audio_216_mc_ab_config_t;

/** Initialises the audio hardware ready for a configuration. Must be called once *after* xk_audio_316_mc_ab_board_setup().
 *
 *  \param   config     Reference to the xk_audio_216_mc_ab_config_t hardware configuration struct.
 */
void xk_audio_216_mc_ab_AudioHwInit(const REFERENCE_PARAM(xk_audio_216_mc_ab_config_t, config));

/** Configures the audio hardware following initialisation. This is typically called each time a sample rate or stream format change occurs.
 *
 *  \param   config         Reference to the xk_audio_216_mc_ab_config_t hardware configuration struct.
 *  \param   samFreq        The sample rate in Hertz.
 *  \param   mClk           The master clock rate in Hertz.
 *  \param   dsdMode        Controls whether the DAC is to be set into DSD mode (1) or PCM mode (0).
 *  \param   sampRes_DAC    The sample resolution of the DAC output in bits. Typically 16, 24 or 32.
 *  \param   sampRes_ADC    The sample resolution of the ADC input in bits. Typically 16, 24 or 32.
 */
void xk_audio_216_mc_ab_AudioHwConfig(const REFERENCE_PARAM(xk_audio_216_mc_ab_config_t, config),
                                      unsigned samFreq,
                                      unsigned mClk,
                                      unsigned dsdMode,
                                      unsigned sampRes_DAC,
                                      unsigned sampRes_ADC);

/**@}*/ // END: addtogroup xk_audio_216_mc_ab
