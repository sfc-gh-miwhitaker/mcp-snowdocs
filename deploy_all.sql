/*******************************************************************************
 * Script: deploy_all.sql
 * Purpose: Deploy a Snowflake-managed MCP server for searching Snowflake docs from MCP-enabled IDEs.
 *
 * Author: SE Community
 * Created: 2026-01-08
 * EXPIRES: 2026-02-07
 *
 * EXECUTION METHOD: Snowsight "Run All" (Copy/Paste → Click "Run All")
 *
 * OUTPUT:
 *   - Single result set containing MCP_URL
 *
 * ESTIMATED RUNTIME: ~2 minutes
 * ESTIMATED COST: Low (XSMALL warehouse, short runtime)
 ******************************************************************************/

/*******************************************************************************
 * EXPIRATION CHECK (halts Run All when expired)
 ******************************************************************************/

EXECUTE IMMEDIATE $$
DECLARE
  demo_expired EXCEPTION (-20001, 'This demo expired on 2026-02-07. Update deploy_all.sql to extend expiration.');
  expires_on DATE := '2026-02-07'::DATE;
BEGIN
  IF (CURRENT_DATE() > expires_on) THEN
    RAISE demo_expired;
  END IF;
END;
$$;

/*******************************************************************************
 * PART 1: Context + Infrastructure
 ******************************************************************************/

-- Best practice: never create objects as ACCOUNTADMIN.
-- Use SYSADMIN for warehouses + database objects, and SECURITYADMIN for RBAC (roles/grants).
USE ROLE SYSADMIN;

CREATE WAREHOUSE IF NOT EXISTS SFE_SNOWDOCS_MCP_WH
  WAREHOUSE_SIZE = 'XSMALL'
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE
  INITIALLY_SUSPENDED = TRUE
  COMMENT = 'DEMO: Snowflake MCP Server (docs search). Author: SE Community. EXPIRES: 2026-02-07';

USE WAREHOUSE SFE_SNOWDOCS_MCP_WH;

-- Demo standard: all demo objects live in SNOWFLAKE_EXAMPLE (create if missing)
CREATE DATABASE IF NOT EXISTS SNOWFLAKE_EXAMPLE
  COMMENT = 'DEMO: Shared demo database for reference implementations. Author: SE Community. EXPIRES: 2026-02-07';

-- Project-specific schema namespace (collision-proof)
CREATE SCHEMA IF NOT EXISTS SNOWFLAKE_EXAMPLE.SNOWDOCS_MCP
  COMMENT = 'DEMO: Snowflake MCP server objects (docs search). Author: SE Community. EXPIRES: 2026-02-07';

/*******************************************************************************
 * PART 3: MCP Server
 ******************************************************************************/

CREATE OR REPLACE MCP SERVER SNOWFLAKE_EXAMPLE.SNOWDOCS_MCP.SNOWFLAKE_DOCS_MCP_SERVER
  FROM SPECIFICATION $$
    tools:
      - name: "snowflake-docs-search"
        type: "CORTEX_SEARCH_SERVICE_QUERY"
        identifier: "SNOWFLAKE_DOCUMENTATION.SHARED.CKE_SNOWFLAKE_DOCS_SERVICE"
        description: "Search Snowflake documentation using Cortex Search"
        title: "Snowflake Documentation Search"

      - name: "snowflake-function-finder"
        type: "CORTEX_SEARCH_SERVICE_QUERY"
        identifier: "SNOWFLAKE_DOCUMENTATION.SHARED.CKE_SNOWFLAKE_DOCS_SERVICE"
        description: "Search Snowflake documentation for built-in functions and usage examples by keyword"
        title: "Snowflake Function Finder"
  $$;

/*******************************************************************************
 * PART 4: Minimal-Privilege Access Role
 ******************************************************************************/

USE ROLE SECURITYADMIN;

CREATE ROLE IF NOT EXISTS SFE_SNOWDOCS_MCP_ACCESS_ROLE
  COMMENT = 'DEMO: Minimal privileges for Snowflake MCP server API access. Author: SE Community. EXPIRES: 2026-02-07';

GRANT USAGE ON WAREHOUSE SFE_SNOWDOCS_MCP_WH TO ROLE SFE_SNOWDOCS_MCP_ACCESS_ROLE;

GRANT USAGE ON DATABASE SNOWFLAKE_EXAMPLE TO ROLE SFE_SNOWDOCS_MCP_ACCESS_ROLE;
GRANT USAGE ON SCHEMA SNOWFLAKE_EXAMPLE.SNOWDOCS_MCP TO ROLE SFE_SNOWDOCS_MCP_ACCESS_ROLE;

GRANT USAGE ON MCP SERVER SNOWFLAKE_EXAMPLE.SNOWDOCS_MCP.SNOWFLAKE_DOCS_MCP_SERVER
  TO ROLE SFE_SNOWDOCS_MCP_ACCESS_ROLE;

-- Documentation database is provided by Snowflake; this grants access to the underlying Cortex Search service.
GRANT IMPORTED PRIVILEGES ON DATABASE SNOWFLAKE_DOCUMENTATION TO ROLE SFE_SNOWDOCS_MCP_ACCESS_ROLE;

-- Assign role to the current user for immediate testing.
SET current_username = CURRENT_USER();
GRANT ROLE SFE_SNOWDOCS_MCP_ACCESS_ROLE TO USER IDENTIFIER($current_username);

/*******************************************************************************
 * PART 5: Final Output (only visible result in Snowsight Run All)
 ******************************************************************************/

SELECT
  (
    'https://' ||
    REPLACE(LOWER(CURRENT_ORGANIZATION_NAME()), '_', '-') || '-' ||
    REPLACE(LOWER(CURRENT_ACCOUNT_NAME()), '_', '-') ||
    '.snowflakecomputing.com/api/v2/databases/SNOWFLAKE_EXAMPLE/schemas/snowdocs_mcp/mcp-servers/snowflake_docs_mcp_server'
  )::STRING AS mcp_url,
  'SFE_SNOWDOCS_MCP_ACCESS_ROLE' AS access_role,
  'SFE_SNOWDOCS_MCP_WH' AS warehouse,
  'If you need a new PAT token, run create_pat.sql (optional). See README.md.' AS next_step;

-- =============================================================================
-- VERIFICATION QUERIES (Run individually AFTER deployment completes)
-- =============================================================================
/*
SHOW MCP SERVERS IN SCHEMA SNOWFLAKE_EXAMPLE.SNOWDOCS_MCP;
SHOW ROLES LIKE 'SFE_SNOWDOCS_MCP_ACCESS_ROLE';
DESC MCP SERVER SNOWFLAKE_EXAMPLE.SNOWDOCS_MCP.SNOWFLAKE_DOCS_MCP_SERVER;
*/
