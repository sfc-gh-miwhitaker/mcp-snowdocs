# Security Posture and Governance

**Goal:** Document the least-privilege design for the Snowflake MCP integration and provide actionable steps for audits, compliance reviews, and teardown.

## Prerequisites

- Successful completion of [`docs/01-SETUP.md`](01-SETUP.md)
- Ability to run SQL as `SECURITYADMIN` or another role empowered to manage grants
- Access to the Snowflake documentation share `SNOWFLAKE_DOCUMENTATION`

## Authentication Methods

### OAuth 2.0 (Production-Grade Option)

OAuth is the production-grade choice for organizations deploying MCP integrations at scale. It provides:

- Token lifecycle management through refresh tokens
- Centralized credential rotation
- Better audit trails through OAuth flows
- Reduced risk of hardcoded token leakage

**When to use OAuth:**
- Production deployments with multiple users
- Enterprise environments with compliance requirements
- Long-lived integrations requiring token rotation

**Setup complexity:** Requires creating a Security Integration and implementing OAuth flow in your client.

For OAuth setup instructions, see the [Snowflake OAuth documentation](https://docs.snowflake.com/en/user-guide/oauth-snowflake-overview).

### Programmatic Access Tokens (PAT) (Demo & Development)

PAT tokens are simpler to configure and work great for demos and learning environments. This project uses PAT tokens to minimize setup friction.

**When to use PAT:**
- Development and testing environments
- Demo projects and proof-of-concepts
- Personal learning and exploration
- Single-user integrations

**Security considerations for PAT:**
- Store tokens in secure credential managers (1Password, Vault, etc.)
- Never commit tokens to version control
- Use the least-privileged role (this project uses `MCP_ACCESS_ROLE`)
- Monitor token usage: `SHOW USER PROGRAMMATIC ACCESS TOKENS`
- Rotate tokens regularly (default expiry: 365 days)

**Setup complexity:** Simple - generate token and add to config file.

### Comparison Table

| Aspect | OAuth 2.0 | PAT Tokens |
|--------|-----------|------------|
| Best for | Production deployments | Demos, development, learning |
| Setup complexity | Higher (security integration + OAuth flow) | Lower (generate and copy) |
| Token rotation | Automatic (refresh tokens) | Manual (re-run create script) |
| Audit trail | OAuth flow logs | Token usage logs |
| Multi-user support | Native | Requires per-user tokens |
| Recommended by Snowflake | Yes, for production | Yes, for non-production |

**This project demonstrates both best-practice implementation patterns AND provides a functional tool. We use PAT for simplicity, but the architecture supports OAuth if you need it.**

---

## Security Model Overview

The project enforces a dedicated role, `MCP_ACCESS_ROLE`, that grants only the privileges necessary to call the Snowflake-managed MCP server.

| Privilege | Object | Purpose |
|-----------|--------|---------|
| `USAGE` | `SNOWFLAKE_INTELLIGENCE` database | Allows access to the Snowflake-managed MCP artifacts |
| `USAGE` | `SNOWFLAKE_INTELLIGENCE.MCP` schema | Allows access to the specific MCP server object |
| `USAGE` | `SNOWFLAKE_MCP_SERVER` | Permits JSON-RPC calls to the MCP server endpoint |
| `USAGE` | `GET_ACCOUNT_INFO()` function | Allows invoking the custom account info tool |
| `USAGE` | `FIND_SNOWFLAKE_FUNCTIONS(VARCHAR)` function | Allows invoking the custom function finder tool |
| `IMPORTED PRIVILEGES` | `SNOWFLAKE_DOCUMENTATION` database | Grants read access to the Cortex Search service powering the documentation |

### Why PUBLIC Role Is Not Used

- PUBLIC inherits any grants applied across the account, often leading to uncontrolled access.
- Revoking PUBLIC requires broad coordination and can break unrelated workloads.
- Tokens scoped to PUBLIC have a large blast radius; compromise exposes every object PUBLIC can touch.
- `MCP_ACCESS_ROLE` provides a narrow, auditable permission surface aligned with least-privilege principles.

---

## Access Control by Tool Type

Access to the MCP Server does NOT automatically grant access to tools. Permissions must be granted separately for each tool.

| Tool Type | Object | Required Privilege | Purpose |
|-----------|--------|-------------------|---------|
| `CORTEX_SEARCH_SERVICE_QUERY` | Cortex Search Service | `SELECT` or `IMPORTED PRIVILEGES` | Invoke Cortex Search tool |
| `GENERIC` (UDF) | User-Defined Function | `USAGE` | Invoke custom tool (UDF) |
| `GENERIC` (Stored Proc) | Stored Procedure | `USAGE` | Invoke custom tool (stored procedure) |
| `CORTEX_ANALYST_MESSAGE` | Semantic View | `SELECT` | Invoke Cortex Analyst tool |
| `CORTEX_AGENT_RUN` | Cortex Agent | `USAGE` | Invoke Cortex Agent tool |
| `SYSTEM_EXECUTE_SQL` | MCP Server | `USAGE` + database permissions | Execute arbitrary SQL |

**This project's tool grants:**
- `USAGE` on `GET_ACCOUNT_INFO()` function (custom tool)
- `USAGE` on `FIND_SNOWFLAKE_FUNCTIONS(VARCHAR)` function (custom tool)
- `IMPORTED PRIVILEGES` on `SNOWFLAKE_DOCUMENTATION` (for Cortex Search)
- `USAGE` on the MCP server object itself

---

## Audit Checklist

Run the following statements to confirm that the security posture is intact:

```sql
-- Confirm role grants
SHOW GRANTS OF ROLE MCP_ACCESS_ROLE;

-- Verify MCP server exists
SHOW MCP SERVERS IN SCHEMA SNOWFLAKE_INTELLIGENCE.MCP;

-- Confirm documentation share is available
SHOW GRANTS TO ROLE MCP_ACCESS_ROLE;
```

Expected results:
- Only the four privileges listed above should appear.
- The MCP server `SNOWFLAKE_MCP_SERVER` should be present.
- No additional database or schema privileges should be attached to `MCP_ACCESS_ROLE`.

## Incident Response and Token Rotation

1. **Generate a new token** by rerunning `sql/01_setup/create_token.sql`.
2. **Reapply the setup** using `sql/01_setup/setup_mcp.sql` to ensure the new token receives the required role grants.
3. **Replace client credentials** in IDE configurations.
4. **Invalidate the old token** with:
   ```sql
   ALTER USER <username> DROP PROGRAMMATIC ACCESS TOKEN <token_name>;
   ```
5. **Document the rotation** in `.cursor/docs/CHANGELOG.md` or your internal runbook.

## Cleanup Workflow

When the demo is no longer needed:

1. Run `sql/99_cleanup/teardown_all.sql` to remove:
   - `SNOWFLAKE_INTELLIGENCE.MCP.SNOWFLAKE_MCP_SERVER`
   - `MCP_ACCESS_ROLE` and its grants
2. Confirm that:
   - `SNOWFLAKE_EXAMPLE` database remains intact (per cleanup rule)
   - Shared resources such as `SFE_*` API integrations are untouched
3. Optionally drop PAT tokens via `ALTER USER ... DROP PROGRAMMATIC ACCESS TOKEN`.

## Documentation and Reporting

- Capture audit evidence (grants, token rotations, cleanup runs) in `.cursor/docs/CHANGELOG.md` or a dedicated compliance log stored under `.cursor/docs/`.
- Reference `docs/01-SETUP.md` for operational steps if remediation is required.

## Navigation

- **Previous:** [`docs/01-SETUP.md`](01-SETUP.md)
- **Next:** [`docs/03-TROUBLESHOOTING.md`](03-TROUBLESHOOTING.md)
- **Related:** [`docs/04-CUSTOM-TOOLS.md`](04-CUSTOM-TOOLS.md) - Custom tool implementation and security
