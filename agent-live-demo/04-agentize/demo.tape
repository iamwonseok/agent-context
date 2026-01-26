# Step 4: Agentize (ReAct Pattern)
# VHS Configuration

Output "04-agentize.gif"

Set Shell zsh
Set FontSize 14
Set Width 1000
Set Height 750
Set Padding 15
Set Theme "Catppuccin Mocha"
Set FontFamily "JetBrains Mono"
Set TypingSpeed 30ms

# Run the demo - shows ReAct loop with error recovery
Type "python3 demo.py"
Enter

# Wait for the entire ReAct demonstration
# (creates buggy code -> compile error -> fix -> retry -> success)
Sleep 28s

# Press enter to exit
Enter
Sleep 1s
