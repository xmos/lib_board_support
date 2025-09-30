#################
lib_board_support
#################

************
Introduction
************

This repo contains board specific hardware configuration code for various `XMOS` evaluation and development kits.
By keeping the board-specific code in a dedicated repository various applications need not replicate commonly used code such as initialisation of on-board peripherals and in addition any updates or fixes can easily be rolled out to all dependent applications.

|newpage|

****************
Supported Boards
****************

The following boards are supported by ``lib_board_support`` with interfaces provided in the languages shown in the table below.

+-----------------------+---------------------+
| Board                 | Supported Languages |
+=======================+=====================+
|XK_EVK_XU316           |       XC / C        |
+-----------------------+---------------------+
|XK_AUDIO_316_MC_AB     |       XC / C        |
+-----------------------+---------------------+
|XK_AUDIO_216_MC_AB     |       XC / C        |
+-----------------------+---------------------+
|XK_EVK_XE216           |       XC            |
+-----------------------+---------------------+
|XK_ETH_316_DUAL        |       XC            |
+-----------------------+---------------------+
|XK-VOICE-L71           |       XC / C        |
+-----------------------+---------------------+

The following sections describe the features of each supported board.

.. toctree::

   xk_audio_316_mc_ab/hw_316_mc
   xk_audio_216_mc_ab/hw_216_mc
   xk_evk_xu316/hw_evk_xu316
   xk_evk_xe216/hw_evk_xe216
   xk_eth_316_dual/hw_eth_316_dual
   xk_voice_l71/hw_xk_voice_l71.rst

|newpage|

*****
Usage
*****

Using ``lib_board_support``
===========================

``lib_board_support`` is intended to be used with `XCommon CMake <https://www.xmos.com/file/xcommon-cmake-documentation/?version=latest>`_
, the `XMOS` application build and dependency management system.

To use ``lib_board_support`` in an application, add it to the list of dependent modules in the application's `CMakeLists.txt` file and shown below.
`XMOS` dependant modules should be pinned to release versions where possible, otherwise the latest commit on the `develop` branch will be used.
The current release version of this library can be found on `XMOS Libraries <https://www.xmos.com/libraries>`_

.. code-block:: cmake

    set(APP_DEPENDENT_MODULES "lib_board_support")

.. note::

    For further details on managing modules, pinning to a release version and other options, please see the page
    `xcommon-cmake Dependency Management <https://www.xmos.com/documentation/XM-015090-PC/html/doc/dependency_management.html>`_.

The application must provide a relevant ``xn`` file or `target`. Example ``xn`` files are provided in this
library (see `xn_files` directory). If using an ``xn`` file, copy it into the application project and add the `CMake` configuration,
example given for the `XK-AUDIO-316-MC`:

.. code-block:: cmake

    set(APP_HW_TARGET "xk-audio-316-mc.xn")

When using `XK-EVK-XU316` and `XK-EVK-XE216` boards, instead of an ``xn`` file, the `target` should be specified as the board name as shown below.
As for general purpose evaluation boards the ``xn`` file provided with the XTC tools.

.. code-block:: cmake

    set(APP_HW_TARGET XK-EVK-XU316)

The application must use the APIs for its target board. To ensure only the correct sources are compiled, set the preprocessor symbol
`BOARD_SUPPORT_BOARD` to one of the boards listed in `api/boards/boards_utils.h`.
This can be done in the application with the following `CMake` of configuration:

.. code-block:: cmake

    set(APP_COMPILER_FLAGS -DBOARD_SUPPORT_BOARD=XK_AUDIO_316_MC_AB)

From the application where board initialisation of configuration is done it is necessary to include
the relevant header file. For example:

.. code-block:: c

    #include "xk_audio_316_mc_ab/board.h"

From then onwards the code may call the relevant API functions to setup and configure the board
hardware. Examples are provided in the `examples` directory of this repo.

Note that in some cases, the `xcore` tile that calls the configuration function (usually from I²S
initialisation) is different from the tile where I²C controller is placed. Since I²C controller is
required by most audio CODECs for configuration and `xcore` tiles can only communicate with each
other via channels, a remote server is needed to provide the I²C setup. This usually takes the
form of a task which is run on a thread placed on the I²C tile and is controlled via a channel
from the other tile where I²S resides. The cross-tile channel must be declared at the top-level
XC main function. The included examples provide a reference for this using both XC and C.

|newpage|

********************
Example Applications
********************

Some simple example applications are provided in order to show how to use ``lib_board_support``.

Simple C Usage
==============

The applications `app_evk_316_simple_c` and `app_xk_audio_316_mc_simple_c` provide a bare-bones
application where the hardware setup is called from C.

These applications run on the `XK-EVK-XU316` and `XK-AUDIO-316-MC` boards respectively.

They show how to use the cross-tile communications in conjunction with the I²C controller (master) server.
The applications only setup the hardware and then exit the I²C server.

XC Usage Example
================

The application `app_xk_audio_316_mc_simple_xc` demonstrates calling the hardware setup API from C.
It runs on the `XK-AUDIO-316-MC` board.

Building the example
====================

This section assumes that the `XMOS XTC Tools <https://www.xmos.com/software-tools/>`_ have been
downloaded and installed. The required version is specified in the accompanying ``README``.

Installation instructions can be found `here <https://xmos.com/xtc-install-guide>`_.

Special attention should be paid to the section on
`Installation of Required Third-Party Tools <https://www.xmos.com/documentation/XM-014363-PC/html/installation/install-configure/install-tools/install_prerequisites.html>`_.

The application is built using the `xcommon-cmake <https://www.xmos.com/file/xcommon-cmake-documentation/?version=latest>`_
build system, which is provided with the XTC tools and is based on `CMake <https://cmake.org/>`_.

The ``lib_board_support`` software ZIP package should be downloaded and extracted to a chosen working
directory.

To configure the build, the following commands should be run from an XTC command prompt.
In the following command-line snippets `<app-name>` is used to refer to the `examples` application sub-folder selected to be built:

.. code-block:: shell

    cd examples/<app-name>
    cmake -G "Unix Makefiles" -B build

If any dependencies are missing they will be retrieved automatically during this step.

The application binaries can be built using ``xmake``:

.. code-block:: shell

    xmake -j -C build

Binary artifacts (.xe files) will be generated under the appropriate subdirectories of the
``examples/<app-name>/bin`` directory — one for each supported build configuration.

For subsequent builds, the ``cmake`` step may be omitted.
If ``CMakeLists.txt`` or other build files are modified, ``cmake`` will be re-run automatically
by ``xmake`` as needed.

Running the example
===================

From an XTC command prompt, the following command should be run from the ``examples/<app-name>`` directory:

.. code-block:: shell

    xrun --io bin/<app-name>.xe

Alternatively, the application can be programmed into flash memory for standalone execution:

.. code-block:: shell

    xflash bin/<app-name>.xe

Full command-line process to build and run the `app_xk_audio_316_mc_simple_xc` example:

.. code-block:: shell

    cd examples/app_xk_audio_316_mc_simple_xc
    cmake -G "Unix Makefiles" -B build
    xmake -C build
    xrun --io bin/app_xk_audio_316_mc_simple_xc.xe

|newpage|

********************************
Application Programmer Interface
********************************

This section contains the details of the API support by `lib_board_support`. The API is broken down into 2 sections:

1. `Boards`: This includes subdirectories for each supported board which need to be included in the application.
2. `Drivers`: This includes sources for configuring peripheral devices which may be on one or more of
   the supported boards.

Common API
==========

This section contains the list of supported boards, one of which needs to be globally defined as
``BOARD_SUPPORT_BOARD`` in the project.

.. doxygengroup:: bs_common
   :content-only:

|newpage|


XK_AUDIO_316_MC_AB API
======================

.. doxygenstruct:: xk_audio_316_mc_ab_config_t
   :members:

.. doxygengroup:: xk_audio_316_mc_ab
   :content-only:

|newpage|


XK_AUDIO_216_MC_AB API
======================

.. doxygenstruct:: xk_audio_216_mc_ab_config_t
    :members:

.. doxygengroup:: xk_audio_216_mc_ab
   :content-only:

|newpage|

XK_EVK_XU316 API
================

.. doxygenstruct:: xk_evk_xu316_config_t
    :members:

.. doxygengroup:: xk_evk_xu316
   :content-only:

|newpage|

XK_EVK_XU216 API
================

.. doxygengroup:: xk_evk_xu216
   :content-only:

|newpage|

XK_ETH_316_DUAL API
==========================

.. doxygengroup:: xk_eth_316_dual
   :content-only:

|newpage|


XK_VOICE_L71 API
================

.. doxygenstruct:: xk_voice_l71_config_t
    :members:

.. doxygenenum:: xk_voice_l71_mclk_modes_t

.. doxygenenum:: xk_voice_l71_dac_pin_t

.. doxygenenum:: xk_voice_l71_rpi_enable_t

.. doxygengroup:: xk_voice_l71
   :content-only:

|newpage|

