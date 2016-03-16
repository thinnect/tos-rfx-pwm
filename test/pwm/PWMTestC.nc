/**
 * PWM module test wiring.
 *
 * @author Raido Pahtma
 * @license MIT
 */
configuration PWMTestC { }
implementation {

	components PWMTestP;

	components MainC;
	PWMTestP.Boot -> MainC;

	components new TimerMilliC();
	PWMTestP.Timer -> TimerMilliC;

	components new RFXPwmC() as Timer3Pwm;
	PWMTestP.GeneralPWM -> Timer3Pwm;

	components AtmegaGeneralIOC;
	Timer3Pwm.PinA -> AtmegaGeneralIOC.PortE3;
	Timer3Pwm.PinB -> AtmegaGeneralIOC.PortE4;
	Timer3Pwm.PinC -> AtmegaGeneralIOC.PortE5;

	components HplAtmRfa1Timer3C as PWMTimer;
	Timer3Pwm.Counter -> PWMTimer.Counter;
	Timer3Pwm.Compare -> PWMTimer.Compare;

}
