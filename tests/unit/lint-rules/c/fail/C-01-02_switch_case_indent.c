/* C-01-02: Switch case at same indent level - FAIL (indented case) */
/* Tool: clang-format */

#include <stdio.h>

void process_command(int cmd)
{
	switch (cmd) {
		case 1:
			printf("Command 1\n");
			break;
		case 2:
			printf("Command 2\n");
			break;
		default:
			printf("Unknown\n");
			break;
	}
}
