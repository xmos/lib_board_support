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

This repo supports the `XMOS` build system; `XCommon CMake`. To use the library add ``lib_board_support``
to an applications `CMakeLists.txt` file using the `APP_DEPENDENT_MODULES` entry. The application
must provide a relevant ``xn`` file,  although example ``xn`` files are provided in alongside this
libray (see `xn_files` directory).

The application must use the APIs for the specific board that it is using.
To ensure that only the correct sources for the board in use get compiled in, it is necessary to
set the preprocessor value ``BOARD_SUPPORT_BOARD`` in the project to one of the available boards
listed in `api/boards/boards_utils.h`. This can be done in the app with the following snippet of
cmake::

    set(APP_COMPILER_FLAGS
        -DBOARD_SUPPORT_BOARD=XK_AUDIO_316_MC_AB  # Change value to select board, see api/boards/boards_utils.h for available boards
    )


From the application where board initialisation of configuration is done it is necessary to include
the relevant header file. For example::

    #include "xk_audio_316_mc_ab/board.h"

From then onwards the code may call the relevant API functions to setup and configure the board
hardware. Examples are provided in the `examples` directory of this repo.

Note that in some cases, the `xcore` tile that calls the configuration function (usually from |I2S|
initialisation) is different from the tile where |I2C| master is placed. Since |I2C| master is
required by most audio CODECs for configuration and `xcore` tiles can only communicate with each
other via channels, a remote server is needed to provide the |I2C| setup. This usually takes the
form of a task which is run on a thread placed on the |I2C| tile and is controlled via a channel
from the other tile where |I2S| resides. The cross-tile channel must be declared at the top-level
XC main function. The included examples provide a reference for this using both XC and C.

********************************
Application Programmer Interface
********************************

This section contains the details of the API support by `lib_board_support`. The API is broken down into 2 sections:

1. `Boards`: This includes subdirectories for each supported board which need to be included in your application.
2. `Drivers`: This includes sources for configuring peripheral devices which may be on one or more of
   the supported boards.


Common API
==========

This section contains the list of supported boards, one of which needs to be globally defined as
``BOARD_SUPPORT_BOARD`` in the project.

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

Some simple example applications are provided in order to show how to use `lib_board_support`.

Simple C Usage
==============

The applications `app_evk_316_simple_c` and `app_xk_audio_316_mc_simple_c` provide a bare-bones
application where the hardware setup is called from C.

These applications run on the `XK-EVK-XU316` and `XK-AUDIO-316-MC` boards respectively.

They show how to use the cross-tile communications in conjunction with the |I2C| master server.
The applications only setup the hardware and then exit the |I2C| server.

XC Usage Example
================

The application `app_xk_audio_316_mc_simple_xc` demonstrates calling the hardware setup API from C.
It runs on the `XK-AUDIO-316-MC` board.

Building and running
====================
To build and run an example, run the following from an XTC tools terminal to configure the build::

    cd examples/<app_name>
    cmake -G "Unix Makefiles" -B build

Any missing dependencies will be downloaded by the build system at this point.

The application binaries can be built using ``xmake``::

    xmake -C build

To run the application use the following command::

    xrun --io bin/<app_name>/<app_name>.xe

For example::

    cd examples/app_xk_audio_316_mc_simple_xc
    cmake -G "Unix Makefiles" -B build
    xmake -C build
    xrun --io bin/app_xk_audio_316_mc_simple_xc.xe


