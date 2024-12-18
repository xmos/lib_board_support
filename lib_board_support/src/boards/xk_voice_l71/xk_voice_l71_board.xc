// Copyright 2024 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include <xs1.h>
#include <stdio.h>
#include <print.h>

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


static inline void PCAL6408_REGWRITE(unsigned reg, unsigned val, client interface i2c_master_if i2c) {
    i2c_regop_res_t result = i2c.write_reg(PCAL6408A_I2C_ADDR, reg, val);
    if (result != I2C_REGOP_SUCCESS){
        printstr("PCAL6408_REGWRITE fail: 0x"); printhexln(reg);
    } else {
        printstr("PCAL6408_REGWRITE win: 0x"); printhex(reg); printstr(" - ");printhexln(val);
    }
}

static inline void DAC3101_REGREAD(unsigned reg, unsigned &val, client interface i2c_master_if i2c)
{
    i2c_regop_res_t result;
    val = i2c.read_reg(DAC3101_I2C_DEVICE_ADDR, reg, result);
}

static inline void DAC3101_REGWRITE(unsigned reg, unsigned val, client interface i2c_master_if i2c)
{
    i2c_regop_res_t result = i2c.write_reg(DAC3101_I2C_DEVICE_ADDR, reg, val);
    if (result != I2C_REGOP_SUCCESS){
        printstr("DAC3101_REGWRITE fail: 0x"); printhexln(reg);
    }
}

[[combinable]]
void AudioHwRemote2(chanend c, client interface i2c_master_if i2c)
{
    //init PCAL6408 once
    // PCAL6408_REGWRITE(PCAL6408A_CONF,               0b10000011, i2c);   //RST_N, INT_N, and MUTE is input
    // PCAL6408_REGWRITE(PCAL6408A_OUTPUT_PORT_CONF,   0b00000000, i2c);   //PushPull for outputs
    // PCAL6408_REGWRITE(PCAL6408A_OUTPUT_PORT,        0b00000100, i2c);   //DAC reset is high

    // TMP for 6416A
    PCAL6408_REGWRITE(0x06, 0xff, i2c); 
    delay_milliseconds(100);
    PCAL6408_REGWRITE(0x06, 0x7f, i2c); 
    delay_milliseconds(100);

    // for(int i=0; i<0x50;i++){
    //     i2c_regop_res_t result;
    //     unsigned val = i2c.read_reg(DAC3101_I2C_DEVICE_ADDR, i, result);
    //     if (result != I2C_REGOP_SUCCESS){
    //         printstr("PCAL6408_REGWRITE fail: 0x"); printhexln(i);
    //     } else {
    //         printstr("PCAL6408_REGWRITE win: 0x"); printhex(i); printstr(" - ");printhexln(val);
    //     }
    // }

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
                else if(cmd == AUDIOHW_CMD_REGWR)
                {
                    unsigned regAddr, regValue;
                    c :> regAddr;
                    c :> regValue;
                    DAC3101_REGWRITE(regAddr, regValue, i2c);
                }
                else if(cmd == AUDIOHW_CMD_EXIT)
                {
                    i2c.shutdown();
                    return;
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


    // set DAC_RST_N to 0 on the I2C expander (address 0x20)
    // We write to reg 6 which sets the direction to input if high
    // The pin has a pull down so first set it to Hi Z then Lo Z with 1 (default data)
    // IOEXP_REGWRITE(6, 0xff);
    // delay_milliseconds(100);
    // IOEXP_REGWRITE(6, 0x7f);
    // delay_milliseconds(100);

    // Set register page to 0
    CODEC_REGWRITE(DAC3101_PAGE_CTRL, 0x00);
    // Initiate SW reset (PLL is powered off as part of reset)
    CODEC_REGWRITE(DAC3101_SW_RST, 0x01);
    // PLL_CLK = CLKIN * ((RxJ.D)/P)

#if 1

    // Set register page to 0
    CODEC_REGWRITE(DAC3101_PAGE_CTRL, 0x00);
    // Initiate SW reset (PLL is powered off as part of reset)
    CODEC_REGWRITE(DAC3101_SW_RST, 0x01);


    // This setup is for 1.024MHz in (BCLK), PLL of 98.304MHz 24.576MHz out and fs of 16kHz or
    // or 3.072MHz BCLK, PLL of 98.304MHz 24.576MHz out and fs of 48kHz
    const unsigned PLLP = 1;
    const unsigned PLLR = 4;
    const unsigned PLLJ = (sample_rate == 16000) ? 24 : 8;
    const unsigned PLLD = 0;
    const unsigned NDAC = 4;
    const unsigned MDAC = (sample_rate == 16000) ? 6 : 4;
    const unsigned DOSR = (sample_rate == 16000) ? 256 : 128;

    // Set PLL J Value
    CODEC_REGWRITE(DAC3101_PLL_J, PLLJ);
    // Set PLL D to...
    CODEC_REGWRITE(DAC3101_PLL_D_LSB, PLLD & 0xff);
    CODEC_REGWRITE(DAC3101_PLL_D_MSB, (PLLD & 0xff00) >> 8);

    // Set BCLK divider to 1
    CODEC_REGWRITE(DAC3101_B_DIV_VAL, 0x80 + 1);

    delay_milliseconds(1);

    // Set PLL_CLKIN = BCLK (device pin), CODEC_CLKIN = PLL_CLK (generated on-chip)
    CODEC_REGWRITE(DAC3101_CLK_GEN_MUX, (0b01 << 2) + 0b11);

    // Set PLL P and R values and power up.
    CODEC_REGWRITE(DAC3101_PLL_P_R, 0x80 + (PLLP << 4)+ PLLR);

    // Set NDAC clock divider and power up.
    CODEC_REGWRITE(DAC3101_NDAC_VAL, 0x80 + NDAC);
    // Set MDAC clock divider and power up.
    CODEC_REGWRITE(DAC3101_MDAC_VAL, 0x80 + MDAC);
    // Set OSR clock divider to 256.
    CODEC_REGWRITE(DAC3101_DOSR_VAL_LSB, DOSR & 0xff);
    CODEC_REGWRITE(DAC3101_DOSR_VAL_MSB, (DOSR & 0xff00) >> 8);

    // Set CLKOUT Mux to DAC_CLK
    CODEC_REGWRITE(DAC3101_CLKOUT_MUX, 0x04);
    // Set CLKOUT M divider to 1 and power up.
    CODEC_REGWRITE(DAC3101_CLKOUT_M_VAL, 0x81);
    // Set GPIO1 output to come from CLKOUT output.
    CODEC_REGWRITE(DAC3101_GPIO1_IO, 0x10);

    // Set CODEC interface mode: I2S, 24 bit, slave mode (BCLK, WCLK both inputs).
    CODEC_REGWRITE(DAC3101_CODEC_IF, 0x20);
    // Set register page to 1
    CODEC_REGWRITE(DAC3101_PAGE_CTRL, 0x01);
    // Program common-mode voltage to mid scale 1.65V.
    CODEC_REGWRITE(DAC3101_HP_DRVR, 0x14);
    // Program headphone-specific depop settings.
    // De-pop, Power on = 800 ms, Step time = 4 ms
    CODEC_REGWRITE(DAC3101_HP_DEPOP, 0x4E);
    // Program routing of DAC output to the output amplifier (headphone/lineout or speaker)
    // LDAC routed to left channel mixer amp, RDAC routed to right channel mixer amp
    CODEC_REGWRITE(DAC3101_DAC_OP_MIX, 0x44);
    // Unmute and set gain of output driver
    // Unmute HPL, set gain = 0 db
    CODEC_REGWRITE(DAC3101_HPL_DRVR, 0x06);
    // Unmute HPR, set gain = 0 dB
    CODEC_REGWRITE(DAC3101_HPR_DRVR, 0x06);
    // Unmute Left Class-D, set gain = 12 dB
    CODEC_REGWRITE(DAC3101_SPKL_DRVR, 0x0C);
    // Unmute Right Class-D, set gain = 12 dB
    CODEC_REGWRITE(DAC3101_SPKR_DRVR, 0x0C);
    // Power up output drivers
    // HPL and HPR powered up
    CODEC_REGWRITE(DAC3101_HP_DRVR, 0xD4);
    // Power-up L and R Class-D drivers
    CODEC_REGWRITE(DAC3101_SPK_AMP, 0xC6);
    // Enable HPL output analog volume, set = -9 dB
    CODEC_REGWRITE(DAC3101_HPL_VOL_A, 0x92);
    // Enable HPR output analog volume, set = -9 dB
    CODEC_REGWRITE(DAC3101_HPR_VOL_A, 0x92);
    // Enable Left Class-D output analog volume, set = -9 dB
    CODEC_REGWRITE(DAC3101_SPKL_VOL_A, 0x92);
    // Enable Right Class-D output analog volume, set = -9 dB
    CODEC_REGWRITE(DAC3101_SPKR_VOL_A, 0x92);

    delay_milliseconds(100);

    // Power up DAC
    // Set register page to 0
    CODEC_REGWRITE(DAC3101_PAGE_CTRL, 0x00);
    // Power up DAC channels and set digital gain
    // Powerup DAC left and right channels (soft step enabled)
    CODEC_REGWRITE(DAC3101_DAC_DAT_PATH, 0xD4);
    // DAC Left gain = 0dB
    CODEC_REGWRITE(DAC3101_DACL_VOL_D, 0x00);
    // DAC Right gain = 0dB
    CODEC_REGWRITE(DAC3101_DACR_VOL_D, 0x00);
    // Unmute digital volume control
    // Unmute DAC left and right channels
    CODEC_REGWRITE(DAC3101_DAC_VOL, 0x00);
    delay_milliseconds(100);

#else
    // This setup is for 1.024MHz in (BCLK), PLL of 98.304MHz 24.576MHz out and fs of 16kHz or
    // or 3.072MHz BCLK, PLL of 98.304MHz 24.576MHz out and fs of 48kHz

    int is_48_family = (mClk % 48000) == 0;
    unsigned pll_freq = is_48_family ? 98304000 : 90316800; // Target internal pll clock
    unsigned bclk_hz = sample_rate * 64;
    unsigned bclk_to_pll_mul = pll_freq / bclk_hz;
    xassert(pll_freq % bclk_hz == 0); // Check settings are valid


    // PLL = (R x J.D)/P
    // const unsigned PLLP = 1;
    // const unsigned PLLR = pll_freq / mClk;

    // const unsigned PLLJ = bclk_to_pll_mul / PLLR;
    // const unsigned PLLD = 0;
    // const unsigned NDAC = 4; // To get to 24/22M MCLK from 98/90M
    // const unsigned MDAC = 4; // To get to 6.144/5.6448M for DAC_MOD_CLK
    // const unsigned DOSR = pll_freq / (NDAC * MDAC) / sample_rate;


    const unsigned PLLP = 1;
    const unsigned PLLR = 4;
    const unsigned PLLJ = (sample_rate == 16000) ? 24 : 8;
    const unsigned PLLD = 0;
    const unsigned NDAC = 4;
    const unsigned MDAC = (sample_rate == 16000) ? 6 : 4;
    const unsigned DOSR = (sample_rate == 16000) ? 256 : 128;


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
    CODEC_REGWRITE(DAC3101_CLK_GEN_MUX, (0b01 << 2) + 0b11);
    CODEC_REGWRITE(DAC3101_PLL_P_R, 0x80 + (PLLP << 4)+ PLLR);
    CODEC_REGWRITE(DAC3101_NDAC_VAL, 0x80 + NDAC);              // NDAC clock divider and power up
    CODEC_REGWRITE(DAC3101_NDAC_VAL, 0x80 + NDAC);              // NDAC clock divider and power up
    CODEC_REGWRITE(DAC3101_DOSR_VAL_LSB, DOSR & 0xff);          // OSR to divide DOSR
    CODEC_REGWRITE(DAC3101_DOSR_VAL_MSB, (DOSR & 0xff00) >> 8);

    CODEC_REGWRITE(DAC3101_PAGE_CTRL, 0x00);                   // register page 0
    CODEC_REGWRITE(DAC3101_DAC_DAT_PATH, 0xD4);                // power up DAC
    CODEC_REGWRITE(DAC3101_DACL_VOL_D, 0x00);                  // DAC left gain = 0dB
    CODEC_REGWRITE(DAC3101_DACR_VOL_D, 0x00);                  // DAC right gain = 0dB
    CODEC_REGWRITE(DAC3101_DAC_VOL, 0x00);                     // unmute digital volume control


    delay_milliseconds(100);
#endif
}

/* Note this is called from tile[1] but the I2C lines to the CODEC are on tile[0]
 * use a channel to communicate CODEC reg read/writes to a remote core */
void xk_voice_l71_AudioHwInit(const xk_voice_l71_config_t &config)
{
    sw_pll_fixed_clock(config.default_mclk);

	// CODEC_REGWRITE(DAC3101_PAGE_CTRL, 0x00);                   // set register page to 0
	// CODEC_REGWRITE(DAC3101_SW_RST, 0x01);                      // init sw reset, powered off PLL
	
    // CODEC_REGWRITE(DAC3101_CLKOUT_MUX, 0x04);                  // CLKOUT MUX to DAC_CLK
    // CODEC_REGWRITE(DAC3101_CLKOUT_M_VAL, 0x81);                // CLKOUT M divide by 1
    // CODEC_REGWRITE(DAC3101_GPIO1_IO, 0x10);                    // GPIO1 output from CLKOUT
    
    // CODEC_REGWRITE(DAC3101_CODEC_IF, 0x20);                    // i2s, 24 bit, slave mode
    
    // CODEC_REGWRITE(DAC3101_PAGE_CTRL, 0x01);                   // set regsiter page to 1
    // CODEC_REGWRITE(DAC3101_HP_DRVR, 0x14);                     // mid scale to 1.65V
    // CODEC_REGWRITE(DAC3101_HP_DEPOP, 0x4E);                    // de-pop. 800ms powerup, Step 4ms
    // CODEC_REGWRITE(DAC3101_DAC_OP_MIX, 0x44);                  // DAC output to amplifier
    // CODEC_REGWRITE(DAC3101_HPL_DRVR, 0x06);                    // unmute HPL. Gain = 0
    // CODEC_REGWRITE(DAC3101_HPR_DRVR, 0x06);                    // unmute HPR. Gain = 0
    // CODEC_REGWRITE(DAC3101_SPKL_DRVR, 0x0C);                   // unmute Left class D. gain = 12dB
    // CODEC_REGWRITE(DAC3101_SPKR_DRVR, 0x0C);                   // unmute right class D. gain = 12dB
    // CODEC_REGWRITE(DAC3101_HP_DRVR, 0xD4);                     // HPL, HPR powered up
    // CODEC_REGWRITE(DAC3101_SPK_AMP, 0xC6);                     // power up L and R class D
    // CODEC_REGWRITE(DAC3101_HPL_VOL_A, 0x92);                   // HPL analog volume -9dB
    // CODEC_REGWRITE(DAC3101_HPR_VOL_A, 0x92);                   // HPR analog volume -9dB
    // CODEC_REGWRITE(DAC3101_SPKL_VOL_A, 0x92);                  // left class D volume -9dB
    // CODEC_REGWRITE(DAC3101_SPKR_VOL_A, 0x92);                  // right class D volume -9dB

    // CODEC_REGWRITE(DAC3101_PAGE_CTRL, 0x00);                   // set register page to 0
    // CODEC_REGWRITE(DAC3101_DAC_VOL, 0x0C);                     // mute digital volume control

    delay_milliseconds(100);
}




#endif
