"""Py-11-01: Use with statement for file operations - PASS.

Tool: Flake8 (resource management)
"""

from contextlib import contextmanager


def read_file(path: str) -> str:
    """Read file content using with statement."""
    with open(path, "r", encoding="utf-8") as f:
        return f.read()


def write_file(path: str, content: str) -> None:
    """Write content to file using with statement."""
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)


def copy_file(src: str, dst: str) -> None:
    """Copy file using with statement."""
    with open(src, "rb") as src_file:
        with open(dst, "wb") as dst_file:
            dst_file.write(src_file.read())


def process_multiple_files(input_path: str, output_path: str) -> None:
    """Process multiple files with nested context managers."""
    with (
        open(input_path, "r") as infile,
        open(output_path, "w") as outfile,
    ):
        outfile.write(infile.read().upper())
