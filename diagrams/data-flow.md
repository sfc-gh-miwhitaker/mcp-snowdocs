# Data Flow - Snowdocs MCP Server
Author: SE Community
Last Updated: 2026-01-09
Expires: 2026-02-07 (30 days from creation)
Status: Reference Implementation

![Snowflake](https://img.shields.io/badge/Snowflake-29B5E8?style=for-the-badge&logo=snowflake&logoColor=white)

Reference Implementation: This code demonstrates production-grade architectural patterns and best practices. Review and customize security, networking, and logic for your organization's specific requirements before deployment.

## Overview
This diagram shows how an MCP client (Cursor/Claude/VS Code) calls the Snowflake MCP endpoint, how authentication works at a high level, and how queries are routed to Snowflake-managed documentation search or custom tool functions.

```mermaid
graph LR
  subgraph "Setup (Snowsight)"
    User[User]
    Snowsight[Snowsight]
    Deploy[deploy_all.sql<br/>Run All]
  end

  subgraph "Snowflake Account"
    MCP[MCP Server<br/>SNOWFLAKE_EXAMPLE.SNOWDOCS_MCP.SNOWFLAKE_DOCS_MCP_SERVER]
    Fn[Custom Tool Function<br/>GET_ACCOUNT_INFO()]
    Docs[Cortex Search Service Query<br/>SNOWFLAKE_DOCUMENTATION...]
    WH[Warehouse<br/>SFE_SNOWDOCS_MCP_WH]
    Role[Access Role<br/>SFE_SNOWDOCS_MCP_ACCESS_ROLE]
    PAT[PAT Token<br/>(token secret shown once)]
  end

  subgraph "MCP Client"
    IDE[Cursor / Claude Desktop / VS Code]
  end

  User --> Snowsight --> Deploy
  Deploy -->|Creates| MCP
  Deploy -->|Creates| Fn
  Deploy -->|Creates/Grants| Role
  Deploy -->|Adds token to user| PAT
  Deploy -->|Creates/uses| WH

  IDE -->|HTTPS + Bearer token_secret| MCP
  MCP -->|Executes on| WH
  MCP -->|RBAC enforcement| Role

  MCP -->|tool: get-account-info| Fn
  MCP -->|tools: docs-search / function-finder| Docs

  Fn -->|Returns OBJECT| IDE
  Docs -->|Returns matched docs chunks| IDE
```

## Component Descriptions
- Purpose: Deployment script
- Technology: Snowflake SQL / Snowflake Scripting (`EXECUTE IMMEDIATE $$ ... $$`)
- Location: `deploy_all.sql`
- Deps: Requires `ACCOUNTADMIN` to create account-level objects (warehouse/role) and MCP server

- Purpose: MCP server endpoint
- Technology: Snowflake `MCP SERVER`
- Location: `deploy_all.sql`
- Deps: Uses Snowflake-managed documentation search service + custom function

- Purpose: Documentation search
- Technology: `CORTEX_SEARCH_SERVICE_QUERY` tool against Snowflake-managed `SNOWFLAKE_DOCUMENTATION`
- Location: MCP server specification in `deploy_all.sql`
- Deps: `GRANT IMPORTED PRIVILEGES ON DATABASE SNOWFLAKE_DOCUMENTATION ...`

- Purpose: Authentication + authorization
- Technology: Programmatic Access Token (PAT) + RBAC role grants
- Location: PAT created in `deploy_all.sql`; bearer token used in MCP client config
- Deps: `SFE_SNOWDOCS_MCP_ACCESS_ROLE` granted USAGE on MCP server and function

## Change History
See `.cursor/DIAGRAM_CHANGELOG.md` for vhistory.
