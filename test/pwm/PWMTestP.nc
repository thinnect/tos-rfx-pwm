#include "generalpwm.h"
module PWMTestP {
	uses {
		interface Timer<TMilli>;
		interface GeneralPWM;
		interface Boot @exactlyonce();
	}
}
implementation {

	enum {
		PWM_TOP = 0x1FF,
	}

	event void Boot.booted() {
		call Timer.startOneShot(1000UL);
	}

	event void Timer.fired() {
		// 1kHz, PWM fast mode
		call GeneralPWM.configure(1000, PWM_MODE_FAST);

		// Count up to PWM_TOP
		call GeneralPWM.setPeriod(PMW_TOP);

		// 33% dutycycle on channel A
		call GeneralPWM.start(0, PWM_TOP*33/100, FALSE);
		// 66% dutycycle on channel B
		call GeneralPWM.start(1, PWM_TOP*66/100, FALSE);
		// 66% inverted dutycycle on channel C
		call GeneralPWM.start(2, PWM_TOP*66/100, TRUE);
		//    _        _        _
		// A | |______| |______| |______
		//    ____     ____     ____
		// B |    |___|    |___|    |___
		//          _        _        _
		// C ______| |______| |______| |
	}

}
