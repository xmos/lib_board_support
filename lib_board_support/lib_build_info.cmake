set(LIB_NAME lib_board_support)
set(LIB_VERSION 1.0.0)
set(LIB_INCLUDES api/boards api/drivers)
set(LIB_COMPILER_FLAGS_COMMON -Os -g)
set(LIB_COMPILER_FLAGS ${LIB_COMPILER_FLAGS_COMMON})
set(LIB_COMPILER_FLAGS_xk_audio_316_mc_ab_board.xc ${LIB_COMPILER_FLAGS_COMMON} -Wno-unusual-code)
set(LIB_DEPENDENT_MODULES   "lib_i2c(6.2.0)"
                            "lib_sw_pll(2.2.0)")

XMOS_REGISTER_MODULE()
