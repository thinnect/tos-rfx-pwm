#include "RFXPwm.h"

generic module RFXPwmP() @safe{
	

	provides {
		interface GeneralPWM;
	}
	uses {
		interface GeneralIO as PinA;
		interface GeneralIO as PinB;
		interface GeneralIO as PinC;
		interface HplAtmegaCounter<uint16_t> as Counter;
		interface HplAtmegaCompare<uint16_t> as Compare[uint8_t channel];
	}
}
implementation {

	// TODO implementation

/*
#define COMMON_TIMER_BASE_FREQUENCY (32768/2)
#define TIMER_COUNTER_16B_MAX 0xFFFF

typedef sTimerProps
{
    uint16_t wDivider;
    uint16_t wTop;
    uint16_t wMatch;

} sTimerProps_t;
*/

	//const sClockDivider_t rgsClockDividers[]={{(uint16_t)1,(uint8_t)1,},{(uint16_t)1,(uint8_t)1,}}
	const uint16_t m_rgwClockDividers[]={1,8,64,256,1024};
	const uint8_t m_bNumClockDividers=(uint8_t)(sizeof(rgwClockDividers)/sizeof(uint16_t));

	uint8_t m_bClkDivNdx=0xFF;
	uint16_t m_wCntrTop=0;

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
				fRes=TRUE
				break;
			}
		}

		//return bRet;
		return fRes;
	}

	bool SetCntrTop(uint16_t wFreq)
	{
		//uint8_t bRet = 0xFF;
		bool fRes=FALSE;
		uint8_t i;

		if(0xFF>m_bClkDivNdx)
		{
			m_wCntrTop = (COMMON_TIMER_BASE_FREQUENCY/m_rgwClockDividers[m_bClkDivNdx]) / wFreq;
			fRes = (0!=m_wCntrTop);
		}

		return fRes;
	}

	uint16_t GetActualFreq()
	{
		uint16_t wRet=0;

		if(0xFF>m_bClkDivNdx && 0<m_wCntrTop)
		{
			wRet = (COMMON_TIMER_BASE_FREQUENCY/m_rgwClockDividers[m_bClkDivNdx]) / m_wCntrTop;
		}

		return wRet;
	}

}