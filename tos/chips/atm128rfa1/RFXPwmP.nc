#include "RFXPwm.h"
#include "generalpwm.h"

generic module RFXPwmP(uint8_t g_channels, bool fSetInputOnZeroDutyCycle) {
	 

	provides {
		interface GeneralPWM;
	}
	uses {
		interface GeneralIO as Pin[uint8_t pin];
		interface HplAtmegaCounter<uint16_t> as Counter;
		interface HplAtmegaCompare<uint16_t> as Compare[uint8_t pin];
		interface HplAtmegaCapture<uint16_t> as Capture;
	}
}
implementation {
    #define __MODUUL__ "tests"
    #define __LOG_LEVEL__ ( LOG_LEVEL_tests & BASE_LOG_LEVEL )
    #include "log.h"

	const uint16_t m_rgwClockDividers[]={1,8,64,256,1024};
	const uint8_t m_rgwClockDividerRegValues[]={1,2,3,4,5};
	const uint8_t m_bNumClockDividers=(uint8_t)(sizeof(m_rgwClockDividers)/sizeof(uint16_t));

	uint8_t 	m_bClkDivNdx=0xFF;
	uint16_t 	m_wCntrTop=0;
	uint16_t	m_wCompare=0;
	uint8_t 	m_bMode=0xFF;

	const uint8_t	m_bTimerMode=0x0E;//Fast PWM, TOP = ICRn
	const uint8_t	m_bTargetMinDutyCycleCnt=100;
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

	bool SetClockDivider(uint16_t wFreq)
	{
		bool fRes=FALSE;
		uint8_t i;

		for(i=1;i<=m_bNumClockDividers;++i)
		{
			if((COMMON_TIMER_BASE_FREQUENCY/m_rgwClockDividers[m_bNumClockDividers-i]) >= wFreq)
			{
				m_bClkDivNdx=m_bNumClockDividers-i;
				fRes=TRUE;
				break;
			}
		}
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
	{//Set counter top (falling edge)
		call Capture.set(wCntrTop);
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
			do
			{
				err=(CalcCntrTop(frequency) ? SUCCESS : FAIL);
			} while(ChkCntTopAndCorrectDiv() && FAIL != err);
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
	{
		error_t ret = (0xFF == m_bMode || 100 < duty_cycle ? FAIL : SUCCESS);
		uint8_t bCmpMode = (TRUE != invert ? 2: 3);
		bool	fZeroDC = !((0 != duty_cycle && !invert) || (100 != duty_cycle && invert));
//uint8_t bWaySet = 0;

		if(!fZeroDC || !fSetInputOnZeroDutyCycle)
		{
			if(fZeroDC)
			{
				m_wCompare = 0;
			}
			else
			{
				m_wCompare = (uint16_t)((float)m_wCntrTop / ((float)100 / (float)duty_cycle));
			}
			
			call Counter.setMode((m_bTimerMode << 3) | m_rgwClockDividerRegValues[m_bClkDivNdx]);
			SetCounterTop(m_wCntrTop); //Counter TOP (fgalling edge)

			if(FAIL != ret && g_channels > channel)
			{
				call Pin.makeOutput[channel]();
				call Pin.set[channel]();
				call Compare.setMode[channel](bCmpMode);
				call Compare.set[channel](m_wCompare);
//bWaySet |= 1;
			}
		}
		else if(g_channels > channel)
		{
			call Pin.makeInput[channel]();
			call Pin.set[channel]();
			call Compare.setMode[channel](0);
			call Compare.set[channel](0);
//bWaySet |= 2;
		}
		

		if(!((0 != duty_cycle && !invert) || (100 != duty_cycle && invert)) && !IsOutputOnAnyChannel())
		{
			call Counter.setMode(0);
			SetCounterTop(0);
//bWaySet |= 4;
		}
//debug1("conf-d DivNdx %d, Top %d, Cmp %d, ch %d, dc %d, inv %d", m_bClkDivNdx, m_wCntrTop, m_wCompare, channel, duty_cycle, invert);
//debug1("conf-d DivNdx %d, Top %d, Cmp %d, ch %d, dc %d, inv %d ws %d T %d", m_bClkDivNdx, m_wCntrTop, m_wCompare, channel, duty_cycle, invert, bWaySet, g_channels);
		return ret;
	}

	default async command void Pin.set[uint8_t i]() {}
	default async command void Pin.makeInput[uint8_t i]() {}
	default async command void Pin.makeOutput[uint8_t i]() {}
	default async command bool Pin.isInput[uint8_t i]() {return FALSE;}

	default async command void Compare.setMode[uint8_t channel](uint8_t bCmpMode) {}
	default async command void Compare.set[uint8_t channel](uint16_t bCmpMode) {}


	async event void Counter.overflow() { }

	async event void Compare.fired[uint8_t channel]() { }

	async event void Capture.fired() { }


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