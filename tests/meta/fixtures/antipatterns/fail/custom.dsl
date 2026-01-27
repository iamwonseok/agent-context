# Custom DSL file (anti-pattern)
# Should use standard YAML or Markdown instead

DEFINE skill parse-requirement
  INPUT: requirement text
  OUTPUT: structured data
  STEPS:
    1. read input
    2. parse
    3. validate
END
