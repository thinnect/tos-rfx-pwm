#ifndef __RFXPWM_H__
#define __RFXPWM_H__

#define COMMON_TIMER_BASE_FREQUENCY (16000000UL)
#define COMMON_ASYNC_TIMER_BASE_FREQUENCY (32768UL) // This frequency should be used, but current frequency constantly stays at 128Hz
#define TIMER_COUNTER_16B_MAX 0xFFFF
#define TIMER_COUNTER_8B_MAX 0xFF
#define TIMER_ASYNC_DO_NOT_DIVIDE_BASE 1
#define MAX_CHANNELS 5

#endif //__RFXPWM_H__