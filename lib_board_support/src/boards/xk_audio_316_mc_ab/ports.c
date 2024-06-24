// Copyright 2024 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
/// Port definitions need to be in C, this prevents XC compiler from
/// Complaining about conflicting ports between different boards.

#include <xs1.h>
#include <xcore/port.h>
#include <xk_audio_316_mc_ab/ports.h>

port_t p_xk_audio_316_scl = PORT_I2C_SCL;
port_t p_xk_audio_316_sda = PORT_I2C_SDA;
port_t p_xk_audio_316_ctrl = PORT_CTRL;
port_t p_xk_audio_316_margin = XS1_PORT_1G;


void xk_audio_316_mc_ab_init_ports() {
    ENABLE_LOCAL_PORT(PORT_CTRL_TILE_NUM, p_xk_audio_316_ctrl);
    ENABLE_LOCAL_PORT(PORT_I2C_SDA_TILE_NUM, p_xk_audio_316_sda);
    ENABLE_LOCAL_PORT(PORT_I2C_SCL_TILE_NUM, p_xk_audio_316_scl);
    ENABLE_LOCAL_PORT(0, p_xk_audio_316_margin);
}
