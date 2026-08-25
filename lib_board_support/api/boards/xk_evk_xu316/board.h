// Copyright 2024-2026 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#ifndef __XK_EVK_XU316_BOARD_H__
#define __XK_EVK_XU316_BOARD_H__

#include "boards_utils.h"
#if (BOARD_SUPPORT_BOARD == XK_EVK_XU316) || defined(__DOXYGEN__)

#include <xccompat.h>
#include "i2c.h"

/**
 *  @brief Configuration struct type for setting the hardware profile.
 *  @var
 */
typedef struct {
    /** Default MCLK frequency in Hz to generate using the secondary PLL at initialisation.
     *  Set to 0 to not generate MCLK; the application is responsible for providing MCLK in that case.
     */
    unsigned default_mclk;
} xk_evk_xu316_config_t;


/**
 * \addtogroup xk_evk_xu316
 *
 * API for the xk_evk_xu316 board.
 *
 * The CODEC is configured over I²C. The application declares an ``i2c_master_if``
 * connection, runs xk_evk_xu316_i2c_master() as a task on the tile carrying the I²C
 * pins (tile[0]), and passes the client end to the configuration functions. The
 * client end may be used from either tile; `XC` implements the cross-tile case over
 * a channel automatically.
 * @{
 */

/** Runs the I2C master task used to configure the CODEC.
 *
 * This must be placed on tile[0], where the CODEC I²C lines are.
 * It runs until xk_evk_xu316_i2c_master_exit() is called.
 *
 *  \param   i2c    Server side of the I2C master interface connection.
 */
void xk_evk_xu316_i2c_master(SERVER_INTERFACE(i2c_master_if, i2c[1]));

/** Shuts the I2C master task down.
 *
 * Call this once the audio hardware is configured if no further dynamic
 * configuration is required, to free the logical core.
 *
 *  \param   i2c    Client side of the I2C master interface connection.
 */
void xk_evk_xu316_i2c_master_exit(CLIENT_INTERFACE(i2c_master_if, i2c));

/** Initialises the audio hardware ready for a configuration. Must be called once *after* xk_evk_xu316_i2c_master() has been started.
 *
 * This releases the CODEC from reset, configures it over I²C and, if requested,
 * starts generating MCLK using the secondary PLL.
 *
 * Note this must be called from tile[1], where the CODEC reset line is.
 *
 *  \param   i2c        Client side of the I2C master interface connection.
 *  \param   config     Reference to the xk_evk_xu316_config_t hardware configuration struct.
 */
void xk_evk_xu316_AudioHwInit(CLIENT_INTERFACE(i2c_master_if, i2c),
                              const REFERENCE_PARAM(xk_evk_xu316_config_t, config));

/** Configures the audio hardware following initialisation. This is typically called each time a sample rate or stream format change occurs.
 *
 *  \param   i2c            Client side of the I2C master interface connection.
 *  \param   samFreq        The sample rate in Hertz.
 *  \param   mClk           The master clock rate in Hertz. If non-zero the secondary PLL is used to
 *                          generate a fixed MCLK of this frequency.
 *  \param   dsdMode        Controls whether the DAC is to be set into DSD mode (1) or PCM mode (0).
 *  \param   sampRes_DAC    The sample resolution of the DAC output in bits. Typically 16, 24 or 32.
 *  \param   sampRes_ADC    The sample resolution of the ADC input in bits. Typically 16, 24 or 32.
 */
void xk_evk_xu316_AudioHwConfig(CLIENT_INTERFACE(i2c_master_if, i2c),
                                unsigned samFreq, unsigned mClk, unsigned dsdMode,
                                unsigned sampRes_DAC, unsigned sampRes_ADC);

/**@}*/ // END: addtogroup xk_evk_xu316

#endif

#endif // __XK_EVK_XU316_BOARD_H__
