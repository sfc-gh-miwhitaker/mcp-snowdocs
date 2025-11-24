# Cross-Platform Automation Wrappers

This directory contains cross-platform CLI wrappers for Snowflake MCP server setup and verification.

## Architecture

**Design Pattern:** Shell wrappers delegate to Python modules for cross-platform compatibility.

- **Wrappers:** `.sh` (Unix/macOS) and `.bat` (Windows) scripts
- **Core Logic:** `python/cli/main.py` (Python module)
- **Execution:** Wrappers call `python -m python.cli.main <command>`

This design ensures:
- ✅ Business logic in one place (Python)
- ✅ Native shell experience on each platform
- ✅ Consistent behavior across operating systems
- ✅ Easy testing (test Python modules directly)

---

## Available Scripts

All numbered scripts are provided in both Unix (`.sh`) and Windows (`.bat`) formats.

### 00_master - Complete Automation
**Purpose:** End-to-end workflow that runs all setup steps sequentially.

**Usage:**
```bash
# Unix/macOS
./tools/00_master.sh --profile <SNOWFLAKE_PROFILE>

# Windows
tools\00_master.bat --profile <SNOWFLAKE_PROFILE>
```

**What it does:**
1. Runs `create-token` module → generates PAT token
2. Runs `setup-mcp` module → provisions MCP server
3. Optionally runs `test-connection` module → verifies setup

**Options:**
- `--profile` - Snowflake CLI profile name (required)
- `--url` - MCP server URL for verification (required for test step)
- `--hostname` - Snowflake hostname for SSL verification (required for test step)
- `--skip-test` - Skip connection verification step
- `--verbose` - Show detailed command output
- `--dry-run` - Show commands without executing

---

### 01_create_token - Generate PAT Token
**Purpose:** Generate a Programmatic Access Token (PAT) for MCP authentication.

**Usage:**
```bash
# Unix/macOS
./tools/01_create_token.sh --profile <SNOWFLAKE_PROFILE>

# Windows
tools\01_create_token.bat --profile <SNOWFLAKE_PROFILE>
```

**What it does:**
- Executes `sql/01_setup/create_token.sql` via Snow CLI
- Creates a PAT token with 365-day expiration
- Displays TOKEN_SECRET (copy immediately!)

**Options:**
- `--profile` - Snowflake CLI profile name (required)
- `--verbose` - Show detailed command output
- `--dry-run` - Show command without executing

---

### 02_setup_mcp - Provision MCP Server
**Purpose:** Create MCP server infrastructure and configure least-privilege access.

**Usage:**
```bash
# Unix/macOS
./tools/02_setup_mcp.sh --profile <SNOWFLAKE_PROFILE>

# Windows
tools\02_setup_mcp.bat --profile <SNOWFLAKE_PROFILE>
```

**What it does:**
- Executes `sql/01_setup/setup_mcp.sql` via Snow CLI
- Creates SNOWFLAKE_INTELLIGENCE.MCP.SNOWFLAKE_MCP_SERVER
- Creates MCP_ACCESS_ROLE with minimal privileges
- Displays MCP server URL for IDE configuration

**Options:**
- `--profile` - Snowflake CLI profile name (required)
- `--verbose` - Show detailed command output
- `--dry-run` - Show command without executing

---

### 03_test_connection - Verify Setup
**Purpose:** Test MCP server connectivity and SSL certificate validation.

**Usage:**
```bash
# Unix/macOS
./tools/03_test_connection.sh \
  --url "https://<org>-<account>.snowflakecomputing.com/api/v2/databases/..." \
  --hostname "<org>-<account>.snowflakecomputing.com"

# Windows
tools\03_test_connection.bat ^
  --url "https://<org>-<account>.snowflakecomputing.com/api/v2/databases/..." ^
  --hostname "<org>-<account>.snowflakecomputing.com"
```

**What it does:**
- Validates SSL certificate for the hostname
- Sends HTTP request to MCP server URL
- Returns JSON summary with status/errors

**Options:**
- `--url` - Full MCP server URL (required)
- `--hostname` - Snowflake hostname for SSL check (required)
- `--token` - PAT token (optional, reads from config file)
- `--config` - Path to IDE config file containing token (optional)
- `--server-key` - Key name in config file (default: "Snowflake")

**Expected Output:**
```json
{
  "ssl_valid": true,
  "http_status": 200,
  "error": null,
  "response": "MCP Server: Ready and responding"
}
```

---

## Common Options

All scripts support these common options:

| Option | Description | Default |
|--------|-------------|---------|
| `--profile` | Snowflake CLI profile name | (required for SQL scripts) |
| `--verbose` | Show detailed command output | false |
| `--dry-run` | Show commands without executing | false |
| `--help` | Display help message | - |

---

## Prerequisites

1. **Python 3.10+** with dependencies installed:
   ```bash
   pip install -r python/requirements.txt
   ```

2. **Snowflake CLI (`snow`)** version 2.5.0+ configured with a profile:
   ```bash
   snow --version
   snow connection list
   ```

3. **Required Snowflake Roles:**
   - `ACCOUNTADMIN` (for marketplace terms acceptance)
   - `SYSADMIN` (for object creation)
   - `SECURITYADMIN` (for role management)

---

## Troubleshooting

### "Command not found" (Unix)
**Cause:** Script not executable

**Fix:**
```bash
chmod +x tools/*.sh
```

### "Python module not found"
**Cause:** Dependencies not installed or virtual environment not activated

**Fix:**
```bash
python3 -m venv .venv
source .venv/bin/activate  # Windows: .venv\Scripts\activate
pip install -r python/requirements.txt
```

### "Snow CLI not found"
**Cause:** Snow CLI not installed or not in PATH

**Fix:**
```bash
# Install Snow CLI
pip install snowflake-cli-labs

# Verify installation
snow --version
```

### "Profile not found"
**Cause:** Snow CLI profile doesn't exist

**Fix:**
```bash
# List available profiles
snow connection list

# Add a new profile
snow connection add
```

---

## Development

### Running Tests
```bash
# Run all tests
pytest python/tests/

# Run specific test file
pytest python/tests/test_cli_main.py

# Run with coverage
pytest --cov=python --cov-report=term-missing
```

### Adding New Scripts

1. **Create Python command** in `python/cli/main.py`:
   ```python
   def cmd_my_feature(args: argparse.Namespace) -> int:
       # Implementation
       return 0
   ```

2. **Add subcommand** to argument parser:
   ```python
   parser_my_feature = subparsers.add_parser('my-feature', help='...')
   parser_my_feature.set_defaults(func=cmd_my_feature)
   ```

3. **Create Unix wrapper** (`tools/##_my_feature.sh`):
   ```bash
   #!/bin/bash
   exec python3 -m python.cli.main my-feature "$@"
   ```

4. **Create Windows wrapper** (`tools/##_my_feature.bat`):
   ```batch
   @echo off
   python -m python.cli.main my-feature %*
   ```

5. **Make Unix script executable:**
   ```bash
   chmod +x tools/##_my_feature.sh
   ```

---

## Design Rationale

### Why Thin Wrappers?

**Problem:** Maintaining business logic in both `.sh` and `.bat` is error-prone and leads to drift.

**Solution:** Wrappers are 3-5 lines that delegate to Python:
```bash
#!/bin/bash
exec python3 -m python.cli.main <command> "$@"
```

**Benefits:**
- Single source of truth for logic
- Easy to test (Python only)
- Consistent error handling
- Cross-platform by default

### Why Not Pure Shell Scripts?

- ❌ Complex shell logic is hard to test
- ❌ Windows batch syntax differs from Bash
- ❌ Error handling inconsistent across platforms
- ❌ No type safety or linting

### Why Not Pure Python Scripts?

- ❌ Requires users to know `python -m` invocation
- ❌ Less discoverable (no `.sh` files to `ls`)
- ❌ Doesn't follow Unix conventions

**Hybrid approach** provides best of both worlds: native shell experience backed by robust Python implementation.

---

## See Also

- `../docs/01-SETUP.md` - Complete setup guide
- `../docs/03-TROUBLESHOOTING.md` - Detailed troubleshooting
- `../python/cli/main.py` - Core CLI implementation
