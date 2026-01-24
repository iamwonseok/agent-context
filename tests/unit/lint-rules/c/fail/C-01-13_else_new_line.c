/* C-01-13: } else { on same line - FAIL (else on new line) */
/* Tool: clang-format */

#include <stdio.h>

void example(int value)
{
	if (value > 0) {
		printf("Positive\n");
	}
	else if (value < 0) {
		printf("Negative\n");
	}
	else {
		printf("Zero\n");
	}
}
