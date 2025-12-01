# Snowflake MCP Server Quickstart

**Author:** SE Community
**Last Updated:** 2025-11-21

This quickstart walks through the required steps to provision the Snowflake-managed MCP server, configure an IDE, and verify connectivity.

## Sequential Workflow

1. **Review setup guide**
   Read `docs/01-SETUP.md` for prerequisites, environment preparation, and an outline of the SQL modules you will run.

2. **(Optional) Customize configuration**
   - Edit `config/settings.yaml` to change database names, roles, or warehouses
   - Edit `config/mcp_spec.yaml` to add or remove tools
   - See `docs/04-CUSTOM-TOOLS.md` for customization guide

3. **Run the automated master script (optional but recommended)**
   - macOS/Linux: `tools/00_master.sh --profile <SNOWFLAKE_PROFILE>`
   - Windows: `tools\00_master.bat --profile <SNOWFLAKE_PROFILE>`
   The master script orchestrates the token creation, MCP provisioning, and verification scripts using the Snow CLI. Provide the `--profile` argument associated with an account that has `ACCOUNTADMIN`, `SYSADMIN`, and `SECURITYADMIN` privileges.

4. **Run individual modules as needed**
   If you prefer manual execution or need to re-run a specific step:
   - Create token: `tools/01_create_token.sh --profile <PROFILE>` or `tools\01_create_token.bat --profile <PROFILE>`
   - Provision MCP: `tools/02_setup_mcp.sh --profile <PROFILE>` or `tools\02_setup_mcp.bat --profile <PROFILE>`
   - Verify endpoint: `tools/03_test_connection.sh --url <MCP_URL> --hostname <ORG-ACCOUNT>.snowflakecomputing.com` or the Windows `.bat` equivalent

5. **Configure your MCP-compatible IDE**
   Update the appropriate configuration file (for example `~/.cursor/mcp.json`) with the MCP URL and programmatic access token returned by the setup scripts. You can optionally test your configuration in `.secrets/mcp.json` before deploying to your IDE. Restart the IDE afterwards.

6. **Review security and documentation**
   - Review `docs/02-SECURITY.md` to understand the least-privilege security model
   - Keep `docs/03-TROUBLESHOOTING.md` handy for diagnostics
   - Learn about custom tools in `docs/04-CUSTOM-TOOLS.md`

7. **Teardown when finished**
   Execute `sql/99_cleanup/teardown_all.sql` from Snowsight (or `snow sql`) to remove MCP-specific resources while preserving shared infrastructure. Confirm that the `SNOWFLAKE_EXAMPLE` database and any shared `SFE_*` integrations remain in place.

## Expected Duration

- Environment preparation and script execution: approximately 10 minutes
- IDE configuration and validation: approximately 5 minutes
- Security review and documentation: approximately 5 minutes

Total time: about 20 minutes.

For deeper explanations and troubleshooting guidance, return to the numbered guides in the `docs/` directory.
