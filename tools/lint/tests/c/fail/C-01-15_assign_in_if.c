/* C-01-15: No assignment in if condition - FAIL (assignment in if) */
/* Tool: clang-tidy (bugprone-assignment-in-if-condition) */

#include <stdio.h>
#include <stdlib.h>

void example(void)
{
	char *ptr;

	if ((ptr = malloc(100)) == NULL) {
		return;
	}

	int value;
	if ((value = get_value()) > 0) {
		printf("Positive\n");
	}

	free(ptr);
}

int get_value(void)
{
	return 42;
}
