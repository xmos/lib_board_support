// Copyright 2024-2026 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#ifndef __XK_VOICE_L71_BOARD_H__
#define __XK_VOICE_L71_BOARD_H__

#include <xccompat.h>


/** 
 * @brief Type of clock to be instantiated. This may be an external clock 
 * or an adjustable or fixed clock using the on-chip application PLL.
 */
typedef enum {
    /** Generate fixed MCLK from XCORE using APP_PLL */ 
    CLK_FIXED,
    /** Expect an externally provided MCLK. Note you will need to set ENABLE_MCLK in xk_voice_l71_rpi_enable_t during xk_voice_l71_AudioHwInit() */
    CLK_EXTERNAL
} xk_voice_l71_mclk_modes_t;

/** 
 * @brief Which DAC I2S data pin to use.
 */
typedef enum {
    /** Use default DAC data pin (primary) */ 
    DAC_DIN_PRI = 1,
    /** Use secondary DAC data pin (secondary)*/
    DAC_DIN_SEC = 2
} xk_voice_l71_dac_pin_t;

/** 
 * @brief Which of the I2C expander enable lines to set. These can be
 * ORed together. Setting these will connect the xcore chip to the 
 * raspberry PI expansion connector.
 */
typedef enum {
    /** All OEs disabled */
    ENABLE_NO_PINS  = 0x0,
    ENABLE_MCLK     = 0x1,
    ENABLE_SPI      = 0x2,
    ENABLE_I2S      = 0x4,
    ENABLE_INT      = 0x8
} xk_voice_l71_rpi_enable_t;

/**
 *  @brief Configuration struct type for setting the hardware profile.
 */
typedef struct {
    /** xk_voice_l71_config_t::clk_mode See xk_voice_l71_mclk_modes_t for available clock mode options. */
    xk_voice_l71_mclk_modes_t clk_mode;
    /** xk_voice_l71_config_t::oe_enables See xk_voice_l71_rpi_enable_t for available clock mode options. */
    xk_voice_l71_rpi_enable_t oe_enables;
    /** xk_voice_l71_config_t::dac_pin See xk_voice_l71_dac_pin_t for available clock mode options. */
    xk_voice_l71_dac_pin_t dac_pin;
    /** The initial MCLK frequency in Hz to output before xk_voice_l71_AudioHwConfig() is called */
    unsigned default_mclk;
} xk_voice_l71_config_t;


/**
 * \addtogroup xk_voice_l71
 *
 * API for the xk_voice_l71 board.
 * @{
 */

/** Starts an I2C master server task. Must be started on tile[0] *before* the tile[1] xk_voice_l71_AudioHwInit calls. 
 * In the background this also starts a combinable channel to interface translation task
 * so the API may be used over a channel end however it still only occupies one thread.
 * May be exited after config by calling xk_voice_l71_AudioHwRemoteKill() if dynamic configuration is not required.
 *
 *  \param   c    Server side of channel connecting I2C master server and HW config functions.
 */
void xk_voice_l71_AudioHwRemote(chanend c);

/** Initialises the client side global channel end for remote communications with I2C. Must be called on tile[1] *before* xk_voice_l71_AudioHwInit(). 
 *
 *  \param   c    Client side of channel connecting I2C master server and HW config functions.
 */
void xk_voice_l71_AudioHwChanInit(chanend c);

/** Initialises the audio hardware ready for a configuration. Must be called once *after* xk_voice_l71_AudioHwRemote() and xk_voice_l71_AudioHwChanInit().
 *
 *  \param   config     Reference to the xk_voice_l71_config_t hardware configuration struct.
 */
void xk_voice_l71_AudioHwInit(const REFERENCE_PARAM(xk_voice_l71_config_t, config));

/** Configures the audio hardware following initialisation. This is typically called each time a sample rate or stream format change occurs.
 *
 *  \param   config         Reference to the xk_voice_l71_config_t hardware configuration struct.
 *  \param   sample_rate    The sample rate in Hertz.
 *  \param   mClk           The master clock rate in Hertz.
 */
void xk_voice_l71_AudioHwConfig(const REFERENCE_PARAM(xk_voice_l71_config_t, config),
                                unsigned sample_rate,
                                unsigned mClk);

/** Kills the remote I2C task. No further DAC or board config will be possible unless xk_voice_l71_AudioHwRemote() is restarted.
 *
 *  \param   c    Server side of channel connecting I2C master server and HW config functions.
 */
void xk_voice_l71_AudioHwRemoteKill(void);

/**@}*/ // END: addtogroup xk_voice_l71


#endif // __XK_VOICE_L71_BOARD_H__
