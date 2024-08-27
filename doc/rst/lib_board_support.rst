#################
lib_board_support
#################

************
Introduction
************

This repo contains board specific hardware configuration code for various `XMOS` evaluation and
development kits. The API is broken down into 2 sections:

1. Boards: This includes subdirectories for each supported board
2. Drivers: This includes sources for configuring peripheral devices which may be on 1 or more of
   the supported boards.

*****
Usage
*****

This repo supports XCommon CMake. Simply add "lib_board_support" to an applications "APP_DEPENDENT_MODULES". The application
must provide the xn file. The application must use the APIs for the specific board that it is using. To ensure that only the correct sources for the board in use get compiled in, it is necessary to set the preprocessor value `BOARD_SUPPORT_BOARD` to one of the available boards. This can be done in the app with the following snippet of cmake::

    set(APP_COMPILER_FLAGS
	    -DBOARD_SUPPORT_BOARD=XK_AUDIO_316_MC_AB  # Change value to select board, see table below for available boards
	)

****************
Supported Boards
****************

The following boards are supported in this repo with interfaces provided in the languages shown in the table.

+--------------------+---------------------+
| Board              | Supported Languages |
+====================+=====================+
|XK_EVK_XU316        | XC                  |
+--------------------+---------------------+
|XK_AUDIO_316_MC_AB  | XC                  |
+--------------------+---------------------+
|XK_AUDIO_216_MC_AB  | XC                  |
+--------------------+---------------------+

