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

## What This Provides

A production-ready, security-focused implementation to expose Snowflake's documentation through the [Model Context Protocol (MCP)](https://modelcontextprotocol.io/) to AI coding assistants like **Cursor**, **Claude Desktop**, **VS Code**, and other MCP-compatible IDEs.

**Key Features:**
- ✅ **Minimal privilege security model** - Dedicated role with only required grants
- ✅ **Copy-paste deployment** - Run SQL scripts directly in Snowsight
- ✅ **Extensible architecture** - Templates and config files for easy customization
- ✅ **Cross-platform tooling** - Automated workflows for Unix/macOS and Windows
- ✅ **Complete documentation** - Every file justified with clear guidance

---

## 👋 First Time Here?

Follow these steps in order:

1. **[Prerequisites & Setup](docs/01-SETUP.md)** — Prepare your environment (5 min)
2. **[Create Token](sql/01_setup/create_token.sql)** — Generate PAT token in Snowsight (1 min)
3. **[Setup MCP Server](sql/01_setup/setup_mcp.sql)** — Provision infrastructure (2 min)
4. **Configure IDE** — Add MCP URL + token to your IDE config (5 min)
5. **[Security Review](docs/02-SECURITY.md)** — Understand the security model (5 min)
6. **[Troubleshooting](docs/03-TROUBLESHOOTING.md)** — Keep handy for diagnostics
7. **[Custom Tools Guide](docs/04-CUSTOM-TOOLS.md)** — Learn extensibility patterns (2 min)
8. **[Proxy Setup](docs/05-PROXY-SETUP.md)** — Fix SSE streaming errors (if needed)

**🚀 Alternative (Automated):** Run `./tools/mcp all --profile <PROFILE>` (macOS) or `tools\mcp all --profile <PROFILE>` (Windows) to automate steps 2-3.

**⏱️ Total setup time:** ~20 minutes

---

## 🎨 Customization

This project is designed to be easily customized for your environment:

### Configuration Files (✅ Safe to Edit)

- **[`config/settings.yaml`](config/settings.yaml)** - Database names, roles, warehouses, token settings
- **[`config/mcp_spec.yaml`](config/mcp_spec.yaml)** - MCP tool definitions (add, remove, or modify tools)

### Adding Custom Tools

1. **Copy a template:**
   - For UDFs: [`sql/02_custom_tools/_TEMPLATE.sql`](sql/02_custom_tools/_TEMPLATE.sql)
   - For semantic views: [`sql/02_custom_tools/SEMANTIC_VIEWS_TEMPLATE.sql`](sql/02_custom_tools/SEMANTIC_VIEWS_TEMPLATE.sql)

2. **Implement your function** in the copied SQL file

3. **Add tool definition** to [`config/mcp_spec.yaml`](config/mcp_spec.yaml)

4. **Run your SQL file** to create the function

5. **Re-run** [`sql/01_setup/setup_mcp.sql`](sql/01_setup/setup_mcp.sql) to update the MCP server

See **[Custom Tools Guide](docs/04-CUSTOM-TOOLS.md)** for detailed instructions and examples.

---

## 🚀 Quick Start

### Prerequisites

**Snowflake Account:**
- Roles: `ACCOUNTADMIN`, `SYSADMIN`, and `SECURITYADMIN`
- Snowflake Marketplace access (for documentation share)

**Local Tools:**
- **Snowflake CLI (`snow`)** version 2.5.0+ configured with above roles
- **Python 3.10+** for automation scripts (optional - can run SQL manually)
- **MCP-compatible IDE:** [Cursor](https://cursor.sh/), [Claude Desktop](https://claude.ai/download), [VS Code](https://code.visualstudio.com/) (with [Continue.dev](https://continue.dev/)), [Zed](https://zed.dev/), or [other MCP clients](https://modelcontextprotocol.io/implementations)

**Python Setup (if using automation tools):**

```bash
python3 -m venv .venv
source .venv/bin/activate  # Windows: .venv\Scripts\activate
pip install -r python/requirements.txt
```

---

### **Step 1: Create Token**

Open **[`sql/01_setup/create_token.sql`](sql/01_setup/create_token.sql)** in Snowsight.

1. Click **"Run All"**
2. Look for the result with **"TOKEN_SECRET"** column
3. **IMMEDIATELY copy the TOKEN_SECRET** value (starts with `eyJ...`)
4. **Save it in your password manager** (you'll never see it again!)

**CLI Alternative:**
```bash
# macOS
./tools/mcp token --profile <SNOWFLAKE_PROFILE>

# Windows
tools\mcp token --profile <SNOWFLAKE_PROFILE>
```

### **Step 2: Setup MCP Server**

Open **[`sql/01_setup/setup_mcp.sql`](sql/01_setup/setup_mcp.sql)** in Snowsight.

1. Click **"Run All"**
2. Look for the result with **"mcp_url"** column
3. **Copy the mcp_url** value

**What this script does:**
- ✅ Creates MCP server infrastructure (if it doesn't exist)
- ✅ Creates `MCP_ACCESS_ROLE` with 5 minimal privileges
- ✅ Grants role to your user
- ✅ Displays your account-specific MCP server URL

**Script is idempotent** - safe to run multiple times.

**CLI Alternative:**
```bash
# macOS
./tools/mcp setup --profile <SNOWFLAKE_PROFILE>

# Windows
tools\mcp setup --profile <SNOWFLAKE_PROFILE>
```

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
# macOS
./tools/mcp test --url "YOUR_MCP_URL_FROM_STEP_2" --hostname "YOUR-ORG-YOUR-ACCOUNT.snowflakecomputing.com"

# Windows
tools\mcp test --url "YOUR_MCP_URL_FROM_STEP_2" --hostname "YOUR-ORG-YOUR-ACCOUNT.snowflakecomputing.com"
```

**Expected output:** `MCP Server: Ready and responding`

The verification script prints a JSON summary showing SSL status, HTTP status, and any errors for easy logging.

**Restart your IDE** (Cmd+Q / Alt+F4 and reopen)

**Test with questions:**
```
> "How do I create a dynamic table in Snowflake?"
> "What Snowflake account am I connected to?"
> "Find functions for working with JSON data"
```

The assistant should call the MCP server and return documentation-based answers or tool results.

---

## 🛠️ Custom Tools Demonstration

Beyond documentation search, this project includes two custom tools that demonstrate extensibility:

1. **Get Account Info** - Returns your Snowflake environment details (version, region, account name, etc.)
2. **Find Snowflake Functions** - Searches for built-in functions by keyword

**Try asking:**
```
> "What Snowflake account am I connected to?"
> "Find functions for working with JSON data"
> "Search for date manipulation functions"
```

These tools showcase how you can extend the MCP server with custom UDFs and stored procedures.

### Adding Your Own Tools

This project provides templates and configuration to make adding custom tools straightforward:

| Template | Purpose | Link |
|----------|---------|------|
| **Generic UDF Template** | Copy-paste starting point for custom functions | [`sql/02_custom_tools/_TEMPLATE.sql`](sql/02_custom_tools/_TEMPLATE.sql) |
| **Semantic View Template** | Template for Cortex Analyst integration | [`sql/02_custom_tools/SEMANTIC_VIEWS_TEMPLATE.sql`](sql/02_custom_tools/SEMANTIC_VIEWS_TEMPLATE.sql) |
| **Tool Configuration** | Add tool definitions (includes commented template) | [`config/mcp_spec.yaml`](config/mcp_spec.yaml) |

**📚 Complete Guide:** See **[Custom Tools Documentation](docs/04-CUSTOM-TOOLS.md)** for step-by-step instructions.

---

## 🔐 Authentication Note

This demo uses **Programmatic Access Tokens (PAT)** for simplicity. PAT tokens are perfect for demos, development, and learning environments.

For production deployments, Snowflake recommends **OAuth 2.0**. The MCP server architecture supports both authentication methods - we chose PAT to minimize setup friction while demonstrating best-practice security patterns (dedicated role, minimal privileges, clear audit trail).

**📚 Learn More:** See **[Security Documentation](docs/02-SECURITY.md)** for a detailed comparison and OAuth setup guidance.

---

## 🔒 Security: Minimal Privileges

The `MCP_ACCESS_ROLE` has **minimal grants** and nothing more:

| Grant | Purpose |
|-------|---------|
| `USAGE` on `SNOWFLAKE_INTELLIGENCE` database | Access MCP infrastructure |
| `USAGE` on `SNOWFLAKE_INTELLIGENCE.MCP` schema | Access MCP objects |
| `USAGE` on the MCP server object | Call MCP endpoints |
| `USAGE` on custom tool functions | Execute demo tools |
| `IMPORTED PRIVILEGES` on `SNOWFLAKE_DOCUMENTATION` | Search documentation |

### If a PAT Token is Compromised

**✅ Attacker CAN:**
- Call MCP server endpoints
- Search Snowflake documentation
- View account metadata (version, region, account name)
- Search for function names in documentation

**❌ Attacker CANNOT:**
- Access user databases or tables
- Read schemas outside of the documentation share
- Create, modify, or delete objects
- Execute arbitrary SQL queries

**Blast radius: minimal** — access is limited to documentation search

**📚 Learn More:** See **[Security Documentation](docs/02-SECURITY.md)** for detailed analysis.

---

## Project Structure

```
.
├── .secrets/                   # Gitignored - local token storage
│   ├── README.md              # Usage instructions
│   ├── mcp.json.example       # Template for IDE config
│   └── .gitkeep
├── config/                     # ✅ CUSTOMIZE THESE FILES
│   ├── settings.yaml          # Database names, roles, warehouses
│   └── mcp_spec.yaml          # MCP tool definitions
├── diagrams/                   # Mermaid architecture diagrams
│   ├── auth-flow.md
│   ├── data-flow.md
│   └── network-flow.md
├── docs/                       # User-facing guides
│   ├── 01-SETUP.md
│   ├── 02-SECURITY.md
│   ├── 03-TROUBLESHOOTING.md
│   ├── 04-CUSTOM-TOOLS.md
│   └── 05-PROXY-SETUP.md       # SSE streaming fix
├── proxy/                      # 🔧 LOCAL PROXY (for SSE issues)
│   ├── config.example.js       # Copy to config.js and edit
│   ├── package.json
│   └── server.js
├── python/                     # CLI logic, services, and tests
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
│   │   └── setup_mcp.sql      # Now uses config/ variables
│   ├── 02_custom_tools/
│   │   ├── _TEMPLATE.sql      # 📋 COPY to create new tools
│   │   ├── SEMANTIC_VIEWS_TEMPLATE.sql  # 📋 COPY for Cortex Analyst
│   │   ├── account_info.sql
│   │   └── function_finder.sql
│   ├── 03_operations/
│   │   └── troubleshoot.sql
│   └── 99_cleanup/
│       └── teardown_all.sql
├── tools/                      # Unified CLI for all operations
│   ├── mcp                     # Main CLI (macOS)
│   ├── mcp.cmd                 # Main CLI (Windows)
│   ├── mac/                    # macOS-specific utilities
│   ├── windows/                # Windows-specific utilities
│   └── README.md               # CLI documentation
├── README.md                   # Main documentation
├── QUICKSTART.md               # Sequential onboarding
└── LICENSE

Legend: ✅ = Customize for your environment | 📋 = Copy and modify template | 🔧 = SSE fix (use if getting streaming errors)
```

---

## 🧹 Cleanup

To remove MCP server, custom tools, and role (preserves reusable infrastructure):

**Execute [`sql/99_cleanup/teardown_all.sql`](sql/99_cleanup/teardown_all.sql) in Snowsight**

### What Gets Removed

| Object | Action |
|--------|--------|
| Custom tool functions | Dropped |
| MCP server object | Dropped |
| `MCP_ACCESS_ROLE` | Dropped (automatically revoked from all users) |

### What Gets Preserved

| Object | Reason |
|--------|--------|
| `SNOWFLAKE_INTELLIGENCE` database | Reusable infrastructure |
| `SNOWFLAKE_INTELLIGENCE.MCP` schema | Reusable infrastructure |
| `SNOWFLAKE_DOCUMENTATION` database | May be used by other examples |
| PAT tokens | User-managed, may be used elsewhere |

### Optional: Remove PAT Token

```sql
-- List your tokens
SHOW USER PROGRAMMATIC ACCESS TOKENS;

-- Drop specific token
ALTER USER CURRENT_USER() DROP PROGRAMMATIC ACCESS TOKEN <token_name>;
```

**Note:** PAT tokens are intentionally preserved because they may be used for other Snowflake integrations or examples.

---

## 🔍 Troubleshooting

### SSE Streaming Error: "Failed to open SSE stream: Not Acceptable"

**Cause:** Content negotiation issue between MCP client and Snowflake server

**Fix:** Use the local proxy server that properly handles SSE headers:

```bash
# 1. Configure the proxy
cp proxy/config.example.js proxy/config.js
# Edit proxy/config.js with your MCP URL and PAT token

# 2. Start the proxy
./tools/mcp proxy start      # macOS
tools\mcp proxy start        # Windows

# 3. Update your IDE to use: http://127.0.0.1:3456/mcp
```

**📚 Full Guide:** See **[Proxy Setup Guide](docs/05-PROXY-SETUP.md)** for detailed instructions.

### HTTP 401: Authorization Failed

**Cause:** PAT token missing required grants

**Fix:**
1. Run **[`sql/03_operations/troubleshoot.sql`](sql/03_operations/troubleshoot.sql)** to check grants
2. Verify `MCP_ACCESS_ROLE` exists and has 5 required grants
3. Verify role is assigned to your user
4. Re-run **[`sql/01_setup/setup_mcp.sql`](sql/01_setup/setup_mcp.sql)** if needed (it's idempotent)

### HTTP 404 or "Agent Server does not exist"

**Cause:** MCP server creation failed or insufficient privileges

**Fix:**
1. Ensure you have `ACCOUNTADMIN`, `SYSADMIN`, and `SECURITYADMIN` roles
2. Re-run **[`sql/01_setup/setup_mcp.sql`](sql/01_setup/setup_mcp.sql)** - it creates the server automatically
3. Verify with:
```sql
SHOW MCP SERVERS IN SCHEMA SNOWFLAKE_INTELLIGENCE.MCP;
```

**📚 More Help:** See **[Troubleshooting Guide](docs/03-TROUBLESHOOTING.md)** for complete diagnostic procedures.

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
- [ ] Verification script returns HTTP 200?
  - macOS: `./tools/mcp test --url <URL> --hostname <HOST>`
  - Windows: `tools\mcp test --url <URL> --hostname <HOST>`
- [ ] Token hasn't expired (default: 365 days)?
- [ ] MCP server URL uses lowercase format?

**📚 More Help:** See **[Troubleshooting Guide](docs/03-TROUBLESHOOTING.md)** for complete diagnostic procedures.

---

## 📊 IDE Compatibility Matrix

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

## 📚 Additional Resources

**Model Context Protocol:**
- [MCP Documentation](https://modelcontextprotocol.io/)
- [MCP Implementation List](https://modelcontextprotocol.io/implementations) - See all compatible IDEs

**Snowflake Documentation:**
- [Managed MCP Server Guide](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-agents-mcp)
- [Programmatic Access Tokens](https://docs.snowflake.com/en/user-guide/authentication-using-pat)
- [RBAC Best Practices](https://docs.snowflake.com/user-guide/security-access-control-considerations)

**Project Documentation:**
- [Complete Setup Guide](docs/01-SETUP.md)
- [Security Model](docs/02-SECURITY.md)
- [Troubleshooting Guide](docs/03-TROUBLESHOOTING.md)
- [Custom Tools Guide](docs/04-CUSTOM-TOOLS.md)

---

## Contributing

Contributions welcome! Please open an issue or pull request if you find bugs or have suggestions.

## License

Apache License 2.0 - See [LICENSE](./LICENSE) file for details.

---

## ✨ Summary

### What This Project Delivers

✅ **Secure MCP server** with minimal privileges  
✅ **Production-ready setup** in ~20 minutes  
✅ **Comprehensive documentation** for all components  
✅ **Automated tooling** for cross-platform deployment  
✅ **Extensibility templates** for custom tools  
✅ **Complete cleanup** procedures

### What's NOT Included

❌ Overly broad permissions  
❌ PUBLIC role grants  
❌ Complex multi-script workflows  
❌ Security trade-offs

---

## 🚀 Getting Started

**Ready to begin?**
- **Manual Setup:** Follow **[Setup Guide](docs/01-SETUP.md)**
- **Automated Setup:** Run `./tools/mcp all --profile <PROFILE>` (macOS) or `tools\mcp all --profile <PROFILE>` (Windows)
- **Full Documentation:** Browse **[docs/](docs/)** directory for complete guides
