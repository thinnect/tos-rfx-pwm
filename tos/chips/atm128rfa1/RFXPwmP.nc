/*
 * @author MxA.M
 * @license MIT
 */
#include "RFXPwm.h"
#include "generalpwm.h"
generic module RFXPwmP(uint8_t g_channels) {
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

	const uint16_t m_rgwClockDividers[] = {1,8,64,256,1024};
	const uint8_t m_rgwClockDividerRegValues[] = {1,2,3,4,5};
	const uint8_t m_bNumClockDividers = (uint8_t)(sizeof(m_rgwClockDividers)/sizeof(uint16_t));

	norace uint8_t  m_bClkDivNdx = 0xFF;
	norace uint16_t m_wCntrTop = 0;
	norace uint16_t m_wCompare = 0;
	norace uint8_t  m_bMode = 0xFF;

	const uint8_t   m_bTimerMode = 0x0E;//Fast PWM, TOP = ICRn
	const uint8_t   m_bTargetMinDutyCycleCnt = 100;
	const uint8_t   m_bMaxPrecisionFactorOverhead = 2; //means that over (m_bTargetDutyCyclyPrecision*m_bMaxPrecisionFactorOverhead) is too much

	norace bool     m_fIsChannelUsed[MAX_CHANNELS];

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
			//if(0 == call Pin.isInput[i]())
			if(m_fIsChannelUsed[i])
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
		uint8_t b;

		for(b=0;b<(sizeof(m_fIsChannelUsed)/sizeof(bool));++b)
		{
			m_fIsChannelUsed[b] = FALSE;
		}

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
		error_t ret = (0xFF == m_bMode || 100 < duty_cycle || g_channels < channel || MAX_CHANNELS < g_channels ? FAIL : SUCCESS);
		uint8_t bCmpMode;
		bool    fFullDC = ((100 == duty_cycle && !invert) || (0 == duty_cycle && invert));
		uint8_t bDBGWaySet = 0;

		if(SUCCESS == ret)
		{
			if(100 == duty_cycle || 0 == duty_cycle)
			{
				bCmpMode = 0;
			}
			else
			{
				bCmpMode = (TRUE != invert ? 2: 3);
			}

			if(0 != bCmpMode)
			{
				//if(fZeroDC)
				if(FALSE)
				{
					m_wCompare = 0;
				}
				else
				{
					m_wCompare = (uint16_t)((float)m_wCntrTop / ((float)100 / (float)duty_cycle));
				}

				call Counter.setMode((m_bTimerMode << 3) | m_rgwClockDividerRegValues[m_bClkDivNdx]);
				SetCounterTop(m_wCntrTop); //Counter TOP (fgalling edge)

				m_fIsChannelUsed[channel] = TRUE;
				call Pin.set[channel]();
				call Compare.set[channel](m_wCompare);
				bDBGWaySet |= 1;
			}
			else if(fFullDC)
			{
				//call Pin.makeInput[channel]();
				m_fIsChannelUsed[channel] = FALSE;
				call Pin.set[channel]();
				bDBGWaySet |= 2;
			}
			else
			{
				//call Pin.makeInput[channel]();
				m_fIsChannelUsed[channel] = FALSE;
				call Pin.clr[channel]();
				bDBGWaySet |= 4;
			}
			call Pin.makeOutput[channel]();

			call Compare.setMode[channel](bCmpMode);

			//if(!((0 != duty_cycle && !invert) || (100 != duty_cycle && invert)) && !IsOutputOnAnyChannel())
			if(!IsOutputOnAnyChannel())
			{
				call Counter.setMode(0);
				SetCounterTop(0);
				bDBGWaySet |= 8;
			}
		}
		//debug1("conf-d DivNdx %d, Top %d, Cmp %d, ch %d, dc %d, inv %d", m_bClkDivNdx, m_wCntrTop, m_wCompare, channel, duty_cycle, invert);
		debug1("conf-d DivNdx %d, Top %d, Cmp %d, ch %d, dc %d, o/p %d inv %d ws %d T %d", m_bClkDivNdx, m_wCntrTop, m_wCompare, channel, duty_cycle, m_fIsChannelUsed[channel], invert, bDBGWaySet, g_channels);
		return ret;
	}

	default async command void Pin.set[uint8_t i]() {}
	default async command void Pin.clr[uint8_t i]() {}
	default async command void Pin.makeOutput[uint8_t i]() {}

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
			//call Pin.makeInput[channel]();
			m_fIsChannelUsed[channel] = FALSE;
			//call Pin.set[channel]();
			call Pin.clr[channel]();
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
