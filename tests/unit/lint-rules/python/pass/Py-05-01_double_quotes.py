"""Py-05-01: Use double quotes for strings - PASS.

Tool: Black
"""


def example():
    """Example with correct quote style."""
    name = "Alice"
    message = "Hello, World!"
    path = "/usr/local/bin"

    # Single quotes when string contains double quotes
    html = '<div class="container">Content</div>'
    sql = 'SELECT * FROM "users"'

    return name, message, path, html, sql
