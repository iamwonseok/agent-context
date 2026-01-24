# Make-02-01: Recipe indentation with tabs - FAIL (uses spaces)
# Tool: make (syntax error)

.PHONY: all build clean

all: build

build:
    echo "Building..."
    gcc -o main main.c
    echo "Done"

clean:
    rm -f main
    rm -f *.o
