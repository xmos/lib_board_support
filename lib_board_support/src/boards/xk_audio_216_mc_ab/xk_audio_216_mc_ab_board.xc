// Copyright 2024 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include <xs1.h>
#include <assert.h>



#include <boards_utils.h>

#if BOARD_SUPPORT_BOARD == XK_AUDIO_216_MC_AB

#include <xk_audio_216_mc_ab/board.h>
#include <platform.h>

#include "xk_audio_216_mc_ab/gpio_access.h"
#include "i2c.h"
#include "cs4384.h"
#include "cs5368.h"
#include "cs2100.h"

// void xk_audio_216_mc_ab_init_ports();

/* The number of timer ticks to wait for the audio PLL to lock */
/* CS2100 lists typical lock time as 100 * input period */
#define     AUDIO_PLL_LOCK_DELAY     (40000000)



on tile[0] : out port xk_audio_216_mc_ab_p_gpio = XS1_PORT_8C;
port p_i2c = PORT_I2C;

#define DAC_REGWRITE(reg, val) {result = i2c.write_reg(CS4384_I2C_ADDR, reg, val);}
#define ADC_REGWRITE(reg, val) {result = i2c.write_reg(CS5368_I2C_ADDR, reg, val);}


static void wait_us(int microseconds)
{
    timer t;
    unsigned time;

    t :> time;
    t when timerafter(time + (microseconds * 100)) :> void;
}

void xk_audio_216_mc_ab_AudioHwInit(const xk_audio_216_mc_ab_config_t & config)
{
    /* Assert reset to ADC and DAC */
    aud_216_set_gpio(P_GPIO_DAC_RST_N, 0);
    aud_216_set_gpio(P_GPIO_ADC_RST_N, 0);

    /* 0b11 : USB B */
    /* 0b10 : USB A */
    if(AUD_216_USB_A == config.usb_sel) {
        aud_216_set_gpio(P_GPIO_USB_SEL0, 0);
        aud_216_set_gpio(P_GPIO_USB_SEL1, 1);
    }
    else
    {
        aud_216_set_gpio(P_GPIO_USB_SEL0, 1);
        aud_216_set_gpio(P_GPIO_USB_SEL1, 1);
    }

    if(AUD_216_CLK_FIXED != config.clk_mode) {
        /* If we have any digital input then use the external PLL - selected via MUX */
        aud_216_set_gpio(P_GPIO_PLL_SEL, 1);

        /* Initialise external PLL */
        i2c_master_if i2c[1];
        par
        {
            i2c_master_single_port(i2c, 1, p_i2c, 10, 0, 1, 0);
            {
                PllInit(i2c[0]);
                i2c[0].shutdown();
            }
        }
    }

    /* Drive low otherwise GPIO peek picks up pull-up resistor */
    aud_216_set_gpio(P_GPIO_VBUS_EN, 0);
}

/* Configures the external audio hardware for the required sample frequency.
 * See gpio.h for I2C helper functions and gpio access
 */
static void AudioHwConfig2(const xk_audio_216_mc_ab_config_t & config, unsigned samFreq, unsigned mClk, unsigned dsdMode,
    unsigned sampRes_DAC, unsigned sampRes_ADC, client interface i2c_master_if i2c)
{
    i2c_regop_res_t result;

    /* Put ADC and DAC into reset */
	aud_216_set_gpio(P_GPIO_ADC_RST_N, 0);
	aud_216_set_gpio(P_GPIO_DAC_RST_N, 0);

    /* Set master clock select appropriately */
    if(AUD_216_CLK_FIXED != config.clk_mode) {
        /* Configure external fractional-n clock multiplier for example 300Hz -> mClkFreq */
        PllMult(mClk, config.pll_sync_freq, i2c);

        /* Allow some time for mclk to lock and MCLK to stabilise - this is important to avoid glitches at start of stream */
        {
            timer t;
            unsigned time;
            t :> time;
            t when timerafter(time+AUDIO_PLL_LOCK_DELAY) :> void;
        }

        if(AUD_216_CLK_EXTERNAL_PLL == config.clk_mode) {
            /* In sync mode we don't currently expect to be locked */
            unsigned char data[1] = {0};
            while(1)
            {
                /* Read Unlock Indicator in PLL as sanity check... */
                CS2100_REGREAD(i2c, CS2100_DEVICE_CONTROL, data);
                if(!(data[0] & 0x80))
                {
                    break;
                }
            }
        }
    }
    else {
        if (0 == mClk % 44100)
        {
            aud_216_set_gpio(P_GPIO_MCLK_FSEL, 0);
        }
        else
        {
            aud_216_set_gpio(P_GPIO_MCLK_FSEL, 1); //mClk = MCLK_48
        }

        /* Allow MCLK to settle */
        wait_us(20000);
    }

    if(dsdMode)
    {
        /* DAC out out reset, note ADC left in reset in for DSD mode */
        aud_216_set_gpio(P_GPIO_DAC_RST_N, 1);

        /* Configure DAC values required for DSD mode */

        /* Mode Control 1 (Address: 0x02) */
        /* bit[7] : Control Port Enable (CPEN)     : Set to 1 for enable
         * bit[6] : Freeze controls (FREEZE)       : Set to 1 for freeze
         * bit[5] : PCM/DSD Selection (DSD/PCM)    : Set to 1 for DSD
         * bit[4:1] : DAC Pair Disable (DACx_DIS)  : All Dac Pairs enabled
         * bit[0] : Power Down (PDN)               : Powered down
         */
        DAC_REGWRITE(CS4384_MODE_CTRL, 0xe1);

        if (samFreq > 3000000)
        {
            /* DSD128 */
            /* DSD Control (Address: 0x04) */
            /* bit[7:5] : DSD Digital Inteface Format (DSD_DIF) : 128x over samples with 4x MCLK
             * bit[4] : Direct DSD Conversion: Set to 0, data sent to DSD processor
             * bit[3] : Static DSD detect : 1 for enabled
             * bit[2] : Invalid DSD Detect : 1 for enabled
             * bit[1] : DSD Phase Modulation Mode Select
             * bit[0] : DSD Phase Modulation Enable
             */
            DAC_REGWRITE(CS4384_DSD_CTRL, 0b11001100);
        }
        else
        {
            /* DSD64 */
            /* DSD Control (Address: 0x04) */
            /* bit[7:5] : DSD Digital Inteface Format (DSD_DIF) : 64x over samples with 8x MCLK
             * bit[4] : Direct DSD Conversion: Set to 0, data sent to DSD processor
             * bit[3] : Static DSD detect : 1 for enabled
             * bit[2] : Invalid DSD Detect : 1 for enabled
             * bit[1] : DSD Phase Modulation Mode Select
             * bit[0] : DSD Phase Modulation Enable
             */
            DAC_REGWRITE(CS4384_DSD_CTRL, 0b01001100);
        }

        /* Mode Control 1 (Address: 0x02) */
        /* bit[7] : Control Port Enable (CPEN)     : Set to 1 for enable
         * bit[6] : Freeze controls (FREEZE)       : Set to 0 for not freeze
         * bit[5] : PCM/DSD Selection (DSD/PCM)    : Set to 1 for DSD
         * bit[4:1] : DAC Pair Disable (DACx_DIS)  : All Dac Pairs enabled
         * bit[0] : Power Down (PDN)               : Power down disabled
         */
        DAC_REGWRITE(CS4384_MODE_CTRL, 0xA0);

        /* Note: ADC kept in reset, no config sent. DSD mode is output only 0*/
    }
    else
    {
        /* dsdMode == 0 */
        /* Set MUX to PCM mode (muxes ADC I2S data lines) */
        aud_216_set_gpio(P_GPIO_DSD_MODE, 0);

        /* Take ADC out of reset */
        aud_216_set_gpio(P_GPIO_ADC_RST_N, 1);

        {
            unsigned dif = 0, mode = 0;
            if(AUD_216_PCM_FORMAT_TDM == config.pcm_format)
                dif = 0x02;   /* TDM */
            else
                dif = 0x01;   /* I2S */

            if(config.codec_is_clk_master) {
                /* Note, only the ADC device supports being I2S master.
                 * Set ADC as master and run DAC as slave */
                if(samFreq < 54000)
                    mode = 0x00;     /* Single-speed Mode Master */
                else if(samFreq < 108000)
                    mode = 0x01;     /* Double-speed Mode Master */
                else if(samFreq < 216000)
                    mode = 0x02;     /* Quad-speed Mode Master */
            } else {
                mode = 0x03;    /* Slave mode all speeds */
            }

            /* Reg 0x01: (GCTL) Global Mode Control Register */
            /* Bit[7]: CP-EN: Manages control-port mode
            * Bit[6]: CLKMODE: Setting puts part in 384x mode
            * Bit[5:4]: MDIV[1:0]: Set to 01 for /2
            * Bit[3:2]: DIF[1:0]: Data Format: 0x01 for I2S, 0x02 for TDM
            * Bit[1:0]: MODE[1:0]: Mode: 0x11 for slave mode
            */
            ADC_REGWRITE(CS5368_GCTL_MDE, 0b10010000 | (dif << 2) | mode);
        }

        /* Reg 0x06: (PDN) Power Down Register */
        /* Bit[7:6]: Reserved
         * Bit[5]: PDN-BG: When set, this bit powers-own the bandgap reference
         * Bit[4]: PDM-OSC: Controls power to internal oscillator core
         * Bit[3:0]: PDN: When any bit is set all clocks going to that channel pair are turned off
         */
        ADC_REGWRITE(CS5368_PWR_DN, 0b00000000);

        if(config.codec_is_clk_master) {
            /* Allow some time for clocks from ADC to become stable */
            wait_us(500);
        }

        /* Configure DAC with PCM values. Note 2 writes to mode control to enable/disable freeze/power down */
        aud_216_set_gpio(P_GPIO_DAC_RST_N, 1);//De-assert DAC reset

        wait_us(500);

        /* Mode Control 1 (Address: 0x02) */
        /* bit[7] : Control Port Enable (CPEN)     : Set to 1 for enable
         * bit[6] : Freeze controls (FREEZE)       : Set to 1 for freeze
         * bit[5] : PCM/DSD Selection (DSD/PCM)    : Set to 0 for PCM
         * bit[4:1] : DAC Pair Disable (DACx_DIS)  : All Dac Pairs enabled
         * bit[0] : Power Down (PDN)               : Powered down
         */
        DAC_REGWRITE(CS4384_MODE_CTRL, 0b11000001);

        if(AUD_216_PCM_FORMAT_TDM == config.pcm_format) {
            /* PCM Control (Address: 0x03) */
            /* bit[7:4] : Digital Interface Format (DIF) : 0b1100 for TDM
             * bit[3:2] : Reserved
             * bit[1:0] : Functional Mode (FM) : 0x11 for auto-speed detect (32 to 200kHz)
            */
            DAC_REGWRITE(CS4384_PCM_CTRL, 0b11000011);
        } else {
            /* PCM Control (Address: 0x03) */
            /* bit[7:4] : Digital Interface Format (DIF) : 0b0001 for I2S up to 24bit
             * bit[3:2] : Reserved
             * bit[1:0] : Functional Mode (FM) : 0x00 - single-speed mode (4-50kHz)
             *                                 : 0x01 - double-speed mode (50-100kHz)
             *                                 : 0x10 - quad-speed mode (100-200kHz)
             *                                 : 0x11 - auto-speed detect (32 to 200kHz)
             *                                 (note, some Mclk/SR ratios not supported in auto)
             *
             */
            unsigned char regVal = 0;
            if(samFreq < 50000)
                regVal = 0b00010100;
            else if(samFreq < 100000)
                regVal = 0b00010101;
            else //if(samFreq < 200000)
                regVal = 0b00010110;

            DAC_REGWRITE(CS4384_PCM_CTRL, regVal);
        }

        /* Mode Control 1 (Address: 0x02) */
        /* bit[7] : Control Port Enable (CPEN)     : Set to 1 for enable
         * bit[6] : Freeze controls (FREEZE)       : Set to 0 for freeze
         * bit[5] : PCM/DSD Selection (DSD/PCM)    : Set to 0 for PCM
         * bit[4:1] : DAC Pair Disable (DACx_DIS)  : All Dac Pairs enabled
         * bit[0] : Power Down (PDN)               : Not powered down
         */
        DAC_REGWRITE(CS4384_MODE_CTRL, 0b10000000);
    }

    return;
}

void xk_audio_216_mc_ab_AudioHwConfig(const xk_audio_216_mc_ab_config_t & config,
                                      unsigned samFreq,
                                      unsigned mClk,
                                      unsigned dsdMode,
                                      unsigned sampRes_DAC,
                                      unsigned sampRes_ADC)
{
    i2c_master_if i2c[1];
    par
    {
        i2c_master_single_port(i2c, 1, p_i2c, 10, 0, 1, 0);
        {
            AudioHwConfig2(config, samFreq, mClk, dsdMode, sampRes_DAC, sampRes_ADC, i2c[0]);
            i2c[0].shutdown();
        }
    }
}

#endif
