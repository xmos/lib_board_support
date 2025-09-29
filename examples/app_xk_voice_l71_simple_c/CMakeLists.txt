cmake_minimum_required(VERSION 3.21)
include($ENV{XMOS_CMAKE_PATH}/xcommon.cmake)
project(app_xk_voice_71_simple_c)

set(APP_HW_TARGET                   src/xk-voice-l71.xn)

include(../deps.cmake)

set(APP_COMPILER_FLAGS              -Os
                                    -g
                                    -report
                                    -DBOARD_SUPPORT_BOARD=XK_VOICE_L71)


# Fetch I2S from fwk_io
set(XMOS_SANDBOX_DIR    ${CMAKE_CURRENT_LIST_DIR}/../../..)

set(XMOS_DEP_DIR_i2s ${XMOS_SANDBOX_DIR}/fwk_io/modules)
if(NOT EXISTS ${XMOS_SANDBOX_DIR}/fwk_io)
    include(FetchContent)
    FetchContent_Declare(
        fwk_io
        GIT_REPOSITORY git@github.com:xmos/fwk_io
        GIT_TAG feature/xcommon_cmake
        SOURCE_DIR ${XMOS_SANDBOX_DIR}/fwk_io
    )
    message(STATUS Fetching fwk_io)
    FetchContent_Populate(fwk_io)
endif()

list(APPEND APP_DEPENDENT_MODULES "i2s")

set(XMOS_SANDBOX_DIR                ${CMAKE_CURRENT_LIST_DIR}/../../..)

XMOS_REGISTER_APP()
