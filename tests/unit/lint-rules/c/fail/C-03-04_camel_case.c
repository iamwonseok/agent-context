/* C-03-04: Use snake_case for identifiers - FAIL (uses camelCase) */
/* Tool: clang-tidy (readability-identifier-naming) */

#include <stdio.h>
#include <stdint.h>

#define maxBufferSize 1024
#define errorCodeInvalid -1

typedef struct {
	int itemCount;
	char *itemName;
} ItemInfo;

static int globalCounter = 0;

int calculateChecksum(const uint8_t *dataBuffer, size_t dataLength)
{
	int checkSum = 0;
	for (size_t idx = 0; idx < dataLength; idx++) {
		checkSum += dataBuffer[idx];
	}
	return checkSum;
}

void processUserInput(const char *userInput)
{
	int inputLength = strlen(userInput);
	char *processedString = malloc(inputLength + 1);

	if (processedString != NULL) {
		strcpy(processedString, userInput);
		free(processedString);
	}
}
