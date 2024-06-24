// Copyright 2024 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#pragma once

#include <xs1.h>

#if defined(__XC__)
#define BOARDS_PORT(TILE, PORT) on tile[TILE]: XS1_PORT_ ## PORT
#else
#define BOARDS_PORT(TILE, PORT) XS1_PORT_ ## PORT
#endif

// Gets the tile index for the current tile as specified
// in the xn file.
unsigned get_local_tile_index();

#ifndef __XC__
#define ENABLE_LOCAL_PORT(TILE_NUM, PORT) do { if(TILE_NUM == get_local_tile_index()) port_enable(PORT);  } while(0);
#endif
