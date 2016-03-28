#include "RFXPwm.h"
#include "generalpwm.h"

generic module RFXAsyncTimerPwmP(uint8_t g_channels) {
	

	provides {
		interface GeneralPWM;
	}
	uses {
		interface GeneralIO as Pin[uint8_t pin];
		interface HplAtmegaCounter<uint8_t> as Counter;
		interface HplAtmegaCompare<uint8_t> as Compare[uint8_t pin];
	}
}
implementation {
    #define __MODUUL__ "tests"
    #define __LOG_LEVEL__ ( LOG_LEVEL_tests & BASE_LOG_LEVEL )
    #include "log.h"

	//const uint16_t m_rgwClockDividers[]={1,8,64,256,1024};
	const uint16_t m_rgwClockDividers[]={1,8,32,64,128,256,1024};
	const uint8_t m_rgwClockDividerRegValues[]={1,2,3,4,5,6,7};
	const uint8_t m_bNumClockDividers=(uint8_t)(sizeof(m_rgwClockDividers)/sizeof(uint16_t));

	uint8_t 	m_bClkDivNdx=0xFF;
	//uint16_t 	m_wCntrTop=0;
	//uint16_t	m_wCompare=0;
	const uint8_t 	m_bCntrTop=TIMER_COUNTER_8B_MAX;
	uint8_t		m_bCompare=0;
	uint8_t 	m_bMode=0xFF;

	const uint8_t	m_bTimerMode=0x03;//Fast PWM, TOP = 0xFF, compare - OCR2A
	const uint8_t	m_bTargetMinDutyCycleCnt=100;
	const uint8_t	m_bMaxPrecisionFactorOverhead=2; //means that over (m_bTargetDutyCyclyPrecision*m_bMaxPrecisionFactorOverhead) is too much

	bool ChkCntTopAndCorrectDiv()
	{
		bool fRrecalcNeeded = FALSE;

		if(0xFF != m_bClkDivNdx && 0 != m_bCntrTop &&
			0 < m_bClkDivNdx && m_bCntrTop < (m_bTargetMinDutyCycleCnt*m_bMaxPrecisionFactorOverhead))
		{
			--m_bClkDivNdx;
			fRrecalcNeeded = TRUE;
		}

		return fRrecalcNeeded;
	}

	bool SetClockDivider(uint16_t wFreq)
	{
		bool fRes=FALSE;
		uint8_t i;

		for(i=1;i<=m_bNumClockDividers;++i)
		{
			//debug1("f %d %d", (COMMON_ASYNC_TIMER_BASE_FREQUENCY/m_rgwClockDividers[m_bNumClockDividers-i]), wFreq);
			debug1("%d", (COMMON_ASYNC_TIMER_BASE_FREQUENCY/m_rgwClockDividers[m_bNumClockDividers-i]));
			if((COMMON_ASYNC_TIMER_BASE_FREQUENCY/m_rgwClockDividers[m_bNumClockDividers-i]) >= wFreq)
			//if((COMMON_TIMER_BASE_FREQUENCY/m_rgwClockDividers[m_bNumClockDividers-i]) >= wFreq)
			{
				m_bClkDivNdx=m_bNumClockDividers-i;
				fRes=TRUE;
				break;
			}
		}
		return fRes;
	}
	
	/*
	bool CalcCntrTop(uint16_t wFreq)
	{
		bool fRes=FALSE;

		if(0xFF>m_bClkDivNdx)
		{
			m_bCntrTop = (uint8_t)(COMMON_ASYNC_TIMER_BASE_FREQUENCY/m_rgwClockDividers[m_bClkDivNdx]) / wFreq;
			fRes = (0!=m_bCntrTop);
		}

		return fRes;
	}
	*/

	uint32_t GetActualFreq()
	{
		uint32_t wRet=0;

		if(0xFF>m_bClkDivNdx && 0<m_bCntrTop)
		{
			wRet = (COMMON_ASYNC_TIMER_BASE_FREQUENCY/m_rgwClockDividers[m_bClkDivNdx]) / m_bCntrTop;
		}

		return wRet;
	}

	void SetCounterTop(uint8_t bCntrTop)
	{//Set counter top (falling edge) - fixed at 0xFF, nothing to do
		//call Capture.set(bCntrTop);
		//OCR2A=bCntrTop;
	}

	bool IsOutputOnAnyChannel()
	{
		bool fRet=FALSE;
		uint8_t i;

		for(i=0;i<g_channels;++i)
		{
			if(0 == call Pin.isInput[i]())
			{
				fRet = TRUE;
				break;
			}
			
		}

		return fRet;
	}

	void SetCounterMode(uint8_t mode)
	{
		atomic
		{
			uint8_t new_TCCR2A, new_TCCR2B;
		/*	
			ASSR = (ASSR & ~(0x3 << AS2))
				| ((mode >> 6) & 0x3) << AS2;
				*/

			while( ASSR & (1 << TCR2AUB | 1 << TCR2BUB) )
				;

			new_TCCR2A = (TCCR2A & ~(0x3 << WGM20))
				| ((mode >> 3) & 0x3) << WGM20;

			new_TCCR2B = (TCCR2B & ~(0x1 << WGM22 | 0x7 << CS20))
				| ((mode >> 5) & 0x1) << WGM22
				| ((mode >> 0) & 0x7) << CS20;

			debug1("n %x %x   c %x %x", new_TCCR2A, new_TCCR2B, TCCR2A, TCCR2B);
/*
			TCCR2A = (TCCR2A & ~(0x3 << WGM20))
				| ((mode >> 3) & 0x3) << WGM20;

			TCCR2B = (TCCR2B & ~(0x1 << WGM22 | 0x7 << CS20))
				| ((mode >> 5) & 0x1) << WGM22
				| ((mode >> 0) & 0x7) << CS20;
				*/

			//TCCR2A = 0x83;
			//TCCR2A = new_TCCR2A;
			TCCR2A = (TCCR2A & ~(0x3 << WGM20))
				| ((mode >> 3) & 0x3) << WGM20;

			// Work-around of an unknown defect: do not modify TCCR2B (causes blinking, even if stays at 0) and ASSR (TinyOS app execution freezes)

			//  TCCR2B = 0x07;
			//OCR2A = 0x0c;
		//	OCR2A = (uint8_t)((float)0xFF / ((float)100 / (float)(m_bCurrFreqNdx*12)));
		}

		//call McuPowerState.update(); //Not yet clear if this is necessary
	}

	async command error_t GeneralPWM.configure(uint32_t frequency, uint8_t mode)
	{
		error_t err = FAIL;

		switch(mode)
		{
			case PWM_MODE_FAST:
				m_bMode=mode;
				err = SUCCESS;
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
			do
			{
				//err=(CalcCntrTop(frequency) ? SUCCESS : FAIL);
			} while(ChkCntTopAndCorrectDiv());
		}


		if(SUCCESS != err)
		{
			m_bClkDivNdx=0xFF;
			//m_bCntrTop=0;
			m_bCompare=0;
		}

//debug1("conf-d m_bClkDivNdx %d, m_bCntrTop %d, m_bCompare %d", m_bClkDivNdx, m_bCntrTop, m_bCompare);
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
	{
		error_t ret = (0xFF == m_bMode || 100 < duty_cycle ? FAIL : SUCCESS);

		uint8_t bCmpMode = (TRUE != invert ? 2: 3);
//debug1("s1 %d %d %d", channel, duty_cycle, invert);
		if(0 != duty_cycle)
		{
			m_bCompare = (uint8_t)((float)m_bCntrTop / ((float)100 / (float)duty_cycle));
//			call Counter.setMode((m_bTimerMode << 3) | m_rgwClockDividerRegValues[m_bClkDivNdx]);
			//call Counter.setMode((m_bTimerMode << 3) | m_rgwClockDividerRegValues[m_bClkDivNdx] | (ASSR & (0x3 << AS2)));
//			SetCounterMode((m_bTimerMode << 3) | m_rgwClockDividerRegValues[m_bClkDivNdx]);
//			SetCounterMode((m_bTimerMode << 3) | 1);
	//		SetCounterMode((m_bTimerMode << 3));
			//SetCounterTop(m_bCntrTop); //Counter TOP (fgalling edge)

			if(FAIL != ret && g_channels > channel)
			{
//				debug1("s2");
				call Pin.makeOutput[channel]();
				call Pin.set[channel]();
				call Compare.setMode[channel](bCmpMode);
				call Compare.set[channel](m_bCompare);

				SetCounterMode((m_bTimerMode << 3));
			}
		}
		else
		{
//			debug1("s1-e");
			call Pin.makeInput[channel]();
			call Pin.set[channel]();
			call Compare.setMode[channel](0);
			call Compare.set[channel](0);
		}

		//if(FAIL == ret && 0 == call PinA.isInput() && 0 == call PinB.isInput() && 0 == call PinC.isInput())
		if((0 == duty_cycle || FAIL == ret) && !IsOutputOnAnyChannel())
		{
			debug1("s1-e2");
			//call Counter.setMode(0 | (ASSR & (0x3 << AS2)));
	//		SetCounterMode(0);
			SetCounterTop(0);
		}
//debug1("conf-d m_bClkDivNdx %d, m_bCntrTop %d, m_bCompare %d, ch %d, dc=%d", m_bClkDivNdx, m_bCntrTop, m_bCompare, channel, duty_cycle);
	debug1("s2-r");
		return ret;
	}

	default async command void Pin.set[uint8_t i]() {}
	default async command void Pin.makeInput[uint8_t i]() {}
	default async command void Pin.makeOutput[uint8_t i]() {}
	default async command bool Pin.isInput[uint8_t i]() {return FALSE;}

	default async command void Compare.setMode[uint8_t channel](uint8_t bCmpMode) {}
	default async command void Compare.set[uint8_t channel](uint8_t bCmpMode) {}


    async event void Counter.overflow() { }

    async event void Compare.fired[uint8_t channel]() { }

//    async event void Capture.fired() { }
    

	async command error_t GeneralPWM.stop(uint8_t channel)
	{
		error_t ret = SUCCESS;

		if(channel < g_channels)
		{
			call Pin.makeInput[channel]();
			call Pin.set[channel]();
			call Compare.setMode[channel](0);
		}
		else
		{
			ret = FAIL;
		}

		if(SUCCESS == ret && !IsOutputOnAnyChannel())
		{
			call Counter.setMode(0);
		}
	}
}