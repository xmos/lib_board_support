// Copyright 2024 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#pragma once

#include <xccompat.h>
#include "i2c.h"

/**
 * \addtogroup xk_audio_316_mc_ab
 *
 * API for the xk_audio_316_mc_ab board.
 * @{
 */

/** I2C interface ports */
extern port p_scl;
extern port p_sda;

/** 
 * @brief Type of clock to be instantiated. This may be a fixed clock using the application PLL,
 *  an adjustable clock using the CS2100 external PLL or an adjustable or fixed clock using 
 *  the on-chip application PLL.
 */
typedef enum {
    CLK_FIXED,
    CLK_CS2100,
    CLK_PLL
} xk_audio_316_mc_ab_mclk_modes_t;

/** 
 * @brief Formats supported by the DAC and ADC. Either I2S using multiple data lines or TDM
 *  supporting multi-channel using a single data line.
 */
typedef enum {
    AUD_316_PCM_FORMAT_I2S,
    AUD_316_PCM_FORMAT_TDM
} xk_audio_316_mc_ab_pcm_format_t;


/** @}*/ // END: addtogroup xk_audio_316_mc_ab


/** @struct xk_audio_316_mc_ab_config_t
 *  Configuration struct type for setting the hardware profile.
 * 
 *  @var xk_audio_316_mc_ab_config_t::clk_mode
 *      See xk_audio_316_mc_ab_mclk_modes_t for available clock mode options.
 *  @var xk_audio_316_mc_ab_config_t::dac_is_clock_master
 *      Boolean setting for whether the DAC or the xcore.ai is I2S clock master. Set to 0 to make the xcore.ai master.
 *  @var xk_audio_316_mc_ab_config_t::default_mclk
 *      Nominal clock frequency in MHz. Standard rates are supported between 11.2896 MHz and 49.152 MHz.
 *  @var xk_audio_316_mc_ab_config_t::pll_sync_freq
 *      When the CLK_CS2100 is used, this defines the nominal reference clock frequency for multiplication by the PLL.
 *      This value is ignored when the CS2100 is not used.
 *  @var xk_audio_316_mc_ab_config_t::pcm_format
 *      See xk_audio_316_mc_ab_pcm_format_t for available data frame options.
 *  @var xk_audio_316_mc_ab_config_t::i2s_n_bits
 *      Number of bits per data frame in I2S.
 *  @var xk_audio_316_mc_ab_config_t::i2s_chans_per_frame
 *      This defines the number of audio channels per frame (a frame is a complete cycle of FSYNC or LRCLK).
 */
typedef struct {
    xk_audio_316_mc_ab_mclk_modes_t clk_mode;
    char dac_is_clock_master;
    unsigned default_mclk;
    unsigned pll_sync_freq;
    xk_audio_316_mc_ab_pcm_format_t pcm_format;
    unsigned i2s_n_bits;
    unsigned i2s_chans_per_frame;
} xk_audio_316_mc_ab_config_t;

/**
 * \addtogroup xk_audio_316_mc_ab
 *
 * API for the xk_audio_316_mc_ab board.
 * @{
 */


/** 
 * @brief Starts an I2C master task. Must be started from tile[0] *after* xk_audio_316_mc_ab_board_setup() and *before* and tile[1] HW calls.
 *
 *  \param   i2c        client side of I2C master interface connection.
 */
void xk_audio_316_mc_ab_i2c_master(SERVER_INTERFACE(i2c_master_if, i2c[1]));

/** 
 * @brief Performs the required port operations to enable and the audio hardware on the platform. Must be called from tile[0]
 *  and *before* xk_audio_316_mc_ab_AudioHwInit() is called.
 *
 *  \param   config     Reference to the xk_audio_316_mc_ab_config_t configuration struct.
 */
void xk_audio_316_mc_ab_board_setup(const REFERENCE_PARAM(xk_audio_316_mc_ab_config_t, config));

/** 
 * @brief Initialises the audio hardware ready for a configuration. Must be called once *after* xk_audio_316_mc_ab_board_setup().
 *
 *  \param   i2c        Client side of I2C master interface connection.
 *  \param   config     Reference to the xk_audio_316_mc_ab_config_t hardware configuration struct.
 */
void xk_audio_316_mc_ab_AudioHwInit(CLIENT_INTERFACE(i2c_master_if, i2c), const REFERENCE_PARAM(xk_audio_316_mc_ab_config_t, config));


/** 
 * @brief Configures the audio hardware following initialisation. This is typically called each time a sample rate or stream format change occurs.
 *
 *  \param   i2c            Client side of I2C master interface connection.
 *  \param   config         Reference to the xk_audio_316_mc_ab_config_t hardware configuration struct.
 *  \param   samFreq        The sample rate in Hertz.
 *  \param   mClk           The master clock rate in Hertz.
 *  \param   dsdMode        Controls whether the DAC is to be set into DSD mode (1) or PCM mode (0).
 *  \param   sampRes_DAC    The sample resolution of the DAC output in bits. Typically 16, 24 or 32.
 *  \param   sampRes_ADC    The sample resolution of the ADC input in bits. Typically 16, 24 or 32.
 */
void xk_audio_316_mc_ab_AudioHwConfig(  CLIENT_INTERFACE(i2c_master_if, i2c),
                                        const REFERENCE_PARAM(xk_audio_316_mc_ab_config_t, config),
                                        unsigned samFreq,
                                        unsigned mClk,
                                        unsigned dsdMode,
                                        unsigned sampRes_DAC,
                                        unsigned sampRes_ADC);

/** 
 * @brief Causes the tile[0] to exit, freeing up a thread. Must be called from tile[1]. Once called,
 *  HW config calls from tile[1] will block forever. It is possible to re-start xk_audio_316_mc_ab_i2c_master()
 *  on tile[0] if needed to re-enable this service.
 *
 *  \param   i2c     Client side of I2C master interface connection.
 */
void xk_audio_316_mc_ab_i2c_master_exit(CLIENT_INTERFACE(i2c_master_if, i2c));


/** @}*/ // END: addtogroup xk_audio_316_mc_ab

