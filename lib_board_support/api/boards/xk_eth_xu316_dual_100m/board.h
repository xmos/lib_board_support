// Copyright 2025 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#ifndef __XK_ETH_XU316_DUAL_100M_BOARD_H__
#define __XK_ETH_XU316_DUAL_100M_BOARD_H__

#include <boards_utils.h>
#if (BOARD_SUPPORT_BOARD == XK_ETH_XU316_DUAL_100M) || defined(__DOXYGEN__)
#include <xccompat.h>
#include "smi.h"

#ifdef __XC__
#define NULLABLE_CLIENT_INTERFACE(tag, name) client interface tag ?name
#else
#define NULLABLE_CLIENT_INTERFACE(type, name) unsigned name
#endif


/**
 * \addtogroup xk_eth_xu316_dual_100m
 *
 * API for the xk_eth_xu316_dual_100m board.
 * @{
 */

/**
 * Type for telling dp83826e_phy_driver which PHY(s) to use.
 * Note it will be necessary to modify R3 and R23 according to which
 * PHY is used. Populate R23 and remove R3 for PHY_0 only otherwise
 * populate R3 and remove R23 for other settings
 */
typedef enum phy_used_t{
    USE_PHY_0, 
    USE_PHY_1,
    USE_PHY_0_AND_1_TWO_MACS, /** Two independent MAC instances */
    USE_PHY_0_AND_1_DUAL_MAC  /** Dual MAC (contact XMOS) */
}phy_used_t;

/** Task that connects to the SMI master and MAC to configure the
 * DP83826E PHY and monitor the link status. Note this task is combinable
 * (typically with SMI) and therefore does not need to take a whole thread.
 *
 *  \param i_smi        Client register read/write interface
 *  \param phy_address  The SMI address of the PHY to access
 *  \param i_eth        Primary client MAC configuration interface
 *  \param i_eth_2      Optional secondary client MAC configuration interface.
 *                      Used in cases where two independent MACs are instantiated.
 */
[[combinable]]
void dp83826e_phy_driver(CLIENT_INTERFACE(smi_if, i_smi),
                         phy_used_t phy_used,
                         CLIENT_INTERFACE(ethernet_cfg_if, i_eth),
                         NULLABLE_CLIENT_INTERFACE(ethernet_cfg_if, i_eth_second));

/** Sends hard reset to both PHYs. Both PHYs will be ready for SMI
 * communication once this function has returned.
 * This function must be called from Tile[1].
 * 
 */
void reset_eth_phys(void);


/**@}*/ // END: addtogroup xk_eth_xu316_dual_100m

#endif // (BOARD_SUPPORT_BOARD == XK_ETH_XU316_DUAL_100M) || defined(__DOXYGEN__)


#endif // __XK_ETH_XU316_DUAL_100M_BOARD_H__
