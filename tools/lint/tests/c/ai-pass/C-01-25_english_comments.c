/* C-01-25: Use English for all code and comments (PASS) */
/* AI Review: All text is in English */

#include <stdio.h>

/* Initialize the counter value */
static int counter = 0;

/**
 * Increment the global counter
 * @return The new counter value
 */
int increment_counter(void)
{
	/* Add one to the counter */
	counter++;
	return counter;
}

/* Reset counter to initial state */
void reset_counter(void)
{
	counter = 0;
}
