// Copyright 2024-2026 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.


#include <boards_utils.h>

#if BOARD_SUPPORT_BOARD == XMS0028

#include "xms0028/gpio_access.h"
#include <xs1.h>
#include <xcore/port.h>
#include <swlock.h>

static swlock_t gpo_swlock = SWLOCK_INITIAL_VALUE;

/* Shadow of the output port. Held here rather than read back from the port so that the
 * state is well defined before the port has been driven for the first time. All LEDs off
 * and the CODEC held in reset (the line is active low) matches the power on state. */
static unsigned gpo_shadow = 0;

/* Declared in xms0028_board.xc */
extern port_t xms0028_p_gpo;
extern port_t xms0028_p_buttons;


unsigned xms0028_gpo_peek(void)
{
    return gpo_shadow;
}

void xms0028_gpo_set(unsigned mask, unsigned value)
{
    /* Wrapped in a lock to ensure it's safe from multiple logical cores. The LEDs and
     * the CODEC reset line share this port, so a blind write would clobber one or the
     * other. */
    swlock_acquire(&gpo_swlock);

    gpo_shadow &= ~mask;
    gpo_shadow |= (value & mask);
    port_out(xms0028_p_gpo, gpo_shadow);

    swlock_release(&gpo_swlock);
}

void xms0028_leds_set(unsigned led_mask)
{
    xms0028_gpo_set(XMS0028_LED_ALL, led_mask);
}

unsigned xms0028_buttons_read(void)
{
    /* Buttons are active low */
    return (~port_in(xms0028_p_buttons)) & XMS0028_BUTTON_ALL;
}

#endif
