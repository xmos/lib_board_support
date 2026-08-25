// Copyright 2024-2026 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

/// API to access the LEDs, buttons and CODEC reset line on the XMS0028 board.

#pragma once

#include "boards_utils.h"
#if (BOARD_SUPPORT_BOARD == XMS0028) || defined(__DOXYGEN__)

#ifdef __XC__
extern "C" {
#endif

/**
 * \addtogroup xms0028_gpio
 *
 * LED, button and CODEC reset access for the xms0028 board.
 *
 * The three LEDs and the CODEC reset line share a single 8-bit output port, so all
 * writes must go through xms0028_gpo_set() which performs a lock protected
 * read-modify-write. Writing the port directly would clobber the CODEC reset line.
 *
 * All of these functions must be called from tile[0], where the ports reside.
 * @{
 */

/** CODEC reset, active low. Held low (in reset) at power on. */
#define XMS0028_CODEC_RST_N     (1 << 4)

/** Green LED 0, active high. */
#define XMS0028_LED0            (1 << 5)
/** Green LED 1, active high. */
#define XMS0028_LED1            (1 << 6)
/** Green LED 2, active high. */
#define XMS0028_LED2            (1 << 7)
/** Mask covering all three LEDs. */
#define XMS0028_LED_ALL         (XMS0028_LED0 | XMS0028_LED1 | XMS0028_LED2)

/** Button 0. */
#define XMS0028_BUTTON0         (1 << 2)
/** Button 1. */
#define XMS0028_BUTTON1         (1 << 3)
/** Mask covering both buttons. */
#define XMS0028_BUTTON_ALL      (XMS0028_BUTTON0 | XMS0028_BUTTON1)

/** Returns the value most recently written to the general purpose output port.
 *
 *  Before the first call to xms0028_gpo_set() this reports the power on state: all LEDs
 *  off and the CODEC held in reset.
 *
 *  \returns The port value, which includes both the LED bits and the CODEC reset bit.
 */
unsigned xms0028_gpo_peek(void);

/** Sets the bits selected by \p mask on the general purpose output port, leaving all
 *  other bits (in particular the CODEC reset line) untouched.
 *
 *  This is safe to call from multiple logical cores.
 *
 *  \param   mask     Bitmask of the bits to change, e.g. ::XMS0028_LED0.
 *  \param   value    The value to write to those bits. Bits outside \p mask are ignored.
 */
void xms0028_gpo_set(unsigned mask, unsigned value);

/** Sets all three LEDs at once.
 *
 *  \param   led_mask    Bitwise OR of ::XMS0028_LED0, ::XMS0028_LED1 and ::XMS0028_LED2.
 *                       LEDs not present in the mask are turned off.
 */
void xms0028_leds_set(unsigned led_mask);

/** Reads the buttons.
 *
 *  The buttons are wired active low; this function inverts them so that a set bit means
 *  the button is pressed.
 *
 *  \returns Bitwise OR of ::XMS0028_BUTTON0 and ::XMS0028_BUTTON1 for each pressed button.
 */
unsigned xms0028_buttons_read(void);

/**@}*/ // END: addtogroup xms0028_gpio

#ifdef __XC__
}
#endif

#endif
