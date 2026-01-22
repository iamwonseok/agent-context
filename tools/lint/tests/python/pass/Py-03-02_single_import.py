"""Py-03-02: One import per line - PASS.

Tool: isort, Flake8 (E401)
"""

import os
import sys

import requests
import yaml

from mypackage import module1
from mypackage import module2


def use_imports():
    """Use the imported modules."""
    print(os.getcwd())
    print(sys.version)
