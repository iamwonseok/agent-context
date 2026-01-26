CC = gcc
CFLAGS = -Wall -Iinclude

all: libcalc.a test_calc

libcalc.a: src/calc.o
	ar rcs $@ $^

test_calc: test/test_calc.c libcalc.a
	$(CC) $(CFLAGS) -o $@ $^

clean:
	rm -f *.a *.o test_calc src/*.o
