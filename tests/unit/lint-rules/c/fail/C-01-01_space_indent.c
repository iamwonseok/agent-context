/* C-01-01: Tab indentation - FAIL (uses spaces) */
/* Tool: clang-format */

#include <stdio.h>

void example_function(void)
{
    int value = 0;
    if (value == 0) {
        printf("Zero\n");
    }
}
