// Copyright 2024-2025 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#include <xk_evk_xe216/board.h>
#include <boards_utils.h>
#if BOARD_SUPPORT_BOARD == XK_EVK_XE216
#include <xs1.h>
#include <platform.h>

#include <debug_print.h>

#define PHY_CHIP_x_ID2_REV_MASK 0x000FU
// v1.3
#define PHY_CHIP_0_PHY_ADDR     0x00
#define PHY_CHIP_0_ID1          0x0022U
#define PHY_CHIP_0_ID2          (0x1622U & ~PHY_CHIP_x_ID2_REV_MASK)

// v1.2
#define PHY_CHIP_4_PHY_ADDR     0x04
#define PHY_CHIP_4_ID1          0x004DU
#define PHY_CHIP_4_ID2          (0xD072U & ~PHY_CHIP_x_ID2_REV_MASK)

// Pin connected to PHY reset
port p_eth_reset  = on tile[1]: XS1_PORT_1N;

[[combinable]]
void ar8035_phy_driver(CLIENT_INTERFACE(smi_if, i_smi),
                       CLIENT_INTERFACE(ethernet_cfg_if, i_eth)) {

    ethernet_link_state_t link_state = ETHERNET_LINK_DOWN;
    ethernet_speed_t link_speed = LINK_1000_MBPS_FULL_DUPLEX;
    const int phy_reset_delay_ms = 1;
    const int link_poll_period_ms = 1000;
    int phy_address = PHY_CHIP_4_PHY_ADDR;
    timer tmr;
    int t;
    tmr :> t;
    p_eth_reset <: 0;
    delay_milliseconds(phy_reset_delay_ms);
    p_eth_reset <: 1;

    // Dummy read, might be FFFF
    uint16_t id1 = i_smi.read_reg(phy_address, PHY_ID1_REG);

    id1 = i_smi.read_reg(phy_address, PHY_ID1_REG);
    uint16_t id2 = i_smi.read_reg(phy_address, PHY_ID2_REG);

    if ((id1 == PHY_CHIP_4_ID1) && ((id2 & ~PHY_CHIP_x_ID2_REV_MASK) == PHY_CHIP_4_ID2)) {
        while (smi_phy_is_powered_down(i_smi, phy_address));
    } else {
        phy_address = PHY_CHIP_0_PHY_ADDR;

        // Dummy read, might be FFFF
        id1 = i_smi.read_reg(phy_address, PHY_ID1_REG);

        id1 = i_smi.read_reg(phy_address, PHY_ID1_REG);
        id2 = i_smi.read_reg(phy_address, PHY_ID2_REG);
        
        if ((id1 == PHY_CHIP_0_ID1) && ((id2 & ~PHY_CHIP_x_ID2_REV_MASK) == PHY_CHIP_0_ID2)) {
            while (smi_phy_is_powered_down(i_smi, phy_address));
        } else {
            debug_printf("Chip not identified\n");
        }
    }

    smi_configure(i_smi, phy_address, LINK_1000_MBPS_FULL_DUPLEX, SMI_ENABLE_AUTONEG);

    while (1) {
        select {
            case tmr when timerafter(t) :> t:
                ethernet_link_state_t new_state = smi_get_link_state(i_smi, phy_address);
                // Read AR8035 status register bits 15:14 to get the current link speed
                if (new_state == ETHERNET_LINK_UP) {
                    link_speed = (ethernet_speed_t)(i_smi.read_reg(phy_address, 0x11) >> 14) & 3;
                }
                if (new_state != link_state) {
                    link_state = new_state;
                    i_eth.set_link_state(0, new_state, link_speed);
                }
                t += link_poll_period_ms * XS1_TIMER_KHZ;
                break;
        }
    }
}

#endif // BOARD_SUPPORT_BOARD == XK_EVK_XE216
