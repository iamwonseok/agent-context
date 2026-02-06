#!/usr/bin/env python3
"""
Mock API Server for Agent-Context Layer 2 Testing.

Simulates Jira and Confluence REST APIs for integration testing without
real network dependencies.

Usage:
    python mock_server.py [--port PORT] [--fixtures-dir DIR]

Environment:
    MOCK_PORT: Server port (default: 8899)
    FIXTURES_DIR: Directory with JSON fixtures (default: ./fixtures)
"""

from __future__ import annotations

import json
import logging
import os
import sys
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path
from typing import Any
from urllib.parse import parse_qs, urlparse

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="[%(levelname)s] %(asctime)s - %(message)s",
    datefmt="%H:%M:%S",
)
log = logging.getLogger("mock-server")

# Default configuration
DEFAULT_PORT = 8899
FIXTURES_DIR = Path(os.environ.get("FIXTURES_DIR", Path(__file__).parent / "fixtures"))


class MockAPIHandler(BaseHTTPRequestHandler):
    """Handler for mock Jira/Confluence API requests."""

    def log_message(self, fmt: str, *args: Any) -> None:
        """Override to use our logger."""
        log.info("%s - %s", self.address_string(), fmt % args)

    def send_json(
        self, data: dict[str, Any] | list[dict[str, Any]], status: int = 200
    ) -> None:
        """Send JSON response."""
        body = json.dumps(data, indent=2).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def send_error_json(self, status: int, message: str) -> None:
        """Send error response in API format."""
        self.send_json({"errorMessages": [message], "errors": {}}, status=status)

    def _load_fixture(self, name: str) -> dict[str, Any] | None:
        """Load fixture JSON file."""
        fixture_path = FIXTURES_DIR / f"{name}.json"
        if fixture_path.exists():
            with open(fixture_path, encoding="utf-8") as f:
                data: dict[str, Any] = json.load(f)
                return data
        return None

    def _check_auth(self) -> bool:
        """Check for valid authentication header."""
        auth = self.headers.get("Authorization", "")
        # Accept any Bearer or Basic token for testing
        if auth.startswith("Bearer ") or auth.startswith("Basic "):
            return True
        return False

    def do_GET(self) -> None:  # noqa: N802 - HTTP method name
        """Handle GET requests."""
        parsed = urlparse(self.path)
        path = parsed.path
        query = parse_qs(parsed.query)

        log.info("GET %s", path)

        # Health check (no auth required)
        if path == "/health":
            self.send_json({"status": "ok", "service": "mock-api"})
            return

        # All other endpoints require auth
        if not self._check_auth():
            self.send_error_json(401, "Unauthorized - missing or invalid token")
            return

        # Route to appropriate handler
        if path.startswith("/rest/api/2/") or path.startswith("/rest/api/3/"):
            self._handle_jira(path, query)
        elif path.startswith("/wiki/rest/api/"):
            self._handle_confluence(path, query)
        else:
            self.send_error_json(404, f"Unknown endpoint: {path}")

    def _handle_jira(  # noqa: C901 - acceptable complexity for mock router
        self, path: str, query: dict[str, list[str]]
    ) -> None:
        """Handle Jira API endpoints."""
        # Remove API version prefix
        if "/rest/api/2/" in path:
            endpoint = path.split("/rest/api/2/")[1]
        elif "/rest/api/3/" in path:
            endpoint = path.split("/rest/api/3/")[1]
        else:
            endpoint = path

        # GET /rest/api/2/myself - Current user
        if endpoint == "myself":
            fixture = self._load_fixture("jira/myself")
            if fixture:
                self.send_json(fixture)
            else:
                self.send_json(
                    {
                        "accountId": "mock-user-123",
                        "displayName": "Mock User",
                        "emailAddress": "mock@example.com",
                        "active": True,
                    }
                )
            return

        # GET /rest/api/2/serverInfo - Server information
        if endpoint == "serverInfo":
            fixture = self._load_fixture("jira/serverInfo")
            if fixture:
                self.send_json(fixture)
            else:
                self.send_json(
                    {
                        "baseUrl": "https://mock.atlassian.net",
                        "version": "1001.0.0",
                        "buildNumber": 100000,
                        "serverTitle": "Mock Jira",
                    }
                )
            return

        # GET /rest/api/2/issue/PROJ-123 - Get issue
        if endpoint.startswith("issue/"):
            issue_key = endpoint.split("issue/")[1].split("?")[0]
            fixture = self._load_fixture(f"jira/issue_{issue_key}")
            if fixture:
                self.send_json(fixture)
            else:
                # Generate mock issue
                self.send_json(
                    {
                        "key": issue_key,
                        "id": "12345",
                        "fields": {
                            "summary": f"Mock issue {issue_key}",
                            "description": "This is a mock issue for testing",
                            "status": {"name": "Open"},
                            "issuetype": {"name": "Task"},
                            "project": {"key": issue_key.split("-")[0]},
                        },
                    }
                )
            return

        # GET /rest/api/2/search - Search issues (JQL)
        if endpoint == "search":
            jql = query.get("jql", [""])[0]
            max_results = int(query.get("maxResults", ["50"])[0])
            fixture = self._load_fixture("jira/search")
            if fixture:
                self.send_json(fixture)
            else:
                self.send_json(
                    {
                        "startAt": 0,
                        "maxResults": max_results,
                        "total": 1,
                        "issues": [
                            {
                                "key": "MOCK-1",
                                "fields": {
                                    "summary": f"Mock search result for: {jql}",
                                    "status": {"name": "Open"},
                                },
                            }
                        ],
                    }
                )
            return

        # GET /rest/api/2/project - List projects
        if endpoint == "project":
            fixture = self._load_fixture("jira/projects")
            if fixture:
                self.send_json(fixture)
            else:
                self.send_json(
                    [
                        {"key": "MOCK", "name": "Mock Project", "id": "10000"},
                        {"key": "TEST", "name": "Test Project", "id": "10001"},
                    ]
                )
            return

        self.send_error_json(404, f"Unknown Jira endpoint: {endpoint}")

    def _handle_confluence(self, path: str, query: dict[str, list[str]]) -> None:
        """Handle Confluence API endpoints."""
        endpoint = (
            path.split("/wiki/rest/api/")[1] if "/wiki/rest/api/" in path else path
        )

        # GET /wiki/rest/api/user/current - Current user
        if endpoint == "user/current":
            fixture = self._load_fixture("confluence/current_user")
            if fixture:
                self.send_json(fixture)
            else:
                self.send_json(
                    {
                        "accountId": "mock-user-123",
                        "displayName": "Mock User",
                        "email": "mock@example.com",
                        "type": "known",
                    }
                )
            return

        # GET /wiki/rest/api/space - List spaces
        if endpoint == "space":
            fixture = self._load_fixture("confluence/spaces")
            if fixture:
                self.send_json(fixture)
            else:
                self.send_json(
                    {
                        "results": [
                            {"key": "MOCK", "name": "Mock Space", "type": "global"},
                            {"key": "TEST", "name": "Test Space", "type": "personal"},
                        ],
                        "size": 2,
                    }
                )
            return

        # GET /wiki/rest/api/content - Get content
        if endpoint.startswith("content"):
            content_id = endpoint.split("/")[1] if "/" in endpoint else None
            if content_id and content_id.isdigit():
                fixture = self._load_fixture(f"confluence/content_{content_id}")
                if fixture:
                    self.send_json(fixture)
                else:
                    self.send_json(
                        {
                            "id": content_id,
                            "type": "page",
                            "title": f"Mock Page {content_id}",
                            "space": {"key": "MOCK"},
                            "body": {
                                "storage": {
                                    "value": "<p>Mock content</p>",
                                    "representation": "storage",
                                }
                            },
                        }
                    )
                return
            # List content
            self.send_json(
                {
                    "results": [
                        {"id": "12345", "type": "page", "title": "Mock Page"},
                    ],
                    "size": 1,
                }
            )
            return

        self.send_error_json(404, f"Unknown Confluence endpoint: {endpoint}")

    def do_POST(self) -> None:  # noqa: N802 - HTTP method name
        """Handle POST requests."""
        if not self._check_auth():
            self.send_error_json(401, "Unauthorized - missing or invalid token")
            return

        parsed = urlparse(self.path)
        path = parsed.path

        log.info("POST %s", path)

        # POST /rest/api/2/issue - Create issue
        if "/rest/api/2/issue" in path or "/rest/api/3/issue" in path:
            content_length = int(self.headers.get("Content-Length", 0))
            body = (
                self.rfile.read(content_length).decode("utf-8")
                if content_length
                else "{}"
            )
            try:
                data = json.loads(body)
            except json.JSONDecodeError:
                self.send_error_json(400, "Invalid JSON body")
                return

            project = data.get("fields", {}).get("project", {}).get("key", "MOCK")
            issue_url = "https://mock.atlassian.net/rest/api/2/issue/99999"
            self.send_json(
                {
                    "id": "99999",
                    "key": f"{project}-999",
                    "self": issue_url,
                },
                status=201,
            )
            return

        self.send_error_json(404, f"Unknown POST endpoint: {path}")


def run_server(port: int = DEFAULT_PORT) -> None:
    """Start the mock server."""
    server_address = ("", port)
    httpd = HTTPServer(server_address, MockAPIHandler)
    log.info("Mock API Server starting on port %d", port)
    log.info("Fixtures directory: %s", FIXTURES_DIR)
    log.info("Endpoints:")
    log.info("  - Health check: GET /health")
    log.info("  - Jira API: /rest/api/2/* or /rest/api/3/*")
    log.info("  - Confluence API: /wiki/rest/api/*")
    log.info("Press Ctrl+C to stop")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        log.info("Shutting down...")
        httpd.shutdown()


def main() -> int:
    """Main entry point."""
    global FIXTURES_DIR  # noqa: PLW0603 - intentional global reassignment
    import argparse

    parser = argparse.ArgumentParser(description="Mock API Server for testing")
    parser.add_argument(
        "--port",
        type=int,
        default=int(os.environ.get("MOCK_PORT", DEFAULT_PORT)),
        help=f"Server port (default: {DEFAULT_PORT})",
    )
    parser.add_argument(
        "--fixtures-dir",
        type=Path,
        default=FIXTURES_DIR,
        help=f"Fixtures directory (default: {FIXTURES_DIR})",
    )
    args = parser.parse_args()

    FIXTURES_DIR = args.fixtures_dir

    if not FIXTURES_DIR.exists():
        log.warning("Fixtures directory does not exist: %s", FIXTURES_DIR)

    run_server(args.port)
    return 0


if __name__ == "__main__":
    sys.exit(main())
