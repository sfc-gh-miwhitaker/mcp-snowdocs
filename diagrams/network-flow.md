# Network Flow - Snowflake MCP Server Setup

**Author:** SE Community
**Last Updated:** 2025-11-21
**Status:** Reference Implementation

---

![Snowflake](https://img.shields.io/badge/Snowflake-29B5E8?style=for-the-badge&logo=snowflake&logoColor=white)

⚠️ **WARNING: This is a demonstration project. NOT FOR PRODUCTION USE.**

---

## Overview

This diagram highlights the network boundaries and protocols between the developer workstation, the Snowflake account hosting the MCP server, and the Snowflake-managed documentation share used by Cortex Search.

---

## Diagram

```mermaid
graph TB
    subgraph "Developer Workstation"
        cli[python.cli.main<br/>(tools/*.sh | .bat)]
        ide[MCP-Compatible IDE]
    end

    subgraph "Public Internet"
        tls1[TLS 1.2+ HTTPS :443]
        tls2[TLS 1.2+ HTTPS :443]
    end

    subgraph "Snowflake Account"
        acct[Snowflake Control Plane<br/>(org-account.snowflakecomputing.com)]
        server[SNOWFLAKE_INTELLIGENCE.MCP.SNOWFLAKE_MCP_SERVER]
        mcp_api[JSON-RPC Endpoint<br/>/api/v2/databases/.../mcp-servers/snowflake_mcp_server]
    end

    subgraph "Snowflake Managed Share"
        docs_db[SNOWFLAKE_DOCUMENTATION<br/>(Marketplace Share)]
        cortex[CKE_SNOWFLAKE_DOCS_SERVICE]
    end

    cli -->|Snow CLI / HTTPS| tls1 --> acct
    ide -->|JSON-RPC over HTTPS| tls2 --> mcp_api
    mcp_api --> server
    server -->|Cortex Search Requests| cortex
    cortex --> docs_db
```

---

## Component Descriptions

### python.cli.main / tools/mcp CLI
- **Purpose:** Sends Snow CLI commands and optional verification requests over HTTPS.
- **Technology:** Python subprocess calls into the Snow CLI; unified CLI wrappers.
- **Location:** `python/cli/main.py`, `tools/mcp`, `tools/mcp.cmd`
- **Dependencies:** Snow CLI authentication profile, outbound HTTPS access on port 443

### SNOWFLAKE_INTELLIGENCE.MCP.SNOWFLAKE_MCP_SERVER
- **Purpose:** Hosts the MCP JSON-RPC endpoint for documentation retrieval.
- **Technology:** Snowflake-managed MCP server
- **Location:** Snowflake account `SNOWFLAKE_INTELLIGENCE.MCP`
- **Dependencies:** ACCESS via HTTPS from IDE, MCP_ACCESS_ROLE grants

### SNOWFLAKE_DOCUMENTATION / CKE_SNOWFLAKE_DOCS_SERVICE
- **Purpose:** Provides the Cortex Search Service that returns documentation matches.
- **Technology:** Snowflake Cortex Search (managed)
- **Location:** Marketplace database `SNOWFLAKE_DOCUMENTATION.SHARED`
- **Dependencies:** Imported privileges granted to `MCP_ACCESS_ROLE`

### MCP-Compatible IDE
- **Purpose:** Issues JSON-RPC calls to the MCP server endpoint from the developer workstation.
- **Technology:** Cursor, Claude Desktop, VS Code (Continue), etc.
- **Location:** Developer workstation
- **Dependencies:** Internet access to the Snowflake account endpoint on port 443

---

## Change History

See `.cursor/docs/DIAGRAM_CHANGELOG.md` for version history.
