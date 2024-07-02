// Copyright 2024 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#ifndef AUDIO_216_MC_AB_PORTS_H
#define AUDIO_216_MC_AB_PORTS_H

#include "../boards_utils.h"
#include <platform.h>

#define PORT_SQI_CS BOARDS_PORT(0, 1B)
#define PORT_SQI_SCLK BOARDS_PORT(0, 1C)
#define PORT_SQI_SIO BOARDS_PORT(0, 4B)
#define PORT_PLL_REF BOARDS_PORT(0, 1A)
#define PORT_MCLK_IN BOARDS_PORT(0, 1F)
#define PORT_I2S_LRCLK BOARDS_PORT(0, 1G)
#define PORT_I2S_BCLK BOARDS_PORT(0, 1H)
#define PORT_I2S_DAC0 BOARDS_PORT(0, 1M)
#define PORT_I2S_DAC1 BOARDS_PORT(0, 1N)
#define PORT_I2S_DAC2 BOARDS_PORT(0, 1O)
#define PORT_I2S_DAC3 BOARDS_PORT(0, 1P)
#define PORT_I2S_ADC0 BOARDS_PORT(0, 1I)
#define PORT_I2S_ADC1 BOARDS_PORT(0, 1J)
#define PORT_I2S_ADC2 BOARDS_PORT(0, 1K)
#define PORT_I2S_ADC3 BOARDS_PORT(0, 1L)
#define PORT_I2C BOARDS_PORT(0, 4A)
#define PORT_DSD_DAC0 BOARDS_PORT(0, 1M)
#define PORT_DSD_DAC1 BOARDS_PORT(0, 1N)
#define PORT_DSD_CLK BOARDS_PORT(0, 1G)
#define PORT_ADAT_OUT BOARDS_PORT(0, 1E)
#define PORT_SPDIF_OUT BOARDS_PORT(0, 1D)
#define PORT_USB_TX_READYIN BOARDS_PORT(1, 1H)
#define PORT_USB_CLK BOARDS_PORT(1, 1J)
#define PORT_USB_TX_READYOUT BOARDS_PORT(1, 1K)
#define PORT_USB_RX_READY BOARDS_PORT(1, 1I)
#define PORT_USB_FLAG0 BOARDS_PORT(1, 1E)
#define PORT_USB_FLAG1 BOARDS_PORT(1, 1F)
#define PORT_USB_FLAG2 BOARDS_PORT(1, 1G)
#define PORT_USB_TXD BOARDS_PORT(1, 8A)
#define PORT_USB_RXD BOARDS_PORT(1, 8B)
#define PORT_MCLK_COUNT BOARDS_PORT(1, 16B)
#define PORT_MCLK_IN_USB BOARDS_PORT(1, 1L)
#define PORT_MIDI_IN BOARDS_PORT(1, 1M)
#define PORT_MIDI_OUT BOARDS_PORT(1, 1N)
#define PORT_ADAT_IN BOARDS_PORT(1, 1O)
#define PORT_SPDIF_IN BOARDS_PORT(1, 1P)



#ifndef XCORE_200_MC_AUDIO_HW_VERSION
#define XCORE_200_MC_AUDIO_HW_VERSION 2
#endif


#if XCORE_200_MC_AUDIO_HW_VERSION == 2

/* General output port bit definitions */
#define P_GPIO_DSD_MODE         (1 << 0) /* DSD mode select 0 = 8i/8o I2S, 1 = 8o DSD*/
#define P_GPIO_DAC_RST_N        (1 << 1)
#define P_GPIO_USB_SEL0         (1 << 2)
#define P_GPIO_USB_SEL1         (1 << 3)
#define P_GPIO_VBUS_EN          (1 << 4)
#define P_GPIO_PLL_SEL          (1 << 5) /* 1 = CS2100, 0 = Phaselink clock source */
#define P_GPIO_ADC_RST_N        (1 << 6)
#define P_GPIO_MCLK_FSEL        (1 << 7) /* Select frequency on Phaselink clock. 0 = 24.576MHz for 48k, 1 = 22.5792MHz for 44.1k.*/

#else

/* General output port bit definitions */
#define P_GPIO_DSD_MODE         (1 << 0) /* DSD mode select 0 = 8i/8o I2S, 1 = 8o DSD*/
#define P_GPIO_DAC_RST_N        (1 << 1)
#define P_GPIO_ADC_RST_N        (1 << 2)
#define P_GPIO_USB_SEL0         (1 << 3)
#define P_GPIO_USB_SEL1         (1 << 4)
#define P_GPIO_VBUS_EN          (1 << 5)
#define P_GPIO_MCLK_FSEL        (1 << 6) /* Select frequency on Phaselink clock. 0 = 24.576MHz for 48k, 1 = 22.5792MHz for 44.1k.*/
#define P_GPIO_PLL_SEL          (1 << 7) /* 1 = CS2100, 0 = Phaselink clock source */

#endif


/*LED array defines*/
#define LED_ALL_ON              0xf00f
#define LED_SQUARE_BIG          0x9009
#define LED_SQUARE_SML          0x6006
#define LED_ROW_1               0xf001
#define LED_ROW_2               0xf003
#define LED_ROW_3               0xf007
#define ALL_OFF                 0x0000
// LED array masks
#define LED_MASK_COL_OFF        0x7fff
#define LED_MASK_DISABLE        0xffff




#endif /* AUDIO_216_MC_AB_PORTS_H */

