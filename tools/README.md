# MCP Snowflake CLI

Unified command-line interface for all MCP server operations.

## Quick Reference

| Command | Description |
|---------|-------------|
| `./tools/mcp token` | Create PAT token for MCP authentication |
| `./tools/mcp setup` | Provision MCP server and apply grants |
| `./tools/mcp test` | Validate SSL and test MCP connection |
| `./tools/mcp all` | Run complete setup (token + setup + test) |
| `./tools/mcp proxy start` | Start local SSE proxy server |
| `./tools/mcp proxy stop` | Stop the proxy server |
| `./tools/mcp proxy status` | Check proxy status |
| `./tools/mcp help` | Show help message |

## Usage

**macOS:**
```bash
./tools/mcp <command> [options]
```

**Windows:**
```cmd
tools\mcp <command> [options]
```

## Examples

```bash
# Create PAT token
./tools/mcp token --profile myprofile

# Setup MCP server
./tools/mcp setup --profile myprofile

# Test connection
./tools/mcp test --url "https://org-acct.snowflakecomputing.com/api/v2/cortex/mcp/..."

# Run complete setup
./tools/mcp all --profile myprofile --url "https://..."

# Start proxy in background
./tools/mcp proxy start --bg

# Check proxy status
./tools/mcp proxy status

# Stop proxy
./tools/mcp proxy stop
```

## Directory Structure

```
tools/
├── mcp           # Main CLI (macOS/Linux)
├── mcp.cmd       # Main CLI (Windows)
├── mac/          # macOS-specific utilities (if needed)
├── windows/      # Windows-specific utilities (if needed)
└── README.md     # This file
```

## Options

### Common Options (token, setup, all)

| Option | Description |
|--------|-------------|
| `--profile <name>` | Snow CLI profile to use |
| `--dry-run` | Print commands without executing |
| `--verbose` | Show detailed output |

### Test Options

| Option | Description |
|--------|-------------|
| `--url <url>` | MCP server URL (required) |
| `--hostname <host>` | Hostname for SSL validation |
| `--token <token>` | Bearer token (or reads from config) |

### Proxy Options

| Option | Description |
|--------|-------------|
| `--bg`, `--background` | Run proxy in background |

## See Also

- [Setup Guide](../docs/01-SETUP.md)
- [Proxy Setup](../docs/05-PROXY-SETUP.md)
- [Troubleshooting](../docs/03-TROUBLESHOOTING.md)

