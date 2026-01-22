# Make-06-03: Target names use kebab-case (FAIL)
# AI Review: Target names don't follow convention

CC := gcc

.PHONY: all clean buildDebug buildRelease runTests installDeps

# Bad: Target names in camelCase or PascalCase
all: buildRelease

buildDebug:
	${CC} -g -O0 -o debug-app main.c

buildRelease:
	${CC} -O2 -o release-app main.c

runTests:
	./run-tests.sh

InstallDeps:
	apt-get install -y libssl-dev

clean:
	${RM} debug-app release-app
