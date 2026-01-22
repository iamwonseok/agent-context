"""Py-11-01: Use with statement for file operations - FAIL.

Tool: Flake8 (resource management)
"""


def read_file(path):
    """Read file content without with statement."""
    f = open(path, "r")
    content = f.read()
    f.close()
    return content


def write_file(path, content):
    """Write content to file without with statement."""
    f = open(path, "w")
    f.write(content)
    f.close()


def copy_file(src, dst):
    """Copy file without with statement."""
    src_file = open(src, "rb")
    dst_file = open(dst, "wb")
    dst_file.write(src_file.read())
    src_file.close()
    dst_file.close()
