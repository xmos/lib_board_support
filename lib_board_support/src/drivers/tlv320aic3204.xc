// Copyright 2024-2026 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include <xs1.h>

#include <boards_utils.h>

/* Shared by every board carrying a TLV320AIC3204. Add new boards here. */
#if (BOARD_SUPPORT_BOARD == XK_EVK_XU316)

#include "i2c.h"
#include "tlv320aic3204.h"

/* Returns non-zero if the register write was not acknowledged or did not complete. */
static inline unsigned reg_write(client interface i2c_master_if i2c, unsigned reg, unsigned val)
{
    return (i2c.write_reg(AIC3204_I2C_DEVICE_ADDR, reg, val) != I2C_REGOP_SUCCESS);
}

/* Returns the register value; the access status is reported through result. */
static inline unsigned reg_read(client interface i2c_master_if i2c, unsigned reg,
                                i2c_regop_res_t &result)
{
    return i2c.read_reg(AIC3204_I2C_DEVICE_ADDR, reg, result);
}

/* Translate a word length in bits into the AIC3204_CODEC_IF value selecting I2S,
 * slave mode, DOUT always driving. */
static unsigned codec_if_val(unsigned i2s_bits)
{
    switch(i2s_bits)
    {
        case 16: return AIC3204_CODEC_IF_I2S_16;
        case 20: return AIC3204_CODEC_IF_I2S_20;
        case 24: return AIC3204_CODEC_IF_I2S_24;
        default: return AIC3204_CODEC_IF_I2S_32;
    }
}

/* Program the analogue input routing. Must be called with the CODEC on page 1.
 * All routes use a 10K input impedance. */
static unsigned set_input_routing(client interface i2c_master_if i2c, tlv320aic3204_input_t input)
{
    unsigned err = 0;

    switch(input)
    {
        case AIC3204_INPUT_IN1L_IN2L_PSEUDO_DIFF:
            // Route IN1_L to LEFT_P, and the common mode to LEFT_M
            err |= reg_write(i2c, AIC3204_LPGA_P_ROUTE, 0x40);
            err |= reg_write(i2c, AIC3204_LPGA_N_ROUTE, 0x40);
            // Route IN2_L to RIGHT_P, and the common mode to RIGHT_M
            err |= reg_write(i2c, AIC3204_RPGA_P_ROUTE, 0x01);
            err |= reg_write(i2c, AIC3204_RPGA_N_ROUTE, 0x40);
            break;

        case AIC3204_INPUT_IN3L_MONO:
            // Enable MICBIAS
            err |= reg_write(i2c, AIC3204_MICBIAS, AIC3204_MICBIAS_ON_2V5);
            // Route IN3_L to LEFT_P, and the common mode to LEFT_M
            err |= reg_write(i2c, AIC3204_LPGA_P_ROUTE, 0x04);
            err |= reg_write(i2c, AIC3204_LPGA_N_ROUTE, 0x40);
            // Nothing routed to RIGHT_P; the right MICPGA is muted below
            err |= reg_write(i2c, AIC3204_RPGA_P_ROUTE, 0x00);
            err |= reg_write(i2c, AIC3204_RPGA_N_ROUTE, 0x40);
            break;

        case AIC3204_INPUT_IN2_IN1_DIFF:
        default:
            // Route IN2_L to LEFT_P
            err |= reg_write(i2c, AIC3204_LPGA_P_ROUTE, 0x10);
            // Route IN2_R to LEFT_M
            err |= reg_write(i2c, AIC3204_LPGA_N_ROUTE, 0x10);
            // Route IN1_R to RIGHT_P
            err |= reg_write(i2c, AIC3204_RPGA_P_ROUTE, 0x40);
            // Route IN1_L to RIGHT_M
            err |= reg_write(i2c, AIC3204_RPGA_N_ROUTE, 0x10);
            break;
    }

    return err;
}

int tlv320aic3204_init(client interface i2c_master_if i2c, const tlv320aic3204_config_t &config)
{
    i2c_regop_res_t result;
    unsigned err = 0;

    // Check we can talk to the CODEC
    const unsigned regVal = reg_read(i2c, AIC3204_NDAC, result);

    if(result != I2C_REGOP_SUCCESS)
    {
        return AIC3204_ERR_I2C;
    }

    if(regVal != 1)
    {
        return AIC3204_ERR_NO_DEVICE;
    }

    // Set register page to 0
    err |= reg_write(i2c, AIC3204_PAGE_CTRL, 0x00);

    // Initiate SW reset (PLL is powered off as part of reset)
    err |= reg_write(i2c, AIC3204_SW_RST, 0x01);

    // Program clock settings

    // Default is CODEC_CLKIN is from MCLK pin. Don't need to change this.
    // Power up NDAC and set to 1
    err |= reg_write(i2c, AIC3204_NDAC, 0x81);

    // Power up MDAC and set to 4
    err |= reg_write(i2c, AIC3204_MDAC, 0x84);

    // Power up NADC and set to 1
    err |= reg_write(i2c, AIC3204_NADC, 0x81);

    // Power up MADC and set to 4
    err |= reg_write(i2c, AIC3204_MADC, 0x84);

    // Program DOSR = 128
    err |= reg_write(i2c, AIC3204_DOSR, 0x80);

    // Program AOSR = 128
    err |= reg_write(i2c, AIC3204_AOSR, 0x80);

    // Set Audio Interface Config: I2S, slave mode, DOUT always driving.
    err |= reg_write(i2c, AIC3204_CODEC_IF, codec_if_val(config.i2s_bits));
    // Program the DAC processing block to be used - PRB_P1
    err |= reg_write(i2c, AIC3204_DAC_SIG_PROC, 0x01);
    // Program the ADC processing block to be used - PRB_R1
    err |= reg_write(i2c, AIC3204_ADC_SIG_PROC, 0x01);
    // Select Page 1
    err |= reg_write(i2c, AIC3204_PAGE_CTRL, 0x01);
    // Enable the internal AVDD_LDO:
    err |= reg_write(i2c, AIC3204_LDO_CTRL, 0x09);
    //
    // Program Analog Blocks
    // ---------------------
    //
    // Disable Internal Crude AVdd in presence of external AVdd supply or before powering up internal AVdd LDO
    err |= reg_write(i2c, AIC3204_PWR_CFG, 0x08);
    // Enable Master Analog Power Control
    err |= reg_write(i2c, AIC3204_LDO_CTRL, 0x01);
    // Set Common Mode voltages: Full Chip CM to 0.9V and Output Common Mode for Headphone to 0.9V.
    // Keeping output common mode at 0.9V improves crosstalk significantly.
    err |= reg_write(i2c, AIC3204_CM_CTRL, 0x00);
    // Set PowerTune Modes
    // Set the Left & Right DAC PowerTune mode to PTM_P3/4. Use Class-AB driver.
    err |= reg_write(i2c, AIC3204_PLAY_CFG1, 0x00);
    err |= reg_write(i2c, AIC3204_PLAY_CFG2, 0x00);
    // Set ADC PowerTune mode PTM_R4.
    err |= reg_write(i2c, AIC3204_ADC_PTM, 0x00);
    // Set MicPGA startup delay to 3.1ms
    err |= reg_write(i2c, AIC3204_AN_IN_CHRG, 0x31);
    // Set the REF charging time to 40ms
    err |= reg_write(i2c, AIC3204_REF_STARTUP, 0x01);
    // HP soft stepping settings for optimal pop performance at power up
    // Rpop used is 6k with N = 6 and soft step = 20usec. This should work with 47uF coupling
    // capacitor. Can try N=5,6 or 7 time constants as well. Trade-off delay vs "pop" sound.
    err |= reg_write(i2c, AIC3204_HP_START, 0x25);
    // Route Left DAC to HPL
    err |= reg_write(i2c, AIC3204_HPL_ROUTE, 0x08);
    // Route Right DAC to HPR
    err |= reg_write(i2c, AIC3204_HPR_ROUTE, 0x08);

    err |= set_input_routing(i2c, config.input);

    // Unmute HPL and set the requested gain
    err |= reg_write(i2c, AIC3204_HPL_GAIN, config.hp_gain_l);
    // Unmute HPR and set the requested gain
    err |= reg_write(i2c, AIC3204_HPR_GAIN, config.hp_gain_r);
    // Unmute Left MICPGA and set the requested gain
    err |= reg_write(i2c, AIC3204_LPGA_VOL, config.micpga_gain_l);
    // Right MICPGA: nothing is routed to it in mono mode, so mute it
    if(config.input == AIC3204_INPUT_IN3L_MONO)
    {
        err |= reg_write(i2c, AIC3204_RPGA_VOL, 0x80);
    }
    else
    {
        err |= reg_write(i2c, AIC3204_RPGA_VOL, config.micpga_gain_r);
    }
    // Power up HPL and HPR drivers
    err |= reg_write(i2c, AIC3204_OP_PWR_CTRL, 0x30);

    // Wait for for soft stepping to take effect
    delay_milliseconds(25);

    //
    // Power Up DAC/ADC
    // ----------------
    //
    // Select Page 0
    err |= reg_write(i2c, AIC3204_PAGE_CTRL, 0x00);
    // Power up the Left and Right DAC Channels. Route Left data to Left DAC and Right data to Right DAC.
    // DAC Vol control soft step 1 step per DAC word clock.
    err |= reg_write(i2c, AIC3204_DAC_CH_SET1, 0xd4);
    // Power up Left and Right ADC Channels, ADC vol ctrl soft step 1 step per ADC word clock.
    err |= reg_write(i2c, AIC3204_ADC_CH_SET, 0xc0);
    // Unmute Left and Right DAC digital volume control
    err |= reg_write(i2c, AIC3204_DAC_CH_SET2, 0x00);
    // Unmute Left and Right ADC Digital Volume Control.
    err |= reg_write(i2c, AIC3204_ADC_FGA_MUTE, 0x00);

    delay_milliseconds(1);

    return err ? AIC3204_ERR_I2C : AIC3204_OK;
}

void tlv320aic3204_config(client interface i2c_master_if i2c, unsigned sample_rate, unsigned mclk)
{
    /* The dividers programmed in tlv320aic3204_init() are correct for mclk == 512 * sample_rate,
     * so there is nothing to do on a rate change. See the header for details. */
    (void)sample_rate;
    (void)mclk;
}

#endif
