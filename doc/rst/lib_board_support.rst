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

This repo supports XCommon CMake. Simply add `lib_board_support` to an applications cmake file using the `APP_DEPENDENT_MODULES` entry. The application
must provide the xn file. The application must use the APIs for the specific board that it is using. To ensure that only the correct sources for the board in use get compiled in, it is necessary to set the preprocessor value `BOARD_SUPPORT_BOARD` to one of the available boards listed in `api/boards/boards_utils.h`. This can be done in the app with the following snippet of cmake::

    set(APP_COMPILER_FLAGS
	    -DBOARD_SUPPORT_BOARD=XK_AUDIO_316_MC_AB  # Change value to select board, see table below for available boards
	)


From the application where board initialisation of configuration is done it is necessary to include the relevant header file. For example::

    #include "xk_audio_316_mc_ab/board.h"

From then onwards in your code you may call the relevant API functions to setup and configure the board hardware.

Note that in some cases, the XCORE tile that calls the configuration function (usually from I2S initilaisation) is different from the tile where I2C master is placed. Since I2C master is required by most audio CODECs for configuration and tiles can only communicate via channels, a remote server is needed to provide the I2C setup. This usually takes the form of a task which is run on a thread placed on the I2C tile and is controlled via a channel. The cross-tile channel must be delcared at the top-level XC main function. The included examples show examples of this using both XC and C.

****************
Supported Boards
****************

The following boards are supported in this repo with interfaces provided in the languages shown in the table below.

+--------------------+---------------------+
| Board              | Supported Languages |
+====================+=====================+
|XK_EVK_XU316        | XC / C              |
+--------------------+---------------------+
|XK_AUDIO_316_MC_AB  | XC / C              |
+--------------------+---------------------+
|XK_AUDIO_216_MC_AB  | XC / C              |
+--------------------+---------------------+

The following section provides specific details on eacho of the boards supported by this library.

.. toctree::

   xk_audio_316_mc_ab/hw_316_mc
   xk_audio_216_mc_ab/hw_216_mc
   xk_evk_xu316/hw_evk_xu316

********************************
Application Programmer Interface
********************************

This section contains the details of the API support by lib_board_support.

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
