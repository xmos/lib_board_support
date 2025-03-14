// Copyright 2024-2025 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#ifndef __XK_EVK_XE216_BOARD_H__
#define __XK_EVK_XE216_BOARD_H__

#include <boards_utils.h>
#if (BOARD_SUPPORT_BOARD == XK_EVK_XE216) || defined(__DOXYGEN__)
#include <xccompat.h>
#include "smi.h"



/**
 * \addtogroup xk_evk_xu216
 *
 * API for the xk_evk_xu216 board.
 * @{
 */

/** Task that connects to the SMI master and MAC to configure the
 * ar8035 PHY and monitor the link status. Note this task is combinable
 * (typically with SMI) and therefore does not need to take a whole thread.
 * This task must be run from tile[1].
 *
 *  \param i_smi        Client register read/write interface
 *  \param i_eth        Client MAC configuration interface
 */
[[combinable]]
void ar8035_phy_driver(CLIENT_INTERFACE(smi_if, i_smi),
                       CLIENT_INTERFACE(ethernet_cfg_if, i_eth));



/**@}*/ // END: addtogroup xk_evk_xu216

#endif // (BOARD_SUPPORT_BOARD == XK_EVK_XE216) || defined(__DOXYGEN__)


#endif // __XK_EVK_XU216_BOARD_H__
