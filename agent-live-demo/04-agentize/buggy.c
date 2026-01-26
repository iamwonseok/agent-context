#include <stdio.h>
#include <stdlib.h>

int main() {
    int *ptr = NULL;
    
    // Bug: dereferencing null pointer
    printf("Value: %d\n", *ptr);
    
    return 0;
}
