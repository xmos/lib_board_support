set(LIB_NAME lib_board_support)
set(LIB_VERSION 1.1.0)
set(LIB_INCLUDES api/boards api/drivers)
set(LIB_COMPILER_FLAGS -Os -g)
set(LIB_DEPENDENT_MODULES   "lib_i2c(6.3.1)"
                            "lib_sw_pll(2.3.1)"
                            "lib_xassert(4.3.1)")

XMOS_REGISTER_MODULE()
