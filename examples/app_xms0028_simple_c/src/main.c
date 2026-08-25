// Copyright 2024-2026 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#include <stdio.h>
#include <xcore/hwtimer.h>
#include "xms0028/board.h"
#include "xms0028/gpio_access.h"

/* Board configuration from lib_board_support */
static const xms0028_config_t hw_config = {
        24576000,               // default_mclk, 512 * 48000 Hz
        XMS0028_INPUT_LINE_IN   // input_source
};

#define LED_STEP_MS     (250)
#define DEMO_STEPS      (20)

void tile_0_i2c(SERVER_INTERFACE(i2c_master_if, i_i2c)){
    printf("Starting I2C master task\n");
    xms0028_i2c_master(&i_i2c);
    printf("I2C master task exited\n");
}

void tile_0_main(CLIENT_INTERFACE(i2c_master_if, i_i2c)){
    printf("Configuring audio hardware\n");
    xms0028_AudioHwInit(i_i2c, &hw_config);
    xms0028_AudioHwConfig(i_i2c, 48000, hw_config.default_mclk, 0, 24, 24);
    printf("Audio hardware configured\n");

    /* Walk the LEDs and report the buttons for a few seconds */
    hwtimer_t tmr = hwtimer_alloc();
    static const unsigned leds[] = {XMS0028_LED0, XMS0028_LED1, XMS0028_LED2};

    for(int i = 0; i < DEMO_STEPS; i++)
    {
        xms0028_leds_set(leds[i % 3]);
        printf("buttons: 0x%x\n", xms0028_buttons_read());
        hwtimer_delay(tmr, LED_STEP_MS * XS1_TIMER_KHZ);
    }

    xms0028_leds_set(0);
    hwtimer_free(tmr);

    xms0028_i2c_master_exit(i_i2c); // Quit the I2C master task
}
