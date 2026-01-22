/* C-01-18: Pointer * on variable side - PASS */
/* Tool: clang-format */

#include <stdio.h>

void example(void)
{
	int *ptr;
	char *str;
	void *data;
	int **double_ptr;

	const char *const_str;
	volatile int *volatile_ptr;
}

int *get_pointer(void)
{
	static int value = 42;
	return &value;
}

void process(const char *input, char **output)
{
	*output = (char *)input;
}
