# Step 4: Reasoning (ReAct) - tmux split version
# VHS Configuration

Output "04_agent_split.gif"

Set Shell zsh
Set FontSize 16
Set Width 1000
Set Height 700
Set Padding 10
Set Theme "Catppuccin Mocha"
Set FontFamily "JetBrains Mono"
Set TypingSpeed 40ms

# Create tmux session with horizontal split (top/bottom)
Hide
Type "tmux new-session -d -s react -x 120 -y 35"
Enter
Sleep 500ms
Type "tmux split-window -v -t react -p 40"
Enter
Sleep 500ms
Type "tmux select-pane -t react:0.0"
Enter
Sleep 300ms
Type "tmux send-keys -t react:0.0 'clear && echo -e \"\\033[1;34m[Agent Brain - ReAct Loop]\\033[0m\"' C-m"
Enter
Sleep 300ms
Type "tmux send-keys -t react:0.1 'clear && echo -e \"\\033[1;33m[Execution Result]\\033[0m\"' C-m"
Enter
Sleep 300ms
Type "tmux attach -t react"
Enter
Sleep 1s
Show

# === ReAct Loop Demo ===

# Step 1: User request (top pane)
Type "echo ''"
Enter
Sleep 300ms
Type "echo 'User: The program crashes. Debug it.'"
Enter
Sleep 1500ms

# Thought 1
Type "echo -e '\\033[1;33m[Thought]\\033[0m User reports crash. Let me compile and run to reproduce.'"
Enter
Sleep 1500ms

# Action 1
Type "echo -e '\\033[1;35m[Action]\\033[0m gcc -g buggy.c -o buggy_app && ./buggy_app'"
Enter
Sleep 1000ms

# Execute in bottom pane
Ctrl+b
Type "o"
Sleep 500ms
Type "cd /Users/wonseok/project-iamwonseok/agent-context/agent-live-demo/4_reasoning && gcc -g buggy.c -o buggy_app 2>&1; ./buggy_app 2>&1 || echo '[Segmentation fault]'"
Enter
Sleep 2000ms

# Back to top pane
Ctrl+b
Type "o"
Sleep 500ms

# Observation 1
Type "echo -e '\\033[1;36m[Observe]\\033[0m Program crashed with segmentation fault!'"
Enter
Sleep 1500ms

# Thought 2
Type "echo -e '\\033[1;33m[Thought]\\033[0m Segfault = null pointer. Let me check the code.'"
Enter
Sleep 1500ms

# Action 2
Type "echo -e '\\033[1;35m[Action]\\033[0m cat buggy.c'"
Enter
Sleep 1000ms

# Execute in bottom pane
Ctrl+b
Type "o"
Sleep 500ms
Type "cat buggy.c"
Enter
Sleep 2000ms

# Back to top pane
Ctrl+b
Type "o"
Sleep 500ms

# Observation 2
Type "echo -e '\\033[1;36m[Observe]\\033[0m Line 8: *ptr dereference, but ptr is NULL!'"
Enter
Sleep 1500ms

# Thought 3
Type "echo -e '\\033[1;33m[Thought]\\033[0m Need to initialize pointer to valid memory.'"
Enter
Sleep 1000ms

# Final summary
Type "echo ''"
Enter
Type "echo -e '\\033[1;32m[Complete]\\033[0m Bug found: null pointer at line 8. Fix: initialize ptr.'"
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
