/* C-01-04: Pointer declarations - one per line (PASS) */
/* AI Review: This follows the rule - pointers declared separately */

#include <stdio.h>

void good_pointer_declarations(void)
{
	/* Good: Each pointer on its own line */
	int *ptr1;
	int *ptr2;
	char *str1;
	char *str2;

	/* Good: Non-pointer basic types can be on same line */
	int a, b, c;
	float x, y;
}
