// Copyright 2024-2026 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#pragma once

#include <xs1.h>

#ifdef __board_support_conf_h_exists__
    #include "board_support_conf.h"
#endif

/**
 * \addtogroup bs_common
 *
 * The common defines for using lib_board_support.
 * @{
 */

/* List of supported boards */

/** Define representing Null board i.e. no board in use*/
#define NULL_BOARD                  0

/** Define representing XK-AUDIO-216-MC, xcore-200 Multi-channel AudioBoard */
#define XK_AUDIO_216_MC_AB          1

/** Define representing XK-AUDIO-316-MC, xcore.ai Multi-channel Audio Board */
#define XK_AUDIO_316_MC_AB          2

/** Define representing XK-EVK-XU316, xcore.ai Explorer Evaluation Kit board */
#define XK_EVK_XU316                3

/** Define representing XK-EVK-XU216, xcore-200 Explorer Evaluation Kit board */
#define XK_EVK_XE216                4

/** Define representing XK-ETH-316-DUAL, xcore.ai Ethernet Development Kit board */
#define XK_ETH_316_DUAL             5

/** Define representing XK_VOICE_L71 , xcore.ai Two Mic Development board */
#define XK_VOICE_L71                6
  
/** Total number of boards supported by the library */
#define BOARD_SUPPORT_N_BOARDS      7  // max board + 1

/** Define that should be set to the current board type in use
  *
  * Default value: NULL_BOARD
  */
#ifndef BOARD_SUPPORT_BOARD
#define BOARD_SUPPORT_BOARD         NULL_BOARD /** This means none of the BSP sources are compiled in to the project */
#endif

#if BOARD_SUPPORT_BOARD >= BOARD_SUPPORT_N_BOARDS
#error Invalid board selected
#endif

/**@}*/ // END: addtogroup lib_board_support
