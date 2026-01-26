#include "swap.h"
#include <stddef.h>

void swap_int(int *a, int *b) {
    if (a == NULL || b == NULL) return;
    int temp = *a;
    *a = *b;
    *b = temp;
}

void swap_float(float *a, float *b) {
    if (a == NULL || b == NULL) return;
    float temp = *a;
    *a = *b;
    *b = temp;
}

void swap_ptr(void **a, void **b) {
    if (a == NULL || b == NULL) return;
    void *temp = *a;
    *a = *b;
    *b = temp;
}
