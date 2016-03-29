/**
 * PWM module test wiring.
 *
 * @author Raido Pahtma
 * @license MIT
 */
#include "loglevels.h"
configuration PWMTestC { }
implementation {

	components PWMTestP;

	components MainC;
	PWMTestP.Boot -> MainC;
	//PWMTestP.Boot -> MainC.Boot;

	components new TimerMilliC();
	PWMTestP.Timer -> TimerMilliC;

	components new TimerMilliC() as TimerLedLevels;
	PWMTestP.TimerLedLevels -> TimerLedLevels;

	components new RFXTimer3PwmC() as Timer3Pwm;
	PWMTestP.Timer3Pwm -> Timer3Pwm;

	components new RFXTimer2PwmC() as Timer2Pwm;
	PWMTestP.Timer2Pwm -> Timer2Pwm;

	components LedsC;
	PWMTestP.Leds -> LedsC;

	#ifndef START_PRINTF_DELAY
		#define START_PRINTF_DELAY 50
	#endif

/*
	components new StartPrintfC(START_PRINTF_DELAY);
	PWMTestP.PrintfControl -> StartPrintfC.SplitControl;
	*/
}
