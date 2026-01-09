# Network Flow - Snowdocs MCP Server
Author: SE Community
Last Updated: 2026-01-09
Expires: 2026-02-07 (30 days from creation)
Status: Reference Implementation

![Snowflake](https://img.shields.io/badge/Snowflake-29B5E8?style=for-the-badge&logo=snowflake&logoColor=white)

Reference Implementation: This code demonstrates production-grade architectural patterns and best practices. Review and customize security, networking, and logic for your organization's specific requirements before deployment.

## Overview
This diagram shows the network path from an MCP client to Snowflake over HTTPS, and the internal Snowflake calls made by the MCP server tools (documentation search).

```mermaid
graph TB
  subgraph "Client Machine"
    IDE[MCP Client<br/>Cursor / Claude Desktop / VS Code]
  end

  subgraph "Public Internet"
    Net[HTTPS/TLS]
  end

  subgraph "Snowflake Cloud"
    SF[Snowflake Account<br/>account.snowflakecomputing.com<br/>:443 HTTPS]
    API[Snowflake REST API<br/>/api/v2/.../mcp-servers/...<br/>:443 HTTPS]
    MCP[MCP Server Object<br/>SNOWFLAKE_EXAMPLE.SNOWDOCS_MCP...]
    WH[Warehouse<br/>SFE_SNOWDOCS_MCP_WH]
    DocsSvc[Snowflake-managed Docs Search Service<br/>SNOWFLAKE_DOCUMENTATION...]
  end

  IDE -->|Bearer token_secret<br/>HTTPS :443| Net
  Net -->|HTTPS :443| SF
  SF -->|HTTPS :443| API
  API --> MCP

  MCP -->|executes SQL on| WH
  MCP --> DocsSvc
```

## Component Descriptions
- Purpose: MCP client
- Technology: IDE integration that speaks MCP over HTTP(S)
- Location: User workstation
- Deps: User config includes `MCP_URL` and `Authorization: Bearer <TOKEN_SECRET>`

- Purpose: Snowflake API endpoint
- Technology: Snowflake REST API (`/api/v2/.../mcp-servers/...`)
- Location: Snowflake account URL
- Deps: PAT token + role grants

- Purpose: Execution environment
- Technology: Snowflake warehouse (`SFE_SNOWDOCS_MCP_WH`)
- Location: Snowflake account
- Deps: Granted to access role; used for tool execution

- Purpose: Documentation search backend
- Technology: Snowflake-managed `SNOWFLAKE_DOCUMENTATION` + Cortex Search service
- Location: Snowflake-managed database
- Deps: Imported privileges granted to access role

## Change History
See `.cursor/DIAGRAM_CHANGELOG.md` for vhistory.
