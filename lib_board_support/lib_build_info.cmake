set(LIB_NAME                lib_board_support)

set(LIB_VERSION             1.5.0)

set(LIB_INCLUDES            api/boards api/drivers)

set(LIB_COMPILER_FLAGS      -Os
                            -g
                            -Wall)

set(LIB_OPTIONAL_HEADERS    board_support_conf.h)

set(LIB_DEPENDENT_MODULES   "lib_xassert(4.3.2)"
                            "lib_logging(3.4.0)"
                            "lib_i2c(6.4.1)"
                            "lib_sw_pll(2.4.1)")

XMOS_REGISTER_MODULE()
