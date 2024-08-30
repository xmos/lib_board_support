// Copyright 2024 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
/// Hardware setup APIs for the XK-EVK-XU316

#ifndef __XK_EVK_XU316_BOARD_H__
#define __XK_EVK_XU316_BOARD_H__

#include <xccompat.h>

/**
 * \addtogroup xk_evk_xu316 xk_evk_xu316
 *
 * The common defines for using lib_board_support.
 * @{
 */


typedef struct {

    /// initial mclk config used in AudioHwInit.
    unsigned default_mclk;
} xk_evk_xu316_config_t;

typedef enum
{
    AUDIOHW_CMD_REGWR,
    AUDIOHW_CMD_REGRD,
    AUDIOHW_CMD_EXIT
} audioHwCmd_t;

//// XUA hw setup convenience APIs

void xk_evk_xu316_AudioHwRemote(chanend c);
void xk_evk_xu316_AudioHwInit(chanend c, const REFERENCE_PARAM(xk_evk_xu316_config_t, config));
void xk_evk_xu316_AudioHwConfig(unsigned samFreq, unsigned mClk, unsigned dsdMode,
    unsigned sampRes_DAC, unsigned sampRes_ADC);

/**@}*/ // END: addtogroup xk_evk_xu316

#endif // __XK_EVK_XU316_BOARD_H__
