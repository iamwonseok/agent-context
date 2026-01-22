/* C-01-04: Pointer declarations - one per line (FAIL) */
/* AI Review: This violates the rule - multiple pointers on same line */

#include <stdio.h>

void bad_pointer_declarations(void)
{
	/* Bad: Multiple pointers on same line */
	int *ptr1, *ptr2, *ptr3;
	char *str1, *str2;

	/* This is also problematic */
	void *data1, *data2;
}
