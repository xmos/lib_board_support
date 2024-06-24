#include <xs1.h>
#include <platform.h>
#include <xccompat.h>

extern tileref tile[];

#define MAX_TILES 255

unsigned get_local_tile_index() {
  unsigned this_id = get_local_tile_id();
  // note that this for loop exits when it finds a match
  // so it will never execute more times than there
  // are tiles in the system.
  for(int i = 0; i < MAX_TILES; ++i) {
    if(this_id == get_tile_id(tile[i])) {
      return i;
    }     
  }
}
