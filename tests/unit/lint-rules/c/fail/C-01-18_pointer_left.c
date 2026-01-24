/* C-01-18: Pointer * on variable side - FAIL (* on type side) */
/* Tool: clang-format */

#include <stdio.h>

void example(void)
{
	int* ptr;
	char* str;
	void* data;
	int** double_ptr;

	const char* const_str;
}

int* get_pointer(void)
{
	static int value = 42;
	return &value;
}
