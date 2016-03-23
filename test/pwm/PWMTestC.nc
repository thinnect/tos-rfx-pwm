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

	components new TimerMilliC() as TimerPrint;
	PWMTestP.TimerPrint -> TimerPrint;

	components new RFXPwmC() as Timer3Pwm;
	PWMTestP.GeneralPWM -> Timer3Pwm;

	//components Leds as LedsC;
	components LedsC;
	//PWMTestP.Leds -> PWMTestP;
	//PWMTestP.Leds -> LedsC;
	PWMTestP.Leds -> LedsC;

	#ifndef START_PRINTF_DELAY
	    #define START_PRINTF_DELAY 50
  	#endif

/*
  	components new StartPrintfC(START_PRINTF_DELAY);
  	PWMTestP.PrintfControl -> StartPrintfC.SplitControl;
  	*/
}
