/* C-01-15: No assignment in if condition - PASS */
/* Tool: clang-tidy (bugprone-assignment-in-if-condition) */

#include <stdio.h>
#include <stdlib.h>

void example(void)
{
	char *ptr = malloc(100);

	if (ptr == NULL) {
		return;
	}

	int value = get_value();
	if (value > 0) {
		printf("Positive\n");
	}

	free(ptr);
}

int get_value(void)
{
	return 42;
}
