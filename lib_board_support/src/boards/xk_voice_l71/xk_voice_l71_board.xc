// Copyright 2024 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include <xs1.h>
#include <stdio.h>

#include <boards_utils.h>
#include "pcal6408a.h"
#include "tlv320dac3101.h"
#include "xassert.h"
#include "i2c.h"

#if BOARD_SUPPORT_BOARD == XK_VOICE_L71


#include "xassert.h"
#include "i2c.h"
#include "tlv320aic3204.h"
#include <xk_voice_l71/board.h>
#include <platform.h>
extern "C" {
    #include "sw_pll.h"
}

// CODEC I2C lines
on tile[0]: port p_scl = XS1_PORT_1N;
on tile[0]: port p_sda = XS1_PORT_1O;


// reduce verbosity
typedef client interface i2c_master_if i2c_cli;


// CODEC Reset bit mask
#define CODEC_RELEASE_RESET      (0x8) // Release codec from reset

typedef enum
{
    L71_AUDIOHW_CMD_REGWR,
    L71_AUDIOHW_CMD_REGRD
} xk_voice_l71_audioHwCmd_t;

static inline void PCAL6408_REGWRITE(unsigned reg, unsigned val, client interface i2c_master_if i2c) {
    i2c.write_reg(PCAL6408A_I2C_ADDR, reg, val);
}

static inline void DAC3101_REGREAD(unsigned reg, unsigned &val, client interface i2c_master_if i2c)
{
    i2c_regop_res_t result;
    val = i2c.read_reg(DAC3101_I2C_DEVICE_ADDR, reg, result);
}

static inline void DAC3101_REGWRITE(unsigned reg, unsigned val, client interface i2c_master_if i2c)
{
    i2c.write_reg(DAC3101_I2C_DEVICE_ADDR, reg, val);
}

[[combinable]]
void AudioHwRemote2(chanend c, client interface i2c_master_if i2c)
{
    //init PCAL6408 once
    PCAL6408_REGWRITE(0x03, 0b10000011, i2c);   //RST_N, INT_N, and MUTE is input
    PCAL6408_REGWRITE(0x4F, 0b00000000, i2c);   //PushPull
    PCAL6408_REGWRITE(0x01, 0b00000100, i2c);   //DAC reset is high

    //Serve commands
    while(1)
    {
        select{
            case c :> unsigned cmd:
                if(cmd == AUDIOHW_CMD_REGRD)
                {
                    unsigned regAddr, regVal;
                    c :> regAddr;
                    DAC3101_REGREAD(regAddr, regVal, i2c);
                    c <: regVal;
                }
                else
                {
                    unsigned regAddr, regValue;
                    c :> regAddr;
                    c :> regValue;
                    DAC3101_REGWRITE(regAddr, regValue, i2c);
                }
                break;
        }
    }
}

void xk_voice_l71_AudioHwRemote(chanend c)
{
    i2c_master_if i2c[1];
    [[combine]]
    par
    {
        i2c_master(i2c, 1, p_scl, p_sda, 10);
        AudioHwRemote2(c, i2c[0]);
    }
}

unsafe chanend uc_audiohw;

static inline void CODEC_REGWRITE(unsigned reg, unsigned val)
{
    unsafe
    {
        uc_audiohw <: (unsigned) AUDIOHW_CMD_REGWR;
        uc_audiohw <: reg;
        uc_audiohw <: val;
    }
}

static inline void CODEC_REGREAD(unsigned reg, unsigned &val)
{
    unsafe
    {
        uc_audiohw <: (unsigned) AUDIOHW_CMD_REGRD;
        uc_audiohw <: reg;
        uc_audiohw :> val;
    }
}

void xk_voice_l71_AudioHwChanInit(chanend c)
{
    unsafe{uc_audiohw = c;}
}

/* Configures the external audio hardware for the required sample frequency.
 */
void xk_voice_l71_AudioHwConfig(
    const REFERENCE_PARAM(xk_voice_l71_config_t, config), 
    unsigned sample_rate, unsigned mClk)
{
    CODEC_REGWRITE(DAC3101_DAC_VOL, 0x0C);                     // mute digital volume control
    delay_milliseconds(10);

    sw_pll_fixed_clock(mClk);

    // This setup is for 1.024MHz in (BCLK), PLL of 98.304MHz 24.576MHz out and fs of 16kHz or
    // or 3.072MHz BCLK, PLL of 98.304MHz 24.576MHz out and fs of 48kHz

    int is_48_family = (mClk % 48000) == 0;
    unsigned pll_freq = is_48_family ? 98304000 : 90316800; // Target internal pll clock
    unsigned bclk_hz = sample_rate * 64;
    unsigned bclk_to_pll_mul = pll_freq / bclk_hz;
    xassert(pll_freq % bclk_hz == 0); // Check settings are valid


    // PLL = (R x J.D)/P
    const unsigned PLLP = 1;
    const unsigned PLLR = pll_freq / mClk;

    const unsigned PLLJ = bclk_to_pll_mul / PLLR;
    const unsigned PLLD = 0;
    const unsigned NDAC = 4; // To get to 24/22M MCLK from 98/90M
    const unsigned MDAC = 4; // To get to 6.144/5.6448M for DAC_MOD_CLK
    const unsigned DOSR = pll_freq / (NDAC * MDAC) / sample_rate;

    printf("PLLP: %u\n", PLLP);
    printf("PLLR: %u\n", PLLR);
    printf("pll_freq target: %u\n", pll_freq);
    printf("bclk_hz target: %u\n", bclk_hz);
    printf("bclk_to_pll_mul: %u\n", bclk_to_pll_mul);
    printf("PLLJ: %u\n", PLLJ);
    printf("PLLD: %u\n", PLLD);
    unsigned dac_clk = (bclk_hz * PLLR * PLLJ) / NDAC;
    printf("DAC_CLK: %u\n", dac_clk);
    unsigned dac_mod_clk = dac_clk / MDAC;
    printf("DAC_MOD_CLK: %u\n", dac_mod_clk);
    printf("DAC_fs: %u\n", dac_mod_clk / DOSR);


    CODEC_REGWRITE(DAC3101_PAGE_CTRL, 0x00);             // set register page to 0
    CODEC_REGWRITE(DAC3101_PLL_J, PLLJ); 
    CODEC_REGWRITE(DAC3101_PLL_D_LSB, PLLD & 0xff);
    CODEC_REGWRITE(DAC3101_PLL_D_MSB, (PLLD & 0xff00) >> 8);

    CODEC_REGWRITE(DAC3101_B_DIV_VAL, 0x80 + 1);         //bclk divider to 1
    delay_milliseconds(2);

    // Set PLL_CLKIN = BCLK (device pin), CODEC_CLKIN = PLL_CLK (generated on-chip)
    //CODEC_REGWRITE(DAC3101_CLK_GEN_MUX, (0b01 << 2) + 0b11) == 0 &&
    CODEC_REGWRITE(DAC3101_CLK_GEN_MUX, (0b00 << 2) + 0b00);    // PLL_CLKIN and CODEC_CLKIN = MCLK pin

    CODEC_REGWRITE(DAC3101_PLL_P_R, 0x80 + (PLLP << 4)+ PLLR);

    CODEC_REGWRITE(DAC3101_NDAC_VAL, 0x80 + NDAC);              //NDAC clock divider and power up
    CODEC_REGWRITE(DAC3101_MDAC_VAL, 0x80 + MDAC);
    CODEC_REGWRITE(DAC3101_DOSR_VAL_LSB, DOSR & 0xff);          // OSR to divide DOSR
    CODEC_REGWRITE(DAC3101_DOSR_VAL_MSB, (DOSR & 0xff00) >> 8);

    CODEC_REGWRITE(DAC3101_PAGE_CTRL, 0x00);                   // register page 0
    CODEC_REGWRITE(DAC3101_DAC_DAT_PATH, 0xD4);                // power up DAC
    CODEC_REGWRITE(DAC3101_DACL_VOL_D, 0x00);                  // DAC left gain = 0dB
    CODEC_REGWRITE(DAC3101_DACR_VOL_D, 0x00);                  // DAC right gain = 0dB
    CODEC_REGWRITE(DAC3101_DAC_VOL, 0x00);                     // unmute digital volume control
    delay_milliseconds(100);

}

/* Note this is called from tile[1] but the I2C lines to the CODEC are on tile[0]
 * use a channel to communicate CODEC reg read/writes to a remote core */
void xk_voice_l71_AudioHwInit(const xk_voice_l71_config_t &config)
{
    sw_pll_fixed_clock(config.default_mclk);

	CODEC_REGWRITE(DAC3101_PAGE_CTRL, 0x00);                   // set register page to 0
	CODEC_REGWRITE(DAC3101_SW_RST, 0x01);                      // init sw reset, powered off PLL
	
    CODEC_REGWRITE(DAC3101_CLKOUT_MUX, 0x04);                  // CLKOUT MUX to DAC_CLK
    CODEC_REGWRITE(DAC3101_CLKOUT_M_VAL, 0x81);                // CLKOUT M divide by 1
    CODEC_REGWRITE(DAC3101_GPIO1_IO, 0x10);                    // GPIO1 output from CLKOUT
    
    CODEC_REGWRITE(DAC3101_CODEC_IF, 0x20);                    // i2s, 24 bit, slave mode
    
    CODEC_REGWRITE(DAC3101_PAGE_CTRL, 0x01);                   // set regsiter page to 1
    CODEC_REGWRITE(DAC3101_HP_DRVR, 0x14);                     // mid scale to 1.65V
    CODEC_REGWRITE(DAC3101_HP_DEPOP, 0x4E);                    // de-pop. 800ms powerup, Step 4ms
    CODEC_REGWRITE(DAC3101_DAC_OP_MIX, 0x44);                  // DAC output to amplifier
    CODEC_REGWRITE(DAC3101_HPL_DRVR, 0x06);                    // unmute HPL. Gain = 0
    CODEC_REGWRITE(DAC3101_HPR_DRVR, 0x06);                    // unmute HPR. Gain = 0
    CODEC_REGWRITE(DAC3101_SPKL_DRVR, 0x0C);                   // unmute Left class D. gain = 12dB
    CODEC_REGWRITE(DAC3101_SPKR_DRVR, 0x0C);                   // unmute right class D. gain = 12dB
    CODEC_REGWRITE(DAC3101_HP_DRVR, 0xD4);                     // HPL, HPR powered up
    CODEC_REGWRITE(DAC3101_SPK_AMP, 0xC6);                     // power up L and R class D
    CODEC_REGWRITE(DAC3101_HPL_VOL_A, 0x92);                   // HPL analog volume -9dB
    CODEC_REGWRITE(DAC3101_HPR_VOL_A, 0x92);                   // HPR analog volume -9dB
    CODEC_REGWRITE(DAC3101_SPKL_VOL_A, 0x92);                  // left class D volume -9dB
    CODEC_REGWRITE(DAC3101_SPKR_VOL_A, 0x92);                  // right class D volume -9dB

    CODEC_REGWRITE(DAC3101_PAGE_CTRL, 0x00);                   // set register page to 0
    CODEC_REGWRITE(DAC3101_DAC_VOL, 0x0C);                     // mute digital volume control

    delay_milliseconds(100);
}




#endif
