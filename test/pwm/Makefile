COMPONENT=PWMTestC

$(info --------------------------------------------------------------------------------)
ifndef WORKSPACE_ROOT
    $(error Please define WORKSPACE_ROOT)
endif

$(info WORKSPACE_ROOT      $(WORKSPACE_ROOT))
$(info --------------------------------------------------------------------------------)
TOSH_DATA_LENGTH=114
PFLAGS += -DTOSH_DATA_LENGTH=$(TOSH_DATA_LENGTH)
$(info TOSH_DATA_LENGTH=$(TOSH_DATA_LENGTH))
$(info --------------------------------------------------------------------------------)

# Avoid strange TinyOS issues
PFLAGS += -DTASKLET_IS_TASK

PFLAGS += -I$(PWD)

BASE_LOG_LEVEL ?= 0xFFFF
PLATFORM_BAUDRATE ?= 115200UL

# Radio conf
RADIO_CHANNEL ?= 25

STACK_BEAT ?= 1
ifneq ($(STACK_BEAT),0)
    $(info STACK_BEAT=1)
    PFLAGS += -DBEAT_RADIO_LED
    PFLAGS += -DBEAT_ACTIVE_LED
    PFLAGS += -DBEAT_NOBEAT_LED

    include $(WORKSPACE_ROOT)/thinnect.tos-busy/tos/busy.mk
    include $(WORKSPACE_ROOT)/thinnect.tos-psend/tos/psend.mk
    include $(WORKSPACE_ROOT)/thinnect.tos-collections/tos/collections.mk
    include $(WORKSPACE_ROOT)/thinnect.beatstack/beatstack.mk
endif


#PFLAGS += -D__AVR_ATmega256RFR2__
CFLAGS += -I/usr/avr/include
#CFLAGS += -I/usr/avr/include/avr
CFLAGS += -I$(WORKSPACE_ROOT)/tos-rfx-pwm/tos/lib

$(info --------------------------------------------------------------------------------)
include $(TINYOS_ROOT_DIR)/Makefile.include
$(call TOSMake_include,extras/groundlib.extra)
$(info --------------------------------------------------------------------------------)
