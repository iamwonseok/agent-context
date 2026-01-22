/* C-04-01: Functions should do one thing only (PASS) */
/* AI Review: Each function has a single, clear responsibility */

#include <stdio.h>
#include <string.h>
#include <stdbool.h>

#define MAX_NAME_LEN 64

/* Single responsibility: validate name length */
bool is_valid_name_length(const char *name)
{
	if (name == NULL) {
		return false;
	}
	return strlen(name) <= MAX_NAME_LEN;
}

/* Single responsibility: check for invalid characters */
bool has_valid_characters(const char *name)
{
	const char *p = name;

	while (*p != '\0') {
		if (*p < 'A' || *p > 'z') {
			return false;
		}
		p++;
	}
	return true;
}

/* Single responsibility: combine validations */
bool validate_name(const char *name)
{
	if (!is_valid_name_length(name)) {
		return false;
	}
	if (!has_valid_characters(name)) {
		return false;
	}
	return true;
}
