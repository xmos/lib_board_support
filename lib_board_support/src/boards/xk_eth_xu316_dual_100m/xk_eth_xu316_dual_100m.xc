// Copyright 2025 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#include <xk_eth_xu316_dual_100m/board.h>
#include <boards_utils.h>
#if BOARD_SUPPORT_BOARD == XK_ETH_XU316_DUAL_100M
#include <xs1.h>
#include <platform.h>
#include <stdio.h>
#include "xassert.h"


// Bit 3 of this port is connected to the PHY resets. Other bits not pinned out.
on tile[1]: out port p_phy_rst_n = PHY_RST_N;
on tile[1]: port p_pwrdn_int = PWRDN_INT;
on tile[1]: out port p_leds = LED_GRN_RED;

#define ETH_PHY_0_ADDR 0x05
#define ETH_PHY_1_ADDR 0x07
const int phy_addresses[2] = {ETH_PHY_0_ADDR, ETH_PHY_1_ADDR};

#define LED_OFF 0xffffffff
#define LED_RED 0xfffffffd
#define LED_GRN 0xfffffffe
#define LED_YEL 0xfffffffc

static void set_smi_reg_bit(CLIENT_INTERFACE(smi_if, i_smi), unsigned phy_address, unsigned reg_addr, unsigned bit, unsigned val)
{
    uint16_t reg_val = i_smi.read_reg(phy_address, reg_addr);
    if(val){
        reg_val |= (0x1 << bit);
    } else {
         reg_val &= ~(0x1 << bit);
    }
    i_smi.write_reg(phy_address, reg_addr, reg_val);
}

void reset_eth_phys()
{
    p_phy_rst_n <: 0x00;
    delay_microseconds(100); // dp83826e datasheet says 25us min
    p_phy_rst_n <: 0x08;     // Set bit 3 high
    delay_milliseconds(2);
}

/* Other possible TODO items from Joe:
RCSR Register (0x17):
For RMII Master PHY (25M clock ref):
Set 25M clock ref, RMII mode, CRS_DV set as data valid not carrier sense: 0x0031
 
For RMII slave PHY (50M clock ref):
Set 50M clock ref, RMII mode, CRS_DV set as data valid not carrier sense: 0x00B1
 
LEDCR register should be ok at default. Otherwise set to default: 0x0400.
 
LEDCFG Register might be ok at default. Depends on their definition of "High" given pin is active low.
LED2 is set to output "Speed, High for 10BASE-T". Does high mean active? If so LED will light for 10BASE-T which isn't what we want? Will have to test and see.
 
It would be useful to read and print registers SOR1 and SOR2 as these contain useful read only status. These are at address 0x467 and 0x468.
*/

[[combinable]]
void dp83826e_phy_driver(CLIENT_INTERFACE(smi_if, i_smi),
                         const phy_used_t phy_used,
                         CLIENT_INTERFACE(ethernet_cfg_if, i_eth),
                         NULLABLE_CLIENT_INTERFACE(ethernet_cfg_if, i_eth_second)){

    p_leds <: LED_RED;
    p_pwrdn_int :> int _; // Make Hi Z. This pin is pulled up by the PHY

    reset_eth_phys();

    ethernet_link_state_t link_state[2] = {ETHERNET_LINK_DOWN, ETHERNET_LINK_DOWN};
    ethernet_speed_t link_speed[2] = {LINK_100_MBPS_FULL_DUPLEX, LINK_100_MBPS_FULL_DUPLEX};
    const int link_poll_period_ms = 1000;

    // PHY_0 is the clock master so we always configure this one, even if only PHY_1 is used
    const int num_phys_to_configure = (phy_used == USE_PHY_0 ? 1 : 2);
    printf("Number of PHYs to configure: %d\n", num_phys_to_configure);

    // Setup PHYs. Always configure PHY_0, optionally PHY_1
    for(int phy_num = 0; phy_num < num_phys_to_configure; phy_num++){
        int phy_address = phy_addresses[phy_num];
        printf("Configuring PHY addr: 0x%x\n", phy_address);

        while (smi_phy_is_powered_down(i_smi, phy_address));
        // Ensure we are set into RXDV rather than CS mode
        set_smi_reg_bit(i_smi, phy_address, RMII_AND_STATUS_REG, IO_CFG_CRS_RX_DV_BIT, 1);
        // Do generic setup, set to 100Mbps always
        smi_configure(i_smi, phy_address, link_speed[phy_num], SMI_DISABLE_AUTONEG);

        // Specific setup for PHY_0
        if(phy_num == 0){

        }

        // Specific setup for PHY_0
        if(phy_num == 0){

        }
    }

    timer tmr;
    int t;
    tmr :> t;

    // work out which PHYs to check the link status of
    const int num_phys_to_poll = ((phy_used == USE_PHY_0) || (phy_used == USE_PHY_1) ? 1 : 2);
    printf("Number of PHYs to poll: %d\n", num_phys_to_poll);
    const int id_of_first_phy = (phy_used == USE_PHY_1 ? 1 : 0);
    printf("ID of first PHY to poll: %d\n", id_of_first_phy);
    p_leds <: LED_YEL;

    // Poll link state and update MAC if changed
    while (1) {
        select {
            case tmr when timerafter(t) :> t:
                for(int phy_num = 0; phy_num < num_phys_to_poll; phy_num++){
                    int phy_idx = phy_num + id_of_first_phy;
                    int phy_address = phy_addresses[phy_idx];
                    printf("Checking link state of PHY: %d addr: 0x%x\n", phy_idx, phy_address);
                    ethernet_link_state_t new_state = smi_get_link_state(i_smi, phy_address);

                    if (new_state != link_state[phy_idx]) {
                        link_state[phy_idx] = new_state;
                        if(phy_num == 0){
                            i_eth.set_link_state(0, new_state, link_speed[phy_idx]);
                        } else {
                            i_eth_second.set_link_state(0, new_state, link_speed[phy_idx]);
                        }
                        printf("Link state of PHY: %d addr: 0x%x changed: %d\n", phy_idx, phy_address, link_state[phy_idx]);
                        p_leds <: (link_state == ETHERNET_LINK_UP) ? LED_GRN : LED_YEL;
                    }
                }
                t += link_poll_period_ms * XS1_TIMER_KHZ;
            break;
        }
    }
}


#endif // BOARD_SUPPORT_BOARD == XK_ETH_XU316_DUAL_100M
