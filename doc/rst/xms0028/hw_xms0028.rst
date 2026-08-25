|newpage|

XMS0028 Audio Development Board
===============================

The `XMS0028` is an `xcore.ai` audio development board built around the XU316-1024-QF60B-C32 device.
It provides a stereo analogue audio interface, user LEDs and buttons, and an integrated debug
adapter, all reachable over a single USB Type-C connection.

The board provides the following features:

- `xcore.ai` XU316-1024-QF60B-C32 device (two tiles)
- TLV320AIC3204 stereo audio CODEC
- 3.5mm CTIA headset jack (stereo output and microphone input)
- 3.5mm stereo line level input jack
- Three green user LEDs and two user push buttons
- 16Mbit QSPI boot flash (Winbond W25Q16JV)
- Integrated `xTAG` debug adapter behind an on-board USB hub
- Expansion pin header bringing out spare I/O

All of the on-board peripherals are wired to ``tile[0]``.

.. warning::

    The `XMS0028` is a development platform and should be considered an "example" rather
    than a fully fledged reference design.

Analogue Audio Input & Output
-----------------------------

A stereo CODEC (TLV320AIC3204), connected to the `xcore.ai` device via an I²S interface, provides
the analogue input and output. The CODEC is configured by the `xcore.ai` device over an I²C bus at
device address ``0x18``. The CODEC reset line is driven from bit 4 of ``PORT_GP_OUT`` and is active low.

Audio output is via the headphone drivers of the CODEC to the 3.5mm headset jack. The jack is wired
to the `CTIA` standard:

+---------+--------------------+
| Contact | Signal             |
+=========+====================+
| T       | Left audio out     |
+---------+--------------------+
| R1      | Right audio out    |
+---------+--------------------+
| R2      | Ground             |
+---------+--------------------+
| S       | Microphone         |
+---------+--------------------+

The headset microphone is biased through a 1K5 resistor and connects to the ``IN3_L`` input of the
CODEC. Note that the TLV320AIC3204 can only route ``IN3_L`` to the left MICPGA, so when the headset
microphone is selected as the input source the capture is mono on the left channel and the right
channel is muted.

A separate 3.5mm jack provides a line-level stereo input. It is connected pseudo-differentially to
reject ground-line noise: the left channel uses ``IN2_L``/``IN2_R`` and the right channel uses
``IN1_R``/``IN1_L``.

Each channel has a 5K6 series resistor and a 2K2 shunt resistor. The shunt resistor is in parallel
with the CODEC's 10K single-ended input impedance at 0 dB gain, giving an effective shunt resistance
of approximately 1K8. This attenuates a 2 Vrms line-level input by approximately 0.243 V/V to
approximately 0.486 Vrms at the CODEC input, below its 0.5 Vrms maximum. The resulting system input
impedance is approximately 7K4.

The headset microphone connects to the CODEC's MFP3 pin for headset detection.

The input source is selected when ``xms0028_AudioHwInit()`` is called, using the ``input_source``
field of ``xms0028_config_t``. It is not switched at run time.

Audio Clocking
--------------

`xcore.ai` devices are equipped with a secondary (or `application`) PLL which is used to generate
the audio master clock for the CODEC. The master clock is routed back into the device on
``PORT_MCLK_IN`` (``XS1_PORT_1O``) of ``tile[0]``, where it clocks the I²S interface. The CODEC
clock dividers are configured for a master clock of 512 times the sample rate.

LEDs, Buttons and Other IO
--------------------------

Three green LEDs and two push buttons are provided for general purpose user interfacing.

The LEDs are active high and share an 8-bit output port with the CODEC reset line. Because of this,
the LEDs must be driven through the helpers in ``xms0028/gpio_access.h``, which perform a lock
protected read-modify-write; writing the port directly would clobber the CODEC reset line.

The buttons are active low, with external pull-ups. ``xms0028_buttons_read()`` inverts them so that
a set bit means the button is pressed. Note that bit 1 of the same port carries the CODEC interrupt
line, so it is not free for application use; the driver does not currently make use of it.

+---------------------+------------------+-----------+
| Function            | Port             | Bits      |
+=====================+==================+===========+
| I²C SCL / SDA       | ``XS1_PORT_4E``  | 2 / 3     |
+---------------------+------------------+-----------+
| CODEC interrupt     | ``XS1_PORT_4F``  | 1         |
+---------------------+------------------+-----------+
| Push buttons        | ``XS1_PORT_4F``  | 2:3       |
+---------------------+------------------+-----------+
| CODEC reset         | ``XS1_PORT_8D``  | 4         |
+---------------------+------------------+-----------+
| Green LEDs          | ``XS1_PORT_8D``  | 5:7       |
+---------------------+------------------+-----------+
| I²S data to CODEC   | ``XS1_PORT_1L``  |           |
+---------------------+------------------+-----------+
| I²S data from CODEC | ``XS1_PORT_1M``  |           |
+---------------------+------------------+-----------+
| I²S bit clock       | ``XS1_PORT_1N``  |           |
+---------------------+------------------+-----------+
| I²S LR clock        | ``XS1_PORT_1P``  |           |
+---------------------+------------------+-----------+
| Master clock        | ``XS1_PORT_1O``  |           |
+---------------------+------------------+-----------+

Both I²C lines share a single 4-bit port and are driven using the single port I²C master from
``lib_i2c``. The board provides the external pull-up resistors this requires.

Spare I/O is brought out and made available on a pin header for easy connection of expansion
boards. These pins are deliberately left unnamed in the supplied ``xn`` file so that applications
are free to declare whatever ports they require.

Boot
----

The board boots from a 16Mbit Winbond W25Q16JV QSPI flash on the standard boot pins of ``tile[0]``.
The supplied ``xn`` file declares the flash by part type rather than by hand written page and sector
counts, so the geometry comes from the tools. The device also supports `SFDP`, so no flash device
specification is required by applications using ``libquadflash``.

Power
-----

The `XMS0028` is powered from the USB Type-C connector. The voltage is converted by on-board
regulators to the supplies used by the components. Applications should therefore configure the
device to present itself as a bus powered device when connected to an active USB host.

Debug
-----

For convenience the board includes an integrated `xTAG` debug adapter for debugging via JTAG/xSCOPE.
The `xTAG` sits behind an on-board USB hub together with the `xcore.ai` device, so a single USB
Type-C cable provides power, the device USB connection and the debug connection.
