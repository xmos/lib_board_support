// Copyright 2024-2026 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#ifndef TLV320AIC3204_H_
#define TLV320AIC3204_H_

//Address on I2C bus
#define AIC3204_I2C_DEVICE_ADDR 0x18

//Register Addresess
// Page 0
#define AIC3204_PAGE_CTRL     0x00 // Register 0  - Page Control
#define AIC3204_SW_RST        0x01 // Register 1  - Software Reset
#define AIC3204_NDAC          0x0B // Register 11 - NDAC Divider Value
#define AIC3204_MDAC          0x0C // Register 12 - MDAC Divider Value
#define AIC3204_DOSR          0x0E // Register 14 - DOSR Divider Value (LS Byte)
#define AIC3204_NADC          0x12 // Register 18 - NADC Divider Value
#define AIC3204_MADC          0x13 // Register 19 - MADC Divider Value
#define AIC3204_AOSR          0x14 // Register 20 - AOSR Divider Value
#define AIC3204_CODEC_IF      0x1B // Register 27 - CODEC Interface Control
#define AIC3204_DAC_SIG_PROC  0x3C // Register 60 - DAC Sig Processing Block Control
#define AIC3204_ADC_SIG_PROC  0x3D // Register 61 - ADC Sig Processing Block Control
#define AIC3204_DAC_CH_SET1   0x3F // Register 63 - DAC Channel Setup 1
#define AIC3204_DAC_CH_SET2   0x40 // Register 64 - DAC Channel Setup 2
#define AIC3204_DACL_VOL_D    0x41 // Register 65 - DAC Left Digital Vol Control
#define AIC3204_DACR_VOL_D    0x42 // Register 66 - DAC Right Digital Vol Control
#define AIC3204_ADC_CH_SET    0x51 // Register 81 - ADC Channel Setup
#define AIC3204_ADC_FGA_MUTE  0x52 // Register 82 - ADC Fine Gain Adjust/Mute

// Page 1
#define AIC3204_PWR_CFG       0x01 // Register 1  - Power Config
#define AIC3204_LDO_CTRL      0x02 // Register 2  - LDO Control
#define AIC3204_PLAY_CFG1     0x03 // Register 3  - Playback Config 1
#define AIC3204_PLAY_CFG2     0x04 // Register 4  - Playback Config 2
#define AIC3204_OP_PWR_CTRL   0x09 // Register 9  - Output Driver Power Control
#define AIC3204_CM_CTRL       0x0A // Register 10 - Common Mode Control
#define AIC3204_HPL_ROUTE     0x0C // Register 12 - HPL Routing Select
#define AIC3204_HPR_ROUTE     0x0D // Register 13 - HPR Routing Select
#define AIC3204_HPL_GAIN      0x10 // Register 16 - HPL Driver Gain
#define AIC3204_HPR_GAIN      0x11 // Register 17 - HPR Driver Gain
#define AIC3204_HP_START      0x14 // Register 20 - Headphone Driver Startup
#define AIC3204_MICBIAS       0x33 // Register 51 - MICBIAS Configuration
#define AIC3204_LPGA_P_ROUTE  0x34 // Register 52 - Left PGA Positive Input Route
#define AIC3204_LPGA_N_ROUTE  0x36 // Register 54 - Left PGA Negative Input Route
#define AIC3204_RPGA_P_ROUTE  0x37 // Register 55 - Right PGA Positive Input Route
#define AIC3204_RPGA_N_ROUTE  0x39 // Register 57 - Right PGA Negative Input Route
#define AIC3204_LPGA_VOL      0x3B // Register 59 - Left PGA Volume
#define AIC3204_RPGA_VOL      0x3C // Register 60 - Right PGA Volume
#define AIC3204_ADC_PTM       0x3D // Register 61 - ADC Power Tune Config
#define AIC3204_AN_IN_CHRG    0x47 // Register 71 - Analog Input Quick Charging Config
#define AIC3204_REF_STARTUP   0x7B // Register 123 - Reference Power Up Config

/* Values for AIC3204_CODEC_IF (page 0, register 27) selecting I2S format, slave
 * mode, with the given word length. */
#define AIC3204_CODEC_IF_I2S_16 0x00
#define AIC3204_CODEC_IF_I2S_20 0x10
#define AIC3204_CODEC_IF_I2S_24 0x20
#define AIC3204_CODEC_IF_I2S_32 0x30

/* Value for AIC3204_MICBIAS (page 1, register 51): MICBIAS powered up and set to
 * 2.5V (with the full chip common mode at 0.9V). */
#define AIC3204_MICBIAS_ON_2V5  0x60

/** Analogue input routing options.
 *
 *  All routes use a 10K input impedance. Note the device can only route ``IN3_L`` to
 *  the left MICPGA, hence ::AIC3204_INPUT_IN3L_MONO being mono on the left channel.
 */
typedef enum
{
    /** Left MICPGA differential across ``IN2_L``/``IN2_R``, right MICPGA differential
     *  across ``IN1_R``/``IN1_L``. */
    AIC3204_INPUT_IN2_IN1_DIFF = 0,
    /** Left MICPGA from ``IN1_L`` and right MICPGA from ``IN2_L``, each referenced to
     *  the internal common mode ``CM1L``/``CM1R``. */
    AIC3204_INPUT_IN1L_IN2L_PSEUDO_DIFF,
    /** Left MICPGA from ``IN3_L`` referenced to the internal common mode, with MICBIAS
     *  enabled. The right MICPGA is muted. */
    AIC3204_INPUT_IN3L_MONO
} tlv320aic3204_input_t;

/** Configuration of the parts of the CODEC setup that differ between boards. */
typedef struct
{
    /** Analogue input routing. See ::tlv320aic3204_input_t. */
    tlv320aic3204_input_t input;
    /** I2S word length in bits. One of 16, 20, 24 or 32. */
    unsigned i2s_bits;
    /** Raw value written to AIC3204_LPGA_VOL. 0x00 is unmuted, 0dB. */
    unsigned micpga_gain_l;
    /** Raw value written to AIC3204_RPGA_VOL. 0x00 is unmuted, 0dB. */
    unsigned micpga_gain_r;
    /** Raw value written to AIC3204_HPL_GAIN. 0x00 is unmuted, 0dB. */
    unsigned hp_gain_l;
    /** Raw value written to AIC3204_HPR_GAIN. 0x00 is unmuted, 0dB. */
    unsigned hp_gain_r;
} tlv320aic3204_config_t;

/**
 * \addtogroup tlv320aic3204
 *
 * Shared driver for the Texas Instruments TLV320AIC3204 stereo CODEC. Used by more
 * than one board so that the (long) register configuration sequence is written once.
 *
 * The functions take the client end of an ``i2c_master_if`` connection to the CODEC.
 * The connection may span tiles, so the caller does not need to be on the tile that
 * owns the I2C master; `XC` carries the interface calls over a channel automatically.
 * @{
 */

/** Error codes returned by tlv320aic3204_init(). */
#define AIC3204_OK              (0)
/** The CODEC did not respond as expected over I2C. */
#define AIC3204_ERR_NO_DEVICE   (1)
/** An I2C register access was not acknowledged or did not complete. */
#define AIC3204_ERR_I2C         (2)

#ifdef __XC__

/** Resets and configures the CODEC over I2C.
 *
 *  The caller is responsible for having released the CODEC reset line and allowed
 *  the device to come out of reset before calling this.
 *
 *  \param   i2c       Client end of an I2C master interface connected to the CODEC.
 *  \param   config    Reference to the tlv320aic3204_config_t configuration struct.
 *  \returns AIC3204_OK on success, AIC3204_ERR_NO_DEVICE if the CODEC did not respond
 *           as expected, or AIC3204_ERR_I2C if an I2C access failed.
 */
int tlv320aic3204_init(client interface i2c_master_if i2c,
                       const tlv320aic3204_config_t &config);

/** Applies a sample rate / master clock change to the CODEC.
 *
 *  The clock dividers programmed by tlv320aic3204_init() (NDAC/MDAC/DOSR = 1/4/128
 *  and NADC/MADC/AOSR = 1/4/128) are correct for a master clock of 512 * sample rate,
 *  which is the ratio used by all boards currently supported. No register writes are
 *  therefore required on a rate change and this function does nothing. It exists so
 *  boards have a place to hook rate-dependent CODEC configuration should a different
 *  master clock ratio ever be needed.
 *
 *  \param   i2c            Client end of an I2C master interface connected to the CODEC.
 *  \param   sample_rate    The sample rate in Hertz.
 *  \param   mclk           The master clock rate in Hertz.
 */
void tlv320aic3204_config(client interface i2c_master_if i2c,
                          unsigned sample_rate,
                          unsigned mclk);

#endif // __XC__

/**@}*/ // END: addtogroup tlv320aic3204

#endif /* TLV320AIC3204_H_ */
