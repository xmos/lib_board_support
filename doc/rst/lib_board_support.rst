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
must provide the xn file. The application must use the APIs for the specific board that it is using. To ensure that only the correct sources for the board in use get compiled in, it is necessary to set the preprocessor value `BOARD_SUPPORT_BOARD` to one of the available boards listed in `api/boards/boards_utils.h`. This can be done in the app with the following snippet of cmake::

    set(APP_COMPILER_FLAGS
	    -DBOARD_SUPPORT_BOARD=XK_AUDIO_316_MC_AB  # Change value to select board, see table below for available boards
	)


From the application it is necessary to include the relevant header file. For example::

    #include "xk_audio_316_mc_ab/board.h"

From then onwards in your code you may call the relevant API functions to setup and configure the board hardware.

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

Common API
==========

.. doxygengroup:: bs_common
   :content-only:


XK_EVK_XU316 API
================

.. doxygengroup:: xk_evk_xu316
   :content-only:

XK_AUDIO_316_MC_AB API
======================

.. doxygengroup:: xk_audio_316_mc_ab
   :content-only:


XK_AUDIO_216_MC_AB API
======================

.. doxygengroup:: xk_audio_216_mc_ab
   :content-only:
