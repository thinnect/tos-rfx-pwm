#include "loglevels.h"
generic configuration RFXTimer2PwmC() {
	provides {
		interface GeneralPWM;
	}
}
implementation {
	components new RFXAsyncTimerPwmP(1) as Module;
	//Module = GeneralPWM;
	GeneralPWM = Module.GeneralPWM;

	components AtmegaGeneralIOC;
    Module.Pin[0] -> AtmegaGeneralIOC.PortB4; //Hard-coded Port B, Pin 4

    components HplAtmRfa1Timer2AsyncC as PWMTimer;
    Module.Counter -> PWMTimer.Counter;
    Module.Compare -> PWMTimer.Compare;
}
