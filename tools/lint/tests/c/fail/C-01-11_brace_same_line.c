/* C-01-11: Function brace on new line - FAIL (brace on same line) */
/* Tool: clang-format */

#include <stdio.h>

void first_function(void) {
	printf("First\n");
}

int second_function(int value) {
	return value * 2;
}
