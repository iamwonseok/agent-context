# Make-04-02: Variable names use UPPER_SNAKE_CASE (PASS)
# AI Review: Variable names follow convention

# Good: Variables in UPPER_SNAKE_CASE
CC           := gcc
CFLAGS       := -Wall -Werror
LDFLAGS      := -lpthread
SRC_DIR      := src
BUILD_DIR    := build
TARGET       := myapp

SOURCES      := $(wildcard ${SRC_DIR}/*.c)
OBJECTS      := $(SOURCES:.c=.o)

.PHONY: all clean

all: ${TARGET}

${TARGET}: ${OBJECTS}
	${CC} ${LDFLAGS} -o $@ $^

clean:
	${RM} ${OBJECTS} ${TARGET}
