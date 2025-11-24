#!/bin/bash
# Name: 02_setup_mcp.sh
# Synopsis: Provision the Snowflake MCP server and apply least-privilege role grants.

set -euo pipefail

PYTHON_BIN="${PYTHON_BIN:-}"

if [[ -z "${PYTHON_BIN}" ]]; then
    if command -v python3 >/dev/null 2>&1; then
        PYTHON_BIN="python3"
    else
        PYTHON_BIN="python"
    fi
fi

exec "$PYTHON_BIN" -m python.cli.main setup-mcp "$@"
