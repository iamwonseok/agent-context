#!/usr/bin/env python3
"""
Step 4: Agentize (ReAct Pattern)
- Same persona + skills + autonomous problem solving
- Thinks, acts, observes, and iterates on errors
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
WHITE = "\033[1;37m"
RESET = "\033[0m"

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

def show_system_info():
    """Display persona and available skills."""
    print(f"{YELLOW}[System] Persona: Senior Embedded C Developer | Skills: write_file, compile, run, read_file, fix_code{RESET}")
    print()

def thought(text):
    print(f"{YELLOW}[Thought] {text}{RESET}")
    time.sleep(0.8)

def action(text):
    print(f"{MAGENTA}[Action]  {text}{RESET}")
    time.sleep(0.5)

def observe(text):
    print(f"{CYAN}[Observe] {text}{RESET}")
    time.sleep(0.8)

def skill_write_file(filename, code, show_content=True):
    """Write code to a file."""
    filepath = os.path.join(SCRIPT_DIR, filename)
    
    action(f"write_file(\"{filename}\")")
    
    with open(filepath, "w") as f:
        f.write(code)
    
    if show_content:
        print(f"{GRAY}---{RESET}")
        for i, line in enumerate(code.split('\n')[:12], 1):
            print(f"{GRAY}{i:2}| {line}{RESET}")
        if len(code.split('\n')) > 12:
            print(f"{GRAY}   ... ({len(code.split(chr(10)))} lines){RESET}")
        print(f"{GRAY}---{RESET}")
    
    observe(f"{filename} created")
    print()
    return filepath

def skill_read_file(filename):
    """Read a file and return contents."""
    filepath = os.path.join(SCRIPT_DIR, filename)
    
    action(f"read_file(\"{filename}\")")
    
    with open(filepath, "r") as f:
        content = f.read()
    
    print(f"{GRAY}---{RESET}")
    for i, line in enumerate(content.split('\n'), 1):
        print(f"{GRAY}{i:2}| {line}{RESET}")
    print(f"{GRAY}---{RESET}")
    print()
    
    return content

def skill_compile(filename):
    """Compile a C file."""
    filepath = os.path.join(SCRIPT_DIR, filename)
    output_name = filename.replace('.c', '_app')
    output = os.path.join(SCRIPT_DIR, output_name)
    
    action(f"compile(\"{filename}\")")
    print(f"{GRAY}$ gcc {filename} -o {output_name}{RESET}")
    
    try:
        result = subprocess.run(
            ["gcc", filepath, "-o", output],
            capture_output=True,
            text=True,
            timeout=10
        )
        if result.returncode == 0:
            observe(f"Compilation successful -> ./{output_name}")
            print()
            return True, ""
        else:
            error_msg = result.stderr.strip()
            print(f"{RED}{error_msg}{RESET}")
            observe("Compilation FAILED!")
            print()
            return False, error_msg
    except Exception as e:
        observe(f"Error: {e}")
        return False, str(e)

def skill_run(binary_name):
    """Run a compiled binary."""
    binary = os.path.join(SCRIPT_DIR, binary_name)
    
    action(f"run(\"./{binary_name}\")")
    
    try:
        result = subprocess.run(
            [binary],
            capture_output=True,
            text=True,
            timeout=10
        )
        if result.returncode == 0:
            print(f"{CYAN}[Output]{RESET}")
            print(f"{CYAN}{result.stdout.strip()}{RESET}")
            print()
            return True
        else:
            observe(f"Runtime error: {result.stderr}")
            return False
    except Exception as e:
        observe(f"Error: {e}")
        return False

def react_swap_demo():
    """Demonstrate ReAct pattern with swap program - with intentional error."""
    print(f"\n{WHITE}You > swap program{RESET}\n")
    time.sleep(1)
    
    print(f"{BLUE}--- ReAct Loop Start ---{RESET}\n")
    
    # Step 1: Initial attempt with a bug (missing semicolon)
    thought("User wants a swap program. I'll create it with my standard defensive style.")
    
    # Intentionally buggy code (missing semicolon on line 5)
    buggy_code = '''#include <stdio.h>

void swap_int(int *a, int *b) {
    if (a == NULL || b == NULL) return
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
    
    skill_write_file("swap.c", buggy_code)
    
    # Step 2: Compile - will fail
    success, error = skill_compile("swap.c")
    
    if not success:
        # Step 3: Analyze error
        thought("Compilation failed. Let me analyze the error message.")
        time.sleep(0.5)
        thought("Error indicates 'expected ; before int' on line 5.")
        thought("Line 4 has 'return' without semicolon. I need to fix this.")
        print()
        
        # Step 4: Fix the code
        fixed_code = '''#include <stdio.h>

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
        
        action("fix_code(\"swap.c\", line=4, add_semicolon)")
        observe("Added semicolon after 'return' on line 4")
        print()
        
        skill_write_file("swap.c", fixed_code, show_content=False)
        
        # Step 5: Retry compile
        thought("Let me try compiling again.")
        success, _ = skill_compile("swap.c")
    
    # Step 6: Run if successful
    if success:
        thought("Compilation successful. Now let me run it to verify.")
        skill_run("swap_app")
    
    # Summary
    print(f"{BLUE}--- ReAct Loop Complete ---{RESET}\n")
    print(f"{GREEN}[Summary] Created swap program. Fixed syntax error (missing semicolon).{RESET}")
    print(f"{GREEN}          Program now works correctly.{RESET}\n")

def main():
    print(f"{BLUE}{'=' * 65}{RESET}")
    print(f"{BLUE}  Step 4: Agentize (ReAct Pattern){RESET}")
    print(f"{BLUE}  - Autonomous: thinks, acts, observes, iterates{RESET}")
    print(f"{BLUE}{'=' * 65}{RESET}")
    print()
    
    show_system_info()
    
    react_swap_demo()
    
    print(f"{GRAY}Demo complete. Press Enter to exit.{RESET}")
    try:
        input()
    except (KeyboardInterrupt, EOFError):
        pass

if __name__ == "__main__":
    main()
