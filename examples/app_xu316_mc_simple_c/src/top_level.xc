// Copyright 2024 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#include <platform.h>
#include "i2c.h"

extern void tile_0_main(server i2c_master_if i_i2c);
extern void tile_1_main(client i2c_master_if i_i2c);

int main(void){
    interface i2c_master_if i_i2c; // Cross tile interface
    par{
        on tile[0]: tile_0_main(i_i2c);
        on tile[1]: tile_1_main(i_i2c);
    }

    return 0;
}
