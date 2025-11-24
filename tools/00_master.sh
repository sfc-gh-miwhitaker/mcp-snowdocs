#!/bin/bash
# Name: 00_master.sh
# Synopsis: End-to-end workflow for provisioning and verifying the Snowflake MCP server.
# Usage: ./tools/00_master.sh --profile <SNOW_PROFILE> --url <MCP_URL> [options]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_BIN="${PYTHON_BIN:-}"

if [[ -z "${PYTHON_BIN}" ]]; then
    if command -v python3 >/dev/null 2>&1; then
        PYTHON_BIN="python3"
    else
        PYTHON_BIN="python"
    fi
fi

exec "$PYTHON_BIN" -m python.cli.main master "$@"
