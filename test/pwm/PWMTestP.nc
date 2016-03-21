#include "generalpwm.h"
//#include <GeneralPWM.h>
module PWMTestP {
	uses {
		interface Timer<TMilli>;
		interface GeneralPWM;
		interface Boot @exactlyonce();
		//interface Leds;

		interface SplitControl as PrintfControl;
	}
}
implementation {

    #define __MODUUL__ "tests"
    #define __LOG_LEVEL__ ( LOG_LEVEL_tests & BASE_LOG_LEVEL )
    #include "log.h"

    bool m_fLedState=FALSE;

	event void Boot.booted() {
		call PrintfControl.start();
		//info1("Boot");
		//call Timer.startOneShot(1000UL);
		
	}


  event void PrintfControl.startDone(error_t err) {
  		info1("PrintfControl.startDone()");
		call Timer.startPeriodic(1000UL);

		//call Leds.led0On();
  }

  event void PrintfControl.stopDone(error_t err) {
  }	

	event void Timer.fired() {
		info1("Timer.fired()");
		debug1("DDRE %x, TIMSK3 %x, OCR3A %x, OCR3C %x, TCCR3A %x, TCCR3B %x", DDRE, TIMSK3, OCR3A, OCR3C, TCCR3A, TCCR3B);
		// 1kHz, PWM fast mode
		call GeneralPWM.configure(1000, PWM_MODE_FAST);
		debug1("DDRE %x, TIMSK3 %x, OCR3A %x, OCR3C %x, TCCR3A %x, TCCR3B %x", DDRE, TIMSK3, OCR3A, OCR3C, TCCR3A, TCCR3B);

		// 33% dutycycle on channel A
		call GeneralPWM.start(0, 33, FALSE);
		debug1("DDRE %x, TIMSK3 %x, OCR3A %x, OCR3C %x, TCCR3A %x, TCCR3B %x", DDRE, TIMSK3, OCR3A, OCR3C, TCCR3A, TCCR3B);
		// 66% dutycycle on channel B
		call GeneralPWM.start(1, 66, FALSE);
		debug1("DDRE %x, TIMSK3 %x, OCR3A %x, OCR3C %x, TCCR3A %x, TCCR3B %x", DDRE, TIMSK3, OCR3A, OCR3C, TCCR3A, TCCR3B);
		// 66% inverted dutycycle on channel C
		call GeneralPWM.start(2, 66, TRUE);
		debug1("DDRE %x, TIMSK3 %x, OCR3A %x, OCR3C %x, TCCR3A %x, TCCR3B %x", DDRE, TIMSK3, OCR3A, OCR3C, TCCR3A, TCCR3B);
		//    _        _        _
		// A | |______| |______| |______
		//    ____     ____     ____
		// B |    |___|    |___|    |___
		//          _        _        _
		// C ______| |______| |______| |

		
		/*
		if(!m_fLedState)
		{
			call Leds.led1Off();
		}
		else
		{
			call Leds.led1On();
		}

		m_fLedState = !m_fLedState;
		*/
	}

}
