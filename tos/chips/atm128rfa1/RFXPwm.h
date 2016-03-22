#ifndef __RFXPWM_H__
#define __RFXPWM_H__

//#define COMMON_TIMER_BASE_FREQUENCY (32768U/2)
//#define COMMON_TIMER_BASE_FREQUENCY (16000000UL/2)
#define COMMON_TIMER_BASE_FREQUENCY (16000000UL)
#define TIMER_COUNTER_16B_MAX 0xFFFF

/*
typedef struct sClockDivider
{
	uint16_t	wDivider;
	uint8_t		bRegValue;
} sClockDivider_t;
*/
/*
typedef struct sTimerProps
{
    uint8_t		wDividerNdx;
    uint16_t	wTop;
    uint16_t	wMatch;

} sTimerProps_t;
*/
#endif //__RFXPWM_H__