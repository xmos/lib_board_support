// Copyright 2024 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#ifndef EVK_XU316_PORTS_H
#define EVK_XU316_PORTS_H
#include <platform.h>  // for tile identifiers
#include "../boards_utils.h"


#define PORT_SQI_CS BOARDS_PORT(0, 1B)
#define PORT_SQI_SCLK BOARDS_PORT(0, 1C)
#define PORT_SQI_SIO BOARDS_PORT(0, 4B)
#define PORT_LEDS BOARDS_PORT(0, 4C)
#define PORT_BUTTONS BOARDS_PORT(0, 4D)
#define WIFI_WIRQ BOARDS_PORT(0, 1I)
#define WIFI_MOSI BOARDS_PORT(0, 1J)
#define WIFI_WUP_RST_N BOARDS_PORT(0, 4E)
#define WIFI_CS_N BOARDS_PORT(0, 4F)
#define WIFI_CLK BOARDS_PORT(0, 1L)
#define WIFI_MISO BOARDS_PORT(0, 1M)
#define PORT_PDM_CLK BOARDS_PORT(1, 1G)
#define PORT_PDM_DATA BOARDS_PORT(1, 1F)
#define PORT_MCLK_IN BOARDS_PORT(1, 1D)
#define PORT_I2S_BCLK BOARDS_PORT(1, 1C)
#define PORT_I2S_LRCLK BOARDS_PORT(1, 1B)
#define PORT_I2S_DAC_DATA BOARDS_PORT(1, 1A)
#define PORT_I2S_ADC_DATA BOARDS_PORT(1, 1N)
#define PORT_CODEC_RST_N BOARDS_PORT(1, 4A)


// initialise tile 0 ports used by this library
void xk_evk_xu316_init_ports_0();

// initialise tile 1 ports used by this library
void xk_evk_xu316_init_ports_1();
#endif /* EVK_XU316_PORTS_H */

