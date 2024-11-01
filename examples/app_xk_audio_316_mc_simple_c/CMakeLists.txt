cmake_minimum_required(VERSION 3.21)
include($ENV{XMOS_CMAKE_PATH}/xcommon.cmake)
project(app_xk_audio_316_mc_simple_c)

set(APP_HW_TARGET                   xk-audio-316-mc.xn)

include(../deps.cmake)

set(APP_COMPILER_FLAGS              -Os
                                    -g
                                    -report
                                    -DBOARD_SUPPORT_BOARD=XK_AUDIO_316_MC_AB)



set(XMOS_SANDBOX_DIR                ${CMAKE_CURRENT_LIST_DIR}/../../..)

XMOS_REGISTER_APP()
