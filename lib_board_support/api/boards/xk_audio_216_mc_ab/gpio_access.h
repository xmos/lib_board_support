// Copyright 2024 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

/// API to access the 8bit gpio port on audio XU216 multi channel board.

#pragma once

#ifdef __XC__
extern "C" {
#endif


void aud_216_p_gpio_lock();
void aud_216_p_gpio_unlock();

/// Read the port
unsigned aud_216_p_gpio_peek();

/// write to the port
void aud_216_p_gpio_out(unsigned x);

/// set individual bits
void aud_216_set_gpio(unsigned bit, unsigned value);

#ifdef __XC__
}
#endif
