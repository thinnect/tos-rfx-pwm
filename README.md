# tos-rfx-pwm
TinyOS PWM module for atmega64/128/256 RFA1 and RFR2.


Location tos/chips/atm128rfa1 contains General PWM implementations of synchronous and asynchronous timers.
 - Synchronous is used for RFXTimer3PwmC component
 - Asynchronous is used for RFXTimer2PwmC component


Note that synchronous implementation allows full command of both general PWM features - frequency and duty cycle. Frequency is manipulated through counter top and divider and is common for all channels of a timer. Duty cycle can be chosen individually per each channel.
Asynchronous implementation is intended for external clock source generationg low frequency and allows only manipulating duty cycle.

In both cases, Fast PWM timer operation is used (and thus the only PWM mode supported).

Interface's configure() function accepts 2 paremeters: frequency and PWM mode (must be always PWM_MODE_FAST), it must be called before start() to initialize the interface.
And start() function wants 3 parameters: channel number (starts from 0), ducty cycle (8-bit unsigned value between 0 and 100) and phase invertion boolean flag. It can be called multiple times sequentially to update signal parameters without calling stop().
stop() function stops operation of the selected channel (passed to the function as an only argiment). It also stops entire timer operation if no output is generated for the other channels also.


Location test/pwm is home for usage example.
