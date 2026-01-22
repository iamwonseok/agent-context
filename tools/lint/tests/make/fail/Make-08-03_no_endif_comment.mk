# Make-08-03: Comment after endif - FAIL (missing comments)
# Tool: manual review

DEBUG ?= 0
PLATFORM ?= linux

ifeq (${DEBUG},1)
CFLAGS += -g -O0 -DDEBUG
else
CFLAGS += -O2 -DNDEBUG
endif

ifeq (${PLATFORM},linux)
LDFLAGS += -lpthread
else ifeq (${PLATFORM},darwin)
LDFLAGS += -framework CoreFoundation
else
$(error Unsupported platform: ${PLATFORM})
endif

ifdef CUSTOM_PATH
INCLUDE_DIRS += ${CUSTOM_PATH}/include
endif

ifndef CC
CC := gcc
endif
