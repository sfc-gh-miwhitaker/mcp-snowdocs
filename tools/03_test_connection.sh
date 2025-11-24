#!/bin/bash
# Name: 03_test_connection.sh
# Synopsis: Validate SSL trust and run an MCP initialize call against the server.

set -euo pipefail

PYTHON_BIN="${PYTHON_BIN:-}"

if [[ -z "${PYTHON_BIN}" ]]; then
    if command -v python3 >/dev/null 2>&1; then
        PYTHON_BIN="python3"
    else
        PYTHON_BIN="python"
    fi
fi

exec "$PYTHON_BIN" -m python.cli.main test-connection "$@"
