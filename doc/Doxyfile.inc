# This file provides overrides to the Doxyfile configuration

PROJECT_NAME           = lib_board_support
PROJECT_BRIEF          = "Board specific hardware configuration code for various XMOS evaluation and development kits"

INPUT                  = ../lib_board_support/api/boards ../lib_board_support/api/boards/xk_evk_xu316 ../lib_board_support/api/boards/xk_audio_316_mc_ab ../lib_board_support/api/boards/xk_audio_216_mc_ab

PREDEFINED             = C_API= EXTERN_C= UNSAFE= __DOXYGEN__=1