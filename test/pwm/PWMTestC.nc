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

	components new RFXPwmC(&TCCR3A, &TCCR3B, &TCCR3C, &OCR3A, &OCR3B, &OCR3C, &TIMSK3, &TIFR3) as Timer3Pwm;
	PWMTestP.GeneralPWM -> Timer3Pwm;

}
