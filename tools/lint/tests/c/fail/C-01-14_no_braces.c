/* C-01-14: Always use braces for control statements - FAIL (missing braces) */
/* Tool: clang-tidy (readability-braces-around-statements) */

#include <stdio.h>

void example(int value)
{
	if (value > 0)
		printf("Positive\n");

	for (int i = 0; i < 10; i++)
		printf("%d\n", i);

	while (value > 0)
		value--;

	if (value == 0)
		return;
}
