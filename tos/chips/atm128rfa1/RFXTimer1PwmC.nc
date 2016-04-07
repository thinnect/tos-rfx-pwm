#include "loglevels.h"
generic configuration RFXTimer1PwmC() {
	provides {
		interface GeneralPWM;
	}
}
implementation {
	components new RFXPwmP(1, FALSE) as Module;
	GeneralPWM = Module.GeneralPWM;

	components AtmegaGeneralIOC;
	Module.Pin[0] -> AtmegaGeneralIOC.PortB5; //Hard-coded Port B, Pin 5

	components HplAtmRfa1Timer1C as PWMTimer;
	Module.Counter -> PWMTimer.Counter;
	Module.Compare -> PWMTimer.Compare;
	Module.Capture -> PWMTimer.Capture;
}
