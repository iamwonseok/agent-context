/* C-02-08: Macro arguments should be parenthesized - FAIL (missing parens) */
/* Tool: clang-tidy (bugprone-macro-parentheses) */

#include <stdio.h>

#define SQUARE(x)      x * x
#define ADD(a, b)      a + b
#define MAX(a, b)      a > b ? a : b
#define DOUBLE(x)      x + x

void example(void)
{
	int a = 3, b = 4;
	int result;

	/* SQUARE(a + 1) expands to: a + 1 * a + 1 = a + a + 1 = 7 (wrong!) */
	result = SQUARE(a + 1);

	/* ADD(a, b) * 2 expands to: a + b * 2 = a + 8 = 11 (wrong!) */
	result = ADD(a, b) * 2;

	printf("Result: %d\n", result);
}
