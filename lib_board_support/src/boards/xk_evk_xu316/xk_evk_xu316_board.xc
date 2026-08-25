// Copyright 2024-2026 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include <xs1.h>


#include <boards_utils.h>

#if BOARD_SUPPORT_BOARD == XK_EVK_XU316


#include "xassert.h"
#include "i2c.h"
#include "tlv320aic3204.h"
#include <xk_evk_xu316/board.h>
#include <platform.h>
extern "C" {
    #include "sw_pll.h"
}


// CODEC I2C lines
on tile[0]: port p_i2c_scl = XS1_PORT_1N;
on tile[0]: port p_i2c_sda = XS1_PORT_1O;

// CODEC reset line
on tile[1]: out port p_codec_reset  = PORT_CODEC_RST_N;

// CODEC Reset bit mask
#define CODEC_RELEASE_RESET      (0x8) // Release codec from reset

/* CODEC configuration for this board. The line-in jack is wired across the IN1/IN2
 * pairs and the line-out jack is driven from the headphone drivers. */
static const tlv320aic3204_config_t codec_config =
{
    AIC3204_INPUT_IN2_IN1_DIFF, // input
    32,                         // i2s_bits
    0x00,                       // micpga_gain_l - unmuted, 0dB
    0x00,                       // micpga_gain_r - unmuted, 0dB
    0x00,                       // hp_gain_l     - unmuted, 0dB
    0x00                        // hp_gain_r     - unmuted, 0dB
};


void xk_evk_xu316_i2c_master(server interface i2c_master_if i2c[1])
{
    i2c_master(i2c, 1, p_i2c_scl, p_i2c_sda, 10);
}

void xk_evk_xu316_i2c_master_exit(client interface i2c_master_if i2c)
{
    i2c.shutdown();
}


/* Note this is called from tile[1], where the CODEC reset line is, but the I2C lines
 * to the CODEC are on tile[0]. The i2c_master_if connection spans the two tiles; XC
 * implements the interface calls over a channel. */
void xk_evk_xu316_AudioHwInit(client interface i2c_master_if i2c,
                              const xk_evk_xu316_config_t &config)
{
    /* Take CODEC out of reset */
    p_codec_reset <: CODEC_RELEASE_RESET;

    delay_milliseconds(100);

    /* The CODEC configuration sequence is shared with every other board carrying this
     * device. See lib_board_support/src/drivers/tlv320aic3204.xc */
    const int status = tlv320aic3204_init(i2c, codec_config);

    assert(status == AIC3204_OK && msg("CODEC initialisation failed"));

    // Set the fractional divider if used
    if (config.default_mclk) {
        sw_pll_fixed_clock(config.default_mclk);
    }

    delay_milliseconds(1);
}


/* Configures the external audio hardware for the required sample frequency and
 * (optionally) generate a fixed mClk using the secondary PLL.
 *
 * Parameters:
 *  - i2c: Client side of the I2C master interface connection.
 *  - samFreq: Requested sample rate (Hz).
 *  - mClk: If non-zero, this function will use the secondary PLL to generate a fixed MCLK of mClk Hz.
 *          If zero, this function will not generate/modify MCLK; the application is responsible for
 *          generating the mClk.
 *  - dsdMode: DSD mode selector.
 *  - sampRes_DAC: DAC sample resolution (bits).
 *  - sampRes_ADC: ADC sample resolution (bits).
 */
void xk_evk_xu316_AudioHwConfig(client interface i2c_master_if i2c,
    unsigned samFreq, unsigned mClk, unsigned dsdMode,
    unsigned sampRes_DAC, unsigned sampRes_ADC)
{
    assert(samFreq >= 22050);

    tlv320aic3204_config(i2c, samFreq, mClk);

    if (mClk) {
        sw_pll_fixed_clock(mClk);
    }

    // Unused parameters in this implementation
    (void)dsdMode;
    (void)sampRes_DAC;
    (void)sampRes_ADC;
}

#endif
