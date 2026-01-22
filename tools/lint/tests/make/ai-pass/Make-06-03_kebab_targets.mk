# Make-06-03: Target names use kebab-case (PASS)
# AI Review: Target names follow convention

CC := gcc

.PHONY: all clean build-debug build-release run-tests install-deps

# Good: Target names in kebab-case
all: build-release

build-debug:
	${CC} -g -O0 -o debug-app main.c

build-release:
	${CC} -O2 -o release-app main.c

run-tests:
	./run-tests.sh

install-deps:
	apt-get install -y libssl-dev

clean:
	${RM} debug-app release-app
