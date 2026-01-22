/* C-01-11: Function brace on new line - PASS */
/* Tool: clang-format */

#include <stdio.h>

void first_function(void)
{
	printf("First\n");
}

int second_function(int value)
{
	return value * 2;
}

static void static_function(void)
{
	printf("Static\n");
}
