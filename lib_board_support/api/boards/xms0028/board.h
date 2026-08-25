// Copyright 2024-2026 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#ifndef __XMS0028_BOARD_H__
#define __XMS0028_BOARD_H__

#include "boards_utils.h"
#if (BOARD_SUPPORT_BOARD == XMS0028) || defined(__DOXYGEN__)
#include <xccompat.h>
#include "i2c.h"

/**
 * \addtogroup xms0028
 *
 * API for the xms0028 board.
 * @{
 */

/**
 *  @brief Analogue input source selection.
 *
 *  The board has two analogue input jacks wired to different CODEC inputs, and the
 *  source is fixed when xms0028_AudioHwInit() is called.
 */
typedef enum
{
    /** 3.5mm stereo line-level input jack, connected pseudo-differentially to reject
     *  ground-line noise. The left channel uses IN2_L/IN2_R and the right channel uses
     *  IN1_R/IN1_L. */
    XMS0028_INPUT_LINE_IN = 0,
    /** Microphone of the 3.5mm CTIA headset jack, on IN3_L. The CODEC can only route
     *  IN3_L to the left MICPGA, so capture is mono on the left channel and the right
     *  channel is muted. */
    XMS0028_INPUT_HEADSET_MIC
} xms0028_input_source_t;

/**
 *  @brief Configuration struct type for setting the hardware profile.
 *  @var
 */
typedef struct {
    /** Default MCLK frequency in Hz to generate using the secondary PLL at initialisation.
     *  The TLV320AIC3204 configuration expects MCLK to be 512 times the sample rate.
     *  Set to 0 to not generate MCLK; the application is responsible for providing MCLK in that case.
     */
    unsigned default_mclk;
    /** Which analogue input to capture from. See xms0028_input_source_t. */
    xms0028_input_source_t input_source;
} xms0028_config_t;

/** Runs the I2C master task used to configure the CODEC.
 *
 * This must be placed on tile[0], where the CODEC I²C lines are.
 * It runs until xms0028_i2c_master_exit() is called.
 *
 *  \param   i2c    Server side of the I2C master interface connection.
 */
void xms0028_i2c_master(SERVER_INTERFACE(i2c_master_if, i2c[1]));

/** Shuts the I2C master task down.
 *
 * Call this once the audio hardware is configured if no further dynamic
 * configuration is required, to free the logical core.
 *
 *  \param   i2c    Client side of the I2C master interface connection.
 */
void xms0028_i2c_master_exit(CLIENT_INTERFACE(i2c_master_if, i2c));

/** Initialises the audio hardware ready for a configuration. Must be called once *after* xms0028_i2c_master() has been started.
 *
 * This releases the CODEC from reset, configures it over I²C and, if requested,
 * starts generating MCLK using the secondary PLL. The generated MCLK must be
 * 512 times the intended sample rate.
 *
 * The CODEC reset line is on tile[0], so this must be called from tile[0].
 *
 *  \param   i2c        Client side of the I2C master interface connection.
 *  \param   config     Reference to the xms0028_config_t hardware configuration struct.
 */
void xms0028_AudioHwInit(CLIENT_INTERFACE(i2c_master_if, i2c),
                         const REFERENCE_PARAM(xms0028_config_t, config));

/** Configures the audio hardware following initialisation. This is typically called each time a sample rate or stream format change occurs.
 *
 *  \param   i2c            Client side of the I2C master interface connection.
 *  \param   samFreq        The sample rate in Hertz.
 *  \param   mClk           The master clock rate in Hertz. If non-zero the secondary PLL is used to
 *                          generate a fixed MCLK of this frequency. The CODEC configuration expects
 *                          this to be 512 times \p samFreq.
 *  \param   dsdMode        Controls whether the DAC is to be set into DSD mode (1) or PCM mode (0). Unused on this board.
 *  \param   sampRes_DAC    The sample resolution of the DAC output in bits. Unused on this board.
 *  \param   sampRes_ADC    The sample resolution of the ADC input in bits. Unused on this board.
 */
void xms0028_AudioHwConfig(CLIENT_INTERFACE(i2c_master_if, i2c),
                           unsigned samFreq, unsigned mClk, unsigned dsdMode,
                           unsigned sampRes_DAC, unsigned sampRes_ADC);

/**@}*/ // END: addtogroup xms0028

#endif

#endif // __XMS0028_BOARD_H__
