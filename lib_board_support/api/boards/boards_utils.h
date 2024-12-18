// Copyright 2024 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#pragma once

#include <xs1.h>

/**
 * \addtogroup bs_common
 *
 * The common defines for using lib_board_support.
 * @{
 */

/* List of supported boards */

/** Define representing Null board i.e. no board in use*/
#define NULL_BOARD                  0

/** Define representing XK-AUDIO-216-MC Board */
#define XK_AUDIO_216_MC_AB          1

/** Define representing XK-AUDIO-316-MC Board */
#define XK_AUDIO_316_MC_AB          2

/** Define representing XK-EVK-XU316 board */
#define XK_EVK_XU316                3

/** Define representing XK-EVK-XU216 board */
#define XK_EVK_XU216                4

/** Total number of boards supported by the library */
#define BOARD_SUPPORT_N_BOARDS      5  // max board + 1

/** Define that should be set to the current board type in use
  *
  * Default value: NULL_BOARD
  */
#ifndef BOARD_SUPPORT_BOARD
#define BOARD_SUPPORT_BOARD         NULL_BOARD // This means none of the BSP sources are compiled in to the project
#endif

#if BOARD_SUPPORT_BOARD >= BOARD_SUPPORT_N_BOARDS
#error Invalid board selected
#endif

/**@}*/ // END: addtogroup lib_board_support
