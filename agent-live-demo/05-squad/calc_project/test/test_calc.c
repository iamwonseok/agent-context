#include <stdio.h>
#include "calc.h"

int main() {
    int passed = 0, failed = 0;
    
    // Test add
    if (calc_add(2, 3) == 5) { passed++; printf("[PASS] add\n"); }
    else { failed++; printf("[FAIL] add\n"); }
    
    // Test sub
    if (calc_sub(5, 3) == 2) { passed++; printf("[PASS] sub\n"); }
    else { failed++; printf("[FAIL] sub\n"); }
    
    // Test mul
    if (calc_mul(4, 3) == 12) { passed++; printf("[PASS] mul\n"); }
    else { failed++; printf("[FAIL] mul\n"); }
    
    // Test div
    if (calc_div(10, 2) == 5) { passed++; printf("[PASS] div\n"); }
    else { failed++; printf("[FAIL] div\n"); }
    
    printf("\nResults: %d passed, %d failed\n", passed, failed);
    return failed;
}
