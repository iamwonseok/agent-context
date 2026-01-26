CC = gcc
CFLAGS = -Wall -Wextra -Iinclude

all: libswap.a test_swap

libswap.a: src/swap.o
	ar rcs $@ $^

src/swap.o: src/swap.c include/swap.h
	$(CC) $(CFLAGS) -c $< -o $@

test_swap: test/test_swap.c libswap.a
	$(CC) $(CFLAGS) -o $@ $^

test: test_swap
	./test_swap

clean:
	rm -f libswap.a test_swap src/*.o
