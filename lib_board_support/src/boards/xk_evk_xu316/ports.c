// Copyright 2024 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
/// Port definitions need to be in C, this prevents XC compiler from
/// Complaining about conflicting ports between different boards.

#include <xs1.h>
#include <xcore/port.h>
#include <boards_utils.h>


port_t p_evk_scl = XS1_PORT_1N;
port_t p_evk_i2c_sda = XS1_PORT_1O;
port_t p_evk_codec_reset =  XS1_PORT_4A;

void xk_evk_xu316_init_ports_0() {
    port_enable(p_evk_scl);
    port_enable(p_evk_i2c_sda);
}
void xk_evk_xu316_init_ports_1() {
    port_enable(p_evk_codec_reset);
}
