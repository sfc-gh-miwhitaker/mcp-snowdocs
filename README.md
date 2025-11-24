![Reference Implementation](https://img.shields.io/badge/Reference-Implementation-blue)
![Ready to Run](https://img.shields.io/badge/Ready%20to%20Run-Yes-green)
![Expires](https://img.shields.io/badge/Expires-2025--12--24-orange)

# Snowflake MCP Server Setup

> **DEMONSTRATION PROJECT - EXPIRES: 2025-12-24**
> This demo uses Snowflake features current as of November 2025.
> After expiration, this repository will be archived and made private.

**Author:** SE Community
**Purpose:** Reference implementation for MCP server setup
**Created:** 2025-11-24 | **Expires:** 2025-12-24 (30 days) | **Status:** ACTIVE

---

**ONE secure approach. THREE simple steps. FIVE minutes.**

This repository provides a production-ready SQL script to provision a [Model Context Protocol (MCP)](https://modelcontextprotocol.io/) server that exposes Snowflake's documentation via Cortex Search to AI coding assistants like **Cursor**, **Claude Desktop**, **VS Code**, and other MCP-compatible IDEs.

---

## First Time Here?

Follow these steps in order:

1. `docs/01-SETUP.md` — Prerequisites and Snowflake preparation (5 min)
2. `sql/01_setup/create_token.sql` — Generate PAT token in Snowsight (1 min)
3. `sql/01_setup/setup_mcp.sql` — Provision MCP server (2 min)
4. Configure your IDE — Add MCP URL + token to IDE config (5 min)
5. `docs/02-SECURITY.md` — Review security model and authentication (5 min)
6. `docs/03-TROUBLESHOOTING.md` — Reference for diagnostics (keep handy)
7. `docs/04-CUSTOM-TOOLS.md` — Learn about custom tools (2 min)

**Alternative (Automated):** Run `tools/00_master.sh --profile <PROFILE>` (Unix) or `tools\00_master.bat --profile <PROFILE>` (Windows) to automate steps 2-3.

**Total setup time:** ~20 minutes

---

## Quick Start

### Prerequisites
- Snowflake account with `ACCOUNTADMIN`, `SYSADMIN`, and `SECURITYADMIN` roles
- Snowflake Marketplace access (for accepting documentation share)
- Snowflake CLI (`snow`) 2.5.0+ configured with the roles above
- Python 3.10+ with dependencies installed via `pip install -r python/requirements.txt`
- MCP-compatible IDE: **Cursor**, **Claude Desktop**, **VS Code** (with Continue.dev), **Zed**, or [others](https://modelcontextprotocol.io/implementations)

Install the Python dependencies before running any tooling:

```bash
python3 -m venv .venv
source .venv/bin/activate  # Windows: .venv\Scripts\activate
pip install -r python/requirements.txt
```

---

### **Step 1: Create Token**

Open [`sql/01_setup/create_token.sql`](sql/01_setup/create_token.sql) in Snowsight.

1. Click "Run All"
2. Look for the result with "TOKEN_SECRET" column
3. **IMMEDIATELY copy the TOKEN_SECRET** value (starts with `eyJ...`)
4. **Save it in your password manager** (you'll never see it again!)

CLI alternative: `tools/01_create_token.sh --profile <SNOWFLAKE_PROFILE>` (or the `.bat` equivalent) runs the same SQL through the Snow CLI.

### **Step 2: Setup MCP**

Open [`sql/01_setup/setup_mcp.sql`](sql/01_setup/setup_mcp.sql) in Snowsight.

1. Click "Run All"
2. Look for the result with "mcp_url" column
3. **Copy the mcp_url** value

**What this script does:**
- Creates MCP server infrastructure (if it doesn't exist)
- Creates `MCP_ACCESS_ROLE` with 4 minimal privileges
- Grants role to your user
- Displays your account-specific MCP server URL

**Script is idempotent** - safe to run multiple times.

CLI alternative: `tools/02_setup_mcp.sh --profile <SNOWFLAKE_PROFILE>` (or the `.bat` equivalent) runs the same SQL through the Snow CLI.

---

### **Step 3: Configure Your MCP Client**

Choose your IDE and follow the configuration below:

<details>
<summary><b>Cursor</b> (Click to expand)</summary>

Edit `~/.cursor/mcp.json`:

```json
{
  "mcpServers": {
    "Snowflake": {
      "url": "PASTE_MCP_SERVER_URL_FROM_STEP_2",
      "headers": {
        "Authorization": "Bearer PASTE_TOKEN_SECRET_FROM_STEP_1"
      }
    }
  }
}
```

**Location by OS:**
- **macOS/Linux**: `~/.cursor/mcp.json`
- **Windows**: `%USERPROFILE%\.cursor\mcp.json`

**After editing:**
1. Save the file
2. Restart Cursor (Cmd+Q on Mac, Alt+F4 on Windows)
3. The Snowflake MCP server will be available in the Composer

</details>

<details>
<summary><b>Claude Desktop</b> (Click to expand)</summary>

Edit Claude Desktop's configuration file:

```json
{
  "mcpServers": {
    "Snowflake": {
      "url": "PASTE_MCP_SERVER_URL_FROM_STEP_2",
      "headers": {
        "Authorization": "Bearer PASTE_TOKEN_SECRET_FROM_STEP_1"
      }
    }
  }
}
```

**Location by OS:**
- **macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`
- **Windows**: `%APPDATA%\Claude\claude_desktop_config.json`
- **Linux**: `~/.config/Claude/claude_desktop_config.json`

**After editing:**
1. Save the file
2. Restart Claude Desktop
3. Look for the hammer icon in the chat—it indicates MCP tools are available

</details>

<details>
<summary><b>VS Code (with Continue.dev extension)</b> (Click to expand)</summary>

**VS Code supports MCP through the Continue.dev extension:**

1. **Install Continue.dev extension** from VS Code marketplace
2. **Edit your Continue configuration** at `~/.continue/config.json`:

```json
{
  "mcpServers": {
    "snowflake": {
      "url": "PASTE_MCP_SERVER_URL_FROM_STEP_2",
      "headers": {
        "Authorization": "Bearer PASTE_TOKEN_SECRET_FROM_STEP_1"
      }
    }
  }
}
```

**Location by OS:**
- **macOS/Linux**: `~/.continue/config.json`
- **Windows**: `%USERPROFILE%\.continue\config.json`

**After editing:**
1. Save the file
2. Reload VS Code window (Cmd+Shift+P → "Developer: Reload Window")
3. Open Continue panel (Cmd+L or Ctrl+L)
4. The Snowflake MCP server will be available in Continue's context menu

**Note**: Continue.dev has broader MCP support than native VS Code. For latest setup instructions, see [Continue.dev documentation](https://docs.continue.dev/).

</details>

<details>
<summary><b>Other MCP-Compatible IDEs</b> (Click to expand)</summary>

Any IDE that supports the [Model Context Protocol](https://modelcontextprotocol.io/) can use this server:

**Configuration Pattern:**
```json
{
  "mcpServers": {
    "Snowflake": {
      "url": "YOUR_MCP_SERVER_URL",
      "headers": {
        "Authorization": "Bearer YOUR_TOKEN_SECRET"
      }
    }
  }
}
```

**Supported IDEs:**
- Cursor (fully supported)
- Claude Desktop (fully supported)
- VS Code with the Continue.dev extension
- Zed with the MCP extension installed
- Other MCP-compatible IDEs listed at [modelcontextprotocol.io/implementations](https://modelcontextprotocol.io/implementations)

</details>

---

### **Step 4: Test & Use**

**Test from command line:**
```bash
./tools/03_test_connection.sh \
  --url "https://<org>-<account>.snowflakecomputing.com/api/v2/databases/..." \
  --hostname "<org>-<account>.snowflakecomputing.com"
```

Windows: `tools\03_test_connection.bat --url "https://<org>-<account>.snowflakecomputing.com/api/v2/databases/..." --hostname "<org>-<account>.snowflakecomputing.com"`

Expected output: `MCP Server: Ready and responding`

The verification script prints a JSON summary showing SSL status, HTTP status, and any errors for easy logging.

**Restart your IDE** (Cmd+Q / Alt+F4 and reopen)

**Test with questions:**
> "How do I create a dynamic table in Snowflake?"
> "What Snowflake account am I connected to?"
> "Find functions for working with JSON data"

The assistant should call the MCP server and return documentation-based answers or tool results.

---

## Custom Tools Demonstration

Beyond documentation search, this project includes two custom tools that demonstrate the extensibility of Snowflake's MCP server:

1. **Get Account Info** - Returns your current Snowflake environment details (version, region, account name, etc.)
2. **Find Snowflake Functions** - Searches for built-in functions by keyword to complement the general doc search

Try asking:
> "What Snowflake account am I connected to?"
> "Find functions for working with JSON data"
> "Search for date manipulation functions"

These tools showcase how you can extend the MCP server with custom UDFs and stored procedures to add domain-specific capabilities.

See [`docs/04-CUSTOM-TOOLS.md`](docs/04-CUSTOM-TOOLS.md) for details on these tools and how to add your own.

---

## Authentication Note

This demo uses **Programmatic Access Tokens (PAT)** for simplicity. PAT tokens are perfect for demos, development, and learning environments.

For production deployments, Snowflake recommends **OAuth 2.0**. The MCP server architecture supports both authentication methods - we chose PAT to minimize setup friction while demonstrating best-practice security patterns (dedicated role, minimal privileges, clear audit trail).

See [`docs/02-SECURITY.md`](docs/02-SECURITY.md) for a detailed comparison and OAuth setup guidance.

---

## Security: Minimal Privileges

The `MCP_ACCESS_ROLE` has **minimal grants** and nothing more:

1. `USAGE` on `SNOWFLAKE_INTELLIGENCE` database
2. `USAGE` on `SNOWFLAKE_INTELLIGENCE.MCP` schema
3. `USAGE` on the MCP server object
4. `USAGE` on custom tool functions (account info, function finder)
5. `IMPORTED PRIVILEGES` on `SNOWFLAKE_DOCUMENTATION` (marketplace database)

**If a PAT token is compromised**, an attacker can only:
- Call MCP server endpoints
- Search Snowflake documentation
- View account metadata (version, region, account name)
- Search for function names in documentation

An attacker cannot:
- Access user databases or tables
- Read schemas outside of the documentation share
- Create, modify, or delete objects
- Execute arbitrary SQL queries

**Blast radius: minimal** — access is limited to documentation search

See [`docs/02-SECURITY.md`](docs/02-SECURITY.md) for detailed analysis.

---

## Project Structure

```
.
├── diagrams/                   # Mandatory Mermaid architecture diagrams
│   ├── auth-flow.md
│   ├── data-flow.md
│   └── network-flow.md
├── docs/                       # User-facing guides
│   ├── 01-SETUP.md
│   ├── 02-SECURITY.md
│   ├── 03-TROUBLESHOOTING.md
│   └── 04-CUSTOM-TOOLS.md
├── python/                     # Shared CLI logic, services, and tests
│   ├── cli/
│   │   └── main.py
│   ├── services/
│   │   ├── snow_cli.py
│   │   └── verification.py
│   ├── requirements.txt
│   └── tests/
│       ├── test_cli_main.py
│       ├── test_snow_cli.py
│       └── test_verification.py
├── sql/                        # Snowflake automation
│   ├── 01_setup/
│   │   ├── create_token.sql
│   │   └── setup_mcp.sql
│   ├── 02_custom_tools/
│   │   ├── account_info.sql
│   │   └── function_finder.sql
│   ├── 03_operations/
│   │   └── troubleshoot.sql
│   └── 99_cleanup/
│       └── teardown_all.sql
├── tools/                      # Cross-platform automation wrappers
│   ├── 00_master.sh
│   ├── 00_master.bat
│   ├── 01_create_token.sh
│   ├── 01_create_token.bat
│   ├── 02_setup_mcp.sh
│   ├── 02_setup_mcp.bat
│   ├── 03_test_connection.sh
│   └── 03_test_connection.bat
├── README.md                   # Main documentation
├── QUICKSTART.md               # Sequential onboarding (created from docs)
├── LICENSE
└── .cursor/
    └── docs/
        └── CHANGELOG.md
```

---

## Cleanup

To remove MCP server, custom tools, and role (preserves reusable infrastructure):

```sql
-- Execute sql/99_cleanup/teardown_all.sql in Snowsight
-- Removes:
--   - Custom functions (GET_ACCOUNT_INFO, FIND_SNOWFLAKE_FUNCTIONS)
--   - MCP server (SNOWFLAKE_INTELLIGENCE.MCP.SNOWFLAKE_MCP_SERVER)
--   - MCP_ACCESS_ROLE and all grants
-- Preserves:
--   - SNOWFLAKE_INTELLIGENCE database and schemas (reusable)
--   - SNOWFLAKE_DOCUMENTATION database (may be used by other examples)
--   - PAT tokens (user-managed, may be used elsewhere)
```

**Objects removed:**
- Custom tool functions
- MCP server object
- `MCP_ACCESS_ROLE` (automatically revoked from users)

**Infrastructure preserved:**
- `SNOWFLAKE_INTELLIGENCE` database
- `SNOWFLAKE_INTELLIGENCE.MCP` schema
- `SNOWFLAKE_DOCUMENTATION` database share
- Programmatic access tokens (managed by the user)

To remove your PAT token manually (optional):

```sql
-- List your tokens
SHOW USER PROGRAMMATIC ACCESS TOKENS;

-- Drop specific token
ALTER USER CURRENT_USER() DROP PROGRAMMATIC ACCESS TOKEN <token_name>;
```

**Note:** PAT tokens are intentionally preserved because they may be used for other Snowflake integrations or examples.

---

## Troubleshooting

### HTTP 401: Authorization Failed

**Cause:** PAT token missing required grants

**Fix:**
1. Run [`sql/03_operations/troubleshoot.sql`](sql/03_operations/troubleshoot.sql) to check grants
2. Verify `MCP_ACCESS_ROLE` exists and has 4 required grants
3. Verify role is assigned to your user
4. Re-run [`sql/01_setup/setup_mcp.sql`](sql/01_setup/setup_mcp.sql) if needed (it's idempotent)

### HTTP 404 or "Agent Server does not exist"

**Cause:** MCP server creation failed or insufficient privileges

**Fix:**
1. Ensure you have `ACCOUNTADMIN`, `SYSADMIN`, and `SECURITYADMIN` roles
2. Re-run [`sql/01_setup/setup_mcp.sql`](sql/01_setup/setup_mcp.sql) - it creates the server automatically
3. Verify with:
```sql
SHOW MCP SERVERS IN SCHEMA SNOWFLAKE_INTELLIGENCE.MCP;
```

### SSL Certificate Error

**Cause:** Wrong URL format for your account

**Fix:** Use the exact URL from the setup script output (don't modify it)

### Token Expired

**Cause:** PAT tokens expire (default 365 days)

**Fix:**
```sql
-- Check expiry
SHOW USER PROGRAMMATIC ACCESS TOKENS;

-- Create new token by re-running sql/01_setup/create_token.sql
```

### IDE Doesn't Show MCP Tools

**For Cursor:**
- [ ] Restarted Cursor after config change?
- [ ] `~/.cursor/mcp.json` has valid JSON?
- [ ] URL and token are correct (no typos)?
- [ ] Check Cursor's MCP status in settings

**For Claude Desktop:**
- [ ] Restarted Claude Desktop after config change?
- [ ] Config file path correct for your OS?
- [ ] Look for the hammer icon in new chats
- [ ] Check Claude Desktop logs: `~/Library/Logs/Claude/` (macOS)

**For VS Code (Continue.dev):**
- [ ] Continue.dev extension installed and enabled?
- [ ] Reloaded VS Code window after config change?
- [ ] Config file at `~/.continue/config.json`?
- [ ] Open Continue panel (Cmd+L / Ctrl+L) to verify

**For All IDEs:**
- [ ] `tools/03_test_connection.sh` or `tools\03_test_connection.bat` returns HTTP 200?
- [ ] Token hasn't expired (default: 365 days)?
- [ ] MCP server URL uses lowercase format?

---

## IDE Compatibility Matrix

| Feature | Cursor | Claude Desktop | VS Code + Continue | Zed |
|---------|--------|----------------|-------------------|-----|
| MCP support | Native | Native | Extension-based | Extension-based |
| Setup complexity | Easy | Easy | Medium | Medium |
| Snowflake documentation access | Yes | Yes | Yes | Yes |
| Real-time search | Yes | Yes | Yes | Yes |
| Configuration file | `~/.cursor/mcp.json` | OS-specific | `~/.continue/config.json` | Extension configuration |
| Visual indicator | Composer tools | Hammer icon | Continue panel (Cmd+L) | Status bar |
| Testing status | Fully verified | Fully verified | Community validated | Community validated |

**Legend:**
- Fully verified: validated by the project team
- Community validated: confirmed by community feedback
- Planned/In development: feature is on the roadmap
- Not supported: capability is not currently available

---

## Additional Resources

- [Model Context Protocol Documentation](https://modelcontextprotocol.io/)
- [MCP Implementation List](https://modelcontextprotocol.io/implementations) - See all compatible IDEs
- [Snowflake Managed MCP Server Documentation](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-agents-mcp)
- [Snowflake Programmatic Access Tokens](https://docs.snowflake.com/en/user-guide/authentication-using-pat)
- [Snowflake RBAC Best Practices](https://docs.snowflake.com/user-guide/security-access-control-considerations)

---

## Contributing

Contributions welcome! Please open an issue or pull request if you find bugs or have suggestions.

## License

Apache License 2.0 - See [LICENSE](./LICENSE) file for details.

---

## Summary

**Delivered by this project**
- Secure MCP server with minimal privileges
- Production-ready setup in approximately five minutes
- Documented security boundaries and troubleshooting guidance
- Automated verification tooling and cleanup scripts

**Not included**
- Overly broad permissions
- PUBLIC role grants
- Complex multi-script workflows
- Security trade-offs

Start now by following [`docs/01-SETUP.md`](docs/01-SETUP.md) or, if you prefer automation, run `tools/00_master.sh` (macOS/Linux) or `tools\00_master.bat` (Windows).
