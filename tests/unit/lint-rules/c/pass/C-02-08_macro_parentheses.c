/* C-02-08: Macro arguments should be parenthesized - PASS */
/* Tool: clang-tidy (bugprone-macro-parentheses) */

#include <stdio.h>

#define SQUARE(x)      ((x) * (x))
#define ADD(a, b)      ((a) + (b))
#define MAX(a, b)      (((a) > (b)) ? (a) : (b))
#define MIN(a, b)      (((a) < (b)) ? (a) : (b))
#define ABS(x)         (((x) < 0) ? -(x) : (x))
#define CLAMP(x, lo, hi) (((x) < (lo)) ? (lo) : (((x) > (hi)) ? (hi) : (x)))

void example(void)
{
	int a = 3, b = 4;
	int result;

	result = SQUARE(a + 1);
	result = ADD(a, b);
	result = MAX(a, b);
	result = MIN(a * 2, b);
	result = ABS(a - b);
	result = CLAMP(a, 0, 10);

	printf("Result: %d\n", result);
}
