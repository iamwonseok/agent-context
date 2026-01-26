#include <stdio.h>

void swap_int(int *a, int *b) {
    if (a == NULL || b == NULL) return;
    int temp = *a;
    *a = *b;
    *b = temp;
}

int main() {
    int x = 5, y = 10;
    
    printf("Before: x=%d, y=%d\n", x, y);
    swap_int(&x, &y);
    printf("After:  x=%d, y=%d\n", x, y);
    
    return 0;
}
