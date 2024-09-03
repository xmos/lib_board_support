#################
lib_board_support
#################

************
Introduction
************

This repo contains board specific hardware configuration code for various `XMOS` evaluation and development kits. 
By keeping the board-specific code in a dedicated repository various applications need not replicate commonly used code such as initialisation of on-board peripherals and in addition any updates or fixes can easily be rolled out to all dependent applications.

****************
Supported Boards
****************

The following boards are supported in this repo with interfaces provided in the languages shown in the table below.

+--------------------+---------------------+
| Board              | Supported Languages |
+====================+=====================+
|XK_EVK_XU316        |       XC / C        |
+--------------------+---------------------+
|XK_AUDIO_316_MC_AB  |       XC / C        |
+--------------------+---------------------+
|XK_AUDIO_216_MC_AB  |       XC / C        |
+--------------------+---------------------+

The following section provides specific details of the features for each of the boards supported by this library.

.. toctree::

   xk_audio_316_mc_ab/hw_316_mc
   xk_audio_216_mc_ab/hw_216_mc
   xk_evk_xu316/hw_evk_xu316


*****
Usage
*****

This repo supports XCommon CMake. Simply add `lib_board_support` to an applications cmake file using the `APP_DEPENDENT_MODULES` entry. The application
must provide the ``xn`` file although example ``xn`` files are provided in this repo in the `xn_files` directory.

The application must use the APIs for the specific board that it is using. To ensure that only the correct sources for the board in use get compiled in, it is necessary to set the preprocessor value `BOARD_SUPPORT_BOARD` in your project to one of the available boards listed in `api/boards/boards_utils.h`. This can be done in the app with the following snippet of cmake::

    set(APP_COMPILER_FLAGS
        -DBOARD_SUPPORT_BOARD=XK_AUDIO_316_MC_AB  # Change value to select board, see api/boards/boards_utils.h for available boards
    )


From the application where board initialisation of configuration is done it is necessary to include the relevant header file. For example::

    #include "xk_audio_316_mc_ab/board.h"

From then onwards in your code you may call the relevant API functions to setup and configure the board hardware. Examples of doing this are provided in the `examples` directory of this repo.

Note that in some cases, the XCORE tile that calls the configuration function (usually from |I2S| initilaisation) is different from the tile where |I2C| master is placed. Since |I2C| master is required by most audio CODECs for configuration and XCORE tiles can only communicate with each other via channels, a remote server is needed to provide the |I2C| setup. This usually takes the form of a task which is run on a thread placed on the |I2C| tile and is controlled via a channel from the other tile where |I2S| resides. The cross-tile channel must be declared at the top-level XC main function. The included examples show examples of this using both XC and C.


********************************
Application Programmer Interface
********************************

This section contains the details of the API support by lib_board_support. The API is broken down into 2 sections:

1. Boards: This includes subdirectories for each supported board which need to be included in your application.
2. Drivers: This includes sources for configuring peripheral devices which may be on one or more of
   the supported boards.


Common API
==========

This section contains the list of supported boards, one of which needs to be globally defined as ``BOARD_SUPPORT_BOARD`` in your project.

.. doxygengroup:: bs_common
   :content-only:


XK_AUDIO_316_MC_AB API
======================

.. doxygenstruct:: xk_audio_316_mc_ab_config_t
   :members:

.. doxygengroup:: xk_audio_316_mc_ab
   :content-only:

XK_AUDIO_216_MC_AB API
======================

.. doxygenstruct:: xk_audio_216_mc_ab_config_t
    :members:

.. doxygengroup:: xk_audio_216_mc_ab
   :content-only:


XK_EVK_XU316 API
================

.. doxygenstruct:: xk_evk_xu316_config_t
    :members:

.. doxygengroup:: xk_evk_xu316
   :content-only:


********************
Example Applications
********************

Example applications are provided to show how to use lib_board_support.

Simple C Usage
==============

The applications `app_evk_316_simple_c <https://github.com/xmos/lib_board_support/tree/develop/examples/app_evk_316_simple_c>`_ and `app_xu316_mc_simple_c <https://github.com/xmos/lib_board_support/blob/develop/examples/app_xu316_mc_simple_c/README.rst>`_ provide a bare-bones application where the hardware setup is called from C. They show how to use the cross-tile communications in conjunction with the |I2C| master server. The applications only setup the hardware and then exit the |I2C| server.

XC Usage Example
================

A more sophisticated example is provided, written in XC, by `app_xu316_i2s_loopback <https://github.com/xmos/lib_board_support/tree/develop/examples/app_xu316_i2s_loopback>`_. This application sets up the hardware on the `XK_AUDIO_316_MC_AB` board and then runs an |I2S| loopback application to take samples from the on-board ADCs and send the signals out through the DACs. It keeps the |I2C| master server running in case the application wants to change sample rate which requires |I2C| configuration of the audio CODECs.

