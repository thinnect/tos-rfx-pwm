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
//		interface HplAtmegaCompare<uint16_t> as Compare;

		interface HplAtmegaCompare<uint16_t> as CompareChA;
		interface HplAtmegaCompare<uint16_t> as CompareChB;
		interface HplAtmegaCompare<uint16_t> as CompareChC;

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
	const uint8_t	m_bTargetMinDutyCycleCnt=10;
	const uint8_t	m_bMaxPrecisionFactorOverhead=2; //means that over (m_bTargetDutyCyclyPrecision*m_bMaxPrecisionFactorOverhead) is too much

	bool ChkCntTopAndCorrectDiv()
	{
		bool fRrecalcNeeded = FALSE;

		if(0xFF != m_bClkDivNdx && 0 != m_wCntrTop &&
			0 < m_bClkDivNdx && m_wCntrTop < (m_bTargetMinDutyCycleCnt*m_bMaxPrecisionFactorOverhead))
		{
			--m_bClkDivNdx;
			fRrecalcNeeded = TRUE;
		}

		return fRrecalcNeeded;
	}

	/*
	//uint8_t GetClockDivider(uint16_t wFreq)
	bool SetClockDivider(uint16_t wFreq)
	{
		//uint8_t bRet = 0xFF;
		bool fRes=FALSE;
		uint8_t i;

		for(i=1;i<=m_bNumClockDividers;++i)
		{
			if((COMMON_TIMER_BASE_FREQUENCY/m_rgwClockDividers[m_bNumClockDividers-i]) >= wFreq)
			{
				//bRet=i;
				//m_bClkDivNdx=i;
				m_bClkDivNdx=m_bNumClockDividers-i;
				fRes=TRUE;
				break;
			}
//debug1("%d %d", (COMMON_TIMER_BASE_FREQUENCY/m_rgwClockDividers[m_bNumClockDividers-i]), m_bNumClockDividers-i);
		}
debug1("%d %d %x", (COMMON_TIMER_BASE_FREQUENCY/m_rgwClockDividers[m_bNumClockDividers-i]), m_bNumClockDividers-i, fRes);
		//return bRet;
		return fRes;
	}
	*/
	bool SetClockDivider(uint16_t wFreq)
	{
		//uint8_t bRet = 0xFF;
		bool fRes=FALSE;
		uint8_t i;

		for(i=0;i<m_bNumClockDividers;++i)
		{
			if((COMMON_TIMER_BASE_FREQUENCY/m_rgwClockDividers[i]) >= wFreq)
			//if((COMMON_TIMER_BASE_FREQUENCY/m_rgwClockDividers[m_bNumClockDividers-i]) >= wFreq)
			{
				//bRet=i;
				m_bClkDivNdx=i;
				//m_bClkDivNdx=m_bNumClockDividers-i;
				fRes=TRUE;
				break;
			}
		}

		//return bRet;
		return fRes;
	}

	bool CalcCntrTop(uint16_t wFreq)
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
/*
		if(0xFF != m_bMode && SetClockDivider(frequency))
		{
			err=(CalcCntrTop(frequency) ? SUCCESS : FAIL);
		}

	uint8_t 	m_bClkDivNdx=0xFF;
	uint16_t 	m_wCntrTop=0;
*/		
//ChkCntTopAndCorrectDiv

		if(0xFF != m_bMode && SetClockDivider(frequency))
		{
			err=(CalcCntrTop(frequency) ? SUCCESS : FAIL);
		}
/*
		if(0xFF != m_bMode && SetClockDivider(frequency))
		{
			do
			{
				err=(CalcCntrTop(frequency) ? SUCCESS : FAIL);
			} while(ChkCntTopAndCorrectDiv());
		}
*/

		if(SUCCESS != err)
		{
			m_bClkDivNdx=0xFF;
			m_wCntrTop=0;
			m_wCompare=0;
		}

//debug1("conf-d m_bClkDivNdx %d, m_wCntrTop %d, m_wCompare %d", m_bClkDivNdx, m_wCntrTop, m_wCompare);
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

/*
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
			uint8_t bCmpMode = (TRUE != invert ? 2: 3);
			m_wCompare = m_wCntrTop / (100 / duty_cycle);
			call Counter.setMode((m_bTimerMode << 3) | m_rgwClockDividers[m_bClkDivNdx]);
			call Compare.setMode(bCmpMode);
//debug1("1 DDRE %x, TIMSK3 %x, OCR3A %x, OCR3C %x, TCCR3A %x, TCCR3B %x, ICR3 %x; tm %x cd %x", DDRE, TIMSK3, OCR3A, OCR3C, TCCR3A, TCCR3B, ICR3, m_bTimerMode, m_bClkDivNdx);

			SetCounterTop(m_wCntrTop); //Counter TOP (fgalling edge)
			call Compare.set(m_wCompare); //OCnA/OCnB/OCnC??? TODO - check

//debug1("2 DDRE %x, TIMSK3 %x, OCR3A %x, OCR3C %x, TCCR3A %x, TCCR3B %x, ICR3 %x", DDRE, TIMSK3, OCR3A, OCR3C, TCCR3A, TCCR3B, ICR3);			
//debug1("DDRE %x, TIMSK3 %x, OCR3A %x, OCR3C %x, TCCR3A %x, TCCR3B %x, ICR3 %x; tm %x cd %x", DDRE, TIMSK3, OCR3A, OCR3C, TCCR3A, TCCR3B, ICR3, m_bTimerMode, m_bClkDivNdx);
debug1("conf-d m_bClkDivNdx %d, m_wCntrTop %d, m_wCompare %d", m_bClkDivNdx, m_wCntrTop, m_wCompare);
		}

		return ret;
	}
*/	

	async command error_t GeneralPWM.start(uint8_t channel, uint8_t duty_cycle, bool invert)
	{//TODO: Check - is channel for channel (A/B/C) or timer number selection? Implement as A/B/C until resolved.
		error_t ret = (0xFF == m_bMode || 100 < duty_cycle ? FAIL : SUCCESS);

		uint8_t bCmpMode = (TRUE != invert ? 2: 3);
		m_wCompare = (uint16_t)((float)m_wCntrTop / ((float)100 / (float)duty_cycle));
		call Counter.setMode((m_bTimerMode << 3) | m_rgwClockDividers[m_bClkDivNdx]);
		SetCounterTop(m_wCntrTop); //Counter TOP (fgalling edge)

		if(FAIL != ret)
		{
			if(0x00 == channel)
			{
				call PinA.makeOutput();
				call PinA.set();
				call CompareChA.setMode(bCmpMode);
				call CompareChA.set(m_wCompare);

			}
			else if(0x01 == channel)
			{
				call PinB.makeOutput();
				call PinB.set();
				call CompareChB.setMode(bCmpMode);
				call CompareChB.set(m_wCompare);
			}
			else if(0x02 == channel)
			{
				call PinC.makeOutput();
				call PinC.set();
				call CompareChC.setMode(bCmpMode);
				call CompareChC.set(m_wCompare);
			}
			else
			{
				ret = FAIL;
			}
		}

		if(FAIL == ret && 0 == call PinA.isInput() && 0 == call PinB.isInput() && 0 == call PinC.isInput())
		{
			call Counter.setMode(0);
			SetCounterTop(0);
		}
debug1("conf-d m_bClkDivNdx %d, m_wCntrTop %d, m_wCompare %d, ch %d", m_bClkDivNdx, m_wCntrTop, m_wCompare, channel);
		return ret;
	}


    async event void Counter.overflow() { }

//    async event void Compare.fired() { }


    async event void CompareChA.fired() { }
    async event void CompareChB.fired() { }
    async event void CompareChC.fired() { }
    

    
	async command error_t GeneralPWM.stop(uint8_t channel)
	{
		error_t ret = SUCCESS;

		if(0x00 == channel)
		{
			call PinA.makeInput();
			call PinA.set();
			call CompareChA.setMode(0);
		}
		else if(0x01 == channel)
		{
			call PinB.makeInput();
			call PinB.set();
			call CompareChB.setMode(0);
		}
		else if(0x02 == channel)
		{
			call PinC.makeInput();
			call PinC.set();
			call CompareChC.setMode(0);
		}
		else
		{
			ret = FAIL;
		}
		

		if(SUCCESS == ret && 0 == call PinA.isInput() && 0 == call PinB.isInput() && 0 == call PinC.isInput())
		{
			//call Compare.setMode(0);
			call Counter.setMode(0);
		}
	}
	


	/*
	async command error_t GeneralPWM.stop(uint8_t channel)
	{
		error_t ret = SUCCESS;

		if(0x00 == channel)
		{
			call PinA.makeInput();
			call PinA.set();
		}
		else if(0x01 == channel)
		{
			call PinB.makeInput();
			call PinB.set();
		}
		else if(0x02 == channel)
		{
			call PinC.makeInput();
			call PinC.set();
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
	*/


}