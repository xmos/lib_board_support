cmake_minimum_required(VERSION 3.21)
include($ENV{XMOS_CMAKE_PATH}/xcommon.cmake)
project(app_xk_voice_71_simple_c)

set(APP_HW_TARGET                   src/xk-voice-l71.xn)

include(../deps.cmake)

set(APP_COMPILER_FLAGS              -Os
                                    -g
                                    -report
                                    -DBOARD_SUPPORT_BOARD=XK_VOICE_L71)



set(XMOS_SANDBOX_DIR                ${CMAKE_CURRENT_LIST_DIR}/../../..)

XMOS_REGISTER_APP()
