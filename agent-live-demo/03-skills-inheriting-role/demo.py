#!/usr/bin/env python3
"""
Step 3: Skills (Tools / Function Calling)
- Same persona + can execute actual actions
- Write file, compile, run - not just output code
"""
import sys
import time
import subprocess
import os

# ANSI Colors
BLUE = "\033[1;34m"
GREEN = "\033[1;32m"
YELLOW = "\033[1;33m"
CYAN = "\033[1;36m"
MAGENTA = "\033[1;35m"
GRAY = "\033[1;30m"
RED = "\033[1;31m"
RESET = "\033[0m"

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

def show_system_info():
    """Display persona and available skills."""
    print(f"{YELLOW}[System] Persona: Senior Embedded C Developer | Skills: write_file, compile, run{RESET}")
    print()
    print(f"{GRAY}Available Skills:{RESET}")
    print(f"{GRAY}  - write_file(name, code) : Create a C source file{RESET}")
    print(f"{GRAY}  - compile(file)          : Compile C source with gcc{RESET}")
    print(f"{GRAY}  - run(binary)            : Execute compiled binary{RESET}")
    print()

def skill_write_file(filename, code):
    """Write code to a file."""
    filepath = os.path.join(SCRIPT_DIR, filename)
    
    print(f"{MAGENTA}[Skill: write_file] Creating {filename}...{RESET}")
    time.sleep(0.5)
    
    with open(filepath, "w") as f:
        f.write(code)
    
    print(f"{GRAY}---{RESET}")
    for line in code.split('\n')[:15]:
        print(f"{GRAY}{line}{RESET}")
    if len(code.split('\n')) > 15:
        print(f"{GRAY}... ({len(code.split(chr(10)))} lines total){RESET}")
    print(f"{GRAY}---{RESET}")
    print(f"{GREEN}[Result] {filename} created{RESET}")
    print()
    return True

def skill_compile(filename):
    """Compile a C file."""
    filepath = os.path.join(SCRIPT_DIR, filename)
    output_name = filename.replace('.c', '')
    output = os.path.join(SCRIPT_DIR, output_name)
    
    print(f"{MAGENTA}[Skill: compile] gcc {filename} -o {output_name}{RESET}")
    time.sleep(0.5)
    
    try:
        result = subprocess.run(
            ["gcc", filepath, "-o", output],
            capture_output=True,
            text=True,
            timeout=10
        )
        if result.returncode == 0:
            print(f"{GREEN}[Result] Compilation successful -> ./{output_name}{RESET}")
            print()
            return True
        else:
            print(f"{RED}[Result] Compilation failed:{RESET}")
            print(f"{RED}{result.stderr}{RESET}")
            print()
            return False
    except FileNotFoundError:
        print(f"{RED}[Result] gcc not found{RESET}")
        return False
    except Exception as e:
        print(f"{RED}[Result] Error: {e}{RESET}")
        return False

def skill_run(binary_name):
    """Run a compiled binary."""
    binary = os.path.join(SCRIPT_DIR, binary_name)
    
    print(f"{MAGENTA}[Skill: run] ./{binary_name}{RESET}")
    time.sleep(0.5)
    
    try:
        result = subprocess.run(
            [binary],
            capture_output=True,
            text=True,
            timeout=10
        )
        print(f"{CYAN}[Output]{RESET}")
        print(f"{CYAN}{result.stdout.strip()}{RESET}")
        print()
        return True
    except Exception as e:
        print(f"{RED}[Result] Error: {e}{RESET}")
        return False

def process_swap_request():
    """Handle swap program request with skills."""
    print(f"{GRAY}[Thinking] User wants a swap program.{RESET}")
    print(f"{GRAY}[Thinking] I'll write the code, compile it, and run it.{RESET}")
    print()
    time.sleep(0.8)
    
    # Senior C Dev style code (same as Step 2, but now we execute it)
    swap_code = '''#include <stdio.h>

void swap_int(int *a, int *b) {
    if (a == NULL || b == NULL) return;
    int temp = *a;
    *a = *b;
    *b = temp;
}

int main() {
    int x = 5, y = 10;
    
    printf("Before: x=%d, y=%d\\n", x, y);
    swap_int(&x, &y);
    printf("After:  x=%d, y=%d\\n", x, y);
    
    return 0;
}
'''
    
    # Execute skills
    skill_write_file("swap.c", swap_code)
    time.sleep(0.3)
    
    if skill_compile("swap.c"):
        time.sleep(0.3)
        skill_run("swap")
    
    print(f"{GREEN}Done! Program created and executed successfully.{RESET}")

def process_request(user_input):
    """Process user request and use appropriate skills."""
    q = user_input.lower()
    
    if "swap" in q:
        process_swap_request()
    elif "list" in q or "file" in q:
        print(f"{MAGENTA}[Skill: list_files]{RESET}")
        files = [f for f in os.listdir(SCRIPT_DIR) if f.endswith(('.c', '.py', ''))]
        print(f"{CYAN}[Result] {', '.join(files)}{RESET}")
        print()
    else:
        print(f"{GRAY}I can create and run C programs. Try: 'swap program' or 'list files'{RESET}")
        print()

def main():
    print(f"{BLUE}{'=' * 65}{RESET}")
    print(f"{BLUE}  Step 3: Skills (Tools / Function Calling){RESET}")
    print(f"{BLUE}  - Same persona + can take real actions{RESET}")
    print(f"{BLUE}{'=' * 65}{RESET}")
    print()
    
    show_system_info()
    
    try:
        while True:
            user_input = input(f"{GREEN}You > {RESET}")
            if not user_input.strip():
                continue
            if user_input.lower() in ['exit', 'quit', 'q']:
                break
            
            print()
            process_request(user_input)
            
    except (KeyboardInterrupt, EOFError):
        pass
    
    print(f"\n{GRAY}Goodbye!{RESET}")

if __name__ == "__main__":
    main()
