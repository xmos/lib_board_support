cmake_minimum_required(VERSION 3.21)
include($ENV{XMOS_CMAKE_PATH}/xcommon.cmake)
project(app_xu316_i2s_loopback)

set(APP_HW_TARGET               xk-audio-316-mc.xn)

set(APP_DEPENDENT_MODULES       "lib_board_support(1.0.0)"
                                "lib_i2s(5.1.0)")

set(APP_COMPILER_FLAGS          -Os
                                -g
                                -report
                                -DBOARD_SUPPORT_BOARD=XK_AUDIO_316_MC_AB
                                )

set(XMOS_SANDBOX_DIR            ${CMAKE_CURRENT_LIST_DIR}/../../..)

XMOS_REGISTER_APP()