"""Py-04-03: Constants use UPPER_SNAKE_CASE (FAIL)"""

# Bad: Constants in lowercase or camelCase
maxRetryCount = 3
default_timeout = 30
apiBaseUrl = "https://api.example.com"
bufferSize = 4096


def process_request(timeout=default_timeout):
    """Process a request with the given timeout."""
    for i in range(maxRetryCount):
        print(f"Attempt {i + 1} with timeout {timeout}")
