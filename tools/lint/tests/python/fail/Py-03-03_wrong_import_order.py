"""Py-03-03: Import order - stdlib, third-party, local - FAIL.

Tool: isort
"""

from mypackage import utils
import requests
import os
from pathlib import Path
import numpy as np
import sys
from mypackage.submodule import helper


def main():
    """Main function."""
    print(os.getcwd())
    print(sys.version)
