# Auth Flow - Snowdocs MCP Server
Author: SE Community
Last Updated: 2026-01-09
Expires: 2026-02-07 (30 days from creation)
Status: Reference Implementation

![Snowflake](https://img.shields.io/badge/Snowflake-29B5E8?style=for-the-badge&logo=snowflake&logoColor=white)

Reference Implementation: This code demonstrates production-grade architectural patterns and best practices. Review and customize security, networking, and logic for your organization's specific requirements before deployment.

## Overview
This diagram shows how a Programmatic Access Token (PAT) is created during deployment, how it is used by an MCP client as a bearer token, and how Snowflake RBAC enforces authorization for MCP server usage.

```mermaid
sequenceDiagram
  actor User
  participant Snowsight as Snowsight (Run All)
  participant SF as Snowflake
  participant Role as SFE_SNOWDOCS_MCP_ACCESS_ROLE
  participant MCP as MCP Server
  participant IDE as MCP Client

  User->>Snowsight: Run deploy_all.sql
  Snowsight->>SF: USE ROLE SYSADMIN + SECURITYADMIN
  SF->>SF: CREATE ROLE / GRANT USAGE / GRANT IMPORTED PRIVILEGES
  SF->>SF: ALTER USER ... ADD PROGRAMMATIC ACCESS TOKEN
  SF-->>Snowsight: token_secret (shown once)
  Snowsight-->>User: MCP_URL + TOKEN_SECRET

  User->>IDE: Configure MCP_URL + Bearer TOKEN_SECRET
  IDE->>SF: HTTPS request to MCP endpoint + Authorization: Bearer TOKEN_SECRET
  SF->>SF: Validate PAT token_secret
  SF->>SF: Resolve user + active role grants
  SF->>Role: Enforce USAGE on MCP server
  Role-->>SF: Authorized
  SF->>MCP: Execute tool request
  MCP-->>IDE: Tool response payload
```

## Component Descriptions
- Purpose: Token issuance
- Technology: Snowflake Programmatic Access Token (PAT)
- Location: `deploy_all.sql` (PART 5)
- Deps: Token secret must be stored securely by the user; it cannot be retrieved later

- Purpose: Authorization boundary
- Technology: Snowflake RBAC via `SFE_SNOWDOCS_MCP_ACCESS_ROLE`
- Location: `deploy_all.sql` (PART 4)
- Deps: Role must have USAGE on MCP server and warehouse, plus imported privileges for `SNOWFLAKE_DOCUMENTATION`

- Purpose: Runtime enforcement
- Technology: Snowflake API layer validating bearer token and evaluating grants
- Location: Snowflake account
- Deps: Correct MCP URL, valid token, and grants

## Change History
See `.cursor/DIAGRAM_CHANGELOG.md` for vhistory.
