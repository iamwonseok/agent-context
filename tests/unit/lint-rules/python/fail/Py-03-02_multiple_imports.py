"""Py-03-02: One import per line - FAIL (multiple imports).

Tool: isort, Flake8 (E401)
"""

import os, sys, json

import requests, yaml

from mypackage import module1, module2, module3


def use_imports():
    """Use the imported modules."""
    print(os.getcwd())
    print(sys.version)
