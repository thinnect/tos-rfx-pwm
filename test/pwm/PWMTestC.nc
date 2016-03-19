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
}
