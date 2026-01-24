/* C-03-04: Use snake_case for identifiers - PASS */
/* Tool: clang-tidy (readability-identifier-naming) */

#include <stdio.h>
#include <stdint.h>

#define MAX_BUFFER_SIZE 1024
#define ERROR_CODE_INVALID -1

typedef struct {
	int item_count;
	char *item_name;
} item_info_t;

static int global_counter = 0;

int calculate_checksum(const uint8_t *data, size_t data_length)
{
	int check_sum = 0;
	for (size_t i = 0; i < data_length; i++) {
		check_sum += data[i];
	}
	return check_sum;
}

void process_user_input(const char *user_input)
{
	int input_length = strlen(user_input);
	char *processed_string = malloc(input_length + 1);

	if (processed_string != NULL) {
		strcpy(processed_string, user_input);
		free(processed_string);
	}
}
