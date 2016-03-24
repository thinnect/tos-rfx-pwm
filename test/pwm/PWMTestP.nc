#include "generalpwm.h"

module PWMTestP {
	uses {
		interface Timer<TMilli>;
		interface Timer<TMilli> as TimerPrint;
		interface Timer<TMilli> as TimerLedLevels;
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

    //LedTest
    const uint8_t m_bMaxLed = 2;
    uint8_t m_bLedNum = 0;
    const uint8_t m_bMaxDuctyCycle = 100;
    const uint32_t m_bFullCycleLoopTime = 5000UL;//MS
    const uint8_t m_bDuctyCycleStep = 5;
    //uint32_t m_bDutyCycleUpdateDelay = (m_bFullCycleLoopTime / (uint32_t)(m_bMaxDuctyCycle / m_bDuctyCycleStep))/(uint32_t)2;//MS
    uint32_t m_bDutyCycleUpdateDelay;
    uint8_t m_bCurrDutyCycle = 0;
    bool m_fDutyCycleIncrement = TRUE;
    //!Ledtest

	event void Boot.booted() {
		m_bDutyCycleUpdateDelay = (m_bFullCycleLoopTime / (uint32_t)(m_bMaxDuctyCycle / m_bDuctyCycleStep))/(uint32_t)2;//MS
		call Timer.startOneShot(1000UL);
	}

	event void Timer.fired() {
debug1("tf");
		//info1("Timer.fired()");
		//debug1("DDRE %x, TIMSK3 %x, OCR3A %x, OCR3C %x, TCCR3A %x, TCCR3B %x, ICR3 %x", DDRE, TIMSK3, OCR3A, OCR3C, TCCR3A, TCCR3B, ICR3);
		// 1kHz, PWM fast mode
		call GeneralPWM.configure(1000, PWM_MODE_FAST);
		//debug1("DDRE %x, TIMSK3 %x, OCR3A %x, OCR3C %x, TCCR3A %x, TCCR3B %x", DDRE, TIMSK3, OCR3A, OCR3C, TCCR3A, TCCR3B);

		// 33% dutycycle on channel A
		call GeneralPWM.start(0, 10, FALSE);
		//debug1("DDRE %x, TIMSK3 %x, OCR3A %x, OCR3C %x, TCCR3A %x, TCCR3B %x", DDRE, TIMSK3, OCR3A, OCR3C, TCCR3A, TCCR3B);
		// 66% dutycycle on channel B
		call GeneralPWM.start(1, 50, TRUE);
		//debug1("DDRE %x, TIMSK3 %x, OCR3A %x, OCR3C %x, TCCR3A %x, TCCR3B %x", DDRE, TIMSK3, OCR3A, OCR3C, TCCR3A, TCCR3B);
		// 66% inverted dutycycle on channel C
		call GeneralPWM.start(2, 90, FALSE);
		//debug1("DDRE %x, TIMSK3 %x, OCR3A %x, OCR3C %x, TCCR3A %x, TCCR3B %x", DDRE, TIMSK3, OCR3A, OCR3C, TCCR3A, TCCR3B);
		//    _        _        _
		// A | |______| |______| |______
		//    ____     ____     ____
		// B |    |___|    |___|    |___
		//          _        _        _
		// C ______| |______| |______| |

		
		call Leds.led1Toggle();
		//call Timer.startOneShot(60000UL);
//debug1("DDRE %x, TIMSK3 %x, OCR3A %x, OCR3C %x, TCCR3A %x, TCCR3B %x, ICR3 %x; tm %x cd %x", DDRE, TIMSK3, OCR3A, OCR3C, TCCR3A, TCCR3B, ICR3, m_bTimerMode, m_bClkDivNdx);
//debug1("DDRE %x, TIMSK3 %x, OCR3A %x, OCR3C %x, TCCR3A %x, TCCR3B %x, ICR3 %x; tm %x cd %x", DDRE, TIMSK3, OCR3A, OCR3C, TCCR3A, TCCR3B, ICR3);
		call TimerPrint.startOneShot(10UL);
		call TimerLedLevels.startPeriodic(m_bDutyCycleUpdateDelay);
	}
	
	event void TimerPrint.fired() {
		debug1("DDRE %x, TIMSK3 %x, OCR3A %x, OCR3C %x, TCCR3A %x, TCCR3B %x, ICR3 %x;", DDRE, TIMSK3, OCR3A, OCR3C, TCCR3A, TCCR3B, ICR3);
	}

	event void TimerLedLevels.fired() {
		/*
	    //LedTest
	    const uint8_t m_bMaxLed = 2;
	    uint8_t m_bLedNum = 0;
	    const uint8_t m_bMaxDuctyCycle = 100;
	    const uint32_t m_bFullCycleLoopTime = 5000UL;//MS
	    const uint8_t m_bDuctyCycleStep = 5;
	    uint32_t m_bDutyCycleUpdateDelay = m_bFullCycleLoopTime / (m_bMaxDuctyCycle / m_bDuctyCycleStep);//MS
	    uint8_t m_bCurrDutyCycle = 0;
	    //!Ledtest
	    */

	    if(m_bCurrDutyCycle == 0 && !m_fDutyCycleIncrement)
	    {
	    	call GeneralPWM.start(m_bLedNum, m_bCurrDutyCycle, FALSE); //Leave current channel at 0 duty cycle level
	    	m_bLedNum = (m_bLedNum >= m_bMaxLed ? 0 : m_bLedNum+1);
	    	m_fDutyCycleIncrement=!m_fDutyCycleIncrement;
	    }
	    else if(m_bMaxDuctyCycle <= m_bCurrDutyCycle && m_fDutyCycleIncrement)
	    {
    		m_fDutyCycleIncrement=!m_fDutyCycleIncrement;
	    }

	    call GeneralPWM.start(m_bLedNum, m_bCurrDutyCycle, FALSE);

	    if(!m_fDutyCycleIncrement)
	    {
	    	m_bCurrDutyCycle -= m_bDuctyCycleStep;
	    }
	    else if(m_fDutyCycleIncrement)
	    {
	    	m_bCurrDutyCycle += m_bDuctyCycleStep;
	    }
	}

}
