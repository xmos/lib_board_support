// Copyright 2024-2025 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#include <platform.h>

extern void tile_0_main(chanend c);
extern void tile_1_main(chanend c);

int main(void){
    chan c;
    par{
        on tile[0]: tile_0_main(c);
        on tile[1]: tile_1_main(c);
    }

    return 0;
}
