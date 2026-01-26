# Step 5: Multi-Agent Orchestration - tmux split version
# VHS Configuration

Output "05_squad_split.gif"

Set Shell zsh
Set FontSize 15
Set Width 1000
Set Height 750
Set Padding 10
Set Theme "Catppuccin Mocha"
Set FontFamily "JetBrains Mono"
Set TypingSpeed 40ms

# Create tmux session with horizontal split (top/bottom)
Hide
Type "tmux new-session -d -s swarm -x 120 -y 40"
Enter
Sleep 500ms
Type "tmux split-window -v -t swarm -p 45"
Enter
Sleep 500ms
Type "tmux send-keys -t swarm:0.0 'clear && echo -e \"\\033[1;34m[Agent Communication]\\033[0m\"' C-m"
Enter
Sleep 300ms
Type "tmux send-keys -t swarm:0.1 'clear && echo -e \"\\033[1;33m[Project Files]\\033[0m\" && cd /tmp && rm -rf calc_demo && mkdir calc_demo && cd calc_demo' C-m"
Enter
Sleep 300ms
Type "tmux attach -t swarm"
Enter
Sleep 1s
Show

# === Multi-Agent Demo ===

# User request
Type "echo ''"
Enter
Type "echo 'User: Create a C calculator library project'"
Enter
Sleep 1500ms

# Manager receives
Type "echo -e '\\033[1;34m[Manager]\\033[0m Analyzing request...'"
Enter
Sleep 1000ms
Type "echo -e '\\033[1;34m[Manager]\\033[0m Delegating to: Architect -> Engineer -> Tester'"
Enter
Sleep 1500ms

# Architect starts
Type "echo ''"
Enter
Type "echo -e '\\033[1;36m[Architect]\\033[0m Creating project structure...'"
Enter
Sleep 1000ms

# Show result in bottom pane
Ctrl+b
Type "o"
Sleep 500ms
Type "mkdir -p include src test && touch Makefile && tree ."
Enter
Sleep 1500ms

# Back to top
Ctrl+b
Type "o"
Sleep 500ms
Type "echo -e '\\033[1;36m[Architect]\\033[0m Done: Makefile, include/, src/, test/'"
Enter
Sleep 1000ms

# Engineer starts
Type "echo ''"
Enter
Type "echo -e '\\033[1;32m[Engineer]\\033[0m Implementing calc.h and calc.c...'"
Enter
Sleep 1000ms

# Create files in bottom pane
Ctrl+b
Type "o"
Sleep 500ms
Type "echo '#ifndef CALC_H' > include/calc.h && echo 'int add(int,int);' >> include/calc.h && echo '#endif' >> include/calc.h"
Enter
Sleep 500ms
Type "echo '#include \"calc.h\"' > src/calc.c && echo 'int add(int a,int b){return a+b;}' >> src/calc.c"
Enter
Sleep 500ms
Type "tree ."
Enter
Sleep 1500ms

# Back to top
Ctrl+b
Type "o"
Sleep 500ms
Type "echo -e '\\033[1;32m[Engineer]\\033[0m Done: include/calc.h, src/calc.c'"
Enter
Sleep 1000ms

# Tester starts
Type "echo ''"
Enter
Type "echo -e '\\033[1;33m[Tester]\\033[0m Writing test cases...'"
Enter
Sleep 1000ms

# Create test in bottom pane
Ctrl+b
Type "o"
Sleep 500ms
Type "echo '#include <stdio.h>' > test/test.c && echo '#include \"calc.h\"' >> test/test.c"
Enter
Sleep 300ms
Type "echo 'int main(){printf(\"2+3=%d\\\\n\",add(2,3));return 0;}' >> test/test.c"
Enter
Sleep 500ms
Type "tree ."
Enter
Sleep 1500ms

# Back to top
Ctrl+b
Type "o"
Sleep 500ms
Type "echo -e '\\033[1;33m[Tester]\\033[0m Done: test/test.c'"
Enter
Sleep 1000ms

# Manager summary
Type "echo ''"
Enter
Type "echo -e '\\033[1;34m[Manager]\\033[0m All agents completed. Project ready!'"
Enter
Sleep 2000ms

# Cleanup
Hide
Ctrl+b
Type ":"
Sleep 200ms
Type "kill-session"
Enter
Sleep 500ms
