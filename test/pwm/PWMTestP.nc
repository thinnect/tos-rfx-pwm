#include "generalpwm.h"

module PWMTestP {
	uses {
		interface Timer<TMilli>;
		interface Timer<TMilli> as TimerLedLevels;
		interface GeneralPWM as TimerPwmRGB;
		interface GeneralPWM as TimerPwmWhite;
		interface Boot @exactlyonce();
		interface Leds;

		//interface GeneralIO as Pin[uint8_t pin];
		interface GeneralIO as PinB4;
	}
}
implementation {

	#define __MODUUL__ "tests"
	#define __LOG_LEVEL__ ( LOG_LEVEL_tests & BASE_LOG_LEVEL )
	#include "log.h"

	bool m_fLedState=FALSE;

	//LedTest
	const uint8_t m_bMaxLed = 3;
	uint8_t m_bLedNum = 0;
	const uint8_t m_bMaxDuctyCycle = 100;
	const uint32_t m_bFullCycleLoopTime = 5000UL;//MS
	const uint8_t m_bDuctyCycleStep = 1;
	uint32_t m_bDutyCycleUpdateDelay;
	uint8_t m_bCurrDutyCycle = 0;
	bool m_fDutyCycleIncrement = TRUE;
//	const uint16_t m_rgFrequencyValues[] = {5,50,75,100,1000};
	const uint16_t m_rgFrequencyValues[] = {60,75,150,1000,5000};
	const uint8_t m_bFreqValNum = (uint8_t)(sizeof(m_rgFrequencyValues)/sizeof(uint16_t));
	uint8_t m_bCurrFreqNdx = 0;
	bool m_fInverted = FALSE;
	//!Ledtest

	event void Boot.booted() {
		debug1("booted");
		m_bDutyCycleUpdateDelay = (m_bFullCycleLoopTime / (uint32_t)(m_bMaxDuctyCycle / m_bDuctyCycleStep))/(uint32_t)2;//MS
		call Timer.startOneShot(1000UL);
	}

	event void Timer.fired() {
		info1("Timer.fired()");
		// 1kHz, PWM fast mode
		call TimerPwmRGB.configure(m_rgFrequencyValues[4], PWM_MODE_FAST);

		// 33% dutycycle on channel A
		//call TimerPwmRGB.start(0, 10, FALSE);
		// 66% dutycycle on channel B
		//call TimerPwmRGB.start(1, 50, TRUE);
		// 66% inverted dutycycle on channel C
		//call TimerPwmRGB.start(2, 90, FALSE);

		//    _        _        _
		// A | |______| |______| |______
		//    ____     ____     ____
		// B |    |___|    |___|    |___
		//          _        _        _
		// C ______| |______| |______| |


		call PinB4.makeInput();
		//call PinB4.set();
		call PinB4.clr();

		call TimerPwmWhite.configure(m_rgFrequencyValues[4], PWM_MODE_FAST);
		//call TimerPwmWhite.start(0, 50, FALSE);
		
		call Leds.led1Toggle();
		call TimerLedLevels.startPeriodic(m_bDutyCycleUpdateDelay);
	}

	event void TimerLedLevels.fired() {
		if(m_bCurrDutyCycle == 0 && !m_fDutyCycleIncrement)
		{
			if(m_bMaxLed == m_bLedNum)
			{
				call TimerPwmWhite.start(0, m_bCurrDutyCycle, m_fInverted);
			}
			else
			{
				call TimerPwmRGB.start(m_bLedNum, m_bCurrDutyCycle, m_fInverted);
			}

			m_bLedNum = (m_bLedNum >= m_bMaxLed ? 0 : m_bLedNum+1);

			m_fDutyCycleIncrement=!m_fDutyCycleIncrement;
		}
		else if(m_bMaxDuctyCycle <= m_bCurrDutyCycle && m_fDutyCycleIncrement)
		{
			m_fDutyCycleIncrement=!m_fDutyCycleIncrement;
		}

		if(m_bMaxLed == m_bLedNum)
		{
			call TimerPwmWhite.start(0, m_bCurrDutyCycle, m_fInverted);
		}
		else
		{
			call TimerPwmRGB.start(m_bLedNum, m_bCurrDutyCycle, m_fInverted);
		}

		if(0 == m_bCurrDutyCycle && m_bMaxLed == m_bLedNum && m_fDutyCycleIncrement)
		{
			++m_bCurrFreqNdx;
			m_bCurrFreqNdx = (m_bCurrFreqNdx >= m_bFreqValNum ? 0 : m_bCurrFreqNdx);
m_bCurrFreqNdx = 4; //Tempoeary work-around for bug when LEDs do not light up for a while after frequency change
			m_fInverted = !m_fInverted;
			call TimerPwmRGB.configure(m_rgFrequencyValues[m_bCurrFreqNdx], PWM_MODE_FAST);

			debug1("F %d, Ndx %d;", m_rgFrequencyValues[m_bCurrFreqNdx], m_bCurrFreqNdx);

			call TimerPwmWhite.configure(m_rgFrequencyValues[m_bCurrFreqNdx], PWM_MODE_FAST);

			call TimerPwmRGB.start(0, m_bCurrDutyCycle, m_fInverted);
			call TimerPwmRGB.start(1, m_bCurrDutyCycle, m_fInverted);
			call TimerPwmRGB.start(2, m_bCurrDutyCycle, m_fInverted);
			call TimerPwmWhite.start(0, m_bCurrDutyCycle, m_fInverted);
		}

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
