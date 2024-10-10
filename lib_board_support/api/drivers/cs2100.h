// Copyright 2024 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#pragma once
#ifndef CS2100_I2C_DEVICE_ADDR
#define CS2100_I2C_DEVICE_ADDR      (0x9c>>1)
#endif

#define CS2100_DEVICE_CONTROL       (0x02)
#define CS2100_DEVICE_CONFIG_1      (0x03)
#define CS2100_GLOBAL_CONFIG        (0x05)
#define CS2100_RATIO_1              (0x06)
#define CS2100_RATIO_2              (0x07)
#define CS2100_RATIO_3              (0x08)
#define CS2100_RATIO_4              (0x09)
#define CS2100_FUNC_CONFIG_1        (0x16)
#define CS2100_FUNC_CONFIG_2        (0x17)


#ifndef CS2100_REGREAD
#define CS2100_REGREAD(i2c, reg, data)  {data[0] = i2c.read_reg(CS2100_I2C_DEVICE_ADDR, reg, result);}
#endif

#ifndef CS2100_REGREAD_ASSERT
#define CS2100_REGREAD_ASSERT(i2c, reg, data, expected)  {data[0] = i2c.read_reg(CS2100_I2C_DEVICE_ADDR, reg, result); assert(data[0] == expected);}
#endif

#ifndef CS2100_REGWRITE
#define CS2100_REGWRITE(i2c, reg, val) {result = i2c.write_reg(CS2100_I2C_DEVICE_ADDR, reg, val);}
#endif

#ifndef UNSAFE
#define UNSAFE
#endif


/* Init of CS2100 */
static inline void PllInit(UNSAFE client interface i2c_master_if i2c)
{
    UNSAFE
    {
    unsigned char data[1] = {0};
    i2c_regop_res_t result;

    /* Enable init */
    CS2100_REGWRITE(i2c, CS2100_DEVICE_CONFIG_1, 0x07);
    CS2100_REGWRITE(i2c, CS2100_GLOBAL_CONFIG, 0x01);
    CS2100_REGWRITE(i2c, CS2100_FUNC_CONFIG_1, 0x08);
    CS2100_REGWRITE(i2c, CS2100_FUNC_CONFIG_2, 0x00); //0x10 for always gen clock even when unlocked

    /* Read back and check */
    CS2100_REGREAD_ASSERT(i2c, CS2100_DEVICE_CONFIG_1, data, 0x07);
    CS2100_REGREAD_ASSERT(i2c, CS2100_GLOBAL_CONFIG, data, 0x01);
    CS2100_REGREAD_ASSERT(i2c, CS2100_FUNC_CONFIG_1, data, 0x08);
    CS2100_REGREAD_ASSERT(i2c, CS2100_FUNC_CONFIG_2, data, 0x00);

    //i2c.shutdown();
    }
}

/* Setup PLL multiplier */
static inline void PllMult(unsigned output, unsigned ref, UNSAFE client interface i2c_master_if i2c)
{
    UNSAFE

    {
    unsigned char data[1] = {0};
    i2c_regop_res_t result;

    /* PLL expects 20.12 format, convert output and ref to 20.12 */
    /* Shift up the dividend by 12 to retain format... */
    unsigned mult = (unsigned) ((((unsigned long long)output) << 32) / (((unsigned long long)ref) << 20));

    CS2100_REGWRITE(i2c, CS2100_RATIO_1, (mult >> 24) & 0xFF);
    CS2100_REGWRITE(i2c, CS2100_RATIO_2, (mult >> 16) & 0xFF);
    CS2100_REGWRITE(i2c, CS2100_RATIO_3, (mult >> 8) & 0xFF);
    CS2100_REGWRITE(i2c, CS2100_RATIO_4, (mult & 0xFF));

	/* Read back and check */
    CS2100_REGREAD_ASSERT(i2c, CS2100_RATIO_1, data, ((mult >> 24) & 0xFF));
    CS2100_REGREAD_ASSERT(i2c, CS2100_RATIO_2, data, ((mult >> 16) & 0xFF));
    CS2100_REGREAD_ASSERT(i2c, CS2100_RATIO_3, data, ((mult >> 8) & 0xFF));
    CS2100_REGREAD_ASSERT(i2c, CS2100_RATIO_4, data, (mult & 0xFF));
    }
}

