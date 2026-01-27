// Copyright 2025-2026 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#include "boards_utils.h"
#include "xk_eth_316_dual/board.h"

#if BOARD_SUPPORT_BOARD == XK_ETH_316_DUAL
#include <platform.h>
#include <xs1.h>

#define DEBUG_UNIT xk_eth_316_dual
#include "debug_print.h"
#include "xassert.h"

#define MMD_GENERAL_RANGE         0x001F

// IO Config Register address
#define IO_CONFIG_REG             0x0302

// IO configuration register bits
#define IO_CONFIG_CRS_RX_DV_BIT   8
#define IO_CONFIG_25_OHMS_BIT     14

#define PHY_RST_DURATION_US       100
#define POST_RST_PHY_DELAY_MS     55

// Time pending macro, difference must be less than (UINT32_MAX / 2) or ~20 seconds.
#define TIME_PENDING(target, now) ((int32_t)((uint32_t)(target) - (uint32_t)(now)) > 0)

// Bit 3 of this port is connected to the PHY resets. Other bits not pinned out.
on tile[1] : out port p_phy_rst = PERIPH_RST;

#define ETH_PHY_0_ADDR 0x00
#define ETH_PHY_1_ADDR 0x02
static const uint8_t phy_addresses[2] = {ETH_PHY_0_ADDR, ETH_PHY_1_ADDR};

static void set_mmd_reg_bitmask(client interface smi_if i_smi, unsigned phy_address, 
                                unsigned reg_addr, unsigned mask) {

  uint16_t reg_val = smi_mmd_read(i_smi, phy_address, MMD_GENERAL_RANGE, reg_addr);
  reg_val |= mask;
  smi_mmd_write(i_smi, phy_address, MMD_GENERAL_RANGE, reg_addr, reg_val);
}

void reset_eth_phys() {
  p_phy_rst <: 0x08;                          // Set bit 3 high to reset the PHY and codec
  delay_microseconds(PHY_RST_DURATION_US);    // dp83825i datasheet says 25us min
  p_phy_rst <: 0x00;                          // Set bit 3 low
  delay_milliseconds(POST_RST_PHY_DELAY_MS);  // dp83825i datasheet says 50ms max to be ready for SMI communication
}

static int check_phy_responds(client interface smi_if i_smi, unsigned phy_address, uint32_t timeout_s) {

  assert((timeout_s <= 20) && msg("Timeout value too large, should be less than or equal to 20s"));

  timer tmr;
  uint32_t timeout;
  uint32_t fail_time;
  uint32_t now;

  tmr :> now;
  fail_time = now + (timeout_s * XS1_TIMER_HZ);
  timeout = now + XS1_TIMER_HZ / 2;

  int result = smi_phy_is_powered_down(i_smi, phy_address);
  while ((result == 1) && TIME_PENDING(fail_time, now))
  {
    select {
      case tmr when timerafter(timeout) :> unsigned current:
        // Power up the PHY
        now = current;
        result = smi_phy_is_powered_down(i_smi, phy_address);
        timeout += XS1_TIMER_HZ / 2;
        break;
    }
  }
  return result;
}

rmii_port_timing_t get_port_timings(port_timing_index_t phy_idx) {
  rmii_port_timing_t port_timing = {0, 0, 0, 0, 0};
  
  if (phy_idx == PHY0_PORT_TIMINGS) {
    port_timing.clk_delay_tx_rising = 4;
    port_timing.clk_delay_tx_falling = 4;
    port_timing.clk_delay_rx_rising = 0;
    port_timing.clk_delay_rx_falling = 0;
    port_timing.pad_delay_rx = 0;

  // TODO - test and update timings for this board - PHY1
  } else if (phy_idx == PHY1_PORT_TIMINGS) {
    port_timing.clk_delay_tx_rising = 0;
    port_timing.clk_delay_tx_falling = 0;
    port_timing.clk_delay_rx_rising = 0;
    port_timing.clk_delay_rx_falling = 0;
    port_timing.pad_delay_rx = 0;

  } else {
    fail("Invalid PHY idx\n");
  }

  return port_timing;
}

[[combinable]]
void dual_ethernet_phy_driver(client interface smi_if i_smi,
                              client interface ethernet_cfg_if ?i_eth_phy0,
                              client interface ethernet_cfg_if ?i_eth_phy1) {
  // Determine config. We always configure PHY0 because it is clock master.
  // We may use any combination of at least one PHY.
  // PHY0 is index 0 and PHY1 is index 1
  int use_phy0 = !isnull(i_eth_phy0);
  int use_phy1 = !isnull(i_eth_phy1);
  int num_phys_to_configure = 0;
  int num_phys_to_poll = 0;
  int idx_of_first_phy_to_poll = 0;

  if (use_phy0 && use_phy1) {
    num_phys_to_configure = 2;
    num_phys_to_poll = 2;
    idx_of_first_phy_to_poll = 0;
  } else if (use_phy0 && !use_phy1) {
    num_phys_to_configure = 1;
    num_phys_to_poll = 1;
    idx_of_first_phy_to_poll = 0;
  } else if (!use_phy0 && use_phy1) {
    num_phys_to_configure = 2;
    num_phys_to_poll = 1;
    idx_of_first_phy_to_poll = 1;
  } else {
    fail("Must specify at least one ethernet_cfg_if configuration interface");
  }

  reset_eth_phys();

  const ethernet_speed_t TARGET_LINK_SPEED = LINK_100_MBPS_FULL_DUPLEX;
  ethernet_link_state_t link_state[2] = {ETHERNET_LINK_DOWN, ETHERNET_LINK_DOWN};
  ethernet_speed_t link_speed[2] = {LINK_100_MBPS_FULL_DUPLEX, LINK_100_MBPS_FULL_DUPLEX};
  const int link_poll_period_ms = 1000;

  // PHY_0 is the clock master so we always configure this one, even if only PHY_1 is used
  // because PHY_1 is the clock slave and PHY_0 is the clock master

  // Setup PHYs. Always configure PHY_0, optionally PHY_1
  for (int phy_idx = 0; phy_idx < num_phys_to_configure; phy_idx++) {
    uint8_t phy_address = phy_addresses[phy_idx];

    int phy_state = check_phy_responds(i_smi, phy_address, 10);
    assert(phy_state == 0 && msg("PHY failed to respond\n"));

    debug_printf("Starting PHY %d\n", phy_idx);

    smi_configure(i_smi, phy_address, TARGET_LINK_SPEED, SMI_ENABLE_AUTONEG);

    // Ensure RXDV is set.
    // Also set pins to higher drive strength "impedance control".
    set_mmd_reg_bitmask(i_smi, phy_address, IO_CONFIG_REG, (1 << IO_CONFIG_25_OHMS_BIT) | (1 << IO_CONFIG_CRS_RX_DV_BIT));

    // Specific setup for PHY_0
    if (phy_idx == 0) {
      // None
    }

    // Specific setup for PHY_1 (if used)
    if (phy_idx == 1) {
      // None
    }
  }

  // Timer for polling
  timer tmr;
  uint32_t t;
  tmr :> t;

  // Poll link state and update MAC if changed
  while (1) {
    select {
      case tmr when timerafter(t) :> t:
        for (int phy_idx = idx_of_first_phy_to_poll; phy_idx < (idx_of_first_phy_to_poll + num_phys_to_poll); phy_idx++) {
          uint8_t phy_address = phy_addresses[phy_idx];
          ethernet_link_state_t new_state = smi_get_link_state(i_smi, phy_address);

          if (new_state != link_state[phy_idx]) {
            link_state[phy_idx] = new_state;
            if (new_state == ETHERNET_LINK_UP) {
              link_speed[phy_idx] = smi_get_link_speed(i_smi, phy_address);
            }
            if (phy_idx == 0) {
              i_eth_phy0.set_link_state(0, new_state, link_speed[phy_idx]);
            } else {
              i_eth_phy1.set_link_state(0, new_state, link_speed[phy_idx]);
            }
          }
        }
        t += link_poll_period_ms * XS1_TIMER_KHZ;
        break;
#if ENABLE_MAC_START_NOTIFICATION
      case use_phy0 => i_eth_phy0.mac_started():
        // Mac has just started, or restarted
        i_eth_phy0.ack_mac_start();
        i_eth_phy0.set_link_state(0, link_state[0], link_speed[0]);
        break;

      case use_phy1 => i_eth_phy1.mac_started():
        // Mac has just started, or restarted
        i_eth_phy1.ack_mac_start();
        i_eth_phy1.set_link_state(0, link_state[1], link_speed[1]);
        break;
#endif
    }
  }
}

#endif  // BOARD_SUPPORT_BOARD == XK_ETH_316_DUAL
