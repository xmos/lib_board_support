// Copyright 2024-2026 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#include <platform.h>
#include "i2c.h"

extern void tile_0_i2c(server i2c_master_if i_i2c);
extern void tile_0_main(client i2c_master_if i_i2c);

int main(void){
    interface i2c_master_if i_i2c;
    par{
        /* Everything on this board is wired to tile[0], so both tasks run there */
        on tile[0]: tile_0_i2c(i_i2c);
        on tile[0]: tile_0_main(i_i2c);
    }

    return 0;
}
