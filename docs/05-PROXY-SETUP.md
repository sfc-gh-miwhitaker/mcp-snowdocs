# MCP Proxy Server Setup

**Goal:** Resolve SSE streaming errors when connecting to Snowflake MCP server from IDEs like Cursor.

## Problem

When connecting to Snowflake's MCP server, some clients encounter this error:

```
[error] Client error for command Streamable HTTP error: Failed to open SSE stream: Not Acceptable
```

This 406 error occurs due to content negotiation issues between the MCP client and Snowflake's server - specifically, the `Accept: text/event-stream` header isn't being handled correctly.

## Solution

This project includes a local npm proxy server that:
1. Accepts MCP requests from your IDE (Cursor, VS Code, etc.)
2. Properly sets the required `Accept` headers for SSE streaming
3. Forwards requests to Snowflake's MCP server with correct authentication
4. Handles SSE response streaming back to the client

## Prerequisites

- **Node.js 18+** installed ([download](https://nodejs.org/))
- **Completed Steps 1-3** of the main setup (token created, MCP server URL obtained)

Verify Node.js version:
```bash
node --version
# Should show v18.x.x or higher
```

## Quick Start

### 1. Configure the Proxy

```bash
# Copy the example configuration
cp proxy/config.example.js proxy/config.js

# Edit with your values
# macOS/Linux:
nano proxy/config.js
# or Windows:
notepad proxy\config.js
```

Fill in your actual values:

```javascript
export default {
    // Your MCP server URL from Step 2 of main setup
    mcpServerUrl: 'https://your-org-your-account.snowflakecomputing.com/api/v2/cortex/mcp/SNOWFLAKE_INTELLIGENCE.MCP.SNOWFLAKE_MCP_SERVER:run',
    
    // Your PAT token from Step 1 of main setup
    authToken: 'eyJ...your-actual-token-here',
    
    // Local proxy settings (defaults work for most cases)
    proxyPort: 3456,
    proxyHost: '127.0.0.1',
    logLevel: 'info'  // Use 'debug' for troubleshooting
};
```

### 2. Start the Proxy

**macOS:**
```bash
# Run in foreground (see logs)
./tools/mcp proxy start

# Or run in background
./tools/mcp proxy start --bg
```

**Windows:**
```cmd
REM Run in foreground
tools\mcp proxy start

REM Or run in background
tools\mcp proxy start --bg
```

You should see:
```
╔══════════════════════════════════════════════════════════════╗
║           MCP Snowflake Proxy Server Started                 ║
╠══════════════════════════════════════════════════════════════╣
║  Local URL:  http://127.0.0.1:3456/mcp
║  Target:     https://your-org-your-account.snowflakecomputing.com
║  Log Level:  info
╠══════════════════════════════════════════════════════════════╣
║  Configure your MCP client to use:                           ║
║  URL: http://127.0.0.1:3456/mcp
║  (No Authorization header needed - proxy handles auth)       ║
╚══════════════════════════════════════════════════════════════╝
```

### 3. Update Your IDE Configuration

Now point your MCP client to the local proxy instead of directly to Snowflake.

<details>
<summary><b>Cursor</b></summary>

Edit `~/.cursor/mcp.json`:

```json
{
  "mcpServers": {
    "Snowflake": {
      "url": "http://127.0.0.1:3456/mcp"
    }
  }
}
```

**Note:** No `Authorization` header needed - the proxy handles authentication.

Restart Cursor after saving.

</details>

<details>
<summary><b>Claude Desktop</b></summary>

Edit the Claude Desktop config file:

```json
{
  "mcpServers": {
    "Snowflake": {
      "url": "http://127.0.0.1:3456/mcp"
    }
  }
}
```

Location:
- **macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`
- **Windows**: `%APPDATA%\Claude\claude_desktop_config.json`
- **Linux**: `~/.config/Claude/claude_desktop_config.json`

Restart Claude Desktop after saving.

</details>

<details>
<summary><b>VS Code (Continue.dev)</b></summary>

Edit `~/.continue/config.json`:

```json
{
  "mcpServers": {
    "snowflake": {
      "url": "http://127.0.0.1:3456/mcp"
    }
  }
}
```

Reload VS Code window (Cmd+Shift+P → "Developer: Reload Window").

</details>

### 4. Verify Connection

```bash
# Check proxy status
./tools/mcp proxy status

# Test health endpoint
curl http://127.0.0.1:3456/health
```

Expected health response:
```json
{"status":"ok","proxy":"mcp-snowflake-proxy","target":"https://your-org.snowflakecomputing.com"}
```

## Operational Commands

| Action | macOS | Windows |
|--------|-------|---------|
| Start (foreground) | `./tools/mcp proxy start` | `tools\mcp proxy start` |
| Start (background) | `./tools/mcp proxy start --bg` | `tools\mcp proxy start --bg` |
| Check status | `./tools/mcp proxy status` | `tools\mcp proxy status` |
| Stop | `./tools/mcp proxy stop` | `tools\mcp proxy stop` |
| View logs | `./tools/mcp proxy logs` | `tools\mcp proxy logs` |

## Configuration Options

Edit `proxy/config.js` to customize:

| Option | Default | Description |
|--------|---------|-------------|
| `mcpServerUrl` | (required) | Your Snowflake MCP server URL |
| `authToken` | (required) | Your PAT token |
| `proxyPort` | `3456` | Local port for the proxy |
| `proxyHost` | `127.0.0.1` | Host to bind (use `127.0.0.1` for security) |
| `logLevel` | `info` | Logging verbosity: `debug`, `info`, `warn`, `error` |

## Troubleshooting

### Proxy won't start

**Check Node.js version:**
```bash
node --version  # Must be 18+
```

**Check configuration exists:**
```bash
ls proxy/config.js  # Must exist
```

**Check for port conflicts:**
```bash
lsof -i :3456  # See what's using the port
```

### Still getting SSE errors

1. Enable debug logging:
   ```javascript
   // In proxy/config.js
   logLevel: 'debug'
   ```

2. Restart the proxy and check logs:
   ```bash
   ./tools/mcp proxy stop
   ./tools/mcp proxy start  # Run in foreground to see logs
   ```

3. Look for upstream errors in the debug output

### Proxy works but IDE doesn't connect

- **Cursor**: Make sure the JSON is valid (no trailing commas)
- **All IDEs**: Restart the IDE completely after config changes
- **Verify proxy is responding**: `curl http://127.0.0.1:3456/health`

### Authentication errors (401)

Your PAT token may be expired or incorrect:
1. Regenerate token: Run `sql/01_setup/create_token.sql`
2. Update `proxy/config.js` with new token
3. Restart proxy: `./tools/mcp proxy stop && ./tools/mcp proxy start`

## Architecture

```
┌─────────────┐     HTTP/SSE      ┌─────────────┐     HTTPS/SSE     ┌─────────────────┐
│  MCP Client │ ───────────────► │  Local Proxy │ ────────────────► │ Snowflake MCP   │
│  (Cursor)   │                   │  :3456/mcp   │  + Auth Headers   │     Server      │
└─────────────┘                   └─────────────┘                    └─────────────────┘
```

The proxy:
1. Receives MCP protocol requests from your IDE
2. Adds proper `Accept: text/event-stream` header for SSE compatibility
3. Adds `Authorization: Bearer <token>` header
4. Forwards to Snowflake MCP server
5. Streams SSE responses back to the IDE

## Security Considerations

- Proxy binds to `127.0.0.1` by default (localhost only)
- Credentials stored in `proxy/config.js` (gitignored)
- No credentials leave your machine except to Snowflake
- HTTPS used for all upstream communication

## When to Use the Proxy

**Use the proxy if:**
- Getting "Failed to open SSE stream: Not Acceptable" errors
- MCP client doesn't support custom header configuration
- Need to debug MCP protocol traffic

**Don't need the proxy if:**
- Direct connection to Snowflake MCP works fine
- You're using an MCP client that handles SSE correctly

## Navigation

- **Previous:** [Custom Tools Guide](04-CUSTOM-TOOLS.md)
- **Next:** Return to [README](../README.md)

