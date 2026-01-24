# Make-08-03: Comment after endif - PASS
# Tool: manual review

.PHONY: all

DEBUG ?= 0
PLATFORM ?= linux

ifeq (${DEBUG},1)
CFLAGS += -g -O0 -DDEBUG
else
CFLAGS += -O2 -DNDEBUG
endif # DEBUG

ifeq (${PLATFORM},linux)
LDFLAGS += -lpthread
else ifeq (${PLATFORM},darwin)
LDFLAGS += -framework CoreFoundation
else
$(error Unsupported platform: ${PLATFORM})
endif # PLATFORM

ifdef CUSTOM_PATH
INCLUDE_DIRS += ${CUSTOM_PATH}/include
endif # CUSTOM_PATH

ifndef CC
CC := gcc
endif # !CC
