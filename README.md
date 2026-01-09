![Reference Implementation](https://img.shields.io/badge/Reference-Implementation-blue)
![Ready to Run](https://img.shields.io/badge/Ready%20to%20Run-Yes-green)
![Expires](https://img.shields.io/badge/Expires-2026--02--07-orange)

# Snowflake MCP Server Setup

> DEMONSTRATION PROJECT - EXPIRES: 2026-02-07
> This demo uses Snowflake features current as of January 2026.
> After expiration, this repository should be archived and made private.

**Author:** SE Community
**Purpose:** Reference implementation for a Snowflake-managed MCP server that enables Snowflake documentation search from MCP clients
**Created:** 2026-01-08 | **Expires:** 2026-02-07 (30 days) | **Status:** ACTIVE

---

## What This Does

Deploys a Snowflake MCP server that gives your AI assistant:
- **Documentation search** - Query Snowflake docs directly from your IDE
- **Account info** - Check your Snowflake environment details
- **Function finder** - Search for Snowflake functions by keyword

## Prerequisites

- Snowflake account with `ACCOUNTADMIN` role
- An MCP-compatible IDE installed:
  - [Cursor](https://cursor.sh/)
  - [Claude Desktop](https://claude.ai/download)
  - [VS Code](https://code.visualstudio.com/) with [Continue.dev](https://continue.dev/)

---

## Quick Start

### Step 1: Deploy the MCP Server

1. Open [`deploy_all.sql`](deploy_all.sql) in **Snowsight**
2. Click **"Run All"**
3. **Copy these two values immediately:**
   - `MCP_URL` from the first result
   - `TOKEN_SECRET` from the first result (shown only once)
4. **Save the token in your password manager** - you can't see it again!

**Time:** ~2 minutes

---

### Step 2: Configure Your IDE

Choose your IDE and follow the setup below:

<details>
<summary><b>Cursor</b></summary>

Edit `~/.cursor/mcp.json` (create if it doesn't exist):

```json
{
  "mcpServers": {
    "Snowflake": {
      "url": "PASTE_YOUR_MCP_URL_HERE",
      "headers": {
        "Authorization": "Bearer PASTE_YOUR_TOKEN_SECRET_HERE"
      }
    }
  }
}
```

**Location:**
- macOS/Linux: `~/.cursor/mcp.json`
- Windows: `%USERPROFILE%\.cursor\mcp.json`

**After editing:**
1. Save the file
2. Restart Cursor completely (Cmd+Q on Mac, Alt+F4 on Windows)
3. The MCP tools will appear in the Composer

</details>

<details>
<summary><b>Claude Desktop</b></summary>

Edit Claude Desktop's configuration file:

```json
{
  "mcpServers": {
    "Snowflake": {
      "url": "PASTE_YOUR_MCP_URL_HERE",
      "headers": {
        "Authorization": "Bearer PASTE_YOUR_TOKEN_SECRET_HERE"
      }
    }
  }
}
```

**Location:**
- macOS: `~/Library/Application Support/Claude/claude_desktop_config.json`
- Windows: `%APPDATA%\Claude\claude_desktop_config.json`
- Linux: `~/.config/Claude/claude_desktop_config.json`

**After editing:**
1. Save the file
2. Restart Claude Desktop
3. Look for the hammer icon (🔨) in chat - indicates MCP tools are available

</details>

<details>
<summary><b>VS Code (Continue.dev)</b></summary>

**First, install Continue.dev:**
1. Open VS Code
2. Go to Extensions (Cmd+Shift+X / Ctrl+Shift+X)
3. Search for "Continue" and install it

**Then configure:**

Edit `~/.continue/config.json`:

```json
{
  "mcpServers": {
    "snowflake": {
      "url": "PASTE_YOUR_MCP_URL_HERE",
      "headers": {
        "Authorization": "Bearer PASTE_YOUR_TOKEN_SECRET_HERE"
      }
    }
  }
}
```

**Location:**
- macOS/Linux: `~/.continue/config.json`
- Windows: `%USERPROFILE%\.continue\config.json`

**After editing:**
1. Save the file
2. Reload VS Code window (Cmd+Shift+P → "Developer: Reload Window")
3. Open Continue panel (Cmd+L or Ctrl+L)

</details>

---

### Step 3: Test It Out

Ask your AI assistant:
- "How do I create a dynamic table in Snowflake?"
- "What Snowflake account am I connected to?"
- "Find Snowflake functions for working with JSON"

You should see it query the MCP server and return documentation-based answers.

---

## Cleanup

When you're done, run [`cleanup.sql`](cleanup.sql) in Snowsight to remove all MCP resources.

This will:
- Drop the MCP server
- Drop the MCP_ACCESS_ROLE
- Drop custom tool functions

**Preserved:**
- SNOWFLAKE_INTELLIGENCE database (reusable)
- SNOWFLAKE_DOCUMENTATION database (reusable)
- PAT tokens (manually managed - see cleanup.sql for instructions)

---

## Troubleshooting

### Error: "Failed to open SSE stream: Not Acceptable"

This is a known issue with some MCP clients. **Solution:**

Create a simple Node.js proxy that handles SSE headers correctly (separate repository). Search for "mcp snowflake proxy" to find a ready-to-use reference implementation.

### Error: HTTP 401 Authorization Failed

**Cause:** Token expired or incorrect

**Fix:**
1. Re-run `deploy.sql` to generate a new token
2. Update your IDE configuration with the new token
3. Restart your IDE

### IDE Doesn't Show MCP Tools

**Checklist:**
- [ ] Restarted IDE after config change?
- [ ] JSON syntax valid (no trailing commas)?
- [ ] URL and token copied correctly?
- [ ] Config file in the right location?

### Token Expired

PAT tokens expire after 365 days by default.

**Check expiry:**
```sql
SHOW USER PROGRAMMATIC ACCESS TOKENS;
```

**Fix:** Re-run `deploy.sql` to create a new token.

---

## Security Model

The `MCP_ACCESS_ROLE` has **minimal privileges**:

**What it CAN do:**
- Query Snowflake documentation
- Execute custom MCP tools (account info, function finder)

**What it CANNOT do:**
- Access your databases or tables
- Create, modify, or delete objects
- Execute arbitrary SQL
- Access schemas outside documentation

**If a token is compromised:** The attacker can only search documentation - no data access.

---

## What Gets Created

| Object | Purpose |
|--------|---------|
| `SNOWFLAKE_INTELLIGENCE` database | MCP server infrastructure |
| `SNOWFLAKE_INTELLIGENCE.MCP` schema | MCP objects |
| `SNOWFLAKE_INTELLIGENCE.MCP.SNOWFLAKE_MCP_SERVER` | MCP server endpoint |
| `SNOWFLAKE_INTELLIGENCE.MCP.GET_ACCOUNT_INFO()` | Custom tool: account info |
| `SNOWFLAKE_INTELLIGENCE.MCP.FIND_SNOWFLAKE_FUNCTIONS()` | Custom tool: function search |
| `MCP_ACCESS_ROLE` | Minimal-privilege role |
| PAT Token | Authentication token (365-day expiry) |

---

## Resources

- [Model Context Protocol](https://modelcontextprotocol.io/) - Official MCP documentation
- [Snowflake MCP Documentation](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-agents-mcp) - Snowflake's guide
- [MCP Implementations](https://modelcontextprotocol.io/implementations) - List of compatible IDEs

---

## License

Apache License 2.0 - See [LICENSE](./LICENSE)

---

## Summary

**Deploy:** Run `deploy.sql` in Snowsight → Copy URL + Token
**Configure:** Add to your IDE config file → Restart IDE
**Test:** Ask Snowflake questions in your AI assistant
**Cleanup:** Run `cleanup.sql` when done

**Total setup time:** ~5 minutes
