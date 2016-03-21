#include "RFXPwm.h"
#include "generalpwm.h"

generic module RFXPwmP() {
	

	provides {
		interface GeneralPWM;
	}
	uses {
		interface GeneralIO as PinA;
		interface GeneralIO as PinB;
		interface GeneralIO as PinC;
		interface HplAtmegaCounter<uint16_t> as Counter;
		interface HplAtmegaCompare<uint16_t> as Compare;
	}
}
implementation {
    #define __MODUUL__ "tests"
    #define __LOG_LEVEL__ ( LOG_LEVEL_tests & BASE_LOG_LEVEL )
    #include "log.h"

	const uint16_t m_rgwClockDividers[]={1,8,64,256,1024};
	const uint8_t m_bNumClockDividers=(uint8_t)(sizeof(m_rgwClockDividers)/sizeof(uint16_t));

	uint8_t 	m_bClkDivNdx=0xFF;
	uint16_t 	m_wCntrTop=0;
	uint16_t	m_wCompare=0;
	uint8_t 	m_bMode=0xFF;

	const uint8_t	m_bTimerMode=0x0E;//Fast PWM, TOP = ICRn

	//uint8_t GetClockDivider(uint16_t wFreq)
	bool SetClockDivider(uint16_t wFreq)
	{
		//uint8_t bRet = 0xFF;
		bool fRes=FALSE;
		uint8_t i;

		for(i=0;i<m_bNumClockDividers;++i)
		{
			if((COMMON_TIMER_BASE_FREQUENCY/m_rgwClockDividers[i]) >= wFreq)
			{
				//bRet=i;
				m_bClkDivNdx=i;
				fRes=TRUE;
				break;
			}
		}

		//return bRet;
		return fRes;
	}

	bool SetCntrTop(uint16_t wFreq)
	{
		bool fRes=FALSE;

		if(0xFF>m_bClkDivNdx)
		{
			m_wCntrTop = (COMMON_TIMER_BASE_FREQUENCY/m_rgwClockDividers[m_bClkDivNdx]) / wFreq;
			fRes = (0!=m_wCntrTop);
		}

		return fRes;
	}

	uint32_t GetActualFreq()
	{
		uint32_t wRet=0;

		if(0xFF>m_bClkDivNdx && 0<m_wCntrTop)
		{
			wRet = (COMMON_TIMER_BASE_FREQUENCY/m_rgwClockDividers[m_bClkDivNdx]) / m_wCntrTop;
		}

		return wRet;
	}

	void SetCounterTop(uint16_t wCntrTop)
	{//Place-holder for setting counter top (falling edge)
		//assign a value to reg ICRn or OCRnA depending on working mode
		//Currently hard-coded for Timer/Counter 3

		ICR3 = wCntrTop;//ICRn acts for all channels of a timer (mode 14),
		//OCRnA can be used to set counter top per each channel inviditually (mode 15)
	}


	async command error_t GeneralPWM.configure(uint32_t frequency, uint8_t mode)
	{
		error_t err = FAIL;

		switch(mode)
		{
			case PWM_MODE_FAST:
				m_bMode=mode;
				break;
			case PWM_MODE_NORMAL:
			case PWM_MODE_FAST_8:
			case PWM_MODE_FAST_9:
			case PWM_MODE_FAST_10:
			default:
				m_bMode=0xFF;
				break;
		}

		if(0xFF != m_bMode && SetClockDivider(frequency))
		{
			err=(SetCntrTop(frequency) ? SUCCESS : FAIL);
		}

		if(SUCCESS != err)
		{
			m_bClkDivNdx=0xFF;
			m_wCntrTop=0;
			m_wCompare=0;
		}

		return err;
	}

	async command uint32_t GeneralPWM.getFrequency()
	{
		return GetActualFreq();
	}

	async command uint8_t GeneralPWM.getMode()
	{
		return m_bMode;
	}

	async command error_t GeneralPWM.start(uint8_t channel, uint8_t duty_cycle, bool invert)
	{//TODO: Check - is channel for channel (A/B/C) or timer number selection? Implement as A/B/C until resolved.
		error_t ret = (0xFF == m_bMode || 100 < duty_cycle ? FAIL : SUCCESS);

		if(FAIL != ret)
		{
			if(0x00 == channel)
			{
				call PinA.makeOutput();
				call PinA.set();
			}
			else if(0x01 == channel)
			{
				call PinB.makeOutput();
				call PinB.set();
			}
			else if(0x02 == channel)
			{
				call PinC.makeOutput();
				call PinC.set();
			}
			else
			{
				ret = FAIL;
			}
		}

		if(FAIL != ret)
		{
			uint8_t bCmpMode = (TRUE == invert ? 2: 3);
			m_wCompare = m_wCntrTop / (100 / duty_cycle);
			call Counter.setMode((m_bTimerMode << 3) | m_rgwClockDividers[m_bClkDivNdx]);
			call Compare.setMode(bCmpMode);
debug1("1 DDRE %x, TIMSK3 %x, OCR3A %x, OCR3C %x, TCCR3A %x, TCCR3B %x, ICR3 %x; tm %x cd %x", DDRE, TIMSK3, OCR3A, OCR3C, TCCR3A, TCCR3B, ICR3, m_bTimerMode, m_bClkDivNdx);

			SetCounterTop(m_wCntrTop); //Counter TOP (fgalling edge)
			call Compare.set(m_wCompare); //OCnA/OCnB/OCnC??? TODO - check

debug1("2 DDRE %x, TIMSK3 %x, OCR3A %x, OCR3C %x, TCCR3A %x, TCCR3B %x, ICR3 %x", DDRE, TIMSK3, OCR3A, OCR3C, TCCR3A, TCCR3B, ICR3);			
		}

		return ret;
	}


    async event void Counter.overflow() { }

    async event void Compare.fired() { }

	async command error_t GeneralPWM.stop(uint8_t channel)
	{
		error_t ret = SUCCESS;

		if(0x00 == channel)
		{
			call PinA.makeInput();
			call PinA.set();
			call Compare.setMode(0);
		}
		else if(0x01 == channel)
		{
			call PinB.makeInput();
			call PinB.set();
			call Compare.setMode(0);
		}
		else if(0x02 == channel)
		{
			call PinC.makeInput();
			call PinC.set();
			call Compare.setMode(0);
		}
		else
		{
			ret = FAIL;
		}
		

		if(SUCCESS == ret && 0 == call PinA.isInput() && 0 == call PinB.isInput() && 0 == call PinC.isInput())
		{
			call Compare.setMode(0);
			call Counter.setMode(0);
		}
	}


}