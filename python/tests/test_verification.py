from __future__ import annotations

import json
from pathlib import Path
from unittest import mock

from python.services import verification


def test_load_token_from_config(tmp_path: Path) -> None:
    # Given a configuration file matching Cursor's schema
    config = tmp_path / "mcp.json"
    config.write_text(
        json.dumps(
            {
                "mcpServers": {
                    "Snowflake": {
                        "url": "https://example",
                        "headers": {"Authorization": "Bearer abc123"},
                    }
                }
            }
        )
    )

    # When loading the token
    token = verification.load_token_from_config(config_path=config)

    # Then the Bearer prefix is removed
    assert token == "abc123"


def test_test_connection_missing_token_returns_error(tmp_path: Path) -> None:
    # Given no configuration file or token
    # When running the test
    result = verification.test_connection(
        url="https://example", config_path=tmp_path / "missing.json"
    )

    # Then an error is reported
    assert result.error is not None
    assert result.http_status is None


def test_test_connection_successful(monkeypatch) -> None:
    # Given SSL verification succeeds and the endpoint returns 200
    monkeypatch.setattr(verification, "verify_ssl", lambda hostname: True)

    mock_response = mock.Mock(status_code=200, text='{"result":"ok"}')
    monkeypatch.setattr(
        verification, "call_mcp_endpoint", lambda url, token: mock_response
    )

    # When testing the connection with an explicit token
    result = verification.test_connection(
        url="https://example/api",
        hostname="example.snowflakecomputing.com",
        token="abc123",
    )

    # Then the result captures the response
    assert result.ssl_valid is True
    assert result.http_status == 200
    assert result.error is None
