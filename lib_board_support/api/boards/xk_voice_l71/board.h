// Copyright 2024 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#ifndef __XK_VOICE_L71_BOARD_H__
#define __XK_VOICE_L71_BOARD_H__

#include <xccompat.h>
#include "i2c.h"


/**
 *  @brief Configuration struct type for setting the hardware profile.
 *  @var 
 */
typedef struct {
    /** xk_voice_l71_config_t::clk_mode See xk_voice_l71_mclk_modes_t for available clock mode options. */
    
    // xk_voice_l71_mclk_modes_t clk_mode;
    char dac_is_clock_master;
    unsigned default_mclk;
    unsigned pll_sync_freq;
    // xk_voice_l71_pcm_format_t pcm_format;
    unsigned i2s_n_bits;
    unsigned i2s_chans_per_frame;
} xk_voice_l71_config_t;


/**
 * \addtogroup xk_voice_l71
 *
 * API for the xk_voice_l71 board.
 * @{
 */

/** Command enumeration for channel based commands to I2C master server on other tile.
 */
typedef enum
{
    AUDIOHW_CMD_REGWR,
    AUDIOHW_CMD_REGRD,
    AUDIOHW_CMD_EXIT
} audioHwCmd_t;

/** 
 * @brief Starts an I2C master task. Must be started from tile[0] *after* xk_audio_316_mc_ab_board_setup() and *before* and tile[1] HW calls.
 *
 *  \param   i2c        client side of I2C master interface connection.
 */
void xk_voice_l71_i2c_master(SERVER_INTERFACE(i2c_master_if, i2c[1]));

/** 
 * @brief Performs the required port operations to enable and the audio hardware on the platform. Must be called from tile[0]
 *  and *before* xk_audio_316_mc_ab_AudioHwInit() is called.
 *
 *  \param   config     Reference to the xk_audio_316_mc_ab_config_t configuration struct.
 */
void xk_voice_l71_board_setup(const REFERENCE_PARAM(xk_voice_l71_config_t, config));


/** Starts an I2C master server task. Must be started *before* the tile[1] xk_voice_l71_AudioHwInit calls. 
 * In the background this also starts a combinable channel to interface translation task
 * so the API may be used over a channel end however it still only occupies one thread.
 * May be exited after config by sending AUDIOHW_CMD_EXIT if dynamic configuration is not required.
 *
 *  \param   c    Server side of channel connecting I2C master server and HW config functions.
 */
void xk_voice_l71_AudioHwRemote(chanend c);

/** Initialises the client side channel for remote communications with I2C. Must be called on tile[1] *before* xk_voice_l71_AudioHwInit(). 
 *
 *  \param   c    Client side of channel connecting I2C master server and HW config functions.
 */
void xk_voice_l71_AudioHwChanInit(chanend c);

/** Initialises the audio hardware ready for a configuration. Must be called once *after* xk_voice_l71_AudioHwRemote() and xk_voice_l71_AudioHwChanInit().
 *
 *  \param   config     Reference to the xk_voice_l71_config_t hardware configuration struct.
 */
void xk_voice_l71_AudioHwInit( const REFERENCE_PARAM(xk_voice_l71_config_t, config));

/** Configures the audio hardware following initialisation. This is typically called each time a sample rate or stream format change occurs.
 *
 *  \param   samFreq        The sample rate in Hertz.
 *  \param   mClk           The master clock rate in Hertz.
 *  \param   dsdMode        Controls whether the DAC is to be set into DSD mode (1) or PCM mode (0).
 *  \param   sampRes_DAC    The sample resolution of the DAC output in bits. Typically 16, 24 or 32.
 *  \param   sampRes_ADC    The sample resolution of the ADC input in bits. Typically 16, 24 or 32.
 */
void xk_voice_l71_AudioHwConfig( 
                                const REFERENCE_PARAM(xk_voice_l71_config_t, config),
                                unsigned samFreq, unsigned mClk, unsigned dsdMode,
                                unsigned sampRes_DAC, unsigned sampRes_ADC);

/**@}*/ // END: addtogroup xk_voice_l71

#endif // __XK_VOICE_L71_BOARD_H__
