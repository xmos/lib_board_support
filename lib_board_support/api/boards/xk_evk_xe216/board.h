// Copyright 2024 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#ifndef __XK_EVK_XU216_BOARD_H__
#define __XK_EVK_XU216_BOARD_H__

#if (BOARD_SUPPORT_BOARD == XK_EVK_XU216) || defined(__DOXYGEN__)

#include <xccompat.h>
#include "smi.h"



/**
 * \addtogroup xk_evk_xu216
 *
 * API for the xk_evk_xu216 board.
 * @{
 */

/** Task that connects to the SMI master and MAC to configure the
 * ar8035 PHY and monitor the link status. Note this is combinable
 * and therefore does not need to take a whole thread.
 *
 *  \param i_smi        Client register read/write interface
 *  \param i_eth        Client MAC configuration interface
 *  \param p_eth_reset  Port connected to the PHY reset pin
 */
[[combinable]]
void ar8035_phy_driver(CLIENT_INTERFACE(smi_if, i_smi),
                       CLIENT_INTERFACE(ethernet_cfg_if, i_eth),
                       out port p_eth_reset);




/**@}*/ // END: addtogroup xk_evk_xu216

#endif // (BOARD_SUPPORT_BOARD == XK_EVK_XU216) || defined(__DOXYGEN__)


#endif // __XK_EVK_XU216_BOARD_H__
