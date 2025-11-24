# Snowflake MCP Server Setup

**Goal:** Provision the Snowflake-managed Model Context Protocol (MCP) server, capture the generated credentials, and verify that an IDE can reach it.

## Prerequisites

- Snowflake account with `ACCOUNTADMIN`, `SYSADMIN`, and `SECURITYADMIN` roles
- Snowflake CLI (`snow`) version 2.5.0 or later configured with a profile that has the roles above
- Python 3.10 or later with dependencies from `python/requirements.txt` (`pip install -r python/requirements.txt`)
- Local tools capable of editing JSON files (for example `code`, `nano`, or `vim`)
- `curl`, `openssl`, and `jq` installed if you plan to run the Unix verification script
- PowerShell 7 minimum if you plan to run the Windows verification script

## Overview of Required Files

| File | Purpose | Location |
|------|---------|----------|
| `sql/01_setup/create_token.sql` | Generates a programmatic access token (PAT) scoped to the dedicated MCP role | Snowflake workspace |
| `sql/01_setup/setup_mcp.sql` | Builds the MCP server, grants least-privilege access, returns the MCP URL | Snowflake workspace |
| `sql/03_operations/troubleshoot.sql` | Diagnostic queries if verification fails | Snowflake workspace |
| `sql/99_cleanup/teardown_all.sql` | Removes MCP-specific resources while preserving shared infrastructure | Snowflake workspace |
| `tools/01_create_token.sh` / `.bat` | Runs `create_token.sql` through the Snow CLI | Local |
| `tools/02_setup_mcp.sh` / `.bat` | Runs `setup_mcp.sql` through the Snow CLI | Local |
| `tools/03_test_connection.sh` / `.bat` | Verifies the MCP endpoint over HTTPS | Local |
| `tools/00_master.sh` / `.bat` | Orchestrates the full setup workflow end-to-end | Local |

> The SQL scripts can be executed from Snowsight or by using the wrapper scripts above. Choose whichever approach matches your workflow.

## Step-by-Step Instructions

1. **Create the PAT token**
   - Execute `sql/01_setup/create_token.sql` in Snowsight **or** run `tools/01_create_token.sh --profile <PROFILE>` (Windows: `tools\01_create_token.bat --profile <PROFILE>`).
   - **Expected output:** A result set containing a `TOKEN_SECRET` column. Copy the token immediately; Snowflake displays it only once.

2. **Provision the MCP server**
   - Execute `sql/01_setup/setup_mcp.sql` in Snowsight **or** run `tools/02_setup_mcp.sh --profile <PROFILE>` (Windows: `tools\02_setup_mcp.bat --profile <PROFILE>`).
   - **Expected output:** A result set containing an `MCP_URL` column along with confirmation messages that the role grants were applied.

3. **Configure your MCP-compatible client**
   - Update the configuration file for your IDE (for example `~/.cursor/mcp.json` for Cursor) with:
     ```json
     {
       "mcpServers": {
         "Snowflake": {
           "url": "PASTE_MCP_URL_FROM_STEP_2",
           "headers": {
             "Authorization": "Bearer PASTE_TOKEN_SECRET_FROM_STEP_1"
           }
         }
       }
     }
     ```
   - Save the file and restart the IDE so the new server registration is loaded.

4. **Verify connectivity**
   - On macOS/Linux, run `tools/03_test_connection.sh --url <MCP_URL> --hostname <ORG-ACCOUNT>.snowflakecomputing.com`.
   - On Windows, run `tools\03_test_connection.bat --url <MCP_URL> --hostname <ORG-ACCOUNT>.snowflakecomputing.com`.
   - **Expected output:** HTTP status `200` or `400/405` along with a JSON response from the MCP server. SSL validation should succeed for the hostname you provide.

5. **(Optional) Run diagnostics**
   - If verification fails, execute `sql/03_operations/troubleshoot.sql` to confirm that the role grants and server objects exist.

## Troubleshooting

- **HTTP 401 or authorization errors**
  - Ensure the token was copied correctly and has not expired.
  - Re-run `sql/01_setup/create_token.sql` to generate a new token, then rerun `sql/01_setup/setup_mcp.sql` to reapply grants.

- **HTTP 404 or missing server**
  - Confirm `sql/01_setup/setup_mcp.sql` ran without errors and that the MCP server object exists via `SHOW MCP SERVERS IN SCHEMA SNOWFLAKE_INTELLIGENCE.MCP;`.

- **SSL certificate failures**
  - Use the organization-based hostname (`<org>-<account>.snowflakecomputing.com`). Region-based URLs will fail validation.

- **Token not found in `~/.cursor/mcp.json`**
  - Check that the configuration file uses the `Bearer <token>` format and that the JSON syntax is valid.

For additional diagnostic guidance, see `sql/03_operations/troubleshoot.sql` and the verification script output.

## Next Steps

- Continue with the security baseline in [`docs/02-SECURITY.md`](02-SECURITY.md) to understand the least-privilege posture and cleanup strategy.
- When you are ready to remove the demo resources, run the teardown routine explained in [`docs/02-SECURITY.md`](02-SECURITY.md) and execute `sql/99_cleanup/teardown_all.sql`.
