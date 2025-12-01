# MCP Snowflake Proxy

Local proxy server to fix SSE streaming errors with Snowflake MCP server.

## Quick Start

```bash
# 1. Configure
cp config.example.js config.js
# Edit config.js with your MCP URL and PAT token

# 2. Start
cd proxy && npm install && npm start

# Or use the mcp CLI:
../tools/mcp proxy start
```

## Purpose

This proxy resolves the error:
```
[error] Client error for command Streamable HTTP error: Failed to open SSE stream: Not Acceptable
```

It properly sets the `Accept: text/event-stream` header that some MCP clients fail to include.

## Configuration

Copy `config.example.js` to `config.js` and fill in:
- `mcpServerUrl`: Your Snowflake MCP server URL
- `authToken`: Your PAT token

## Full Documentation

See [docs/05-PROXY-SETUP.md](../docs/05-PROXY-SETUP.md) for complete setup instructions.

