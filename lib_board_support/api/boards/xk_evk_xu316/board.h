// Copyright 2024 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
/// Hardware setup APIs for the XK-EVK-XU316

#ifndef __XK_EVK_XU316_BOARD_H__
#define __XK_EVK_XU316_BOARD_H__

#include <xccompat.h>

/**
 * \addtogroup xk_evk_xu316 xk_evk_xu316
 *
 * The common defines for using lib_board_support.
 * @{
 */

/** @struct xk_evk_xu316_config_t
 *  @brief Configuration struct type for setting the hardware profile.
 *  @var xk_audio_316_mc_ab_config_t::clk_mode
 *  See xk_audio_316_mc_ab_mclk_modes_t for available clock mode options.
 */
typedef struct {
    unsigned default_mclk;
} xk_evk_xu316_config_t;

/** Command enumeration for channel based commands to I2C master server on other tile.
 */
typedef enum
{
    AUDIOHW_CMD_REGWR,
    AUDIOHW_CMD_REGRD,
    AUDIOHW_CMD_EXIT
} audioHwCmd_t;

/** Starts an I2C master server task. Must be started *before* the tile[1] xk_evk_xu316_AudioHwInit calls. 
 * In the background this also starts a combinable channel to interface translation task
 * so the API may be used over a channel end however it still only occupies one thread.
 * May be exited after config by sending AUDIOHW_CMD_EXIT if dynamic configuration is not required.
 *
 *  \param   c    Channel connecting I2C master server and HW config functions.
 */
void xk_evk_xu316_AudioHwRemote(chanend c);

/** Initialises the audio hardware ready for a configuration. Must be called once *after* xk_evk_xu316_AudioHwRemote().
 *
 *  \param   i2c        Client side of I2C master interface connection.
 *  \param   config     Reference to the xk_audio_316_mc_ab_config_t hardware configuration struct.
 */
void xk_evk_xu316_AudioHwInit(chanend c, const REFERENCE_PARAM(xk_evk_xu316_config_t, config));

/** Configures the audio hardware following initialisation. This is typically called each time a sample rate or stream format change occurs.
 *
 *  \param   samFreq        The sample rate in Hertz.
 *  \param   mClk           The master clock rate in Hertz.
 *  \param   dsdMode        Controls whether the DAC is to be set into DSD mode (1) or PCM mode (0).
 *  \param   sampRes_DAC    The sample resolution of the DAC output in bits. Typically 16, 24 or 32.
 *  \param   sampRes_ADC    The sample resolution of the ADC input in bits. Typically 16, 24 or 32.
 */
void xk_evk_xu316_AudioHwConfig(unsigned samFreq, unsigned mClk, unsigned dsdMode,
    unsigned sampRes_DAC, unsigned sampRes_ADC);

/**@}*/ // END: addtogroup xk_evk_xu316

#endif // __XK_EVK_XU316_BOARD_H__
