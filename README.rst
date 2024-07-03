lib_board_support
=================

This repo contains board specific hardware configuration code for various XMOS evaluation kits. The
API is broken down into 2 sections:

1. Boards: This includes subdirectories for each supported board
2. Drivers: This includes sources for configuring peripheral devices which may be on 1 or more of the supported boards.

Usage
*****

This repo supports XCommon CMake. Simply add "lib_board_support" to an applications "APP_DEPENDENT_MODULES". The application
must provide the xn file. The application must use the APIs for the specific board that it is using. This library
is structured so that all boards get compiled and linked, this means that no further configuration is required to specify
the board that will be used.

Boards
******

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


