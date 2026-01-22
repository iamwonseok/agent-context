"""Py-02-01: Space indentation (4 spaces) - PASS.

Tool: Black, Flake8
"""


def example_function():
    """Example with correct indentation."""
    value = 0
    if value == 0:
        print("Zero")
        for i in range(10):
            print(i)
