#!/usr/bin/env python3
"""
Step 1: The Brain (Raw LLM)
- No persona, no tools, just learned knowledge
- Input -> LLM -> Output (explanation only)
"""
import sys
import time

# ANSI Colors
BLUE = "\033[1;34m"
GREEN = "\033[1;32m"
GRAY = "\033[1;30m"
CYAN = "\033[1;36m"
RESET = "\033[0m"

def typing_effect(text, delay=0.02):
    """Simulate typing effect for output."""
    for char in text:
        sys.stdout.write(char)
        sys.stdout.flush()
        time.sleep(delay)
    print()

def simulate_llm_response(question):
    """Simulate LLM response based on keywords."""
    q = question.lower()
    
    if "swap" in q:
        return '''To swap two numbers in C, you can use a temporary variable.

Here's an example:

#include <stdio.h>

int main() {
    int a = 5, b = 10;
    int temp;
    
    printf("Before: a=%d, b=%d\\n", a, b);
    
    temp = a;
    a = b;
    b = temp;
    
    printf("After: a=%d, b=%d\\n", a, b);
    
    return 0;
}

To compile this code, save it as swap.c and run:
  gcc swap.c -o swap

Then execute it with:
  ./swap

The output will show the values before and after swapping.'''
    
    elif "hello" in q or "print" in q:
        return '''To print "Hello, World!" in C:

#include <stdio.h>

int main() {
    printf("Hello, World!\\n");
    return 0;
}

The printf function outputs text to the console.'''
    
    elif "memory" in q or "malloc" in q:
        return '''Dynamic memory allocation in C uses malloc():

int *ptr = (int*)malloc(sizeof(int) * 10);
if (ptr == NULL) {
    // Handle allocation failure
}
// Use the memory...
free(ptr);  // Don't forget to free!'''
    
    else:
        return "I can answer questions about C programming based on my training data."

def main():
    print(f"{BLUE}{'=' * 55}{RESET}")
    print(f"{BLUE}  Step 1: The Brain (Raw LLM){RESET}")
    print(f"{BLUE}  - No persona, no tools, just trained knowledge{RESET}")
    print(f"{BLUE}{'=' * 55}{RESET}")
    print()
    
    try:
        while True:
            user_input = input(f"{GREEN}You > {RESET}")
            if not user_input.strip():
                continue
            if user_input.lower() in ['exit', 'quit', 'q']:
                break
            
            print(f"{GRAY}[Generating response...]{RESET}")
            time.sleep(1.0)
            
            response = simulate_llm_response(user_input)
            print()
            print(f"{CYAN}{response}{RESET}")
            print()
            
    except (KeyboardInterrupt, EOFError):
        pass
    
    print(f"\n{GRAY}Goodbye!{RESET}")

if __name__ == "__main__":
    main()
