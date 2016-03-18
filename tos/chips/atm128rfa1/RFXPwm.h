#ifndef __RFXPWM_H__
#define __RFXPWM_H__

#define COMMON_TIMER_BASE_FREQUENCY (32768/2)
#define TIMER_COUNTER_16B_MAX 0xFFFF

/*
typedef sClockDivider
{
	uint16_t	wDivider;
	uint8_t		bRegValue;
} sClockDivider_t;
*/

typedef sTimerProps
{
    uint8_t		wDividerNdx;
    uint16_t	wTop;
    uint16_t	wMatch;

} sTimerProps_t;

#endif //__RFXPWM_H__