#include "generalpwm.h"

module PWMTestP {
	uses {
		interface Timer<TMilli>;
		interface GeneralPWM;
		interface Boot @exactlyonce();
		interface Leds;
	}
}
implementation {

    #define __MODUUL__ "tests"
    #define __LOG_LEVEL__ ( LOG_LEVEL_tests & BASE_LOG_LEVEL )
    #include "log.h"

    bool m_fLedState=FALSE;

	event void Boot.booted() {
		call Timer.startOneShot(1000UL);
	}

	event void Timer.fired() {
		//info1("Timer.fired()");
		//debug1("DDRE %x, TIMSK3 %x, OCR3A %x, OCR3C %x, TCCR3A %x, TCCR3B %x, ICR3 %x", DDRE, TIMSK3, OCR3A, OCR3C, TCCR3A, TCCR3B, ICR3);
		// 1kHz, PWM fast mode
		call GeneralPWM.configure(1000, PWM_MODE_FAST);
		//debug1("DDRE %x, TIMSK3 %x, OCR3A %x, OCR3C %x, TCCR3A %x, TCCR3B %x", DDRE, TIMSK3, OCR3A, OCR3C, TCCR3A, TCCR3B);

		// 33% dutycycle on channel A
		call GeneralPWM.start(0, 33, FALSE);
		//debug1("DDRE %x, TIMSK3 %x, OCR3A %x, OCR3C %x, TCCR3A %x, TCCR3B %x", DDRE, TIMSK3, OCR3A, OCR3C, TCCR3A, TCCR3B);
		// 66% dutycycle on channel B
//		call GeneralPWM.start(1, 66, FALSE);
		//debug1("DDRE %x, TIMSK3 %x, OCR3A %x, OCR3C %x, TCCR3A %x, TCCR3B %x", DDRE, TIMSK3, OCR3A, OCR3C, TCCR3A, TCCR3B);
		// 66% inverted dutycycle on channel C
		//call GeneralPWM.start(2, 66, TRUE);
		//debug1("DDRE %x, TIMSK3 %x, OCR3A %x, OCR3C %x, TCCR3A %x, TCCR3B %x", DDRE, TIMSK3, OCR3A, OCR3C, TCCR3A, TCCR3B);
		//    _        _        _
		// A | |______| |______| |______
		//    ____     ____     ____
		// B |    |___|    |___|    |___
		//          _        _        _
		// C ______| |______| |______| |

		
		call Leds.led1Toggle();
		//call Timer.startOneShot(60000UL);
	}

}
