# InterruptHandlerLED
ARM Assembly Language program using the Vectored Interrupt Controller (VIC) to handle interrupts and interact with LPC2138's built-in LED's.

The program begins by turning an LED at _P1.16_ on. It then causes an interrupt to be raised every 5ms using the LPC2138's built in clock which has a period of 14745600Hz. This interrupt is then handled using the LPC2138's **Vectored Interrupt Controller (VIC)** which causes program execution to be halted, and passes execution to the respective **IRQ Handler**.

This handler counts to a given register until the interrupt has been called exactly 200 times i.e 1s since 200/5ms = 1s. It then turns off the current LED and turns on the next LED e.g _P1.17_. This occurs in an endless loop.