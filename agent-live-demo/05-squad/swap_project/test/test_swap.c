#include <stdio.h>
#include "swap.h"

static int passed = 0;
static int failed = 0;

#define TEST(name, cond) do { \
    if (cond) { passed++; printf("[PASS] %s\n", name); } \
    else { failed++; printf("[FAIL] %s\n", name); } \
} while(0)

int main() {
    /* Test swap_int */
    int a = 5, b = 10;
    swap_int(&a, &b);
    TEST("swap_int basic", a == 10 && b == 5);
    
    /* Test swap_int null safety */
    swap_int(NULL, &b);  /* Should not crash */
    TEST("swap_int null safe", 1);
    
    /* Test swap_float */
    float x = 1.5f, y = 2.5f;
    swap_float(&x, &y);
    TEST("swap_float basic", x == 2.5f && y == 1.5f);
    
    /* Test swap_ptr */
    int v1 = 100, v2 = 200;
    void *p1 = &v1, *p2 = &v2;
    swap_ptr(&p1, &p2);
    TEST("swap_ptr basic", *(int*)p1 == 200 && *(int*)p2 == 100);
    
    printf("\n=============================\n");
    printf("Results: %d passed, %d failed\n", passed, failed);
    printf("=============================\n");
    
    return failed;
}
