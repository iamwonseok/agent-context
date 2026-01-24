"""Py-04-03: Constants use UPPER_SNAKE_CASE (PASS)"""

# Good: Constants in UPPER_SNAKE_CASE
MAX_RETRY_COUNT = 3
DEFAULT_TIMEOUT = 30
API_BASE_URL = "https://api.example.com"
BUFFER_SIZE = 4096


def process_request(timeout=DEFAULT_TIMEOUT):
    """Process a request with the given timeout."""
    for i in range(MAX_RETRY_COUNT):
        print(f"Attempt {i + 1} with timeout {timeout}")
