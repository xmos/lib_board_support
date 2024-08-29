#include <platform.h>

extern void tile_0_main(void);
extern void tile_1_main(void);

int main(void){
    par{
        on tile[0]: tile_0_main();
        on tile[1]: tile_1_main();
    }
}