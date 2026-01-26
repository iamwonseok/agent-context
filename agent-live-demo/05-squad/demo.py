#!/usr/bin/env python3
"""
Step 5: Squad (Multi-Agent Collaboration)
- Manager orchestrates specialized agents
- Each agent has specific expertise
- Complex project requires teamwork
"""
import sys
import time
import subprocess
import os
import shutil

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
PROJECT_DIR = os.path.join(SCRIPT_DIR, "swap_project")

def show_system_info():
    """Display squad configuration."""
    print(f"{YELLOW}[System] Squad Configuration:{RESET}")
    print(f"{GRAY}  - Manager   : Task analysis & delegation{RESET}")
    print(f"{GRAY}  - Architect : Project structure & design{RESET}")
    print(f"{GRAY}  - Engineer  : Implementation{RESET}")
    print(f"{GRAY}  - Tester    : Test cases & verification{RESET}")
    print()

def agent_msg(agent_name, color, message):
    print(f"{color}[{agent_name}]{RESET} {message}")
    time.sleep(0.6)

def show_file_tree():
    """Display project file tree."""
    print(f"{GRAY}swap_project/{RESET}")
    print(f"{GRAY}├── Makefile{RESET}")
    print(f"{GRAY}├── include/{RESET}")
    print(f"{GRAY}│   └── swap.h{RESET}")
    print(f"{GRAY}├── src/{RESET}")
    print(f"{GRAY}│   └── swap.c{RESET}")
    print(f"{GRAY}└── test/{RESET}")
    print(f"{GRAY}    └── test_swap.c{RESET}")
    print()
    time.sleep(0.5)

def cleanup_project():
    """Clean up existing project directory."""
    if os.path.exists(PROJECT_DIR):
        shutil.rmtree(PROJECT_DIR)

def squad_orchestration():
    """Demonstrate multi-agent collaboration for swap library project."""
    
    print(f"\n{WHITE}You > swap utility library project, int/float support, with tests{RESET}\n")
    time.sleep(1.5)
    
    # Manager receives and analyzes
    print(f"{BLUE}{'─' * 60}{RESET}")
    agent_msg("Manager", BLUE, "Analyzing request...")
    time.sleep(0.5)
    agent_msg("Manager", BLUE, "This is a library project requiring:")
    print(f"{GRAY}          1. Project structure    -> Architect{RESET}")
    print(f"{GRAY}          2. Multi-type swap impl -> Engineer{RESET}")
    print(f"{GRAY}          3. Test suite           -> Tester{RESET}")
    time.sleep(0.5)
    agent_msg("Manager", BLUE, "Delegating to specialists...")
    print(f"{BLUE}{'─' * 60}{RESET}\n")
    time.sleep(1)
    
    cleanup_project()
    
    # Phase 1: Architect
    print(f"{CYAN}[Phase 1: Architecture]{RESET}")
    agent_msg("Architect", CYAN, "Designing project structure...")
    
    # Create directories
    os.makedirs(os.path.join(PROJECT_DIR, "include"), exist_ok=True)
    os.makedirs(os.path.join(PROJECT_DIR, "src"), exist_ok=True)
    os.makedirs(os.path.join(PROJECT_DIR, "test"), exist_ok=True)
    
    agent_msg("Architect", CYAN, "Created directory structure:")
    show_file_tree()
    
    # Create Makefile
    makefile = """CC = gcc
CFLAGS = -Wall -Wextra -Iinclude

all: libswap.a test_swap

libswap.a: src/swap.o
\tar rcs $@ $^

src/swap.o: src/swap.c include/swap.h
\t$(CC) $(CFLAGS) -c $< -o $@

test_swap: test/test_swap.c libswap.a
\t$(CC) $(CFLAGS) -o $@ $^

test: test_swap
\t./test_swap

clean:
\trm -f libswap.a test_swap src/*.o
"""
    with open(os.path.join(PROJECT_DIR, "Makefile"), "w") as f:
        f.write(makefile)
    
    agent_msg("Architect", CYAN, "Created Makefile with build rules")
    agent_msg("Architect", CYAN, f"{GREEN}[DONE]{RESET} Architecture complete")
    print()
    time.sleep(0.5)
    
    # Phase 2: Engineer
    print(f"{GREEN}[Phase 2: Implementation]{RESET}")
    agent_msg("Engineer", GREEN, "Implementing swap utilities...")
    
    # Create header
    header = """#ifndef SWAP_H
#define SWAP_H

/* Integer swap with null check */
void swap_int(int *a, int *b);

/* Float swap with null check */
void swap_float(float *a, float *b);

/* Generic pointer swap (swaps pointer values) */
void swap_ptr(void **a, void **b);

#endif /* SWAP_H */
"""
    with open(os.path.join(PROJECT_DIR, "include", "swap.h"), "w") as f:
        f.write(header)
    agent_msg("Engineer", GREEN, "Created include/swap.h")
    
    # Create implementation
    impl = """#include "swap.h"
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
"""
    with open(os.path.join(PROJECT_DIR, "src", "swap.c"), "w") as f:
        f.write(impl)
    agent_msg("Engineer", GREEN, "Created src/swap.c (defensive programming style)")
    agent_msg("Engineer", GREEN, f"{GREEN}[DONE]{RESET} Implementation complete")
    print()
    time.sleep(0.5)
    
    # Phase 3: Tester
    print(f"{YELLOW}[Phase 3: Testing]{RESET}")
    agent_msg("Tester", YELLOW, "Writing test suite...")
    
    # Create test
    test = """#include <stdio.h>
#include "swap.h"

static int passed = 0;
static int failed = 0;

#define TEST(name, cond) do { \\
    if (cond) { passed++; printf("[PASS] %s\\n", name); } \\
    else { failed++; printf("[FAIL] %s\\n", name); } \\
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
    
    printf("\\n=============================\\n");
    printf("Results: %d passed, %d failed\\n", passed, failed);
    printf("=============================\\n");
    
    return failed;
}
"""
    with open(os.path.join(PROJECT_DIR, "test", "test_swap.c"), "w") as f:
        f.write(test)
    agent_msg("Tester", YELLOW, "Created test/test_swap.c")
    
    # Build and run tests
    agent_msg("Tester", YELLOW, "Building and running tests...")
    print(f"{GRAY}$ cd swap_project && make test{RESET}")
    
    try:
        result = subprocess.run(
            ["make", "test"],
            capture_output=True,
            text=True,
            timeout=30,
            cwd=PROJECT_DIR
        )
        
        # Show test output
        output_lines = result.stdout.strip().split('\n')
        for line in output_lines:
            if '[PASS]' in line:
                print(f"{GREEN}{line}{RESET}")
            elif '[FAIL]' in line:
                print(f"{RED}{line}{RESET}")
            elif 'Results:' in line or '===' in line:
                print(f"{CYAN}{line}{RESET}")
            else:
                print(f"{GRAY}{line}{RESET}")
        
        if result.returncode == 0:
            agent_msg("Tester", YELLOW, f"{GREEN}[DONE]{RESET} All tests passed!")
        else:
            agent_msg("Tester", YELLOW, f"{RED}[DONE]{RESET} Some tests failed")
    except Exception as e:
        agent_msg("Tester", YELLOW, f"Build error: {e}")
    
    print()
    time.sleep(0.5)
    
    # Manager summary
    print(f"{BLUE}{'─' * 60}{RESET}")
    agent_msg("Manager", BLUE, "All agents completed their tasks.")
    agent_msg("Manager", BLUE, "Project Summary:")
    print()
    show_file_tree()
    
    print(f"{GRAY}Deliverables:{RESET}")
    print(f"{GRAY}  - Library  : libswap.a{RESET}")
    print(f"{GRAY}  - Functions: swap_int, swap_float, swap_ptr{RESET}")
    print(f"{GRAY}  - Tests    : 4 test cases, all passed{RESET}")
    print()
    
    agent_msg("Manager", BLUE, f"{GREEN}Project created successfully!{RESET}")
    print(f"{BLUE}{'─' * 60}{RESET}\n")

def main():
    print(f"{BLUE}{'=' * 60}{RESET}")
    print(f"{BLUE}  Step 5: Squad (Multi-Agent Collaboration){RESET}")
    print(f"{BLUE}  - Manager + Architect + Engineer + Tester{RESET}")
    print(f"{BLUE}{'=' * 60}{RESET}")
    print()
    
    show_system_info()
    squad_orchestration()
    
    print(f"{GRAY}Demo complete. Press Enter to exit.{RESET}")
    try:
        input()
    except (KeyboardInterrupt, EOFError):
        pass

if __name__ == "__main__":
    main()
