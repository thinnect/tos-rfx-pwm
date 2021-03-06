#include "loglevels.h"
configuration RFXTimer3PwmC {
	provides {
		interface GeneralPWM;
	}
}
implementation {
	//components new RFXPwmP(3, TRUE) as Module;
	components new RFXPwmP(3) as Module;
	//Module = GeneralPWM;
	GeneralPWM = Module.GeneralPWM;

	components AtmegaGeneralIOC;
	Module.Pin[0] -> AtmegaGeneralIOC.PortE3; //Hard-coded Port E, Pin 3
	Module.Pin[1] -> AtmegaGeneralIOC.PortE4; //Hard-coded Port E, Pin 4
	Module.Pin[2] -> AtmegaGeneralIOC.PortE5; //Hard-coded Port E, Pin 5

	components HplAtmRfa1Timer3C as PWMTimer;
	Module.Counter -> PWMTimer.Counter;
	Module.Compare -> PWMTimer.Compare;
	Module.Capture -> PWMTimer.Capture;
}
