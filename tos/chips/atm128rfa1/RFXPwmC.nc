generic configuration RFXPwmC() {
	provides {
		interface GeneralPWM;
	}
}
implementation {

	// TODO implementation
	components new RFXPwmP() as Module;
	//Module = GeneralPWM;
	GeneralPWM = Module.GeneralPWM;

	components AtmegaGeneralIOC;
    Module.PinA -> AtmegaGeneralIOC.PortE3; //Hard-coded Port E, Pin 3
    Module.PinB -> AtmegaGeneralIOC.PortE4; //Hard-coded Port E, Pin 4
    Module.PinC -> AtmegaGeneralIOC.PortE5; //Hard-coded Port E, Pin 5

    components HplAtmRfa1Timer3C as PWMTimer;
    Module.Counter -> PWMTimer.Counter;
    Module.Compare -> PWMTimer.Compare[0]; //Hard-coded channel A
}
