/* C-01-25: Use English for all code and comments (FAIL) */
/* AI Review: Contains non-English (Korean) text */

#include <stdio.h>

/* 카운터 초기화 */
static int counter = 0;

/**
 * 카운터 증가 함수
 * @return 새로운 카운터 값
 */
int increment_counter(void)
{
	/* 카운터에 1을 더함 */
	counter++;
	return counter;
}

/* 카운터를 초기 상태로 리셋 */
void reset_counter(void)
{
	counter = 0;
}
