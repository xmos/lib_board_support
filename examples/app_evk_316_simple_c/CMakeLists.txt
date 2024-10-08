cmake_minimum_required(VERSION 3.21)
include($ENV{XMOS_CMAKE_PATH}/xcommon.cmake)
project(app_evk_316_simple_c)

set(APP_HW_TARGET                   XCORE-AI-EXPLORER) # This is the XTC tools supplied XN file for the XK_EVK_XU316

include(../deps.cmake)

set(APP_COMPILER_FLAGS              -Os
                                    -g
                                    -report
                                    -DBOARD_SUPPORT_BOARD=XK_EVK_XU316)



set(XMOS_SANDBOX_DIR                ${CMAKE_CURRENT_LIST_DIR}/../../..)

XMOS_REGISTER_APP()
