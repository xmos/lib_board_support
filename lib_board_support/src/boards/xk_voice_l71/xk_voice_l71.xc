#include <xs1.h>
#include <assert.h>
#include <stdio.h>
#include <platform.h>
#include "xassert.h"
#include "i2c.h"
#include "dac3101.h"
#include "pcal6408a.h"

/* I2C io expander address on XCF3610_Q60A board */
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

unsafe chanend uc_audiohw;

// These are client side commands to be called from tile[1]
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

// These are called on tile[0]
static i2c_regop_res_t i2c_reg_write(uint8_t device_addr, uint8_t reg, uint8_t data)
{
    uint8_t a_data[2] = {reg, data};
    size_t n;

    unsafe
    {
        i_i2c_client.write(device_addr, a_data, 2, n, 1);
    }

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

static uint8_t i2c_reg_read(uint8_t device_addr, uint8_t reg, i2c_regop_res_t &result)
{
    uint8_t a_reg[1] = {reg};
    uint8_t data[1] = {0};
    size_t n;
    i2c_res_t res;

    unsafe
    {
        res = i_i2c_client.write(device_addr, a_reg, 1, n, 0);

        if (n != 1)
        {
            result = I2C_REGOP_DEVICE_NACK;
            i_i2c_client.send_stop_bit();
            return 0;
        }

        res = i_i2c_client.read(device_addr, data, 1, 1);
    }

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


int dac3101_codec_reset_and_enable_rpi_io(void)
{
    int error = 0;
    /* Set DAC_RST_N to 0 and enable all level shifters */
    uint8_t bitmask = (1<<XVF_RST_N_PIN) |
                      (1<<INT_N_PIN)     |
                      (1<<BOOT_SEL_PIN)  |
                      (1<<MCLK_OE_PIN)   |
                      (1<<SPI_OE_PIN)    |
                      (1<<I2S_OE_PIN)    |
                      (1<<MUTE_PIN);
                      // DAC_RST_N_PIN = 0

    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(IOEXP_I2C_ADDR, PCAL6408A_OUTPUT_PORT, bitmask));
    delay_milliseconds(10);

    /* Pin directions 0 = output*/
    bitmask = (1<<XVF_RST_N_PIN) |
              (1<<INT_N_PIN)     |
              (1<<BOOT_SEL_PIN)  |
              (1<<MUTE_PIN);
              // DAC_RST, SPI_OE, MCLK_OE and I2S_OE outputs

    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(IOEXP_I2C_ADDR, PCAL6408A_CONF, bitmask));
    delay_milliseconds(10);

    /* Enable interrupts */
    bitmask = 0xFF & ~(1<<INT_N_PIN);
    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(IOEXP_I2C_ADDR, PCAL6408A_INTERRUPT_MASK, bitmask));
    delay_milliseconds(10);

    /* Reset the dac */
    bitmask = (1<<XVF_RST_N_PIN) |
              (1<<INT_N_PIN)     |
              (1<<DAC_RST_N_PIN) |
              (1<<BOOT_SEL_PIN)  |
              (1<<MCLK_OE_PIN)   |
              (1<<SPI_OE_PIN)    |
              (1<<I2S_OE_PIN)    |
              (1<<MUTE_PIN);

    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(IOEXP_I2C_ADDR, PCAL6408A_OUTPUT_PORT, bitmask));

    // Remove unused fn warning for now
    if(0){
        i2c_regop_res_t result;
        i2c_reg_read(0, 0, result);
    }

    return error;
}


int setup_dac3101(unsigned samFreq)
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
    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(DAC3101_I2C_DEVICE_ADDR, DAC3101_PAGE_CTRL, 0x00));

    // Initiate SW reset (PLL is powered off as part of reset)
    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(DAC3101_I2C_DEVICE_ADDR, DAC3101_SW_RST, 0x01));

    // Program clock settings
    // Set PLL J Value
    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(DAC3101_I2C_DEVICE_ADDR, DAC3101_PLL_J, PLLJ));
    // Set PLL D to...
    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(DAC3101_I2C_DEVICE_ADDR, DAC3101_PLL_D_LSB, PLLD & 0xff));
    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(DAC3101_I2C_DEVICE_ADDR, DAC3101_PLL_D_MSB, (PLLD & 0xff00) >> 8));

    // Set BCLK divider to 1
    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(DAC3101_I2C_DEVICE_ADDR, DAC3101_B_DIV_VAL, 0x80 + 1));

    // Wait for 1 ms
    delay_milliseconds(1);

    // Set PLL_CLKIN = BCLK (device pin), CODEC_CLKIN = PLL_CLK (generated on-chip)
    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(DAC3101_I2C_DEVICE_ADDR, DAC3101_CLK_GEN_MUX, (0b01 << 2) + 0b11));

    // Set PLL P and R values and power up.
    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(DAC3101_I2C_DEVICE_ADDR, DAC3101_PLL_P_R, 0x80 + (PLLP << 4)+ PLLR));

    // Set NDAC clock divider and power up.
    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(DAC3101_I2C_DEVICE_ADDR, DAC3101_NDAC_VAL, 0x80 + NDAC));
    // Set MDAC clock divider and power up.
    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(DAC3101_I2C_DEVICE_ADDR, DAC3101_MDAC_VAL, 0x80 + MDAC));
    // Set OSR clock divider to 256.
    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(DAC3101_I2C_DEVICE_ADDR, DAC3101_DOSR_VAL_LSB, DOSR & 0xff));
    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(DAC3101_I2C_DEVICE_ADDR, DAC3101_DOSR_VAL_MSB, (DOSR & 0xff00) >> 8));


    // Set CLKOUT Mux to DAC_CLK
    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(DAC3101_I2C_DEVICE_ADDR, DAC3101_CLKOUT_MUX, 0x04));
    // Set CLKOUT M divider to 1 and power up.
    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(DAC3101_I2C_DEVICE_ADDR, DAC3101_CLKOUT_M_VAL, 0x81));

#if (DAC3101_USE_2ND_IF == 1)
    // Set Secondary DIN is obtained from the GPIO1 pin.
    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(DAC3101_I2C_DEVICE_ADDR, DAC3101_CODEC_IF2_C1, 0b00100100));
    // Set Secondary DIN is fed to codec serial-interface block.
    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(DAC3101_I2C_DEVICE_ADDR, DAC3101_CODEC_IF2_C2, 0b00000001));
    // Set GPIO1 enabled as secondary input. (see pg. 62 of datasheet)
    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(DAC3101_I2C_DEVICE_ADDR, DAC3101_GPIO1_IO, 0b00000100));
#else
    // Uses IF1 by default
#endif

    // Set CODEC interface mode: I2S, 24 bit, slave mode (BCLK, WCLK both inputs).
    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(DAC3101_I2C_DEVICE_ADDR, DAC3101_CODEC_IF, 0x20));
    // Set register page to 1
    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(DAC3101_I2C_DEVICE_ADDR, DAC3101_PAGE_CTRL, 0x01));
    // Program common-mode voltage to mid scale 1.65V.
    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(DAC3101_I2C_DEVICE_ADDR, DAC3101_HP_DRVR, 0x14));
    // Program headphone-specific depop settings.
    // De-pop, Power on = 800 ms, Step time = 4 ms
    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(DAC3101_I2C_DEVICE_ADDR, DAC3101_HP_DEPOP, 0x4E));
    // Program routing of DAC output to the output amplifier (headphone/lineout or speaker)
    // LDAC routed to left channel mixer amp, RDAC routed to right channel mixer amp
    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(DAC3101_I2C_DEVICE_ADDR, DAC3101_DAC_OP_MIX, 0x44));
    // Unmute and set gain of output driver
    // Unmute HPL, set gain = 0 db
    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(DAC3101_I2C_DEVICE_ADDR, DAC3101_HPL_DRVR, 0x06));
    // Unmute HPR, set gain = 0 dB
    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(DAC3101_I2C_DEVICE_ADDR, DAC3101_HPR_DRVR, 0x06));
    // Unmute Left Class-D, set gain = 12 dB
    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(DAC3101_I2C_DEVICE_ADDR, DAC3101_SPKL_DRVR, 0x0C));
    // Unmute Right Class-D, set gain = 12 dB
    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(DAC3101_I2C_DEVICE_ADDR, DAC3101_SPKR_DRVR, 0x0C));
    // Power up output drivers
    // HPL and HPR powered up
    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(DAC3101_I2C_DEVICE_ADDR, DAC3101_HP_DRVR, 0xD4));
    // Power-up L and R Class-D drivers
    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(DAC3101_I2C_DEVICE_ADDR, DAC3101_SPK_AMP, 0xC6));
    // Enable HPL output analog volume, set = -9 dB
    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(DAC3101_I2C_DEVICE_ADDR, DAC3101_HPL_VOL_A, 0x92));
    // Enable HPR output analog volume, set = -9 dB
    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(DAC3101_I2C_DEVICE_ADDR, DAC3101_HPR_VOL_A, 0x92));
    // Enable Left Class-D output analog volume, set = -9 dB
    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(DAC3101_I2C_DEVICE_ADDR, DAC3101_SPKL_VOL_A, 0x92));
    // Enable Right Class-D output analog volume, set = -9 dB
    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(DAC3101_I2C_DEVICE_ADDR, DAC3101_SPKR_VOL_A, 0x92));

    // Wait for 10 ms
    delay_milliseconds(10);

    // Power up DAC
    // Set register page to 0
    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(DAC3101_I2C_DEVICE_ADDR, DAC3101_PAGE_CTRL, 0x00));
    // Power up DAC channels and set digital gain
    // Powerup DAC left and right channels (soft step enabled)
    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(DAC3101_I2C_DEVICE_ADDR, DAC3101_DAC_DAT_PATH, 0xD4));
    // DAC Left gain = 0dB
    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(DAC3101_I2C_DEVICE_ADDR, DAC3101_DACL_VOL_D, 0x00));
    // DAC Right gain = 0dB
    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(DAC3101_I2C_DEVICE_ADDR, DAC3101_DACR_VOL_D, 0x00));
    // Unmute digital volume control
    // Unmute DAC left and right channels
    error |= (I2C_REGOP_SUCCESS != i2c_reg_write(DAC3101_I2C_DEVICE_ADDR, DAC3101_DAC_VOL, 0x00));

    return error;
}

void xk_voice_l71_AudioHwChanInit(chanend c)
{
    unsafe{uc_audiohw = c;}
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
        i2c_master(i2c, 1, p_scl, p_sda, 100);
        AudioHwRemote2(c, i2c[0]);
    }
}

    CLK_FIXED
    CLK_EXTERNAL
NO_OE_PINS
    MCLK_OE_PIN
    SPI_OE_PIN
    I2S_OE_PIN

/* Note this is called from tile[1] but the I2C lines to the CODEC are on tile[0]
 * use a channel to communicate CODEC reg read/writes to a remote core */
void xk_voice_l71_AudioHwInit(const xk_voice_l71_config_t &config)
{


void xk_voice_l71_AudioHwConfig(
    const REFERENCE_PARAM(xk_voice_l71_config_t, config), 
    unsigned sample_rate, unsigned mClk)
{

