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
#define NULL_BOARD                  0
#define XK_AUDIO_216_MC_AB          1
#define XK_AUDIO_316_MC_AB          2
#define XK_EVK_XU316                3
#define BOARD_SUPPORT_N_BOARDS      4  // max board + 1

#ifndef BOARD_SUPPORT_BOARD
#define BOARD_SUPPORT_BOARD         NULL_BOARD // This means none of the BSP sources are compiled in to the project
#endif

#if BOARD_SUPPORT_BOARD >= BOARD_SUPPORT_N_BOARDS
#error Invalid board selected
#endif

/**@}*/ // END: addtogroup lib_board_support
