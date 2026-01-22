"""Py-03-03: Import order - stdlib, third-party, local - PASS.

Tool: isort
"""

# Standard library
import os
import sys
from pathlib import Path

# Third-party
import numpy as np
import requests

# Local
from mypackage import utils
from mypackage.submodule import helper


def main():
    """Main function."""
    print(os.getcwd())
    print(sys.version)
