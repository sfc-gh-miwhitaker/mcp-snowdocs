from __future__ import annotations

import json
import socket
import ssl
from dataclasses import dataclass
from pathlib import Path
from typing import Optional

import requests

DEFAULT_SERVER_KEY = "Snowflake"
DEFAULT_CONFIG_PATH = Path.home() / ".cursor" / "mcp.json"
JSON_RPC_INIT = {"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {}}


@dataclass(frozen=True)
class VerificationResult:
    ssl_valid: bool
    http_status: Optional[int]
    response_text: str
    error: Optional[str]


def load_token_from_config(
    config_path: Path = DEFAULT_CONFIG_PATH,
    server_key: str = DEFAULT_SERVER_KEY,
) -> Optional[str]:
    """Load the Bearer token for the specified server from a Cursor-style config."""
    if not config_path.exists():
        return None

    with config_path.open("r", encoding="utf-8") as handle:
        data = json.load(handle)

    servers = data.get("mcpServers") or data.get("servers")
    if not isinstance(servers, dict):
        return None

    server_entry = servers.get(server_key)
    if not isinstance(server_entry, dict):
        return None

    headers = server_entry.get("headers")
    if not isinstance(headers, dict):
        return None

    authorization = headers.get("Authorization") or headers.get("authorization")
    if not isinstance(authorization, str):
        return None

    prefix = "Bearer "
    if authorization.startswith(prefix):
        return authorization[len(prefix) :].strip()
    return authorization.strip() or None


def verify_ssl(hostname: str, timeout: float = 10.0) -> bool:
    """Attempt to validate the TLS certificate for the provided hostname."""
    context = ssl.create_default_context()
    try:
        with socket.create_connection((hostname, 443), timeout=timeout) as sock:
            with context.wrap_socket(sock, server_hostname=hostname):
                return True
    except OSError:
        return False


def call_mcp_endpoint(url: str, token: str, timeout: float = 15.0) -> requests.Response:
    """Send a JSON-RPC initialize payload to the MCP endpoint."""
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
    }
    response = requests.post(
        url,
        headers=headers,
        json=JSON_RPC_INIT,
        timeout=timeout,
    )
    return response


def test_connection(
    url: str,
    hostname: Optional[str] = None,
    token: Optional[str] = None,
    config_path: Optional[Path] = None,
    server_key: str = DEFAULT_SERVER_KEY,
) -> VerificationResult:
    """Validate SSL and perform an MCP initialize call."""
    config_path = config_path or DEFAULT_CONFIG_PATH

    resolved_token = token or load_token_from_config(config_path, server_key=server_key)
    if not resolved_token:
        return VerificationResult(
            ssl_valid=False,
            http_status=None,
            response_text="",
            error="Token not provided and not found in configuration.",
        )

    ssl_valid = True
    if hostname:
        ssl_valid = verify_ssl(hostname)

    try:
        response = call_mcp_endpoint(url=url, token=resolved_token)
        return VerificationResult(
            ssl_valid=ssl_valid,
            http_status=response.status_code,
            response_text=response.text,
            error=None,
        )
    except requests.RequestException as exc:
        return VerificationResult(
            ssl_valid=ssl_valid,
            http_status=None,
            response_text="",
            error=str(exc),
        )
