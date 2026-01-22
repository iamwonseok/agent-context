/* C-04-01: Functions should do one thing only (FAIL) */
/* AI Review: Function does too many unrelated things */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#define MAX_NAME_LEN 64

/* Bad: This function does validation, logging, database, and notification */
int process_user_registration(const char *name, const char *email, int age)
{
	FILE *log_file;
	char query[256];
	int result = 0;

	/* Validation */
	if (name == NULL || strlen(name) > MAX_NAME_LEN) {
		return -1;
	}
	if (email == NULL || strchr(email, '@') == NULL) {
		return -2;
	}
	if (age < 0 || age > 150) {
		return -3;
	}

	/* Logging */
	log_file = fopen("/var/log/app.log", "a");
	if (log_file != NULL) {
		fprintf(log_file, "New user: %s\n", name);
		fclose(log_file);
	}

	/* Database operation */
	snprintf(query, sizeof(query), 
		"INSERT INTO users VALUES ('%s', '%s', %d)", name, email, age);
	/* execute_query(query); */

	/* Send notification */
	printf("Welcome email sent to %s\n", email);

	/* Update statistics */
	/* increment_user_count(); */

	return result;
}
