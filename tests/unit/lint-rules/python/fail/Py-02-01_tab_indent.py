"""Py-02-01: Space indentation (4 spaces) - FAIL (uses tabs).

Tool: Black, Flake8 (E101, W191)
"""


def example_function():
	"""Example with wrong indentation."""
	value = 0
	if value == 0:
		print("Zero")
		for i in range(10):
			print(i)
