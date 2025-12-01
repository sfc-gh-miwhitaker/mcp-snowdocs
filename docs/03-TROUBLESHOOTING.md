# Troubleshooting and Validation

**Goal:** Provide a repeatable workflow to diagnose MCP connectivity issues, validate configuration, and document resolutions.

## Prerequisites

- Completion of [`docs/01-SETUP.md`](01-SETUP.md) and configuration of an MCP-compatible client
- Access to run SQL as the user who owns the PAT token
- `curl`, `jq`, and `openssl` (macOS/Linux) or PowerShell 7 (Windows) for endpoint validation

## Diagnostic Workflow

1. **Gather context**
   - Confirm the exact error message from your IDE or CLI.
   - Record the timestamp and which environment (dev/test/prod) encountered the issue.

2. **Validate MCP endpoint**
   - macOS: `./tools/mcp test --url <MCP_URL> --hostname <ORG-ACCOUNT>.snowflakecomputing.com`
   - Windows: `tools\mcp test --url <MCP_URL> --hostname <ORG-ACCOUNT>.snowflakecomputing.com`
   - Expected results:
     - SSL validation output showing a valid certificate subject.
     - HTTP status `200`, `400`, or `405` with JSON payload.

3. **Inspect Snowflake grants**
   - Run `sql/03_operations/troubleshoot.sql` in Snowsight.
   - Review the result sets for:
     - Presence of `MCP_ACCESS_ROLE`
     - Correct grants to the role
     - Existence of the MCP server object

4. **Regenerate credentials (if required)**
   - Rerun `sql/01_setup/create_token.sql` to generate a new token.
   - Rerun `sql/01_setup/setup_mcp.sql` to reapply grants and obtain the MCP URL.
   - Update IDE configuration with the new token and restart the client.

5. **Document the incident**
   - Capture the remediation steps and outcome in `.cursor/docs/CHANGELOG.md` or your operational log.

## Common Issues and Resolutions

| Symptom | Probable Cause | Resolution |
|---------|----------------|------------|
| HTTP 401 from verification script | Expired or incorrect token | Regenerate token and update IDE configuration |
| HTTP 404 from verification script | MCP server not provisioned | Rerun `sql/01_setup/setup_mcp.sql` |
| SSL certificate failure | Region-based hostname used | Switch to `<org>-<account>.snowflakecomputing.com` |
| IDE cannot discover MCP server | Client not restarted after config update | Save config and restart the IDE |
| "Failed to open SSE stream: Not Acceptable" | SSE content negotiation issue | Use local proxy - see [Proxy Setup](05-PROXY-SETUP.md) |
| 406 Not Acceptable | Accept header not set correctly | Use local proxy - see [Proxy Setup](05-PROXY-SETUP.md) |

## Escalation

- If the issue persists after completing the diagnostic workflow, collect the SQL output, verification script logs, and IDE screenshots, then escalate through your internal support process.

## MCP Protocol Version Compatibility

**Supported version:** Snowflake supports MCP protocol revision `2025-06-18`

If you encounter protocol version errors:
- Verify your MCP client supports protocol `2025-06-18`
- Update your MCP client library to the latest version
- Review [MCP specification](https://modelcontextprotocol.io/) for compatibility details

## Hostname Format Issues

**Issue:** Connection errors with MCP server URL

**Cause:** Underscores in hostname (Snowflake account or organization names)

**Fix:** The setup script automatically converts underscores to hyphens in the URL. If you manually constructed the URL, ensure you replace underscores with hyphens:
- ❌ `my_org-my_account.snowflakecomputing.com`
- ✅ `my-org-my-account.snowflakecomputing.com`

Per Snowflake documentation, MCP servers have connection issues with hostnames containing underscores.

## Navigation

- **Previous:** [`docs/02-SECURITY.md`](02-SECURITY.md)
- **Next:** [`docs/04-CUSTOM-TOOLS.md`](04-CUSTOM-TOOLS.md)
