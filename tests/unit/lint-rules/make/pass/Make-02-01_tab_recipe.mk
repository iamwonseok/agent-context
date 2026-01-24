# Make-02-01: Recipe indentation with tabs - PASS
# Tool: make (syntax requirement)

.PHONY: all build clean

all: build

build:
	echo "Building..."
	gcc -o main main.c
	echo "Done"

clean:
	rm -f main
	rm -f *.o
