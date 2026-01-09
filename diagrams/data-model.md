# Data Model - Snowdocs MCP Server
Author: SE Community
Last Updated: 2026-01-09
Expires: 2026-02-07 (30 days from creation)
Status: Reference Implementation

![Snowflake](https://img.shields.io/badge/Snowflake-29B5E8?style=for-the-badge&logo=snowflake&logoColor=white)

Reference Implementation: This code demonstrates production-grade architectural patterns and best practices. Review and customize security, networking, and logic for your organization's specific requirements before deployment.

## Overview
This diagram shows the Snowflake objects created by `deploy_all.sql` and how they relate to each other to expose an MCP server endpoint backed by Snowflake-managed documentation search.

```mermaid
erDiagram
  WAREHOUSE ||--o{ MCP_SERVER : "executes with"
  ROLE ||--o{ MCP_SERVER : "USAGE on"
  DATABASE_SNOWFLAKE_EXAMPLE ||--o{ SCHEMA_SNOWDOCS_MCP : contains
  SCHEMA_SNOWDOCS_MCP ||--o{ MCP_SERVER : contains
  USER ||--o{ PROGRAMMATIC_ACCESS_TOKEN : "auth secret"
  USER ||--o{ ROLE : "granted role"

  WAREHOUSE {
    string name "SFE_SNOWDOCS_MCP_WH"
    string size "XSMALL"
    int auto_suspend_seconds
  }

  DATABASE_SNOWFLAKE_EXAMPLE {
    string name "SNOWFLAKE_EXAMPLE"
    string purpose "shared demo database"
  }

  SCHEMA_SNOWDOCS_MCP {
    string name "SNOWFLAKE_EXAMPLE.SNOWDOCS_MCP"
    string purpose "project namespace"
  }

  MCP_SERVER {
    string name "SNOWFLAKE_DOCS_MCP_SERVER"
    string tool_1 "snowflake-docs-search"
    string tool_2 "snowflake-function-finder"
  }

  ROLE {
    string name "SFE_SNOWDOCS_MCP_ACCESS_ROLE"
    string purpose "minimal API access"
  }

  PROGRAMMATIC_ACCESS_TOKEN {
    string name "MCP_PAT_YYYYMMDD_HH24MISS"
    int days_to_expiry
  }

  USER {
    string name "CURRENT_USER()"
  }
```

## Component Descriptions
- Purpose: Snowflake Warehouse
- Technology: Snowflake virtual warehouse (`SFE_SNOWDOCS_MCP_WH`)
- Location: Created in `deploy_all.sql`
- Deps: Granted to `SFE_SNOWDOCS_MCP_ACCESS_ROLE`

- Purpose: Project schema namespace
- Technology: Snowflake database + schema (`SNOWFLAKE_EXAMPLE.SNOWDOCS_MCP`)
- Location: Created in `deploy_all.sql`
- Deps: `SFE_SNOWDOCS_MCP_ACCESS_ROLE` granted USAGE on DB/SCHEMA

- Purpose: MCP server endpoint
- Technology: Snowflake `MCP SERVER` object exposing tools
- Location: Created in `deploy_all.sql`
- Deps: Uses Snowflake-managed Cortex Search service; executed on `SFE_SNOWDOCS_MCP_WH`

- Purpose: Access role + token
- Technology: Snowflake RBAC + Programmatic Access Token (PAT)
- Location: Created/assigned in `deploy_all.sql`
- Deps: `SFE_SNOWDOCS_MCP_ACCESS_ROLE` is granted USAGE on the MCP server; PAT is added to the current user

## Change History
See `.cursor/DIAGRAM_CHANGELOG.md` for vhistory.
