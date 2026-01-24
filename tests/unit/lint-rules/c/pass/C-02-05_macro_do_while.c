/* C-02-05: Multi-statement macro with do-while(0) - PASS */
/* Tool: clang-tidy (bugprone-macro-parentheses) */

#include <stdio.h>

#define LOG_AND_RETURN(msg, val) \
	do { \
		printf("%s\n", msg); \
		return val; \
	} while (0)

#define SAFE_FREE(ptr) \
	do { \
		if (ptr) { \
			free(ptr); \
			ptr = NULL; \
		} \
	} while (0)

#define INCREMENT_AND_CHECK(x, limit) \
	do { \
		(x)++; \
		if ((x) > (limit)) { \
			(x) = (limit); \
		} \
	} while (0)

int example(int *ptr)
{
	if (ptr == NULL) {
		LOG_AND_RETURN("Null pointer", -1);
	}
	return 0;
}
