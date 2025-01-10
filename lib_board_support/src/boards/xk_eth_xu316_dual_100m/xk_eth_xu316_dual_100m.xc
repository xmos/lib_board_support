// Copyright 2025 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#include <xk_eth_xu316_dual_100m/board.h>
#include <boards_utils.h>
#if BOARD_SUPPORT_BOARD == XK_ETH_XU316_DUAL_100M
#include <xs1.h>
#include <platform.h>

[[combinable]]
void dp83826e_phy_driver(CLIENT_INTERFACE(smi_if, i_smi),
                         CLIENT_INTERFACE(ethernet_cfg_if, i_eth)){

    ethernet_link_state_t link_state = ETHERNET_LINK_DOWN;
    ethernet_speed_t link_speed = LINK_100_MBPS_FULL_DUPLEX;
    const int link_poll_period_ms = 1000;
    const int phy_address = 0x0;
    timer tmr;
    int t;
    tmr :> t;

    while (smi_phy_is_powered_down(smi, phy_address));
    smi_configure(smi, phy_address, LINK_100_MBPS_FULL_DUPLEX, SMI_ENABLE_AUTONEG);

    while (1) {
        select {
            case tmr when timerafter(t) :> t:
                ethernet_link_state_t new_state = smi_get_link_state(smi, phy_address);
                // Read LAN8710A status register bit 2 to get the current link speed
                if ((new_state == ETHERNET_LINK_UP) && ((smi.read_reg(phy_address, 0x1F) >> 2) & 1)) {
                    link_speed = LINK_10_MBPS_FULL_DUPLEX;
                }
                else {
                    link_speed = LINK_100_MBPS_FULL_DUPLEX;
                }
                if (new_state != link_state) {
                    link_state = new_state;
                    eth.set_link_state(0, new_state, link_speed);
                }
                t += link_poll_period_ms * XS1_TIMER_KHZ;
                break;
        }
    }
}


#endif // BOARD_SUPPORT_BOARD == XK_ETH_XU316_DUAL_100M
