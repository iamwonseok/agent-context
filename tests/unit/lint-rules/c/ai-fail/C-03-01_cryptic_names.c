/* C-03-01: Use descriptive names for globals and functions (FAIL) */
/* AI Review: Names are cryptic and unclear */

#include <stdio.h>
#include <stdbool.h>

/* Bad: What does 'cnt' count? What is 'flg'? */
static int cnt = 0;
static bool flg = false;

/* Bad: Function name doesn't describe what it does */
int do_stuff(void)
{
	int x = 0;
	int i;

	for (i = 0; i < 3; i++) {
		cnt++;
	}

	flg = true;
	return x;
}

/* Bad: 'chk' is too abbreviated */
bool chk(void)
{
	return flg;
}

/* Bad: Single letter global function name */
int f(int a, int b)
{
	return a + b;
}
