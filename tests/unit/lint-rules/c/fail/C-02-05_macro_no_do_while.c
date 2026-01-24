/* C-02-05: Multi-statement macro with do-while(0) - FAIL (no wrapper) */
/* Tool: clang-tidy (bugprone-macro-parentheses) */

#include <stdio.h>

#define LOG_AND_RETURN(msg, val) \
	printf("%s\n", msg); \
	return val;

#define SAFE_FREE(ptr) \
	if (ptr) { \
		free(ptr); \
		ptr = NULL; \
	}

int example(int *ptr)
{
	if (ptr == NULL)
		LOG_AND_RETURN("Null pointer", -1);

	return 0;
}
