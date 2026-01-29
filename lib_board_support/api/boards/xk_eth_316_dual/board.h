// Copyright 2025-2026 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#ifndef __XK_ETH_316_DUAL_BOARD_H__
#define __XK_ETH_316_DUAL_BOARD_H__

#include <boards_utils.h>
#if (BOARD_SUPPORT_BOARD == XK_ETH_316_DUAL) || defined(__DOXYGEN__)
#include <xccompat.h>
#include "smi.h"

#ifndef NULLABLE_CLIENT_INTERFACE
#ifdef __XC__
#define NULLABLE_CLIENT_INTERFACE(tag, name) client interface tag ?name
#else
#define NULLABLE_CLIENT_INTERFACE(type, name) unsigned name
#endif
#endif // NULLABLE_CLIENT_INTERFACE

/**
 * \addtogroup xk_eth_316_dual
 *
 * API for the XK-ETH-316-DUAL board.
 * @{
 */

 /** Index value used with get_port_timings() to refer to which PHY is in operation.
  *
  * The timings change according to which PHY is active in the hardware configuration
  * of the dual PHY dev-kit.
  */
typedef enum {
    NULL_PHY_TIMINGS,
    PHY0_PORT_TIMINGS,
    PHY1_PORT_TIMINGS,
} port_timing_index_t;

/** Task that connects to the SMI master and MAC to configure the
 * DP83825I PHYs and monitor the link status. Note this task is combinable
 * (typically with SMI) and therefore does not need to take a whole thread.
 *
 * \note It is not necessary to use both PHYs. If only one PHY is needed, the other should be set to `null`.
 * PHY0 is the clock master so will always be configured regardless of which PHYs are in use.
 *
 *  \param i_smi        Client register read/write interface
 *  \param i_eth_phy_0  Client MAC configuration interface for PHY_0. Set to NULL if unused.
 *  \param i_eth_phy_1  Client MAC configuration interface for PHY_1. Set to NULL if unused.
 */
[[combinable]]
void dual_ethernet_phy_driver(CLIENT_INTERFACE(smi_if, i_smi),
                              NULLABLE_CLIENT_INTERFACE(ethernet_cfg_if, i_eth_phy_0),
                              NULLABLE_CLIENT_INTERFACE(ethernet_cfg_if, i_eth_phy_1));

/** Sends hard reset to both PHYs. Both PHYs will be ready for SMI
 * communication once this function has returned.
 * This function must be called from Tile[1].
 * 
 * \warning This function will reset both PHYs and the audio codec. To reset
 * one of these devices after start-up, use the smi_phy_reset() function to
 * set the reset bit in PHY Basic Control register.
 *
 */
void reset_eth_phys(void);

/** Returns a timing struct tuned to the XK-ETH-316-DUAL hardware.
 * This struct should be passed to the call to rmii_ethernet_rt_mac() and will
 * ensure setup and hold times are maximised at the pin level of the PHY connection.
 * rmii_port_timing_t is defined in lib_ethernet.
 * 
 *  \param phy_idx      The index of the PHY to get timing data about.
 *  \returns            The timing struct to be passed to the PHY.
 */
rmii_port_timing_t get_port_timings(port_timing_index_t phy_idx);


/**@}*/ // END: addtogroup xk_eth_316_dual

#endif // (BOARD_SUPPORT_BOARD == XK_ETH_316_DUAL) || defined(__DOXYGEN__)

#endif // __XK_ETH_316_DUAL_BOARD_H__
