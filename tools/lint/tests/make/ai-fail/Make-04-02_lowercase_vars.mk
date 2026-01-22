# Make-04-02: Variable names use UPPER_SNAKE_CASE (FAIL)
# AI Review: Variable names don't follow convention

# Bad: Variables in lowercase or camelCase
cc           := gcc
cFlags       := -Wall -Werror
ldflags      := -lpthread
srcDir       := src
build_dir    := build
target       := myapp

sources      := $(wildcard ${srcDir}/*.c)
objects      := $(sources:.c=.o)

.PHONY: all clean

all: ${target}

${target}: ${objects}
	${cc} ${ldflags} -o $@ $^

clean:
	${RM} ${objects} ${target}
