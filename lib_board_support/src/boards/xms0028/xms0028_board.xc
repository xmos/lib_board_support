// Copyright 2024-2026 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include <xs1.h>


#include <boards_utils.h>

#if BOARD_SUPPORT_BOARD == XMS0028


#include "xassert.h"
#include "i2c.h"
#include "tlv320aic3204.h"
#include <xms0028/board.h>
#include <xms0028/gpio_access.h>
#include <platform.h>
extern "C" {
    #include "sw_pll.h"
}


/* CODEC I2C lines. Both share a single 4 bit port; the board has external pull-ups
 * on SCL and SDA as required by i2c_master_single_port(). */
on tile[0]: port p_i2c = PORT_I2C;

#define I2C_SCL_BIT             (2)
#define I2C_SDA_BIT             (3)
#define I2C_OTHER_BITS_MASK     (0)
#define I2C_KBITS_PER_SECOND    (100)

/* General purpose output port. Carries the three LEDs and the CODEC reset line, so it
 * is only ever written through the read-modify-write helpers in gpio_access.c. */
on tile[0]: out port xms0028_p_gpo = PORT_GP_OUT;

/* Buttons, active low. Bits 2 and 3 only; bit 1 of this port is the CODEC INT line. */
on tile[0]: in port xms0028_p_buttons = PORT_BUTTON;


static void get_codec_config(xms0028_input_source_t input_source, tlv320aic3204_config_t &config)
{
    config.input = (input_source == XMS0028_INPUT_HEADSET_MIC) ?
                        AIC3204_INPUT_IN3L_MONO :
                        AIC3204_INPUT_IN2_IN1_DIFF;
    config.i2s_bits      = 32;
    config.micpga_gain_l = 0x00; // unmuted, 0dB
    config.micpga_gain_r = 0x00; // unmuted, 0dB
    config.hp_gain_l     = 0x00; // unmuted, 0dB
    config.hp_gain_r     = 0x00; // unmuted, 0dB
}


void xms0028_i2c_master(server interface i2c_master_if i2c[1])
{
    i2c_master_single_port(i2c, 1, p_i2c, I2C_KBITS_PER_SECOND,
                           I2C_SCL_BIT, I2C_SDA_BIT, I2C_OTHER_BITS_MASK);
}

void xms0028_i2c_master_exit(client interface i2c_master_if i2c)
{
    i2c.shutdown();
}


void xms0028_AudioHwInit(client interface i2c_master_if i2c, const xms0028_config_t &config)
{
    tlv320aic3204_config_t codec_config;

    /* Pulse the CODEC reset line. It is active low and shares a port with the LEDs,
     * hence the read-modify-write helper. */
    xms0028_gpo_set(XMS0028_CODEC_RST_N, 0);
    delay_milliseconds(1);
    xms0028_gpo_set(XMS0028_CODEC_RST_N, XMS0028_CODEC_RST_N);

    delay_milliseconds(100);

    get_codec_config(config.input_source, codec_config);

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
 * (optionally) generates a fixed mClk using the secondary PLL.
 *
 * Parameters:
 *  - i2c: Client side of the I2C master interface connection.
 *  - samFreq: Requested sample rate (Hz).
 *  - mClk: If non-zero, this function will use the secondary PLL to generate a fixed MCLK of mClk Hz.
 *          If zero, this function will not generate/modify MCLK; the application is responsible for
 *          generating the mClk.
 *  - dsdMode: DSD mode selector. Unused, this board has no DSD capable DAC.
 *  - sampRes_DAC: DAC sample resolution (bits). Unused, the CODEC is configured for 32 bit I2S.
 *  - sampRes_ADC: ADC sample resolution (bits). Unused, the CODEC is configured for 32 bit I2S.
 */
void xms0028_AudioHwConfig(client interface i2c_master_if i2c,
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
