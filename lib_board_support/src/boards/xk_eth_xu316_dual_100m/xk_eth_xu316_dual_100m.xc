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

rmii_port_timing_t get_port_timings(int phy_idx){
    rmii_port_timing_t port_timing = {0};
    if(phy_idx == 0){
        port_timing.clk_delay_tx_rising = 1;
        port_timing.clk_delay_tx_falling = 1;
        port_timing.clk_delay_rx_rising = 0;
        port_timing.clk_delay_tx_rising = 0;
        port_timing.pad_delay_rx = 1;
    } else if(phy_idx == 2) {
        port_timing.clk_delay_tx_rising = 0;
        port_timing.clk_delay_tx_falling = 0;
        port_timing.clk_delay_rx_rising = 0;
        port_timing.clk_delay_tx_rising = 0;
        port_timing.pad_delay_rx = 4;
    } else {
        fail("Invalid PHY idx\n");
    }

    return port_timing;
}


[[combinable]]
void dual_dp83826e_phy_driver(CLIENT_INTERFACE(smi_if, i_smi),
                              NULLABLE_CLIENT_INTERFACE(ethernet_cfg_if, i_eth_phy0),
                              NULLABLE_CLIENT_INTERFACE(ethernet_cfg_if, i_eth_phy1)){

    // Determine config. We always configure PHY0 because it is clock master.
    // We may use any combination of at least one PHY.
    // PHY0 is index 0 and PHY1 is index 1
    int use_phy0 = !isnull(i_eth_phy0);
    int use_phy1 = !isnull(i_eth_phy1);
    int num_phys_to_configure = 0;
    int num_phys_to_poll = 0;
    int idx_of_first_phy_to_poll = 0;

    if(use_phy0 && use_phy1){
        num_phys_to_configure = 2;
        num_phys_to_poll = 2;
        idx_of_first_phy_to_poll = 0;
    }
    else if (use_phy0 && !use_phy1){
        num_phys_to_configure = 1;
        num_phys_to_poll = 1;
        idx_of_first_phy_to_poll = 0;
    }
    else if (!use_phy0 && use_phy1){
        num_phys_to_configure = 2;
        num_phys_to_poll = 1;
        idx_of_first_phy_to_poll = 1;
    } else {
        fail("Must specify at least one ethernet_cfg_if configuration interface");
    }

    p_leds <: LED_RED; // Indicate link(s) down
    p_pwrdn_int :> int _; // Make Hi Z. This pin is pulled up by the PHY

    reset_eth_phys();

    ethernet_link_state_t link_state[2] = {ETHERNET_LINK_DOWN, ETHERNET_LINK_DOWN};
    ethernet_speed_t link_speed[2] = {LINK_100_MBPS_FULL_DUPLEX, LINK_100_MBPS_FULL_DUPLEX};
    const int link_poll_period_ms = 1000;

    // PHY_0 is the clock master so we always configure this one, even if only PHY_1 is used
    // because PHY_1 is the clock slave and PHY_0 is the clock master

    // Setup PHYs. Always configure PHY_0, optionally PHY_1
    for(int phy_idx = 0; phy_idx < num_phys_to_configure; phy_idx++){
        int phy_address = phy_addresses[phy_idx];
        //printf("Configuring PHY %d addr: 0x%x\n", phy_idx, phy_address);

        while(smi_phy_is_powered_down(i_smi, phy_address));
        // printf("PHY addr: 0x%x powered up\n", phy_address);

        // unsigned phy_id = smi_get_id(i_smi, phy_address);
        // printf("phy_id = 0x%08X\n", phy_id);

        // Ensure we are set into RXDV rather than CS mode
        set_smi_reg_bit(i_smi, phy_address, IO_CONFIG_1_REG, IO_CFG_CRS_RX_DV_BIT, 1);


        // Set LED config to light the SPEED100M LED correctly. LEDCFG register (0x0460). LED2. Want to set bits 11-8 to 0x5.
        // Datasheet says LED control is on bits 11-8 but I think it's really bits 4-7.
        // Reset value seems to be 0x0565, If we write 0x0555 it seems to work.
        // we should do a read modify write of bits 4-7.
        // "Here this is a mistake in the datasheet, but please test which led has what registers, to my knowledge the settings described will configure the Leds mentioned."
        // "Led LED grouping is swapped so LED1 is 3-0 LED2 is 7-4 and LED3 is 11-8 the description status the same. Please confirm with your tests"
        smi_mmd_write(i_smi, phy_address, 0x001F, 0x0460, 0x0555);

        // Set pins to higher drive strength "impedance control". This is needed especially for clock signal. This results in a wider eye by some 2ns also.
        // Note we also ensure RXDV is set too
        smi_mmd_write(i_smi, phy_address, 0x001F, 0x0302, 0xC100);

        // Specific setup for PHY_0
        if(phy_idx == 0){
            // None
        }

        // Specific setup for PHY_1 (if used)
        if(phy_idx == 1){
            // None
        }
    }


    // Timer for polling
    timer tmr;
    int t;
    tmr :> t;

    // printf("Number of PHYs to poll: %d\n", num_phys_to_poll);
    // printf("ID of first PHY to poll: %d\n", idx_of_first_phy_to_poll);

    // Poll link state and update MAC if changed
    while (1) {
        select {
            case tmr when timerafter(t) :> t:
                for(int phy_idx = idx_of_first_phy_to_poll; phy_idx < idx_of_first_phy_to_poll + num_phys_to_poll; phy_idx++){
                    int phy_address = phy_addresses[phy_idx];
                    ethernet_link_state_t new_state = smi_get_link_state(i_smi, phy_address);

                    if (new_state != link_state[phy_idx]) {
                        link_state[phy_idx] = new_state;
                        if(phy_idx == 0){
                            i_eth_phy0.set_link_state(0, new_state, link_speed[phy_idx]);
                        } else {
                            i_eth_phy1.set_link_state(0, new_state, link_speed[phy_idx]);
                        }
                        // printf("Link state of PHY: %d addr: 0x%x changed: %d\n", phy_idx, phy_address, link_state[phy_idx]);
                    }
                }
                // Do LEDs. Red means no link(s). Green means all links up. Yellow means one of two links up (if 2 PHYs uses).
                if(num_phys_to_poll == 2){
                    if((link_state[0] == ETHERNET_LINK_UP) && (link_state[1]) == ETHERNET_LINK_UP){ // Both are up
                        p_leds <: LED_GRN;
                    } else if((link_state[0] == ETHERNET_LINK_UP) ||(link_state[1]) == ETHERNET_LINK_UP){ // One is up
                        p_leds <: LED_YEL;
                    } else {
                        p_leds <: LED_RED; // Both down
                    }
                } else {
                    if(link_state[idx_of_first_phy_to_poll] == ETHERNET_LINK_UP){
                        p_leds <: LED_GRN;
                    } else {
                        p_leds <: LED_RED;
                    }
                }
                t += link_poll_period_ms * XS1_TIMER_KHZ;
            break;
#if ENABLE_MAC_START_NOTIFICATION
            case use_phy0 => i_eth_phy0.mac_started():
                // Mac has just started, or restarted
                i_eth_phy0.set_link_state(0, link_state[0], link_speed[0]);
            break;

            case use_phy1 => i_eth_phy1.mac_started():
                // Mac has just started, or restarted
                i_eth_phy1.set_link_state(0, link_state[1], link_speed[1]);
            break;
#endif
        }
    }
}

#endif // BOARD_SUPPORT_BOARD == XK_ETH_XU316_DUAL_100M
