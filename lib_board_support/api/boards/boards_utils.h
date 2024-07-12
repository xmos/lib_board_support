// Copyright 2024 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#pragma once

#include <xs1.h>

#define XK_AUDIO_216_MC_AB 0
#define XK_AUDIO_316_MC_AB 1
#define XK_EVK_XU316 2
#define BOARD_SUPPORT_N_BOARDS 3  // max board + 1

#ifndef BOARD_SUPPORT_BOARD
#error BOARD_SUPPORT_BOARD must be defined and set to one of the supported boards
#endif

#if BOARD_SUPPORT_BOARD >= BOARD_SUPPORT_N_BOARDS
#error Invalid board selected
#endif
