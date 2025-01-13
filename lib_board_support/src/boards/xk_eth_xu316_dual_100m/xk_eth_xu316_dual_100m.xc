// Copyright 2025 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#include <xk_eth_xu316_dual_100m/board.h>
#include <boards_utils.h>
#if BOARD_SUPPORT_BOARD == XK_ETH_XU316_DUAL_100M
#include <xs1.h>
#include <platform.h>

static void set_smi_reg_bit(CLIENT_INTERFACE(smi_if, i_smi), phy_address, reg_addr, bit, val){
    uint16_t reg_val = smi.read_reg(phy_address, reg_addr);
    if(val){
        reg_val |= (0x1 << bit);
    } else {
         reg_val & = ~(0x1 << bit);
    }
    smi.write_reg(phy_address, reg_addr, reg_val);
}

// Bit 3 of this port is connected to the PHY resets. Other bits not pinned out.
on tile[1]: out port p_phy_rst_n = PHY_RST_N;
void reset_eth_phys(void){
    // From dp83826e datasheet
    p_phy_rst_n <: 0x00;
    delay_microseconds(25);
    p_phy_rst_n <: 0x08;
    delay_milliseconds(2);
}


[[combinable]]
void dp83826e_phy_driver(CLIENT_INTERFACE(smi_if, i_smi),
                         CLIENT_INTERFACE(ethernet_cfg_if, i_eth),
                         int phy_address){

    ethernet_link_state_t link_state = ETHERNET_LINK_DOWN;
    ethernet_speed_t link_speed = LINK_100_MBPS_FULL_DUPLEX;
    const int link_poll_period_ms = 1000;

    timer tmr;
    int t;
    tmr :> t;

    while (smi_phy_is_powered_down(smi, phy_address));
    // Ensure we are set into RXDV rather than CS mode
    set_smi_reg_bit(i_smi, phy_address, RMII_AND_STATUS_REG, IO_CFG_CRS_RX_DV_BIT, 1);
    // Do generic setup, set to 100Mbps always
    smi_configure(smi, phy_address, link_speed, SMI_DISABLE_AUTONEG);

    // Poll link state and update MAC if changed
    while (1) {
        select {
            case tmr when timerafter(t) :> t:
                ethernet_link_state_t new_state = smi_get_link_state(smi, phy_address);

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
