// Copyright 2025-2026 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include "boards_utils.h"
#if BOARD_SUPPORT_BOARD == XK_VOICE_L71
#include "xk_voice_l71/board.h"

#include <xs1.h>
#include <assert.h>
#include <stdio.h>
#include <platform.h>
#include "xassert.h"
#include "i2c.h"
#include "dac3101.h"
#include "pcal6408a.h"
extern "C" {
#include "sw_pll.h"
}

/* I2C io expander address on L71 board */
#define IOEXP_I2C_ADDR        PCAL6408A_I2C_ADDR

/* IO expander pinout */
#define XVF_RST_N_PIN   0
#define INT_N_PIN       1
#define DAC_RST_N_PIN   2
#define BOOT_SEL_PIN    3
#define MCLK_OE_PIN     4
#define SPI_OE_PIN      5
#define I2S_OE_PIN      6
#define MUTE_PIN        7

/* Commands available over the channel end */
#define AUDIOHW_CMD_INIT        10
#define AUDIOHW_CMD_CONFIG      11
#define AUDIOHW_CMD_EXIT        12

/* Port all on tile[0] */
port p_scl = PORT_I2C_SCL;
port p_sda = PORT_I2C_SDA;

/* Connection to client */
static unsafe chanend gc_audiohw;
typedef client interface i2c_master_if i2c_cli_t; /* reduce verbosity */

// These are called on tile[0]
static i2c_regop_res_t i2c_reg_write(i2c_cli_t i_i2c_client, uint8_t device_addr, uint8_t reg, uint8_t data)
{
    uint8_t a_data[2] = {reg, data};
    size_t n;
    i_i2c_client.write(device_addr, a_data, 2, n, 1);

    if (n == 0)
    {
        return I2C_REGOP_DEVICE_NACK;
    }
    if (n < 2)
    {
        return I2C_REGOP_INCOMPLETE;
    }

    return I2C_REGOP_SUCCESS;
}

static uint8_t i2c_reg_read(i2c_cli_t i_i2c_client, uint8_t device_addr, uint8_t reg, i2c_regop_res_t &result)
{
    uint8_t a_reg[1] = {reg};
    uint8_t data[1] = {0};
    size_t n;
    i2c_res_t res;

    res = i_i2c_client.write(device_addr, a_reg, 1, n, 0);

    if (n != 1)
    {
        result = I2C_REGOP_DEVICE_NACK;
        i_i2c_client.send_stop_bit();
        return 0;
    }

    res = i_i2c_client.read(device_addr, data, 1, 1);

    if (res == I2C_ACK)
    {
        result = I2C_REGOP_SUCCESS;
    }
    else
    {
        result = I2C_REGOP_DEVICE_NACK;
    }
    return data[0];
}

// This must be called on tile[0]
int set_enables_and_reset_dac(i2c_cli_t i_i2c, xk_voice_l71_rpi_enable_t enables)
{
    int error = 0;

    /* Set DAC_RST_N to 0 and enable all level shifters */
    /* OEs are set to output 1, but this will only happen if expander is set to output (next step)*/
    uint8_t output_bitmask =    (1 << MCLK_OE_PIN)   |
                                (1 << SPI_OE_PIN)    |
                                (1 << I2S_OE_PIN);
                                // DAC_RST_N_PIN = 0 implicitly

    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(i_i2c, IOEXP_I2C_ADDR, PCAL6408A_OUTPUT_PORT, output_bitmask));

    /* Pin directions 0 = output, 1 = input */
    uint8_t direction_bitmask = 0xff; /* all inputs */
    if(enables & ENABLE_MCLK)   direction_bitmask &= ~(1 << MCLK_OE_PIN);
    if(enables & ENABLE_SPI)    direction_bitmask &= ~(1 << SPI_OE_PIN);
    if(enables & ENABLE_I2S)    direction_bitmask &= ~(1 << I2S_OE_PIN);
    direction_bitmask &= ~(1 << DAC_RST_N_PIN);

    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(i_i2c, IOEXP_I2C_ADDR, PCAL6408A_CONF, direction_bitmask));

    delay_milliseconds(10); // Reset delay for DAC

    /* Set DAC RST high to bring out of reset */
    output_bitmask |= (1 << DAC_RST_N_PIN);
    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(i_i2c, IOEXP_I2C_ADDR, PCAL6408A_OUTPUT_PORT, output_bitmask));

    delay_milliseconds(10); // Reset exit delay for DAC


    /* Enable interrupts */
    if(enables & ENABLE_INT)
    {
        uint8_t interrupt_bitmask = 0xff & ~(1 << INT_N_PIN);
        error |= (I2C_REGOP_SUCCESS != i2c_reg_write(i_i2c, IOEXP_I2C_ADDR, PCAL6408A_INTERRUPT_MASK, interrupt_bitmask));
    }

    return error;
}


// This must be called on tile[0]
int dac3101_configure(i2c_cli_t i_i2c, unsigned samFreq, unsigned mclk, xk_voice_l71_dac_pin_t dac_pin)
{
    assert((samFreq == 16000) || (samFreq == 48000));

    int error = 0;

    // This setup is for 1.024MHz in (BCLK), PLL of 98.304MHz 24.576MHz out and fs of 16kHz or
    // or 3.072MHz BCLK, PLL of 98.304MHz 24.576MHz out and fs of 48kHz
    const unsigned PLLP = 1;
    const unsigned PLLR = 4;
    const unsigned PLLJ = (samFreq == 16000) ? 24 : 8;
    const unsigned PLLD = 0;
    const unsigned NDAC = 4;
    const unsigned MDAC = (samFreq == 16000) ? 6 : 4;
    const unsigned DOSR = (samFreq == 16000) ? 256 : 128;

    // Set register page to 0
    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(i_i2c, DAC3101_I2C_DEVICE_ADDR, DAC3101_PAGE_CTRL, 0x00));

    // Initiate SW reset (PLL is powered off as part of reset)
    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(i_i2c, DAC3101_I2C_DEVICE_ADDR, DAC3101_SW_RST, 0x01));

    // Program clock settings
    // Set PLL J Value
    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(i_i2c, DAC3101_I2C_DEVICE_ADDR, DAC3101_PLL_J, PLLJ));
    // Set PLL D to...
    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(i_i2c, DAC3101_I2C_DEVICE_ADDR, DAC3101_PLL_D_LSB, PLLD & 0xff));
    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(i_i2c, DAC3101_I2C_DEVICE_ADDR, DAC3101_PLL_D_MSB, (PLLD & 0xff00) >> 8));

    // Set BCLK divider to 1
    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(i_i2c, DAC3101_I2C_DEVICE_ADDR, DAC3101_B_DIV_VAL, 0x80 + 1));

    sw_pll_fixed_clock(mclk);

    // Wait for 1 ms
    delay_milliseconds(1);

    // Set PLL_CLKIN = BCLK (device pin), CODEC_CLKIN = PLL_CLK (generated on-chip)
    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(i_i2c, DAC3101_I2C_DEVICE_ADDR, DAC3101_CLK_GEN_MUX, (0b01 << 2) + 0b11));

    // Set PLL P and R values and power up.
    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(i_i2c, DAC3101_I2C_DEVICE_ADDR, DAC3101_PLL_P_R, 0x80 + (PLLP << 4)+ PLLR));

    // Set NDAC clock divider and power up.
    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(i_i2c, DAC3101_I2C_DEVICE_ADDR, DAC3101_NDAC_VAL, 0x80 + NDAC));
    // Set MDAC clock divider and power up.
    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(i_i2c, DAC3101_I2C_DEVICE_ADDR, DAC3101_MDAC_VAL, 0x80 + MDAC));
    // Set OSR clock divider to 256.
    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(i_i2c, DAC3101_I2C_DEVICE_ADDR, DAC3101_DOSR_VAL_LSB, DOSR & 0xff));
    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(i_i2c, DAC3101_I2C_DEVICE_ADDR, DAC3101_DOSR_VAL_MSB, (DOSR & 0xff00) >> 8));


    // Set CLKOUT Mux to DAC_CLK
    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(i_i2c, DAC3101_I2C_DEVICE_ADDR, DAC3101_CLKOUT_MUX, 0x04));
    // Set CLKOUT M divider to 1 and power up.
    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(i_i2c, DAC3101_I2C_DEVICE_ADDR, DAC3101_CLKOUT_M_VAL, 0x81));

    if(dac_pin == DAC_DIN_SEC)
    {
        // Set Secondary DIN is obtained from the GPIO1 pin.
        error |= (I2C_REGOP_SUCCESS != i2c_reg_write(i_i2c, DAC3101_I2C_DEVICE_ADDR, DAC3101_CODEC_IF2_C1, 0b00100100));
        // Set Secondary DIN is fed to codec serial-interface block.
        error |= (I2C_REGOP_SUCCESS != i2c_reg_write(i_i2c, DAC3101_I2C_DEVICE_ADDR, DAC3101_CODEC_IF2_C2, 0b00000001));
        // Set GPIO1 enabled as secondary input. (see pg. 62 of datasheet)
        error |= (I2C_REGOP_SUCCESS != i2c_reg_write(i_i2c, DAC3101_I2C_DEVICE_ADDR, DAC3101_GPIO1_IO, 0b00000100));
    } else {
        // Uses IF1 by default
    }

    // Set CODEC interface mode: I2S, 24 bit, slave mode (BCLK, WCLK both inputs).
    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(i_i2c, DAC3101_I2C_DEVICE_ADDR, DAC3101_CODEC_IF, 0x20));
    // Set register page to 1
    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(i_i2c, DAC3101_I2C_DEVICE_ADDR, DAC3101_PAGE_CTRL, 0x01));
    // Program common-mode voltage to mid scale 1.65V.
    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(i_i2c, DAC3101_I2C_DEVICE_ADDR, DAC3101_HP_DRVR, 0x14));
    // Program headphone-specific depop settings.
    // De-pop, Power on = 800 ms, Step time = 4 ms
    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(i_i2c, DAC3101_I2C_DEVICE_ADDR, DAC3101_HP_DEPOP, 0x4E));
    // Program routing of DAC output to the output amplifier (headphone/lineout or speaker)
    // LDAC routed to left channel mixer amp, RDAC routed to right channel mixer amp
    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(i_i2c, DAC3101_I2C_DEVICE_ADDR, DAC3101_DAC_OP_MIX, 0x44));
    // Unmute and set gain of output driver
    // Unmute HPL, set gain = 0 db
    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(i_i2c, DAC3101_I2C_DEVICE_ADDR, DAC3101_HPL_DRVR, 0x06));
    // Unmute HPR, set gain = 0 dB
    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(i_i2c, DAC3101_I2C_DEVICE_ADDR, DAC3101_HPR_DRVR, 0x06));
    // Unmute Left Class-D, set gain = 12 dB
    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(i_i2c, DAC3101_I2C_DEVICE_ADDR, DAC3101_SPKL_DRVR, 0x0C));
    // Unmute Right Class-D, set gain = 12 dB
    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(i_i2c, DAC3101_I2C_DEVICE_ADDR, DAC3101_SPKR_DRVR, 0x0C));
    // Power up output drivers
    // HPL and HPR powered up
    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(i_i2c, DAC3101_I2C_DEVICE_ADDR, DAC3101_HP_DRVR, 0xD4));
    // Power-up L and R Class-D drivers
    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(i_i2c, DAC3101_I2C_DEVICE_ADDR, DAC3101_SPK_AMP, 0xC6));
    // Enable HPL output analog volume, set = -9 dB
    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(i_i2c, DAC3101_I2C_DEVICE_ADDR, DAC3101_HPL_VOL_A, 0x92));
    // Enable HPR output analog volume, set = -9 dB
    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(i_i2c, DAC3101_I2C_DEVICE_ADDR, DAC3101_HPR_VOL_A, 0x92));
    // Enable Left Class-D output analog volume, set = -9 dB
    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(i_i2c, DAC3101_I2C_DEVICE_ADDR, DAC3101_SPKL_VOL_A, 0x92));
    // Enable Right Class-D output analog volume, set = -9 dB
    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(i_i2c, DAC3101_I2C_DEVICE_ADDR, DAC3101_SPKR_VOL_A, 0x92));

    // Wait for 100 ms for analog to come up
    delay_milliseconds(100);

    // Power up DAC
    // Set register page to 0
    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(i_i2c, DAC3101_I2C_DEVICE_ADDR, DAC3101_PAGE_CTRL, 0x00));
    // Power up DAC channels and set digital gain
    // Powerup DAC left and right channels (soft step enabled)
    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(i_i2c, DAC3101_I2C_DEVICE_ADDR, DAC3101_DAC_DAT_PATH, 0xD4));
    // DAC Left gain = 0dB
    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(i_i2c, DAC3101_I2C_DEVICE_ADDR, DAC3101_DACL_VOL_D, 0x00));
    // DAC Right gain = 0dB
    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(i_i2c, DAC3101_I2C_DEVICE_ADDR, DAC3101_DACR_VOL_D, 0x00));
    // Unmute digital volume control
    // Unmute DAC left and right channels
    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(i_i2c, DAC3101_I2C_DEVICE_ADDR, DAC3101_DAC_VOL, 0x00));

    // Keep this here to suppress unused fn. This may be handy if we extend functionality on this board
    if(0){
        i2c_regop_res_t result;
        i2c_reg_read(i_i2c, 0, 0, result);
    }

    return error;
}

void xk_voice_l71_AudioHwChanInit(chanend c)
{
    unsafe{gc_audiohw = c;}
}

[[combinable]]
void AudioHwRemote(chanend c, client interface i2c_master_if i_i2c)
{

    //Serve commands
    while(1)
    {
        select{
            case c :> unsigned cmd:
                if(cmd == AUDIOHW_CMD_INIT)
                {
                    xk_voice_l71_config_t config;
                    c :> config;
                    if(config.clk_mode == CLK_FIXED){
                        sw_pll_fixed_clock(config.default_mclk);
                    } else {
                        sw_pll_fixed_clock(0);
                    }
                    int error = set_enables_and_reset_dac(i_i2c, config.oe_enables);
                    c <: error;
                }
                else if(cmd == AUDIOHW_CMD_CONFIG)
                {
                    xk_voice_l71_config_t config;
                    unsigned sample_rate;
                    unsigned mclk;
                    c :> config;
                    c :> sample_rate;
                    c :> mclk;
                    if(config.clk_mode == CLK_EXTERNAL){
                        // Since dac3101_configure() directly calls the App PLL setup from sw_pll, we need
                        // to zero mclk to ensure PLL is switched off if specifying external clock
                        mclk = 0;
                    }
                    int error = dac3101_configure(i_i2c, sample_rate, mclk, config.dac_pin);
                    c <: error;
                }
                else if(cmd == AUDIOHW_CMD_EXIT)
                {
                    i_i2c.shutdown();
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
        i2c_master(i2c, 1, p_scl, p_sda, 100);
        AudioHwRemote(c, i2c[0]);
    }
}



/* Note this is called from tile[1] but the I2C lines to the CODEC are on tile[0]
 * use a channel to communicate CODEC reg read/writes to a remote core */
void xk_voice_l71_AudioHwInit(const xk_voice_l71_config_t &config)
{
    unsafe{
        while((unsigned)gc_audiohw == 0); // Wait for chanend to be initialised
        gc_audiohw <: AUDIOHW_CMD_INIT;
        gc_audiohw <: config;
        int error;
        gc_audiohw :> error;
    }
}


void xk_voice_l71_AudioHwConfig(
    const REFERENCE_PARAM(xk_voice_l71_config_t, config),
    unsigned sample_rate, unsigned mclk)
{
    unsafe{
        gc_audiohw <: AUDIOHW_CMD_CONFIG;
        gc_audiohw <: config;
        gc_audiohw <: sample_rate;
        gc_audiohw <: mclk;
        int error;
        gc_audiohw :> error;
    }
}

void xk_voice_l71_AudioHwRemoteKill(void){
    unsafe{
        gc_audiohw <: AUDIOHW_CMD_EXIT;
    }
}

#endif
