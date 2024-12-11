// Copyright 2024 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include <xs1.h>


#include <boards_utils.h>
#include "pcal6408a.h"
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

#include "debug_print.h"

// CODEC I2C lines
on tile[0]: port p_scl = XS1_PORT_1N;
on tile[0]: port p_sda = XS1_PORT_1O;

#define DAC3101_I2C_DEVICE_ADDR 0x18

// TLV320DAC3101 Register Addresses
// Page 0
#define DAC3101_PAGE_CTRL     0x00 // Register 0 - Page Control
#define DAC3101_SW_RST        0x01 // Register 1 - Software Reset
#define DAC3101_CLK_GEN_MUX   0x04 // Register 4 - Clock-Gen Muxing
#define DAC3101_PLL_P_R       0x05 // Register 5 - PLL P and R Values
#define DAC3101_PLL_J         0x06 // Register 6 - PLL J Value
#define DAC3101_PLL_D_MSB     0x07 // Register 7 - PLL D Value (MSB)
#define DAC3101_PLL_D_LSB     0x08 // Register 8 - PLL D Value (LSB)
#define DAC3101_NDAC_VAL      0x0B // Register 11 - NDAC Divider Value
#define DAC3101_MDAC_VAL      0x0C // Register 12 - MDAC Divider Value
#define DAC3101_DOSR_VAL_MSB  0x0D // Register 13 - DOSR Divider Value (MS Byte)
#define DAC3101_DOSR_VAL_LSB  0x0E // Register 14 - DOSR Divider Value (LS Byte)
#define DAC3101_CLKOUT_MUX    0x19 // Register 25 - CLKOUT MUX
#define DAC3101_CLKOUT_M_VAL  0x1A // Register 26 - CLKOUT M_VAL
#define DAC3101_CODEC_IF      0x1B // Register 27 - CODEC Interface Control
#define DAC3101_B_DIV_VAL     0x1E // Register 30 - BCLK Divider
#define DAC3101_DAC_DAT_PATH  0x3F // Register 63 - DAC Data Path Setup
#define DAC3101_DAC_VOL       0x40 // Register 64 - DAC Vol Control
#define DAC3101_DACL_VOL_D    0x41 // Register 65 - DAC Left Digital Vol Control
#define DAC3101_DACR_VOL_D    0x42 // Register 66 - DAC Right Digital Vol Control
#define DAC3101_GPIO1_IO      0x33 // Register 51 - GPIO1 In/Out Pin Control
// Page 1
#define DAC3101_HP_DRVR       0x1F // Register 31 - Headphone Drivers
#define DAC3101_SPK_AMP       0x20 // Register 32 - Class-D Speaker Amp
#define DAC3101_HP_DEPOP      0x21 // Register 33 - Headphone Driver De-pop
#define DAC3101_DAC_OP_MIX    0x23 // Register 35 - DAC_L and DAC_R Output Mixer Routing
#define DAC3101_HPL_VOL_A     0x24 // Register 36 - Analog Volume to HPL
#define DAC3101_HPR_VOL_A     0x25 // Register 37 - Analog Volume to HPR
#define DAC3101_SPKL_VOL_A    0x26 // Register 38 - Analog Volume to Left Speaker
#define DAC3101_SPKR_VOL_A    0x27 // Register 39 - Analog Volume to Right Speaker
#define DAC3101_HPL_DRVR      0x28 // Register 40 - Headphone Left Driver
#define DAC3101_HPR_DRVR      0x29 // Register 41 - Headphone Right Driver
#define DAC3101_SPKL_DRVR     0x2A // Register 42 - Left Class-D Speaker Driver
#define DAC3101_SPKR_DRVR     0x2B // Register 43 - Right Class-D Speaker Driver

//=========================================================================================

// App PLL setup
#define APP_PLL_CTL_BYPASS       (0)   // 0 = no bypass, 1 = bypass.
#define APP_PLL_CTL_INPUT_SEL    (0)   // 0 = XTAL, 1 = sysPLL
#define APP_PLL_CTL_ENABLE       (1)   // 0 = disabled, 1 = enabled.

// 24MHz in, 24.576MHz out, integer mode
// Found exact solution:   IN  24000000.0, OUT  24576000.0, VCO 2457600000.0, RD  5, FD  512, OD 10, FOD  10
#define APP_PLL_CTL_OD_48        (4)   // Output divider = (OD+1)
#define APP_PLL_CTL_F_48         (511) // FB divider = (F+1)/2
#define APP_PLL_CTL_R_48         (4)   // Ref divider = (R+1)

#define APP_PLL_CTL_48           ((APP_PLL_CTL_BYPASS << 29) | (APP_PLL_CTL_INPUT_SEL << 28) | (APP_PLL_CTL_ENABLE << 27) |\
                                    (APP_PLL_CTL_OD_48 << 23) | (APP_PLL_CTL_F_48 << 8) | APP_PLL_CTL_R_48)

// Fractional divide is M/N
#define APP_PLL_FRAC_EN_48             (0)   // 0 = disabled
#define APP_PLL_FRAC_NPLUS1_CYCLES_48  (0)   // M value is this reg value + 1.
#define APP_PLL_FRAC_TOTAL_CYCLES_48   (0)   // N value is this reg value + 1.
#define APP_PLL_FRAC_48          ((APP_PLL_FRAC_EN_48 << 31) | (APP_PLL_FRAC_NPLUS1_CYCLES_48 << 8) | APP_PLL_FRAC_TOTAL_CYCLES_48)

// 24MHz in, 22.5792MHz out (44.1kHz * 512), frac mode
// Found exact solution:   IN  24000000.0, OUT  22579200.0, VCO 2257920000.0, RD  5, FD  470.400 (m =   2, n =   5), OD  5, FOD   10
#define APP_PLL_CTL_OD_441       (4)   // Output divider = (OD+1)
#define APP_PLL_CTL_F_441        (469) // FB divider = (F+1)/2
#define APP_PLL_CTL_R_441        (4)   // Ref divider = (R+1)

#define APP_PLL_CTL_441          ((APP_PLL_CTL_BYPASS << 29) | (APP_PLL_CTL_INPUT_SEL << 28) | (APP_PLL_CTL_ENABLE << 27) |\
                                    (APP_PLL_CTL_OD_441 << 23) | (APP_PLL_CTL_F_441 << 8) | APP_PLL_CTL_R_441)

#define APP_PLL_FRAC_EN_44             (1)   // 1 = enabled
#define APP_PLL_FRAC_NPLUS1_CYCLES_44  (1)   // M value is this reg value + 1.
#define APP_PLL_FRAC_TOTAL_CYCLES_44   (4)   // N value is this reg value + 1.define APP_PLL_CTL_R_441        (4)   // Ref divider = (R+1)
#define APP_PLL_FRAC_44   ((APP_PLL_FRAC_EN_44 << 31) | (APP_PLL_FRAC_NPLUS1_CYCLES_44 << 8) | APP_PLL_FRAC_TOTAL_CYCLES_44)

#define APP_PLL_DIV_INPUT_SEL    (1)   // 0 = sysPLL, 1 = app_PLL
#define APP_PLL_DIV_DISABLE      (0)   // 1 = disabled (pin connected to X1D11), 0 = enabled divider output to pin.
#define APP_PLL_DIV_VALUE        (4)   // Divide by N+1 - remember there's a /2 also afterwards for 50/50 duty cycle.
#define APP_PLL_DIV              ((APP_PLL_DIV_INPUT_SEL << 31) | (APP_PLL_DIV_DISABLE << 16) | APP_PLL_DIV_VALUE)


// reduce verbosity
typedef client interface i2c_master_if i2c_cli;


void xk_voice_l71_board_setup(const xk_voice_l71_config_t &config)
{

}


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

// [[combinable]]
void AudioHwRemote2(chanend c, client interface i2c_master_if i2c)
{
    debug_printf("starts audiohw\n");
    //init PCAL6408 once
    PCAL6408_REGWRITE(0x03, 0b10000011, i2c);   //RST_N, INT_N, and MUTE is input
    PCAL6408_REGWRITE(0x4F, 0b00000000, i2c);   //PushPull
    PCAL6408_REGWRITE(0x01, 0b00000100, i2c);   //DAC reset is high

    //init DAC3101
    while(1)
    {
        unsigned cmd;
        c :> cmd;

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
    }
}

void xk_voice_l71_AudioHwRemote(chanend c)
{
    i2c_master_if i2c[1];
    // [[combine]]
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
 * See gpio.h for I2C helper functions and gpio access
 */
void xk_voice_l71_AudioHwConfig(
    const REFERENCE_PARAM(xk_voice_l71_config_t, config), 
    unsigned samFreq, unsigned mClk, unsigned dsdMode,
    unsigned sampRes_DAC, unsigned sampRes_ADC)
{
    assert(samFreq >= 22050);

    // Set the AppPLL up to output MCLK.
    if ((samFreq % 22050) == 0)
    {
        // Disable the PLL
        write_node_config_reg(tile[1], XS1_SSWITCH_SS_APP_PLL_CTL_NUM, (APP_PLL_CTL_441 & 0xF7FFFFFF));
        // Enable the PLL to invoke a reset on the appPLL.
        write_node_config_reg(tile[1], XS1_SSWITCH_SS_APP_PLL_CTL_NUM, APP_PLL_CTL_441);
        // Must write the CTL register twice so that the F and R divider values are captured using a running clock.
        write_node_config_reg(tile[1], XS1_SSWITCH_SS_APP_PLL_CTL_NUM, APP_PLL_CTL_441);
        // Now disable and re-enable the PLL so we get the full 5us reset time with the correct F and R values.
        write_node_config_reg(tile[1], XS1_SSWITCH_SS_APP_PLL_CTL_NUM, (APP_PLL_CTL_441 & 0xF7FFFFFF));
        write_node_config_reg(tile[1], XS1_SSWITCH_SS_APP_PLL_CTL_NUM, APP_PLL_CTL_441);

        // Set the fractional divider if used
        write_node_config_reg(tile[0], XS1_SSWITCH_SS_APP_PLL_FRAC_N_DIVIDER_NUM, APP_PLL_FRAC_44);
    }
    else if ((samFreq % 24000) == 0)
    {
        // Disable the PLL
        write_node_config_reg(tile[1], XS1_SSWITCH_SS_APP_PLL_CTL_NUM, (APP_PLL_CTL_48 & 0xF7FFFFFF));
        // Enable the PLL to invoke a reset on the appPLL.
        write_node_config_reg(tile[1], XS1_SSWITCH_SS_APP_PLL_CTL_NUM, APP_PLL_CTL_48);
        // Must write the CTL register twice so that the F and R divider values are captured using a running clock.
        write_node_config_reg(tile[1], XS1_SSWITCH_SS_APP_PLL_CTL_NUM, APP_PLL_CTL_48);
        // Now disable and re-enable the PLL so we get the full 5us reset time with the correct F and R values.
        write_node_config_reg(tile[1], XS1_SSWITCH_SS_APP_PLL_CTL_NUM, (APP_PLL_CTL_48 & 0xF7FFFFFF));
        write_node_config_reg(tile[1], XS1_SSWITCH_SS_APP_PLL_CTL_NUM, APP_PLL_CTL_48);

        // Set the fractional divider if used
        write_node_config_reg(tile[0], XS1_SSWITCH_SS_APP_PLL_FRAC_N_DIVIDER_NUM, APP_PLL_FRAC_48);
    }

    // Wait for PLL output frequency to stabilise due to fractional divider enable
    delay_microseconds(100);

    // Turn on the clock output
    write_node_config_reg(tile[0], XS1_SSWITCH_SS_APP_CLK_DIVIDER_NUM, APP_PLL_DIV);
}

/* Note this is called from tile[1] but the I2C lines to the CODEC are on tile[0]
 * use a channel to communicate CODEC reg read/writes to a remote core */
void xk_voice_l71_AudioHwInit(const xk_voice_l71_config_t &config)
{
    // unsafe{uc_audiohw = c;}
    debug_printf ("Configure DAC\n");
    //dac3101_codec_reset();
    //xassert((sample_rate == 16000) || (sample_rate == 48000));

#if 0
    // This setup is for 1.024MHz in (BCLK), PLL of 98.304MHz 24.576MHz out and fs of 16kHz or
    // or 3.072MHz BCLK, PLL of 98.304MHz 24.576MHz out and fs of 48kHz
    const unsigned PLLP = 1;
    const unsigned PLLR = 4;
    const unsigned PLLJ = (sample_rate == 16000) ? 24 : 8;
    const unsigned PLLD = 0;
    const unsigned NDAC = 4;
    const unsigned MDAC = (sample_rate == 16000) ? 6 : 4;
    const unsigned DOSR = (sample_rate == 16000) ? 256 : 128;
#else
    // This setup works only for 24.576MHz MCLK and 96kHz sample rate
    const unsigned PLLP = 1;  // don't care
    const unsigned PLLR = 4;  // don't care
    const unsigned PLLJ = 8;  // don't care
    const unsigned PLLD = 0;
    const unsigned NDAC = 1;
    const unsigned MDAC = 8;
    const unsigned DOSR = 32;
#endif

		CODEC_REGWRITE(DAC3101_PAGE_CTRL, 0x00);             // set register page to 0
		CODEC_REGWRITE(DAC3101_SW_RST, 0x01);                // init sw reset, powered off PLL
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
        CODEC_REGWRITE(DAC3101_DOSR_VAL_LSB, DOSR & 0xff);          // OSR to divide by 256
        CODEC_REGWRITE(DAC3101_DOSR_VAL_MSB, (DOSR & 0xff00) >> 8);

        CODEC_REGWRITE(DAC3101_CLKOUT_MUX, 0x04);                  //CLKOUT MUX to DAC_CLK
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
        delay_milliseconds(100);

        CODEC_REGWRITE(DAC3101_PAGE_CTRL, 0x00);                   // register page 0
        CODEC_REGWRITE(DAC3101_DAC_DAT_PATH, 0xD4);                // power up DAC
        CODEC_REGWRITE(DAC3101_DACL_VOL_D, 0x00);                  // DAC left gain = 0dB
        CODEC_REGWRITE(DAC3101_DACR_VOL_D, 0x00);                  // DAC right gain = 0dB
        CODEC_REGWRITE(DAC3101_DAC_VOL, 0x00);                     // unmute digital volume control
        delay_milliseconds(100);

    debug_printf("Default freq %d\n", DEFAULT_FREQ);
#if 0
    // Set the fractional divider if used
    if(DEFAULT_FREQ % 22050 == 0) {
        write_node_config_reg(tile[0], XS1_SSWITCH_SS_APP_PLL_FRAC_N_DIVIDER_NUM, APP_PLL_FRAC_44);
    } else {
        write_node_config_reg(tile[0], XS1_SSWITCH_SS_APP_PLL_FRAC_N_DIVIDER_NUM, APP_PLL_FRAC_48);
    }
    delay_microseconds(100);  // wait for PLL stable
    write_node_config_reg(tile[0], XS1_SSWITCH_SS_APP_CLK_DIVIDER_NUM, APP_PLL_DIV);  //turn on clk output
    delay_milliseconds(1);
#endif
//    xk_voice_l71_AudioHwConfig( config, 48000, 0, 0, 0, 0);
    debug_printf ("End Configure DAC\n");
}




#endif
