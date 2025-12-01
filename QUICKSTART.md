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

3. **Run the automated setup (optional but recommended)**
   - macOS: `./tools/mcp all --profile <SNOWFLAKE_PROFILE>`
   - Windows: `tools\mcp all --profile <SNOWFLAKE_PROFILE>`
   This orchestrates token creation, MCP provisioning, and verification using the Snow CLI. Provide the `--profile` argument associated with an account that has `ACCOUNTADMIN`, `SYSADMIN`, and `SECURITYADMIN` privileges.

4. **Run individual commands as needed**
   If you prefer manual execution or need to re-run a specific step:
   - Create token: `./tools/mcp token --profile <PROFILE>` (Windows: `tools\mcp token --profile <PROFILE>`)
   - Setup MCP: `./tools/mcp setup --profile <PROFILE>` (Windows: `tools\mcp setup --profile <PROFILE>`)
   - Test connection: `./tools/mcp test --url <MCP_URL> --hostname <ORG-ACCOUNT>.snowflakecomputing.com`

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
