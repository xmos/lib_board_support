// Copyright 2025 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#ifndef __XK_ETH_XU316_DUAL_100M_BOARD_H__
#define __XK_ETH_XU316_DUAL_100M_BOARD_H__

#include <boards_utils.h>
#if (BOARD_SUPPORT_BOARD == XK_ETH_XU316_DUAL_100M) || defined(__DOXYGEN__)
#include <xccompat.h>
#include "smi.h"



/**
 * \addtogroup xk_eth_xu316_dual_100m
 *
 * API for the xk_eth_xu316_dual_100m board.
 * @{
 */

/** Task that connects to the SMI master and MAC to configure the
 * DP83826E PHY and monitor the link status. Note this task is combinable
 * (typically with SMI) and therefore does not need to take a whole thread.
 *
 *  \param i_smi        Client register read/write interface
 *  \param i_eth        Client MAC configuration interface
 *  \param phy_address  The SMI address of the PHY to access
 */
[[combinable]]
void dp83826e_phy_driver(CLIENT_INTERFACE(smi_if, i_smi),
                         CLIENT_INTERFACE(ethernet_cfg_if, i_eth),
                         int phy_address);


/**@}*/ // END: addtogroup xk_eth_xu316_dual_100m

#endif // (BOARD_SUPPORT_BOARD == XK_ETH_XU316_DUAL_100M) || defined(__DOXYGEN__)


#endif // __XK_ETH_XU316_DUAL_100M_BOARD_H__
