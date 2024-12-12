// Copyright 2024 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#ifndef __XK_VOICE_L71_BOARD_H__
#define __XK_VOICE_L71_BOARD_H__

#include <xccompat.h>
#include "i2c.h"




/** 
 * @brief Type of clock to be instantiated. This may be a fixed clock using the application PLL,
 *  an adjustable clock using the CS2100 external PLL or an adjustable or fixed clock using 
 *  the on-chip application PLL.
 */
typedef enum {
    CLK_FIXED,      /** Generate fixed MCLK from XCORE using APP_PLL */ 
    CLK_EXTERNAL    /** Expect an externally provided MCLK  */
} xk_voice_l71_mclk_modes_t;


/**
 *  @brief Configuration struct type for setting the hardware profile.
 *  @var 
 */
typedef struct {
    /** xk_voice_l71_config_t::clk_mode See xk_voice_l71_mclk_modes_t for available clock mode options. */
    xk_voice_l71_mclk_modes_t clk_mode;
    char dac_is_clock_master;
    unsigned default_mclk;

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
 *  \param   config         Reference to the xk_voice_l71_config_t hardware configuration struct.
 *  \param   samFreq        The sample rate in Hertz.
 *  \param   mClk           The master clock rate in Hertz.
 */
void xk_voice_l71_AudioHwConfig( 
                                const REFERENCE_PARAM(xk_voice_l71_config_t, config),
                                unsigned samFreq,
                                unsigned mClk);

/**@}*/ // END: addtogroup xk_voice_l71

#endif // __XK_VOICE_L71_BOARD_H__
