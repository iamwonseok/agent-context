#include <stdio.h>
#include <stdlib.h>

int main() {
    int value = 42;
    int *ptr = &value;  // Fixed: point to valid memory
    
    printf("Value: %d\n", *ptr);
    
    return 0;
}