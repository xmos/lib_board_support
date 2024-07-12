set(LIB_NAME lib_board_support)
set(LIB_VERSION 0.1.0)
set(LIB_INCLUDES api/boards api/drivers)
set(LIB_COMPILER_FLAGS -O3 -g)
set(LIB_DEPENDENT_MODULES "lib_i2c")

XMOS_REGISTER_MODULE()
