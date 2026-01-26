#!/usr/bin/env python3
"""
Step 2: Persona (System Prompt)
- Agent has a defined role and behavior rules
- Same question, different style (expert-level output)
"""
import sys
import time
import os

# ANSI Colors
BLUE = "\033[1;34m"
GREEN = "\033[1;32m"
YELLOW = "\033[1;33m"
CYAN = "\033[1;36m"
GRAY = "\033[1;30m"
RESET = "\033[0m"

def typing_effect(text, delay=0.02):
    for char in text:
        sys.stdout.write(char)
        sys.stdout.flush()
        time.sleep(delay)
    print()

def load_persona():
    """Load and display persona from agent.md."""
    agent_file = os.path.join(os.path.dirname(__file__), "agent.md")
    
    print(f"{YELLOW}[System] Loading persona from agent.md...{RESET}")
    time.sleep(0.5)
    
    try:
        with open(agent_file, "r") as f:
            content = f.read()
            print(f"{GRAY}---{RESET}")
            for line in content.split('\n')[:12]:
                print(f"{GRAY}{line}{RESET}")
            print(f"{GRAY}---{RESET}")
    except FileNotFoundError:
        print(f"{YELLOW}[Warning] agent.md not found, using defaults{RESET}")
    
    print()
    print(f"{YELLOW}[System] Persona: Senior Embedded C Developer{RESET}")
    print()

def simulate_persona_response(question):
    """Respond as a Senior C Developer - concise, defensive, production-ready."""
    q = question.lower()
    
    if "swap" in q:
        return '''void swap_int(int *a, int *b) {
    if (a == NULL || b == NULL) return;
    int temp = *a;
    *a = *b;
    *b = temp;
}

// Usage: swap_int(&x, &y);'''
    
    elif "hello" in q or "print" in q:
        return '''puts("Hello, World!");  // More efficient than printf for simple strings'''
    
    elif "array" in q or "reverse" in q:
        return '''void reverse_array(int *arr, size_t len) {
    if (arr == NULL || len < 2) return;
    for (size_t i = 0; i < len / 2; i++) {
        int temp = arr[i];
        arr[i] = arr[len - 1 - i];
        arr[len - 1 - i] = temp;
    }
}'''
    
    else:
        return "// Specify a clear C programming task."

def main():
    print(f"{BLUE}{'=' * 55}{RESET}")
    print(f"{BLUE}  Step 2: Persona (System Prompt){RESET}")
    print(f"{BLUE}  - Role defines behavior and output style{RESET}")
    print(f"{BLUE}{'=' * 55}{RESET}")
    print()
    
    load_persona()
    time.sleep(1)
    
    try:
        while True:
            user_input = input(f"{GREEN}You > {RESET}")
            if not user_input.strip():
                continue
            if user_input.lower() in ['exit', 'quit', 'q']:
                break
            
            print(f"{GRAY}[Generating as Senior C Dev...]{RESET}")
            time.sleep(0.8)
            
            response = simulate_persona_response(user_input)
            print()
            print(f"{CYAN}{response}{RESET}")
            print()
            
    except (KeyboardInterrupt, EOFError):
        pass
    
    print(f"\n{GRAY}Goodbye!{RESET}")

if __name__ == "__main__":
    main()
