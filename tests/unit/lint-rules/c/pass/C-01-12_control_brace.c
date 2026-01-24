/* C-01-12: Control statement brace on same line - PASS */
/* Tool: clang-format */

#include <stdio.h>

void example(int value)
{
	if (value > 0) {
		printf("Positive\n");
	}

	for (int i = 0; i < 10; i++) {
		printf("%d\n", i);
	}

	while (value > 0) {
		value--;
	}
}
