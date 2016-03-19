#include "generalpwm.h"
//#include <GeneralPWM.h>
module PWMTestP {
	uses {
		interface Timer<TMilli>;
		interface GeneralPWM;
		interface Boot @exactlyonce();
	}
}
implementation {

	event void Boot.booted() {
		call Timer.startOneShot(1000UL);
	}

	event void Timer.fired() {
		// 1kHz, PWM fast mode
		call GeneralPWM.configure(1000, PWM_MODE_FAST);

		// 33% dutycycle on channel A
		call GeneralPWM.start(0, 33, FALSE);
		// 66% dutycycle on channel B
		call GeneralPWM.start(1, 66, FALSE);
		// 66% inverted dutycycle on channel C
		call GeneralPWM.start(2, 66, TRUE);
		//    _        _        _
		// A | |______| |______| |______
		//    ____     ____     ____
		// B |    |___|    |___|    |___
		//          _        _        _
		// C ______| |______| |______| |
	}

}
