// Copyright 2024-2025 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.


#include <boards_utils.h>

#if BOARD_SUPPORT_BOARD == XK_AUDIO_216_MC_AB

#include "xk_audio_216_mc_ab/gpio_access.h"
#include <xs1.h>
#include <xcore/port.h>
#include <swlock.h>

static swlock_t gpo_swlock = SWLOCK_INITIAL_VALUE;
extern port_t xk_audio_216_mc_ab_p_gpio;


void aud_216_p_gpio_lock() {
  swlock_acquire(&gpo_swlock);
    
}
void aud_216_p_gpio_unlock() {
  swlock_release(&gpo_swlock);
    
}

unsigned aud_216_p_gpio_peek()
{
    unsigned portId, x;


    asm("ldw %0, dp[xk_audio_216_mc_ab_p_gpio]":"=r"(portId));
    asm volatile("peek %0, res[%1]":"=r"(x):"r"(portId));

    return x;
}

void aud_216_p_gpio_out(unsigned x)
{
    unsigned portId;

    asm("ldw %0, dp[xk_audio_216_mc_ab_p_gpio]":"=r"(portId));
    asm volatile("out res[%0], %1"::"r"(portId),"r"(x));

}

void aud_216_set_gpio(unsigned bit, unsigned value)
{
  // Wrapped in lock to ensure it's safe from multiple logical cores
  swlock_acquire(&gpo_swlock);
	unsigned port_shadow;
	port_shadow = aud_216_p_gpio_peek();        // Read port pin value
	if (value == 0) port_shadow &= ~bit; // If writing a 0, generate mask and AND with current val
	else port_shadow |= bit;             // Else use mask and OR to set bit
	aud_216_p_gpio_out(port_shadow);             // Write back to port. Will make port an output if not already
  // Wrapped in lock to ensure it's safe from multiple logical cores
  swlock_release(&gpo_swlock);
}


#endif
