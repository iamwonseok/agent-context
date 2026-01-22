# Make-06-02: Declare .PHONY targets - PASS
# Tool: checkmake

.PHONY: all build test clean install uninstall help

TARGET := myapp

all: build

build: ${TARGET}

${TARGET}: main.o utils.o
	${CC} -o $@ $^

test:
	./run_tests.sh

clean:
	${RM} ${TARGET} *.o

install: ${TARGET}
	install -m 755 ${TARGET} /usr/local/bin/

uninstall:
	${RM} /usr/local/bin/${TARGET}

help:
	@echo "Targets: all, build, test, clean, install, uninstall"
